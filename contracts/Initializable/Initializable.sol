// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Module} from "@cavalre/contracts/router/Module.sol";

import {Initializable as OZInitializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Shadow version of OpenZeppelin's Initializable to support module-specific initialization.
 *
 * This contract overrides the default `_initializableStorageSlot` behavior to enforce separate
 * initialization storage slots for each module in a diamond-style Router/Module architecture.
 *
 * Without this override, all modules that inherit OpenZeppelin's Initializable would use the
 * same storage slot for their initialization status, leading to collisions when using delegatecall.
 *
 * @notice Must be used instead of OpenZeppelin's Initializable directly in module contracts.
 */
abstract contract Initializable is Module, OZInitializable {
    function _initializableStorageSlot() internal pure virtual override returns (bytes32) {
        // Must be overridden per-module to ensure unique slot
        revert("Initializable: must override _initializableStorageSlot()");
    }
}

