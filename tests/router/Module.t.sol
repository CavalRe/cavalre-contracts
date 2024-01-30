// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ModuleLib as ML} from "@cavalre/router/Module.sol";
import {Router} from "@cavalre/router/Router.sol";
import {Test} from "forge-std/Test.sol";

contract ModuleTest is Test {
    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    function testModuleInit() public {
        vm.startPrank(alice);

        Router router = new Router();
        assertEq(router.owner(address(router)), alice, "RouterTest: Owner not set");
    }
}