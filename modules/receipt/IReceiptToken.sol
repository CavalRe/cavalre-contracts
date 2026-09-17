// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IReceiptToken {
    error InvalidReceiptState(uint256 supply, uint256 backing);
    error InvalidReceiptHolder(address holder);
    error InvalidReceiptAmount();
    error InvalidSettlement();
    error UnsupportedDecimalDifference();

    event ReceiptIssued(address indexed token, address indexed holder, uint256 receipts, uint256 backing);
    event ReceiptRedeemed(address indexed token, address indexed holder, uint256 receipts, uint256 backing);
    event ReceiptCancelled(address indexed token, address indexed holder, uint256 receipts);

    /// @notice Cancel raw receipt units without releasing backing; the wrapper authenticates the holder.
    /// @dev Only the token's registered wrapper may call; ERC20 allowance alone is insufficient.
    /// Zero amounts revert. Cancelling the entire supply leaves any backing unassigned.
    function cancelReceipt(address token, address holder, uint256 receipts) external;
}
