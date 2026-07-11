// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../modules/Dispatchable.sol";
import {DispatcherLib} from "../libraries/DispatcherLib.sol";
import {IDispatcher} from "../interfaces/IDispatcher.sol";
import {console} from "forge-std/src/console.sol";

struct Store {
    mapping(address => address) pendingOwners;
}

library SentryLib {
    // Stores
    bytes32 internal constant STORE_POSITION = keccak256("@cavalre.sentry.store");

    // Selectors
    bytes4 internal constant TRANSFER_OWNERSHIP = bytes4(keccak256("transferOwnership(address,address)"));
    bytes4 internal constant ACCEPT_OWNERSHIP = bytes4(keccak256("acceptOwnership(address)"));
    bytes4 internal constant RENOUNCE_OWNERSHIP = bytes4(keccak256("renounceOwnership(address)"));
    bytes4 internal constant CONFIRM_RENOUNCE_OWNERSHIP = bytes4(keccak256("confirmRenounceOwnership(address)"));
    bytes4 internal constant PENDING_OWNER = bytes4(keccak256("pendingOwner(address)"));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract Sentry is Dispatchable {
    // Events
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Errors
    error OwnableInvalidOwner(address owner);

    function signatures() public pure virtual override returns (string[] memory _signatures) {
        _signatures = new string[](5);
        _signatures[0] = "transferOwnership(address,address)";
        _signatures[1] = "acceptOwnership(address)";
        _signatures[2] = "renounceOwnership(address)";
        _signatures[3] = "confirmRenounceOwnership(address)";
        _signatures[4] = "pendingOwner(address)";
    }

    function selectors() public pure virtual override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](5);
        _selectors[0] = SentryLib.TRANSFER_OWNERSHIP;
        _selectors[1] = SentryLib.ACCEPT_OWNERSHIP;
        _selectors[2] = SentryLib.RENOUNCE_OWNERSHIP;
        _selectors[3] = SentryLib.CONFIRM_RENOUNCE_OWNERSHIP;
        _selectors[4] = SentryLib.PENDING_OWNER;
    }

    function transferOwnership(address _module, address _newOwner) external {
        enforceIsOwner();
        if (_newOwner == address(0)) {
            revert OwnableInvalidOwner(_newOwner);
        }
        Store storage s = SentryLib.store();
        s.pendingOwners[_module] = _newOwner;

        emit OwnershipTransferStarted(DispatcherLib.store().owners[_module], _newOwner);
    }

    function acceptOwnership(address _module) external {
        Store storage s = SentryLib.store();
        address sender = msg.sender;
        if (s.pendingOwners[_module] != sender) {
            revert IDispatcher.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = DispatcherLib.store().owners[_module];
        DispatcherLib.store().owners[_module] = sender;
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferred(oldOwner, sender);
    }

    function renouceOwnership(address _module) external {
        enforceIsOwner();
        Store storage s = SentryLib.store();
        address sender = msg.sender;
        if (DispatcherLib.store().owners[_module] != sender) {
            revert IDispatcher.OwnableUnauthorizedAccount(sender);
        }
        address oldOwner = DispatcherLib.store().owners[_module];
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferStarted(oldOwner, address(0));
    }

    function confirmRenounceOwnership(address _module) external {
        enforceIsOwner();
        Store storage s = SentryLib.store();
        address oldOwner = DispatcherLib.store().owners[_module];
        DispatcherLib.store().owners[_module] = address(0);
        s.pendingOwners[_module] = address(0);

        emit OwnershipTransferred(oldOwner, address(0));
    }

    function pendingOwner(address _module) external view returns (address) {
        return SentryLib.store().pendingOwners[_module];
    }
}
