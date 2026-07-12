// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerView {
    function name(address addr) external view returns (string memory);
    function symbol(address addr) external view returns (string memory);
    function decimals(address addr) external view returns (uint8);
    function nativeName() external view returns (string memory);
    function nativeSymbol() external view returns (string memory);
    function nativeDecimals() external view returns (uint8);
    function debitBalanceOf(address parent, address owner) external view returns (uint256);
    function creditBalanceOf(address parent, address owner) external view returns (uint256);
    function balanceOf(address parent, address owner) external view returns (uint256);
    function totalSupply(address token) external view returns (uint256);
    function isClaim(address token) external view returns (bool);
    function claimAccountOf(address token) external view returns (address);
}
