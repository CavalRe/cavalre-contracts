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
        dispatcher.addModule(address(foo));
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
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, alice));
        dispatcher.addModule(address(bar));

        vm.stopPrank();

        vm.startPrank(bob);
        dispatcher.addModule(address(bar));
        assertEq(dispatcher.module(TestDispatchableLib.BAR), address(bar), "DispatcherTest: bar() not set");
    }

    function testDispatcherRejectsDuplicateModule() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.ModuleAlreadyAdded.selector, address(foo)));
        dispatcher.addModule(address(foo));
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
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, alice));
        dispatcher.removeModule(address(foo));

        vm.stopPrank();

        vm.startPrank(bob);
        dispatcher.removeModule(address(foo));
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
        dispatcher.removeModule(address(foo));

        Foo foo2 = new Foo();
        dispatcher.addModule(address(foo2));

        assertEq(dispatcher.module(TestDispatchableLib.FOO), address(foo2), "DispatcherTest: foo() not redeployed");
    }

    function testDispatcherCannotRemoveStaleModule() public {
        vm.startPrank(bob);
        dispatcher.removeModule(address(foo));

        Foo foo2 = new Foo();
        dispatcher.addModule(address(foo2));

        vm.expectRevert(
            abi.encodeWithSelector(
                IDispatcher.CommandInWrongModule.selector, TestDispatchableLib.FOO, address(foo), address(foo2)
            )
        );
        dispatcher.removeModule(address(foo));

        assertEq(dispatcher.module(TestDispatchableLib.FOO), address(foo2), "DispatcherTest: replacement cleared");
    }
}
