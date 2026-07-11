// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../../modules/Dispatchable.sol";
import {Router} from "../../modules/Router.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Test, console} from "forge-std/src/Test.sol";

library TestDispatchableLib {
    bytes4 internal constant FOO = bytes4(keccak256("foo()"));
    bytes4 internal constant BAR = bytes4(keccak256("bar()"));
}

contract Foo is Dispatchable {
    function selectors() public pure override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = TestDispatchableLib.FOO;
    }

    function foo() public pure returns (string memory) {
        return "Foo module";
    }
}

contract Bar is Dispatchable {
    function selectors() public pure override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = TestDispatchableLib.BAR;
    }

    function bar() public pure returns (string memory) {
        return "Bar module";
    }
}

contract RouterTest is Test, ContextUpgradeable {
    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    Router router;
    Foo foo;

    function setUp() public {
        router = new Router(bob);

        vm.startPrank(bob);
        foo = new Foo();
        router.addModule(address(foo));
    }

    function testRouterInit() public view {
        assertEq(router.owner(address(router)), bob, "RouterTest: Owner not set");

        assertEq(router.module(TestDispatchableLib.FOO), address(foo), "RouterTest: foo() not set");
    }

    function testRouterAddModule() public {
        vm.startPrank(alice);

        Bar bar = new Bar();
        vm.expectRevert(abi.encodeWithSelector(Dispatchable.OwnableUnauthorizedAccount.selector, alice));
        router.addModule(address(bar));

        vm.stopPrank();

        vm.startPrank(bob);
        router.addModule(address(bar));
        assertEq(router.module(TestDispatchableLib.BAR), address(bar), "RouterTest: bar() not set");
    }

    function testRouterCallModule() public {
        (bool success, bytes memory data) = address(router).call(abi.encodeWithSelector(TestDispatchableLib.FOO));
        assertTrue(success, "RouterTest: foo() failed");
        assertEq(abi.decode(data, (string)), "Foo module", "RouterTest: foo() wrong return");

        (success, data) = address(router).call(abi.encodeWithSelector(TestDispatchableLib.BAR));
        assertFalse(success, "RouterTest: bar() should fail");
    }

    function testRouterRemoveModule() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Dispatchable.OwnableUnauthorizedAccount.selector, alice));
        router.removeModule(address(foo));

        vm.stopPrank();

        vm.startPrank(bob);
        router.removeModule(address(foo));
        assertEq(router.module(TestDispatchableLib.FOO), address(0), "RouterTest: foo() not removed");

        vm.expectRevert(abi.encodeWithSelector(Router.CommandNotFound.selector, TestDispatchableLib.FOO));
        (bool success, bytes memory data) = address(router).call(abi.encodeWithSelector(TestDispatchableLib.FOO));

        vm.expectRevert(abi.encodeWithSelector(Router.CommandNotFound.selector, TestDispatchableLib.BAR));
        (success, data) = address(router).call(abi.encodeWithSelector(TestDispatchableLib.BAR));
    }

    function testRouterRedeployModule() public {
        vm.startPrank(bob);
        router.removeModule(address(foo));

        Foo foo2 = new Foo();
        router.addModule(address(foo2));

        assertEq(router.module(TestDispatchableLib.FOO), address(foo2), "RouterTest: foo() not redeployed");
    }
}
