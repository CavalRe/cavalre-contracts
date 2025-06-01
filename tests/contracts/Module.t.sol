// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Lib as ML} from "../../contracts/Module.sol";
import {Router} from "../../contracts/Router.sol";
import {Test} from "forge-std/src/Test.sol";

contract ModuleTest is Test {
    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    function testModuleInit() public {
        vm.startPrank(alice);

        Router router = new Router(alice);
        assertEq(router.owner(address(router)), alice, "RouterTest: Owner not set");
    }
}