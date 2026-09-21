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
        address stakingGroup;
        uint256 stakedBalance;
        address rewardLedger;
        address rewardGroup;
        address rewardAccount;
        address rewardShareToken;
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
        address indexed stakingGroup,
        address indexed rewardGroup,
        address rewardShareToken,
        uint256 halfLife
    );
    event Staked(address indexed token, address indexed holder, uint256 stake, uint256 shares);
    event Unstaked(address indexed token, address indexed holder, uint256 shares, uint256 stake);
    event Rewarded(address indexed token, address indexed funder, uint256 amount, uint256 units);
    event Claimed(address indexed token, address indexed holder, uint256 amount, uint256 units);
    event Forfeited(address indexed token, address indexed account, uint256 pendingUnits, uint256 cancelledUnits);

    /// @notice Create an ERC20 wrapper over actual stakes beneath an absolute staking group.
    /// @dev Configure two registered debit groups and a positive half-life. The staking group starts empty.
    function createStakingRewardToken(
        address stakingGroup,
        address rewardGroup,
        uint256 halfLife,
        ILedgerTokenFactory.TokenMetadata memory metadata
    ) external returns (address token);

    /// @notice Transfer actual staking tokens from the caller's wallet account into their staking account.
    function stake(address token, uint256 amount, uint256 minimumShares) external returns (uint256 shares);

    /// @notice Withdraw actual staking tokens, retaining available rewards and forfeiting proportional pending rewards.
    /// @dev On a full exit by the last reward-unit holder, all remaining rewards become available to them.
    function unstake(address token, uint256 shares, uint256 minimumStake) external returns (uint256 amount);

    /// @notice Fund pending rewards from the caller's R Ledger balance, allocated to current share holders.
    function reward(address token, uint256 amount) external;

    /// @notice Redeem all available reward units into the caller's R Ledger balance.
    /// @dev Pays the floored token value and leaves pending units unchanged, even if the payout rounds to zero.
    function claim(address token) external returns (uint256 claimed);

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
