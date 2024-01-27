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
        _commands[0] = bytes4(keccak256("transferOwnership(address)"));
        _commands[1] = bytes4(keccak256("acceptOwnership()"));
        _commands[2] = bytes4(keccak256("renounceOwnership()"));
        _commands[3] = bytes4(keccak256("confirmRenounceOwnership()"));
        _commands[4] = bytes4(keccak256("pendingOwner()"));
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
