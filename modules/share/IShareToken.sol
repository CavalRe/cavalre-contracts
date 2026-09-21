// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IShareToken {
    error InvalidShareState(uint256 supply, uint256 backing);
    error InvalidShareAmount();
    error InvalidSettlement();
    error UnsupportedDecimalDifference();

    event ShareIssued(address indexed token, address indexed holder, uint256 shares, uint256 backing);
    event ShareRedeemed(address indexed token, address indexed holder, uint256 shares, uint256 backing);
    event ShareCancelled(address indexed token, address indexed holder, uint256 shares);
}
