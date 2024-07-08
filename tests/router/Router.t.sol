// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Test, console} from "forge-std/src/Test.sol";

contract RouterTest is Test, ContextUpgradeable {
    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    function testRouterInit() public {
        vm.startPrank(alice);

        Router router = new Router(alice);
        assertEq(
            router.owner(address(router)),
            alice,
            "RouterTest: Owner not set"
        );
    }
}
