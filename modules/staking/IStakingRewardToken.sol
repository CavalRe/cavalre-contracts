// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LedgerLib} from "../ledger/LedgerLib.sol";

interface IStakingRewardToken {
    struct Rewards {
        uint256 totalUnits;
        uint256 pendingUnits;
        uint256 total;
        uint256 pending;
        uint256 available;
    }

    struct Configuration {
        LedgerLib.ReceiptToken receipt;
        address rewardLedger;
        address rewardAccount;
        address forfeitedAccount;
        uint256 halfLife;
        uint256 forfeitedBalance;
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

    event StakingRewardTokenConfigured(address indexed token, address indexed rewardLedger, uint256 halfLife);
    event Staked(address indexed token, address indexed holder, uint256 stake, uint256 receipts);
    event Unstaked(address indexed token, address indexed holder, uint256 receipts, uint256 stake);
    event Rewarded(address indexed token, address indexed funder, uint256 amount, uint256 units);
    event Claimed(address indexed token, address indexed holder, uint256 amount, uint256 units);
    event Forfeited(address indexed token, address indexed account, uint256 pendingUnits, uint256 cancelledUnits);
    event RewardsReserved(address indexed token, uint256 amount);
    event RewardsRecycled(address indexed token, uint256 amount);

    /// @notice Attach immutable reward configuration to an empty receipt token with an empty debit backing account.
    function configureStakingRewardToken(address token, address rewardLedger, uint256 halfLife) external;

    /// @notice Deposit S from the caller's Ledger balance and mint principal receipts.
    function stake(address token, uint256 amount, uint256 minimumReceipts) external returns (uint256 receipts);

    /// @notice Burn principal receipts, retaining available rewards and forfeiting proportional pending rewards.
    function unstake(address token, uint256 receipts, uint256 minimumStake) external returns (uint256 amount);

    /// @notice Fund pending rewards from the caller's R Ledger balance, allocated to current receipt holders.
    function reward(address token, uint256 amount) external;

    /// @notice Claim R into the caller's Ledger balance. Use type(uint256).max to burn all available units.
    function claim(address token, uint256 amount) external returns (uint256 claimed);

    /// @notice Owner reallocates rewards reserved when no other reward-unit holder could receive a forfeiture.
    function recycleRewards(address token, uint256 amount) external;

    function stakingRewardToken(address token) external view returns (Configuration memory);

    /// @notice Current rewards for a token-local holder key, including holders who have exited.
    /// @dev Token amounts use R's raw decimals; units are internal accounting quantities.
    function rewardsOf(address token, address holder) external view returns (Rewards memory);
}
