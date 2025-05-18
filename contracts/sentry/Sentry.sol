// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, Lib as ML, Store as MS} from "@cavalre/contracts/router/Module.sol";
import {console} from "forge-std/src/console.sol";

struct Store {
    mapping(address => address) pendingOwners;
}

library Lib {
    // Stores
    bytes32 internal constant STORE_POSITION =
        keccak256("@cavalre.sentry.store");

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

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract Sentry is Module {
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

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](5);
        _commands[0] = Lib.TRANSFER_OWNERSHIP;
        _commands[1] = Lib.ACCEPT_OWNERSHIP;
        _commands[2] = Lib.RENOUNCE_OWNERSHIP;
        _commands[3] = Lib.CONFIRM_RENOUNCE_OWNERSHIP;
        _commands[4] = Lib.PENDING_OWNER;
    }

    function transferOwnership(address _module, address _newOwner) external {
        MS storage ms = enforceIsOwner();
        if (_newOwner == address(0)) {
            revert OwnableInvalidOwner(_newOwner);
        }
        Store storage s = Lib.store();
        s.pendingOwners[_module] = _newOwner;

        emit OwnershipTransferStarted(ms.owners[_module], _newOwner);
    }

    function acceptOwnership(address _module) external {
        MS storage ms = ML.store();
        Store storage s = Lib.store();
        address sender = msg.sender;
        if (s.pendingOwners[_module] != sender) {
            revert Module.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = ms.owners[_module];
        ms.owners[_module] = sender;
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferred(oldOwner, sender);
    }

    function renouceOwnership(address _module) external {
        MS storage ms = enforceIsOwner();
        Store storage s = Lib.store();
        address sender = msg.sender;
        if (ms.owners[_module] != sender) {
            revert Module.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = ms.owners[_module];
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferStarted(oldOwner, address(0));
    }

    function confirmRenounceOwnership(address _module) external {
        MS storage ms = enforceIsOwner();
        Store storage s = Lib.store();
        address oldOwner = ms.owners[_module];
        ms.owners[_module] = address(0);
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferred(oldOwner, address(0));
    }

    function pendingOwner(address _module) external view returns (address) {
        return Lib.store().pendingOwners[_module];
    }
}
