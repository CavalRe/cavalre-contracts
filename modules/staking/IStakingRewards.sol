// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";

interface IStakingRewards {
    struct Rewards {
        uint256 unclaimedUnits;
        uint256 pendingUnits;
        uint256 unclaimed;
        uint256 pending;
        uint256 available;
    }

    struct Configuration {
        address tokenAddress;
        uint256 totalSupply;
        address stakingLedger;
        // Compatibility view: always the token ledger root, not configurable.
        address stakingGroup;
        uint256 stakedBalance;
        address rewardLedger;
        address rewardGroup;
        address rewardAccount;
        address rewardShareToken;
        uint256 halfLife;
        Rewards rewards;
        uint256 allocationRemainderUnits;
    }

    error NotStakingRewardToken(address token);
    error AlreadyConfigured(address token);
    error InvalidConfiguration();
    error AccountReserved(address account);
    error UnauthorizedTransfer();
    error ZeroAmount();
    error NoStake();
    error InsufficientRewards();
    error InsufficientStake();

    event StakingRewardTokenCreated(
        address indexed token,
        address indexed stakingGroup,
        address indexed rewardGroup,
        address rewardShareToken,
        uint256 halfLife
    );
    event Rewarded(address indexed token, address indexed funder, uint256 amount, uint256 units);
    event Claimed(address indexed token, address indexed holder, uint256 amount, uint256 units);
    event Forfeited(
        address indexed token, address indexed account, uint256 pendingUnits, uint256 allocationRemainderUnits
    );

    /// @notice Create an SR ledger root with credit Stake/Source leaves and a debit Rewards group.
    /// @dev Direct debit leaves earn rewards; nested leaves and groups do not. Reward backing is
    /// rewardGroup / token, a debit leaf. For self rewards, pass the predicted token's Rewards group.
    function createStakingRewardToken(
        address rewardGroup,
        uint256 halfLife,
        ILedgerTokenFactory.TokenMetadata memory metadata
    ) external returns (address token);

    /// @notice Add funded rewards, allocated as pending rewards in proportion to current stake.
    /// @dev Moves existing tokens from the caller's reward-ledger wallet account to rewardGroup / token.
    /// Funding requires nonzero stake. Checkpoints record holder entitlements; no per-holder reward accounts are created.
    /// Existing rewards keep their accrued vesting. If the reward token is SR, funding reduces the caller's eligible balance and applies forfeiture.
    /// @param token SR wrapper address identifying the program to fund, not the token used as reward backing.
    /// @param amount Amount to contribute, in the configured reward ledger's raw token units.
    function reward(address token, uint256 amount) external;

    /// @notice Fund pending rewards directly from the caller's leaf under a chosen reward-account parent.
    /// @dev The parent must be the reward ledger root. Application-owned accounts require an authorized consumer.
    /// Departing stake forfeits pending rewards under the usual rules; new funding is allocated after that exit.
    /// Funding that would leave the recipient program without stake reverts atomically.
    /// @param token SR wrapper identifying the program to fund.
    /// @param funderParent Absolute parent of the caller's funding leaf, which must equal the reward ledger root.
    /// @param amount Contribution in the configured reward ledger's raw token units.
    function reward(address token, address funderParent, uint256 amount) external;

    /// @notice Collect all of the caller's available rewards without withdrawing their stake.
    /// @dev Settles elapsed vesting, redeems all available reward units, and pays from rewardGroup / token
    /// into the caller's reward-ledger wallet account. Remaining pending units stay pending.
    /// The payout is rounded down; available units are consumed even when their token value rounds to zero.
    /// If the reward asset is SR, the payout becomes eligible after settling the recipient's old balance.
    /// @param token SR wrapper address identifying the program whose rewards are being claimed.
    /// @return claimed Amount paid, in the configured reward ledger's raw token units.
    function claim(address token) external returns (uint256 claimed);

    /// @notice Collect all available rewards directly into the caller's leaf under a chosen reward-account parent.
    /// @dev The parent must be the reward ledger root. Application-owned accounts require an authorized consumer.
    /// Paying into an SR ledger increases eligible stake without giving incoming tokens past rewards.
    /// Remaining pending rewards stay with the claiming position. Available units are consumed even for a zero payout.
    /// @param token SR wrapper identifying the program whose rewards are being claimed.
    /// @param recipientParent Absolute parent of the caller's payout leaf in the configured reward ledger.
    /// @return claimed Payout in raw reward-ledger token units, rounded down from the redeemed units.
    function claim(address token, address recipientParent) external returns (uint256 claimed);

    /// @notice Transfer direct SR balances after settling sender and recipient rewards.
    /// @dev Only the token's registered wrapper may call. The wrapper owns allowance checks.
    function transfer(address token, address from, address to, uint256 amount) external;

    /// @notice SR configuration and balances, expressed in each token's raw decimals.
    function stakingRewardToken(address token) external view returns (Configuration memory);

    /// @notice Current rewards for a direct holder, including holders who have exited.
    /// @dev Token amounts use R's raw decimals; units are internal accounting quantities.
    function rewardsOf(address token, address holder) external view returns (Rewards memory);
    /// @notice Rewards for an internal leaf with explicit absolute parent context.
    function rewardsOfAccount(address token, address parent, address relative) external view returns (Rewards memory);
}
