// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, ModuleLib as ML, Store as ModuleStore} from "@cavalre/contracts/router/Module.sol";
import {console} from "forge-std/src/console.sol";

struct Store {
    mapping(address => address) pendingOwners;
}

library SentryLib {
    // Stores
    bytes32 internal constant STORE_POSITION =
        keccak256("@cavalre.sentry.store");

    // Events
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Errors
    error OwnableInvalidOwner(address owner);

    // Selectors
    bytes4 internal constant TRANSFER_OWNERSHIP =
        bytes4(keccak256("transferOwnership(address,address)"));
    bytes4 internal constant ACCEPT_OWNERSHIP =
        bytes4(keccak256("acceptOwnership(address)"));
    bytes4 internal constant RENOUNCE_OWNERSHIP =
        bytes4(keccak256("renounceOwnership(address)"));
    bytes4 internal constant CONFIRM_RENOUNCE_OWNERSHIP =
        bytes4(keccak256("confirmRenounceOwnership(address)"));
    bytes4 internal constant PENDING_OWNER =
        bytes4(keccak256("pendingOwner(address)"));

    // Commands
    function transferOwnership(address _module, address _newOwner) internal {
        ML.enforceIsOwner(_module);
        if (_newOwner == address(0)) {
            revert SentryLib.OwnableInvalidOwner(_newOwner);
        }
        Store storage s = store();
        s.pendingOwners[_module] = _newOwner;

        emit SentryLib.OwnershipTransferStarted(ML.store().owners[_module], _newOwner);
    }

    function acceptOwnership(address _module) internal {
        ModuleStore storage ms = ML.store();
        Store storage s = store();
        address sender = msg.sender;
        if (s.pendingOwners[_module] != sender) {
            revert ML.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = ms.owners[_module];
        ms.owners[_module] = sender;
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferred(oldOwner, sender);
    }

    function renouceOwnership(address _module) internal {
        ModuleStore storage ms = ML.enforceIsOwner(_module);
        Store storage s = store();
        address sender = msg.sender;
        if (ms.owners[_module] != sender) {
            revert ML.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = ms.owners[_module];
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferStarted(oldOwner, address(0));
    }

    function confirmRenounceOwnership(address _module) internal {
        ModuleStore storage ms = ML.enforceIsOwner(_module);
        Store storage s = store();
        address oldOwner = ms.owners[_module];
        ms.owners[_module] = address(0);
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferred(oldOwner, address(0));
    }

    function enforceIsPendingOwner(address _module, Store storage s) internal view {
        if (s.pendingOwners[_module] != msg.sender) {
            revert ML.OwnableUnauthorizedAccount(msg.sender);
        }
    }

    function enforceIsPendingOwner(address _module) internal view returns (Store storage s) {
        s = store();
        if (s.pendingOwners[_module] != msg.sender) {
            revert ML.OwnableUnauthorizedAccount(msg.sender);
        }
        return s;
    }

    function pendingOwner(address _module) internal view returns (address) {
        return store().pendingOwners[_module];
    }

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract Sentry is Module {
    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](5);
        _commands[0] = SentryLib.TRANSFER_OWNERSHIP;
        _commands[1] = SentryLib.ACCEPT_OWNERSHIP;
        _commands[2] = SentryLib.RENOUNCE_OWNERSHIP;
        _commands[3] = SentryLib.CONFIRM_RENOUNCE_OWNERSHIP;
        _commands[4] = SentryLib.PENDING_OWNER;
    }

    function transferOwnership(address _module, address _newOwner) external {
        SentryLib.transferOwnership(_module, _newOwner);
    }

    function acceptOwnership(address _module) external {
        SentryLib.acceptOwnership(_module);
    }

    function renouceOwnership(address _module) external {
        SentryLib.renouceOwnership(_module);
    }

    function confirmRenounceOwnership(address _module) external {
        SentryLib.confirmRenounceOwnership(_module);
    }

    function pendingOwner(address _module) external view returns (address) {
        return SentryLib.pendingOwner(_module);
    }
}
