// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/**
 * @dev Shadow version of OpenZeppelin's ReentrancyGuardTransient to support module-specific storage slots.
 *
 * This contract overrides the default `_reentrancyGuardStorageSlot` behavior to enforce separate
 * storage slots for each module in a diamond-style Router/Module architecture.
 *
 * Without this override, all modules that inherit OpenZeppelin's ReentrancyGuardTransient would use the
 * same storage slot, leading to collisions when using delegatecall.
 *
 * @notice Must be used instead of OpenZeppelin's ReentrancyGuardTransient directly in module contracts.
 */
abstract contract ReentrancyGuard is ReentrancyGuardTransient {
    function _reentrancyGuardStorageSlot()
        internal
        pure
        virtual
        override
        returns (bytes32)
    {
        // Must be overridden per-module to ensure unique slot
        revert("ReentrancyGuard: must override _reentrancyGuardStorageSlot()");
    }
}
