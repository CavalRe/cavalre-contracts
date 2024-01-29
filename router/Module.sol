// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

struct RouterStore {
    address owner;
    mapping(bytes4 => address) modules;
}

library ModuleLib {
    // Stores
    bytes32 internal constant ROUTER_STORE_POSITION =
        keccak256("@cavalre.router.store");

    // Errors
    error IsDelegated();
    error NotDelegated();
    error OwnableUnauthorizedAccount(address account);

    // Selectors
    bytes4 internal constant OWNER = bytes4(keccak256("owner()"));
    bytes4 internal constant MODULE = bytes4(keccak256("module(bytes4)"));

    function enforceIsOwner(RouterStore storage s) internal view {
        if (s.owner != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

    function enforceIsOwner() internal view returns (RouterStore storage s) {
        s = routerStore();
        if (s.owner != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
        return s;
    }

    function enforceIsDelegated(address __self) internal view {
        if (address(this) == __self) revert NotDelegated();
    }

    function enforceNotDelegated(address __self) internal view {
        if (address(this) != __self) revert NotDelegated();
    }

    function owner() internal view returns (address) {
        return ModuleLib.routerStore().owner;
    }

    function module(bytes4 _command) internal view returns (address) {
        return ModuleLib.routerStore().modules[_command];
    }

    function routerStore() internal pure returns (RouterStore storage r) {
        bytes32 position = ROUTER_STORE_POSITION;
        assembly {
            r.slot := position
        }
    }
}

contract Module is Test {
    address private immutable __self = address(this);

    // Commands
    function commands()
        public
        pure
        virtual
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](0);
    }

    function enforceIsDelegated() internal view {
        ModuleLib.enforceIsDelegated(__self);
    }

    function enforceNotDelegated() internal view {
        ModuleLib.enforceNotDelegated(__self);
    }

    function owner() public view returns (address) {
        return ModuleLib.owner();
    }

    function module(bytes4 _command) public view returns (address) {
        return ModuleLib.module(_command);
    }
}
