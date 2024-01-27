// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

struct RouterStore {
    address owner;
    mapping(bytes4 => address) modules;
}

contract Module is Test {
    // Stores
    bytes32 internal constant ROUTER_STORE_POSITION =
        keccak256("@cavalre.router.store");

    // Errors
    error OwnableUnauthorizedAccount(address account);

    // Commands
    function commands() public pure virtual returns (bytes4[] memory _commands) {
        _commands = new bytes4[](0);
    }

    function enforceIsOwner() internal view returns (RouterStore storage s) {
        s = routerStore();
        if (s.owner != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
        return s;
    }

    function owner() public view returns (address) {
        return routerStore().owner;
    }

    function module(bytes4 _command) external view returns (address) {
        return routerStore().modules[_command];
    }

    function routerStore() internal pure returns (RouterStore storage r) {
        bytes32 position = ROUTER_STORE_POSITION;
        assembly {
            r.slot := position
        }
    }
}
