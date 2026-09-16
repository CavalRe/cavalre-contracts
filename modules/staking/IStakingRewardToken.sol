// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";

interface IStakingRewardToken {
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
        address stakingAccount;
        uint256 stakedBalance;
        address rewardLedger;
        address rewardAccount;
        uint256 halfLife;
        Rewards rewards;
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
    error Slippage(uint256 amount, uint256 minimum);

    event StakingRewardTokenCreated(
        address indexed token,
        address indexed stakingLedger,
        address indexed rewardLedger,
        address stakingAccount,
        uint256 halfLife
    );
    event Staked(address indexed token, address indexed holder, uint256 stake, uint256 shares);
    event Unstaked(address indexed token, address indexed holder, uint256 shares, uint256 stake);
    event Rewarded(address indexed token, address indexed funder, uint256 amount, uint256 units);
    event Claimed(address indexed token, address indexed holder, uint256 amount, uint256 units);
    event Forfeited(address indexed token, address indexed account, uint256 pendingUnits, uint256 cancelledUnits);

    /// @notice Create an SR token with immutable S, R, absolute staking account T, and half-life configuration.
    /// @dev T must be an empty debit leaf on S. Identical creation requests return the existing token.
    function createStakingRewardToken(
        address stakingLedger,
        address rewardLedger,
        address stakingAccount,
        uint256 halfLife,
        ILedgerTokenFactory.TokenMetadata memory metadata
    ) external returns (address token, uint256 flags);

    /// @notice Deposit S from the caller's Ledger balance and mint principal shares.
    function stake(address token, uint256 amount, uint256 minimumShares) external returns (uint256 shares);

    /// @notice Burn principal shares, retaining available rewards and forfeiting proportional pending rewards.
    /// @dev On a full exit by the last reward-unit holder, all remaining rewards become available to them.
    function unstake(address token, uint256 shares, uint256 minimumStake) external returns (uint256 amount);

    /// @notice Fund pending rewards from the caller's R Ledger balance, allocated to current share holders.
    function reward(address token, uint256 amount) external;

    /// @notice Redeem all available reward units into the caller's R Ledger balance.
    /// @dev Pays the floored token value and leaves pending units unchanged, even if the payout rounds to zero.
    function claim(address token) external returns (uint256 claimed);

    /// @notice SR configuration and balances, expressed in each token's raw decimals.
    function stakingRewardToken(address token) external view returns (Configuration memory);

    /// @notice Current rewards for a token-local holder key, including holders who have exited.
    /// @dev Token amounts use R's raw decimals; units are internal accounting quantities.
    function rewardsOf(address token, address holder) external view returns (Rewards memory);
}
