// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerView {
    function name(address absolute) external view returns (string memory);
    function symbol(address absolute) external view returns (string memory);
    function decimals(address absolute) external view returns (uint8);
    function nativeName() external view returns (string memory);
    function nativeSymbol() external view returns (string memory);
    function nativeDecimals() external view returns (uint8);
    function rootCount() external view returns (uint256);
    function rootAt(uint256 index) external view returns (address);
    function roots(uint256 start, uint256 limit) external view returns (address[] memory);
    function debitBalanceOf(address root, address holderParent, address relative) external view returns (uint256);
    function creditBalanceOf(address root, address holderParent, address relative) external view returns (uint256);
    function balanceOf(address root, address holderParent, address relative) external view returns (uint256);
    function totalSupply(address root) external view returns (uint256);
    function isClaim(address root) external view returns (bool);
    function claimAccountOf(address root) external view returns (address);
}
