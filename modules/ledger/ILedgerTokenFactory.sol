// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerTokenFactory {
    function createInternalToken(string memory name, string memory symbol, uint8 decimals, string memory version)
        external
        returns (address token, uint256 flags);

    function createClaimToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address root,
        address holderParent,
        address relative,
        string memory version
    ) external returns (address token, uint256 flags);
}
