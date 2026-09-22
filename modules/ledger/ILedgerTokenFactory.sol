// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerTokenFactory {
    struct TokenMetadata {
        string name;
        string symbol;
        uint8 decimals;
        string version;
    }

    struct ShareTokenConfig {
        address backingAccount;
        TokenMetadata metadata;
    }

    function createInternalTokens(TokenMetadata[] memory tokens)
        external
        returns (address[] memory tokenAddresses, uint256[] memory flags);

    /// @notice Create share tokens in input order; any failed item reverts the entire batch.
    function createShareTokens(ShareTokenConfig[] memory tokens)
        external
        returns (address[] memory tokenAddresses, uint256[] memory flags);
    /// @notice Create an SR wrapper with immutable staking group, reward group and half-life.
    function createStakingRewardToken(
        address stakingGroup,
        address rewardGroup,
        uint256 halfLife,
        TokenMetadata memory metadata
    ) external returns (address token);
}
