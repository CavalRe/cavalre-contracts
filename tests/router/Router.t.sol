// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module} from "../../contracts/router/Module.sol";
import {Router} from "../../contracts/router/Router.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Test, console} from "forge-std/src/Test.sol";

library TestModuleLib {
    bytes4 internal constant FOO = bytes4(keccak256("foo()"));
    bytes4 internal constant BAR = bytes4(keccak256("bar()"));
}

contract Foo is Module {
    function commands()
        public
        pure
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](1);
        _commands[0] = TestModuleLib.FOO;
    }

    function foo() public pure returns (string memory) {
        return "Foo module";
    }
}

contract Bar is Module {
    function commands()
        public
        pure
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](1);
        _commands[0] = TestModuleLib.BAR;
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

    function testRouterInit() public {
        assertEq(
            router.owner(address(router)),
            bob,
            "RouterTest: Owner not set"
        );

        assertEq(
            router.module(TestModuleLib.FOO),
            address(foo),
            "RouterTest: foo() not set"
        );
    }

    function testRouterAddModule() public {
        vm.startPrank(alice);

        Bar bar = new Bar();
        vm.expectRevert(
            abi.encodeWithSelector(
                Module.OwnableUnauthorizedAccount.selector,
                alice
            )
        );
        router.addModule(address(bar));

        vm.stopPrank();

        vm.startPrank(bob);
        router.addModule(address(bar));
        assertEq(
            router.module(TestModuleLib.BAR),
            address(bar),
            "RouterTest: bar() not set"
        );
    }

    function testRouterCallModule() public {
        (bool success, bytes memory data) = address(router).call(
            abi.encodeWithSelector(TestModuleLib.FOO)
        );
        assertTrue(success, "RouterTest: foo() failed");
        assertEq(abi.decode(data, (string)), "Foo module", "RouterTest: foo() wrong return");

        (success, data) = address(router).call(
            abi.encodeWithSelector(TestModuleLib.BAR)
        );
        assertFalse(success, "RouterTest: bar() should fail");
    }

    function testRouterRemoveModule() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                Module.OwnableUnauthorizedAccount.selector,
                alice
            )
        );
        router.removeModule(address(foo));

        vm.stopPrank();

        vm.startPrank(bob);
        router.removeModule(address(foo));
        assertEq(
            router.module(TestModuleLib.FOO),
            address(0),
            "RouterTest: foo() not removed"
        );

        vm.expectRevert(
            abi.encodeWithSelector(Router.CommandNotFound.selector, TestModuleLib.FOO)
        );
        (bool success, bytes memory data) = address(router).call(
            abi.encodeWithSelector(TestModuleLib.FOO)
        );

        vm.expectRevert(
            abi.encodeWithSelector(Router.CommandNotFound.selector, TestModuleLib.BAR)
        );
        (success, data) = address(router).call(
            abi.encodeWithSelector(TestModuleLib.BAR)
        );
    }

    function testRouterRedeployModule() public {
        vm.startPrank(bob);
        router.removeModule(address(foo));

        Foo foo2 = new Foo();
        router.addModule(address(foo2));

        assertEq(
            router.module(TestModuleLib.FOO),
            address(foo2),
            "RouterTest: foo() not redeployed"
        );
    }
}
