// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../../modules/dispatcher/Dispatchable.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {DispatcherLib} from "../../modules/dispatcher/DispatcherLib.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Test, console} from "forge-std/src/Test.sol";

library TestDispatchableLib {
    bytes4 internal constant FOO = bytes4(keccak256("foo()"));
    bytes4 internal constant BAR = bytes4(keccak256("bar()"));
}

contract Foo is Dispatchable {
    function signatures() external pure override returns (string[] memory _signatures) {
        _signatures = new string[](1);
        _signatures[0] = "foo()";
    }

    function selectors() public pure override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = TestDispatchableLib.FOO;
    }

    function foo() public pure returns (string memory) {
        return "Foo module";
    }
}

contract Bar is Dispatchable {
    function signatures() external pure override returns (string[] memory _signatures) {
        _signatures = new string[](1);
        _signatures[0] = "bar()";
    }

    function selectors() public pure override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = TestDispatchableLib.BAR;
    }

    function bar() public pure returns (string memory) {
        return "Bar module";
    }
}

contract Receiver is Dispatchable {
    event Received(address sender, uint256 value);
    error ReceiveRejected();

    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](1);
        signatures_[0] = "receive()";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](1);
        selectors_[0] = bytes4(0);
    }

    receive() external payable {
        if (msg.value == 7) revert ReceiveRejected();
        emit Received(msg.sender, msg.value);
    }

    // A permissive module fallback must not expose the reserved receive route.
    fallback() external payable {}
}

contract DispatcherTest is Test, ContextUpgradeable {
    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    Dispatcher dispatcher;
    Foo foo;

    function setUp() public {
        dispatcher = new Dispatcher(bob);

        vm.startPrank(bob);
        foo = new Foo();
        address[] memory _modules = new address[](1);
        _modules[0] = address(foo);
        dispatcher.addModule(_modules);
    }

    function testDispatcherReceiveRoute() public {
        Receiver receiver_ = new Receiver();
        address[] memory modules_ = new address[](1);
        modules_[0] = address(receiver_);
        dispatcher.addModule(modules_);
        assertEq(dispatcher.module(bytes4(0)), address(receiver_));
        DispatcherLib.Command[] memory commands_ = dispatcher.commands(modules_);
        assertEq(commands_[0].selector, bytes4(0));
        assertEq(commands_[0].signature, "receive()");

        vm.deal(bob, 1 ether);
        vm.expectEmit(address(dispatcher));
        emit Receiver.Received(bob, 1 ether);
        (bool success_,) = address(dispatcher).call{value: 1 ether}("");
        assertTrue(success_);
        assertEq(address(dispatcher).balance, 1 ether);
        assertEq(address(receiver_).balance, 0);

        Receiver replacement_ = new Receiver();
        modules_[0] = address(replacement_);
        vm.expectRevert(
            abi.encodeWithSelector(IDispatcher.CommandAlreadySet.selector, bytes4(0), address(replacement_))
        );
        dispatcher.addModule(modules_);

        modules_[0] = address(receiver_);
        dispatcher.removeModule(modules_);
        assertEq(dispatcher.module(bytes4(0)), address(0));
        (bool removedSuccess_, bytes memory data_) = address(dispatcher).call("");
        assertFalse(removedSuccess_);
        assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, bytes4(0)));
    }

    function testDispatcherReceiveBubblesRevert() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new Receiver());
        dispatcher.addModule(modules_);
        vm.deal(bob, 7);
        (bool success_, bytes memory data_) = address(dispatcher).call{value: 7}("");
        assertFalse(success_);
        assertEq(data_, abi.encodeWithSelector(Receiver.ReceiveRejected.selector));
        assertEq(address(dispatcher).balance, 0);
    }

    function testDispatcherRejectsNonemptyReceiveKey() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new Receiver());
        dispatcher.addModule(modules_);
        for (uint256 length_ = 1; length_ <= 5; length_++) {
            (bool success_, bytes memory data_) = address(dispatcher).call(new bytes(length_));
            assertFalse(success_);
            assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, bytes4(0)));
        }
    }

    function testDispatcherRejectsInvalidReceiveManifest() public {
        bytes4[] memory selectors_ = new bytes4[](1);
        selectors_[0] = bytes4(0);
        vm.mockCall(address(foo), abi.encodeWithSelector(Dispatchable.selectors.selector), abi.encode(selectors_));
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.InvalidSignature.selector, bytes4(0), "foo()"));
        dispatcher.verifyModule(address(foo));

        string[] memory signatures_ = new string[](1);
        signatures_[0] = "receive()";
        selectors_[0] = bytes4(keccak256("receive()"));
        vm.mockCall(address(foo), abi.encodeWithSelector(Dispatchable.signatures.selector), abi.encode(signatures_));
        vm.mockCall(address(foo), abi.encodeWithSelector(Dispatchable.selectors.selector), abi.encode(selectors_));
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.InvalidSignature.selector, selectors_[0], "receive()"));
        dispatcher.verifyModule(address(foo));
    }

    function testDispatcherInit() public view {
        assertEq(dispatcher.owner(address(dispatcher)), bob, "DispatcherTest: Owner not set");

        assertEq(dispatcher.module(TestDispatchableLib.FOO), address(foo), "DispatcherTest: foo() not set");
        address[] memory _modules = dispatcher.modules();
        assertEq(_modules.length, 1, "DispatcherTest: module count");
        assertEq(_modules[0], address(foo), "DispatcherTest: foo not listed");
        bytes4[] memory _selectors = dispatcher.selectors(address(foo));
        assertEq(_selectors.length, 1, "DispatcherTest: foo selectors length");
        assertEq(_selectors[0], TestDispatchableLib.FOO, "DispatcherTest: foo selector");
        string[] memory _signatures = dispatcher.signatures(address(foo));
        assertEq(_signatures.length, 1, "DispatcherTest: foo signatures length");
        assertEq(_signatures[0], "foo()", "DispatcherTest: foo signature");

        DispatcherLib.Command[] memory _commands = dispatcher.commands();
        assertEq(_commands.length, 1, "DispatcherTest: command count");
        assertEq(_commands[0].module, address(foo), "DispatcherTest: foo command module");
        assertEq(_commands[0].selector, TestDispatchableLib.FOO, "DispatcherTest: foo command selector");
        address[] memory _commandModules = new address[](1);
        _commandModules[0] = address(foo);
        _commands = dispatcher.commands(_commandModules);
        assertEq(_commands.length, 1, "DispatcherTest: batch command count");
    }

    function testDispatcherAddModule() public {
        vm.startPrank(alice);

        Bar bar = new Bar();
        address[] memory _modules = new address[](1);
        _modules[0] = address(bar);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, alice));
        dispatcher.addModule(_modules);

        vm.stopPrank();

        vm.startPrank(bob);
        dispatcher.addModule(_modules);
        assertEq(dispatcher.module(TestDispatchableLib.BAR), address(bar), "DispatcherTest: bar() not set");
    }

    function testDispatcherRejectsDuplicateModule() public {
        vm.startPrank(bob);
        address[] memory _modules = new address[](1);
        _modules[0] = address(foo);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.ModuleAlreadyAdded.selector, address(foo)));
        dispatcher.addModule(_modules);
    }

    function testDispatcherVerifyModule() public view {
        (bytes4[] memory _selectors, string[] memory _signatures) = dispatcher.verifyModule(address(foo));
        assertEq(_selectors.length, 1, "DispatcherTest: selector count");
        assertEq(_selectors[0], TestDispatchableLib.FOO, "DispatcherTest: selector");
        assertEq(_signatures.length, 1, "DispatcherTest: signature count");
        assertEq(_signatures[0], "foo()", "DispatcherTest: signature");
    }

    function testDispatcherCallModule() public {
        (bool success, bytes memory data) = address(dispatcher).call(abi.encodeWithSelector(TestDispatchableLib.FOO));
        assertTrue(success, "DispatcherTest: foo() failed");
        assertEq(abi.decode(data, (string)), "Foo module", "DispatcherTest: foo() wrong return");

        (success, data) = address(dispatcher).call(abi.encodeWithSelector(TestDispatchableLib.BAR));
        assertFalse(success, "DispatcherTest: bar() should fail");
    }

    function testDispatcherRemoveModule() public {
        address[] memory _modules = new address[](1);
        _modules[0] = address(foo);

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, alice));
        dispatcher.removeModule(_modules);

        vm.stopPrank();

        vm.startPrank(bob);
        dispatcher.removeModule(_modules);
        assertEq(dispatcher.module(TestDispatchableLib.FOO), address(0), "DispatcherTest: foo() not removed");
        assertEq(dispatcher.modules().length, 0, "DispatcherTest: module not removed");
        assertEq(dispatcher.commands().length, 0, "DispatcherTest: commands not removed");

        vm.expectRevert(abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, TestDispatchableLib.FOO));
        (bool success, bytes memory data) = address(dispatcher).call(abi.encodeWithSelector(TestDispatchableLib.FOO));

        vm.expectRevert(abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, TestDispatchableLib.BAR));
        (success, data) = address(dispatcher).call(abi.encodeWithSelector(TestDispatchableLib.BAR));
    }

    function testDispatcherRedeployModule() public {
        vm.startPrank(bob);
        address[] memory _modules = new address[](1);
        _modules[0] = address(foo);
        dispatcher.removeModule(_modules);

        Foo foo2 = new Foo();
        _modules[0] = address(foo2);
        dispatcher.addModule(_modules);

        assertEq(dispatcher.module(TestDispatchableLib.FOO), address(foo2), "DispatcherTest: foo() not redeployed");
    }

    function testDispatcherCannotRemoveStaleModule() public {
        vm.startPrank(bob);
        address[] memory _modules = new address[](1);
        _modules[0] = address(foo);
        dispatcher.removeModule(_modules);

        Foo foo2 = new Foo();
        _modules[0] = address(foo2);
        dispatcher.addModule(_modules);

        vm.expectRevert(
            abi.encodeWithSelector(
                IDispatcher.CommandInWrongModule.selector, TestDispatchableLib.FOO, address(foo), address(foo2)
            )
        );
        _modules[0] = address(foo);
        dispatcher.removeModule(_modules);

        assertEq(dispatcher.module(TestDispatchableLib.FOO), address(foo2), "DispatcherTest: replacement cleared");
    }
}
