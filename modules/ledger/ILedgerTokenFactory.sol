// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerTokenFactory {
    struct TokenMetadata {
        string name;
        string symbol;
        uint8 decimals;
        string version;
    }

    function createInternalToken(TokenMetadata[] memory tokens)
        external
        returns (address[] memory tokenAddresses, uint256[] memory flags);

    function createClaimToken(address absoluteClaimAccount, TokenMetadata memory token)
        external
        returns (address tokenAddress, uint256 flags);
}
