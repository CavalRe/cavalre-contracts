// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {Test} from "forge-std/src/Test.sol";

contract ModuleTest is Test {
    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    function testModuleInit() public {
        vm.startPrank(alice);

        Dispatcher dispatcher = new Dispatcher(alice);
        assertEq(dispatcher.owner(address(dispatcher)), alice, "DispatcherTest: Owner not set");
    }
}
