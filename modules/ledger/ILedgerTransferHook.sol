// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Optional Dispatcher callback, invoked before Ledger balances change.
/// @dev Implementations must authenticate the Dispatcher self-call. Account arguments are absolute keys.
interface ILedgerTransferHook {
    function beforeLedgerTransfer(
        address ledger,
        address from,
        address to,
        bool fromIsCredit,
        bool toIsCredit,
        uint256 amount
    ) external;
}
