// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module, RouterStore} from "../router/Module.sol";

struct Store {
    address pendingOwner;
}

contract Sentry is Module {
    // Stores
    bytes32 internal constant SENTRY_STORE_POSITION =
        keccak256("@cavalre.sentry.store");

    // Commands
    bytes4 internal constant TRANSFER_OWNERSHIP =
        bytes4(keccak256("transferOwnership(address)"));
    bytes4 internal constant ACCEPT_OWNERSHIP =
        bytes4(keccak256("acceptOwnership()"));
    bytes4 internal constant RENOUNCE_OWNERSHIP =
        bytes4(keccak256("renounceOwnership()"));
    bytes4 internal constant CONFIRM_RENOUNCE_OWNERSHIP =
        bytes4(keccak256("confirmRenounceOwnership()"));
    bytes4 internal constant OWNER = bytes4(keccak256("owner()"));
    bytes4 internal constant PENDING_OWNER =
        bytes4(keccak256("pendingOwner()"));

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

    function commands() public pure override returns (bytes4[] memory _commands) {
        _commands = new bytes4[](5);
        _commands[0] = TRANSFER_OWNERSHIP;
        _commands[1] = ACCEPT_OWNERSHIP;
        _commands[2] = RENOUNCE_OWNERSHIP;
        _commands[3] = CONFIRM_RENOUNCE_OWNERSHIP;
        _commands[4] = PENDING_OWNER;
    }

    function transferOwnership(address _newOwner) external {
        enforceIsOwner();
        if (_newOwner == address(0)) {
            revert OwnableInvalidOwner(_newOwner);
        }
        Store storage s = store();
        s.pendingOwner = _newOwner;

        emit OwnershipTransferStarted(owner(), _newOwner);
    }

    function acceptOwnership() external {
        RouterStore storage rs = routerStore();
        Store storage s = store();
        address sender = msg.sender;
        if (s.pendingOwner != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = rs.owner;
        rs.owner = sender;
        s.pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, sender);
    }

    function renouceOwnership() external {
        RouterStore storage rs = enforceIsOwner();
        Store storage s = store();
        address sender = msg.sender;
        if (rs.owner != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = rs.owner;
        s.pendingOwner = address(0);

        emit OwnershipTransferStarted(oldOwner, address(0));
    }

    function confirmRenounceOwnership() external {
        RouterStore storage rs = enforceIsOwner();
        Store storage s = store();
        address oldOwner = rs.owner;
        rs.owner = address(0);
        s.pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, address(0));
    }

    function pendingOwner() external view returns (address) {
        return store().pendingOwner;
    }

    function store() internal pure returns (Store storage s) {
        bytes32 position = SENTRY_STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
