// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerView {
    function name(address absolute) external view returns (string memory);
    function symbol(address absolute) external view returns (string memory);
    function decimals(address absolute) external view returns (uint8);
    function nativeName() external view returns (string memory);
    function nativeSymbol() external view returns (string memory);
    function nativeDecimals() external view returns (uint8);
    function ledgerCount() external view returns (uint256);
    function ledgerAt(uint256 index) external view returns (address);
    function ledgers(uint256 start, uint256 limit) external view returns (address[] memory);
    function debitBalanceOf(address ledger, address parent, address relative) external view returns (uint256);
    function creditBalanceOf(address ledger, address parent, address relative) external view returns (uint256);
    function balanceOf(address ledger, address parent, address relative) external view returns (uint256);
    function totalSupply(address ledger) external view returns (uint256);
    function isClaim(address ledger) external view returns (bool);
    function claimAccountOf(address ledger) external view returns (address);
}
