// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Test, console} from "forge-std/src/Test.sol";

library RouterTestLib {
    function call(
        Router router,
        bytes4 selector,
        bytes memory payload
    ) internal returns (bytes memory data){
        bool success;
        (success, data) = payable(router).call(
            abi.encodePacked(selector, payload)
        );
        if (!success) {
            string
                memory reason = "Function call failed without specified reason";
            if (data.length > 0) {
                reason = abi.decode(data, (string));
            }
            revert(reason);
        }
    }
}

contract RouterTest is Test, ContextUpgradeable {
    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    function testRouterInit() public {
        vm.startPrank(alice);

        Router router = new Router();
        assertEq(
            router.owner(address(router)),
            alice,
            "RouterTest: Owner not set"
        );
    }
}
