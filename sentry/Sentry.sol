// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module, ModuleLib as ML, RouterStore} from "../router/Module.sol";
import {console} from "forge-std/console.sol";

struct Store {
    address pendingOwner;
}

library SentryLib {
    // Stores
    bytes32 internal constant SENTRY_STORE_POSITION =
        keccak256("@cavalre.sentry.store");

    // Errors
    error OwnableInvalidOwner(address owner);

    // Events
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Selectors
    bytes4 internal constant TRANSFER_OWNERSHIP =
        bytes4(keccak256("transferOwnership(address)"));
    bytes4 internal constant ACCEPT_OWNERSHIP =
        bytes4(keccak256("acceptOwnership()"));
    bytes4 internal constant RENOUNCE_OWNERSHIP =
        bytes4(keccak256("renounceOwnership()"));
    bytes4 internal constant CONFIRM_RENOUNCE_OWNERSHIP =
        bytes4(keccak256("confirmRenounceOwnership()"));
    bytes4 internal constant PENDING_OWNER =
        bytes4(keccak256("pendingOwner()"));

    // Commands
    function transferOwnership(address _newOwner) internal {
        ML.enforceIsOwner();
        if (_newOwner == address(0)) {
            revert SentryLib.OwnableInvalidOwner(_newOwner);
        }
        Store storage s = store();
        s.pendingOwner = _newOwner;

        emit SentryLib.OwnershipTransferStarted(ML.owner(), _newOwner);
    }

    function acceptOwnership() internal {
        RouterStore storage rs = ML.routerStore();
        Store storage s = store();
        address sender = msg.sender;
        if (s.pendingOwner != sender) {
            revert ML.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = rs.owner;
        rs.owner = sender;
        s.pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, sender);
    }

    function renouceOwnership() internal {
        RouterStore storage rs = ML.enforceIsOwner();
        Store storage s = store();
        address sender = msg.sender;
        if (rs.owner != sender) {
            revert ML.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = rs.owner;
        s.pendingOwner = address(0);

        emit OwnershipTransferStarted(oldOwner, address(0));
    }

    function confirmRenounceOwnership() internal {
        RouterStore storage rs = ML.enforceIsOwner();
        Store storage s = store();
        address oldOwner = rs.owner;
        rs.owner = address(0);
        s.pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, address(0));
    }

    function pendingOwner() internal view returns (address) {
        return store().pendingOwner;
    }

    function store() internal pure returns (Store storage s) {
        bytes32 position = SENTRY_STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract Sentry is Module {
    function commands()
        public
        pure
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

    function transferOwnership(address _newOwner) external {
        SentryLib.transferOwnership(_newOwner);
    }

    function acceptOwnership() external {
        SentryLib.acceptOwnership();
    }

    function renouceOwnership() external {
        SentryLib.renouceOwnership();
    }

    function confirmRenounceOwnership() external {
        SentryLib.confirmRenounceOwnership();
    }

    function pendingOwner() external view returns (address) {
        return SentryLib.pendingOwner();
    }
}
