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
    event Forfeited(
        address indexed token, address indexed account, uint256 pendingUnits, uint256 allocationRemainderUnits
    );

    /// @notice Create an ERC20 wrapper over actual stakes beneath an absolute staking group.
    /// @dev Configure two registered debit groups and a positive half-life. The staking group starts empty.
    /// Nested SR stake/reward assets are rejected, including programs created inside a prospective outer stake group.
    function createStakingRewardToken(
        address stakingGroup,
        address rewardGroup,
        uint256 halfLife,
        ILedgerTokenFactory.TokenMetadata memory metadata
    ) external returns (address token);

    /// @notice Transfer actual staking tokens from the caller's wallet account into their staking account.
    function stake(address token, uint256 amount, uint256 minimumShares) external returns (uint256 shares);

    /// @notice Withdraw actual staking tokens, retaining available rewards and forfeiting proportional pending rewards.
    /// @dev On the final eligible-stake exit, pending rewards become available; exited holders retain their rewards.
    function unstake(address token, uint256 shares, uint256 minimumStake) external returns (uint256 amount);

    /// @notice Add funded rewards, allocated as pending rewards in proportion to current stake.
    /// @dev Moves existing tokens from the caller's reward-ledger wallet account to rewardGroup / token.
    /// Funding requires nonzero stake. Checkpoints record holder entitlements; no per-holder reward accounts are created.
    /// Existing rewards keep their accrued vesting. This does not withdraw tokens from the caller's staking account.
    /// @param token SR wrapper address identifying the program to fund, not the token used as reward backing.
    /// @param amount Amount to contribute, in the configured reward ledger's raw token units.
    function reward(address token, uint256 amount) external;

    /// @notice Fund pending rewards directly from the caller's leaf under a chosen reward-account parent.
    /// @dev The parent must be the reward ledger root or a registered staking group in that ledger.
    /// Departing stake forfeits pending rewards under the usual rules; new funding is allocated after that exit.
    /// Funding that would leave the recipient program without stake reverts atomically.
    /// @param token SR wrapper identifying the program to fund.
    /// @param funderParent Absolute parent of the caller's funding leaf, such as USD.cav's configured Stake group.
    /// @param amount Contribution in the configured reward ledger's raw token units.
    function reward(address token, address funderParent, uint256 amount) external;

    /// @notice Collect all of the caller's available rewards without withdrawing their stake.
    /// @dev Settles elapsed vesting, redeems all available reward units, and pays from rewardGroup / token
    /// into the caller's reward-ledger wallet account. Remaining pending units stay pending.
    /// The payout is rounded down; available units are consumed even when their token value rounds to zero.
    /// This does not stake the payout or increase a recipient's SR wrapper balance automatically.
    /// @param token SR wrapper address identifying the program whose rewards are being claimed.
    /// @return claimed Amount paid, in the configured reward ledger's raw token units.
    function claim(address token) external returns (uint256 claimed);

    /// @notice Collect all available rewards directly into the caller's leaf under a chosen reward-account parent.
    /// @dev The parent must be the reward ledger root or a registered staking group in that ledger.
    /// Paying into Stake increases that program's public SR balance without giving the incoming balance past rewards.
    /// Remaining pending rewards stay with the claiming position. Available units are consumed even for a zero payout.
    /// @param token SR wrapper identifying the program whose rewards are being claimed.
    /// @param recipientParent Absolute parent of the caller's payout leaf in the configured reward ledger.
    /// @return claimed Payout in raw reward-ledger token units, rounded down from the redeemed units.
    function claim(address token, address recipientParent) external returns (uint256 claimed);

    /// @notice Transfer direct SR balances after settling sender and recipient rewards.
    /// @dev Only the token's registered wrapper may call. The wrapper owns allowance checks.
    function transfer(address token, address from, address to, uint256 amount) external;

    /// @dev Internal posting settlement; only the Dispatcher itself may invoke this selector.
    function settleStakeTransfer(
        address token,
        address from,
        address to,
        bool fromOutside,
        bool toOutside,
        uint256 amount
    ) external;

    /// @notice SR configuration and balances, expressed in each token's raw decimals.
    function stakingRewardToken(address token) external view returns (Configuration memory);

    /// @notice Current rewards for a direct holder, including holders who have exited.
    /// @dev Token amounts use R's raw decimals; units are internal accounting quantities.
    function rewardsOf(address token, address holder) external view returns (Rewards memory);
    /// @notice Rewards for an internal leaf with explicit absolute parent context.
    function rewardsOfAccount(address token, address parent, address relative) external view returns (Rewards memory);
}
