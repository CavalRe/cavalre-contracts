// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStakingRewardToken} from "./IStakingRewardToken.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {LedgerTokenFactoryLib} from "../ledger/LedgerTokenFactoryLib.sol";
import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

library StakingRewardLib {
    struct State {
        uint256 total;
        uint256 pending;
        uint256 totalIndex;
        uint256 pendingIndex;
        uint256 updatedAt;
    }

    struct Program {
        address rewardLedger;
        uint256 halfLife;
        State state;
        address stakingAccount;
    }

    struct Store {
        mapping(address token => Program) programs;
        mapping(address token => mapping(address absolute => State)) positions;
        mapping(address absolute => address token) reservedAccounts;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken")) - 1)) & ~bytes32(uint256(0xff));

    // Index increments are integral units per raw share. Quantizing issuance to supply * index
    // makes total units exactly equal the sum of holder units, including lazy holder checkpoints.
    uint256 internal constant UNIT_SCALE = 1e36;
    uint256 private constant WAD = 1e18;
    uint256 private constant LN2 = 693147180559945309;

    // Deliberately truncated hashes, following Ledger's relative account keys.
    // forge-lint: disable-next-line(unsafe-typecast)
    address internal constant REWARDS = address(uint160(uint256(keccak256("Staking Rewards"))));

    function store() internal pure returns (Store storage s) {
        bytes32 position_ = STORE_POSITION;
        assembly {
            s.slot := position_
        }
    }

    // -- Configuration --

    struct CreateStakingRewardTokenCache {
        address rewardAccount;
        uint256 flags;
    }

    function createStakingRewardToken(
        address stakingLedger_,
        address rewardLedger_,
        address stakingAccount_,
        uint256 halfLife_,
        ILedgerTokenFactory.TokenMetadata memory metadata_
    ) internal returns (address token_, uint256 flags_) {
        CreateStakingRewardTokenCache memory c;
        (token_, flags_) = LedgerTokenFactoryLib.createInternalToken(metadata_);
        Program storage p = store().programs[token_];
        if (p.halfLife != 0) {
            if (
                p.rewardLedger != rewardLedger_ || p.halfLife != halfLife_ || p.stakingAccount != stakingAccount_
                    || LedgerLib.ledger(stakingAccount_) != stakingLedger_
            ) revert IStakingRewardToken.AlreadyConfigured(token_);
            return (token_, flags_);
        }
        c.flags = LedgerLib.flags(rewardLedger_);
        if (
            halfLife_ == 0 || rewardLedger_ == token_ || !LedgerLib.isLedger(c.flags)
                || !LedgerLib.isDebitGroup(c.flags) || !LedgerLib.isDebitLedger(LedgerLib.flags(stakingAccount_))
                || LedgerLib.ledger(stakingAccount_) != stakingLedger_ || stakingLedger_ == token_
                || LedgerLib.totalSupply(token_) != 0 || LedgerLib.balanceOf(stakingAccount_, false) != 0
        ) revert IStakingRewardToken.InvalidConfiguration();

        LedgerLib.addSubAccountGroup(rewardLedger_, rewardLedger_, REWARDS, "Staking Rewards", false);
        LedgerLib.addSubAccount(rewardLedger_, REWARDS, token_, "Rewards", false);
        c.rewardAccount = LedgerLib.toAddress(rewardLedger_, REWARDS, token_);
        protectCustodyAccount(token_, stakingAccount_);
        protectCustodyAccount(token_, c.rewardAccount);
        p.rewardLedger = rewardLedger_;
        p.halfLife = halfLife_;
        p.state.updatedAt = block.timestamp;
        p.stakingAccount = stakingAccount_;
        emit IStakingRewardToken.StakingRewardTokenCreated(
            token_, stakingLedger_, rewardLedger_, stakingAccount_, halfLife_
        );
    }

    function protectCustodyAccount(address token_, address absolute_) private {
        if (store().reservedAccounts[absolute_] != address(0) || LedgerLib.balanceOf(absolute_, false) != 0) {
            revert IStakingRewardToken.AccountReserved(absolute_);
        }
        store().reservedAccounts[absolute_] = token_;
    }

    function stakingRewardProgram(address token_) internal view returns (Program storage p) {
        p = store().programs[token_];
        if (p.halfLife == 0) revert IStakingRewardToken.NotStakingRewardToken(token_);
    }

    // -- Time and Checkpoints --

    /// @dev Whole half-lives use exact binary shifts; only the fractional half-life uses expWad.
    ///      No scheduled periods, keeper, or iteration over holders is required.
    function applyHalfLife(uint256 value_, uint256 elapsed_, uint256 halfLife_) internal pure returns (uint256) {
        uint256 halves_ = elapsed_ / halfLife_;
        if (halves_ >= 256) return 0;
        value_ >>= halves_;
        uint256 fraction_ = FixedPointMathLib.fullMulDiv(LN2, elapsed_ % halfLife_, halfLife_);
        // fraction_ is bounded by ln(2) * 1e18; expWad returns a positive value at most 1e18.
        // forge-lint: disable-next-line(unsafe-typecast)
        return FixedPointMathLib.fullMulDiv(value_, uint256(FixedPointMathLib.expWad(-int256(fraction_))), WAD);
    }

    function currentRewardState(Program storage p) internal view returns (State memory state_) {
        state_ = p.state;
        uint256 elapsed_ = block.timestamp - state_.updatedAt;
        state_.pending = applyHalfLife(state_.pending, elapsed_, p.halfLife);
        state_.pendingIndex = applyHalfLife(state_.pendingIndex, elapsed_, p.halfLife);
        state_.updatedAt = block.timestamp;
    }

    struct CurrentHolderRewardStateCache {
        uint256 elapsed;
        uint256 pendingIndex;
    }

    function currentHolderRewardState(State memory position_, State memory state_, uint256 balance_, uint256 halfLife_)
        private
        view
        returns (State memory)
    {
        CurrentHolderRewardStateCache memory c;
        c.elapsed = block.timestamp - position_.updatedAt;
        c.pendingIndex = applyHalfLife(position_.pendingIndex, c.elapsed, halfLife_);
        position_.total += balance_ * (state_.totalIndex - position_.totalIndex);
        position_.pending = applyHalfLife(position_.pending, c.elapsed, halfLife_);
        // Independently rounded decay paths can differ by their final precision digits.
        // A negative delta cannot represent newly funded rewards.
        if (state_.pendingIndex > c.pendingIndex) {
            position_.pending += balance_ * (state_.pendingIndex - c.pendingIndex);
        }
        if (position_.pending > position_.total) position_.pending = position_.total;
        position_.totalIndex = state_.totalIndex;
        position_.pendingIndex = state_.pendingIndex;
        position_.updatedAt = block.timestamp;
        return position_;
    }

    // -- Principal --

    struct StakingBackingCache {
        address ledger;
        address parent;
        address relative;
        uint256 balance;
        uint256 supply;
    }

    function stakingBacking(address token_) private view returns (StakingBackingCache memory c) {
        address absolute_ = stakingRewardProgram(token_).stakingAccount;
        c.ledger = LedgerLib.ledger(absolute_);
        c.parent = LedgerLib.parent(LedgerLib.flags(absolute_));
        c.relative = LedgerLib.subAccount(
            c.parent == c.ledger ? c.ledger : LedgerLib.toAddress(c.ledger, c.parent),
            LedgerLib.subAccountIndex(absolute_) - 1
        );
        c.balance = LedgerLib.balanceOf(absolute_, false);
        c.supply = LedgerLib.totalSupply(token_);
    }

    struct StakeCache {
        StakingBackingCache backing;
        uint256 decimals;
        uint256 shareDecimals;
    }

    function stake(address token_, address holder_, uint256 amount_, uint256 minimum_)
        internal
        returns (uint256 shares_)
    {
        StakeCache memory c;
        c.backing = stakingBacking(token_);
        if (amount_ == 0) revert IStakingRewardToken.ZeroAmount();
        if (store().reservedAccounts[LedgerLib.toAddress(c.backing.ledger, holder_)] != address(0)) {
            revert IStakingRewardToken.AccountReserved(LedgerLib.toAddress(c.backing.ledger, holder_));
        }
        if (c.backing.supply == 0) {
            c.decimals = LedgerLib.decimals(c.backing.ledger);
            c.shareDecimals = LedgerLib.decimals(token_);
            shares_ = c.shareDecimals >= c.decimals
                ? amount_ * (10 ** (c.shareDecimals - c.decimals))
                : amount_ / (10 ** (c.decimals - c.shareDecimals));
        } else {
            shares_ = FixedPointMathLib.fullMulDiv(amount_, c.backing.supply, c.backing.balance);
        }
        if (shares_ == 0) revert IStakingRewardToken.ZeroAmount();
        if (shares_ < minimum_) revert IStakingRewardToken.Slippage(shares_, minimum_);
        LedgerLib.transfer(
            c.backing.ledger,
            c.backing.ledger,
            holder_,
            c.backing.parent,
            c.backing.relative,
            amount_,
            settleTransferRewards
        );
        LedgerLib.transfer(token_, token_, LedgerLib.SOURCE_ADDRESS, token_, holder_, shares_, settleTransferRewards);
        emit IStakingRewardToken.Staked(token_, holder_, amount_, shares_);
    }

    function unstake(address token_, address holder_, uint256 shares_, uint256 minimum_)
        internal
        returns (uint256 amount_)
    {
        StakingBackingCache memory c = stakingBacking(token_);
        if (shares_ == 0) revert IStakingRewardToken.ZeroAmount();
        if (shares_ > c.supply) revert IStakingRewardToken.InsufficientStake();
        amount_ = FixedPointMathLib.fullMulDiv(shares_, c.balance, c.supply);
        if (amount_ < minimum_) revert IStakingRewardToken.Slippage(amount_, minimum_);
        LedgerLib.transfer(token_, token_, holder_, token_, LedgerLib.SOURCE_ADDRESS, shares_, settleTransferRewards);
        LedgerLib.transfer(c.ledger, c.parent, c.relative, c.ledger, holder_, amount_, settleTransferRewards);
        emit IStakingRewardToken.Unstaked(token_, holder_, shares_, amount_);
    }

    // -- Funding and Claims --

    struct RewardCache {
        uint256 supply;
        uint256 balance;
        uint256 units;
        uint256 index;
    }

    function reward(address token_, address funder_, uint256 amount_) internal {
        Program storage p = stakingRewardProgram(token_);
        if (amount_ == 0) revert IStakingRewardToken.ZeroAmount();
        RewardCache memory c;
        if (store().reservedAccounts[LedgerLib.toAddress(p.rewardLedger, funder_)] != address(0)) {
            revert IStakingRewardToken.AccountReserved(LedgerLib.toAddress(p.rewardLedger, funder_));
        }
        c.supply = LedgerLib.totalSupply(token_);
        if (c.supply == 0) revert IStakingRewardToken.NoStake();
        c.balance = LedgerLib.balanceOf(LedgerLib.toAddress(p.rewardLedger, REWARDS, token_), false);
        p.state = currentRewardState(p);
        c.units = p.state.total == 0
            ? FixedPointMathLib.fullMulDiv(amount_, UNIT_SCALE, 1)
            : FixedPointMathLib.fullMulDiv(amount_, p.state.total, c.balance);
        c.index = c.units / c.supply;
        if (c.index == 0) revert IStakingRewardToken.ZeroAmount();
        c.units = c.index * c.supply;
        p.state.total += c.units;
        p.state.pending += c.units;
        // Accumulate issued units, not R amounts: forfeiture can change R per unit.
        p.state.totalIndex += c.index;
        p.state.pendingIndex += c.index;
        LedgerLib.transfer(p.rewardLedger, p.rewardLedger, funder_, REWARDS, token_, amount_, settleTransferRewards);
        emit IStakingRewardToken.Rewarded(token_, funder_, amount_, c.units);
    }

    struct ClaimCache {
        address absolute;
        uint256 balance;
        uint256 available;
        uint256 units;
    }

    function claim(address token_, address holder_, uint256 amount_) internal returns (uint256 claimed_) {
        Program storage p = stakingRewardProgram(token_);
        if (amount_ == 0) revert IStakingRewardToken.ZeroAmount();
        ClaimCache memory c;
        c.absolute = LedgerLib.toAddress(token_, holder_);
        p.state = currentRewardState(p);
        State storage position_ = settleHolderRewards(p, token_, c.absolute, 0);
        c.available = position_.total - position_.pending;
        if (c.available == 0) revert IStakingRewardToken.InsufficientRewards();
        c.balance = LedgerLib.balanceOf(LedgerLib.toAddress(p.rewardLedger, REWARDS, token_), false);
        if (amount_ == type(uint256).max) {
            c.units = c.available;
            claimed_ = FixedPointMathLib.fullMulDiv(c.units, c.balance, p.state.total);
        } else {
            c.units = FixedPointMathLib.fullMulDivUp(amount_, p.state.total, c.balance);
            if (c.units > c.available) revert IStakingRewardToken.InsufficientRewards();
            claimed_ = amount_;
        }
        position_.total -= c.units;
        p.state.total -= c.units;
        if (p.state.pending > p.state.total) p.state.pending = p.state.total;
        LedgerLib.transfer(p.rewardLedger, REWARDS, token_, p.rewardLedger, holder_, claimed_, settleTransferRewards);
        emit IStakingRewardToken.Claimed(token_, holder_, claimed_, c.units);
    }

    // -- Share Transfers and Forfeiture --

    /// @dev The Dispatcher hook protects custody and SR supply changes on ordinary Ledger transfers.
    function beforeLedgerTransfer(
        address ledger_,
        address from_,
        address to_,
        bool fromIsCredit_,
        bool toIsCredit_,
        uint256 amount_
    ) internal {
        if (from_ == to_ || amount_ == 0) return;
        if (store().reservedAccounts[from_] != address(0)) {
            revert IStakingRewardToken.AccountReserved(from_);
        }
        if (fromIsCredit_ != toIsCredit_ && store().programs[ledger_].halfLife != 0) {
            revert IStakingRewardToken.UnauthorizedTransfer();
        }
        settleTransferRewards(ledger_, from_, to_, fromIsCredit_, toIsCredit_, amount_);
    }

    /// @dev Shared by SR operations and the Dispatcher hook. Settle rewards before changing share balances.
    ///      Transfers behave as sender exits and receiver entries; accrued rewards stay with the sender.
    function settleTransferRewards(
        address ledger_,
        address from_,
        address to_,
        bool fromIsCredit_,
        bool toIsCredit_,
        uint256 amount_
    ) private {
        if (from_ == to_ || amount_ == 0) return;
        Program storage p = store().programs[ledger_];
        if (p.halfLife == 0) return;
        p.state = currentRewardState(p);
        if (!toIsCredit_) settleHolderRewards(p, ledger_, to_, 0);
        if (!fromIsCredit_) settleHolderRewards(p, ledger_, from_, amount_);
    }

    struct SettleHolderRewardsCache {
        uint256 balance;
        uint256 pending;
        uint256 available;
        uint256 cancelled;
    }

    /// @dev Checkpoint one holder and apply any outgoing shares using the same pre-transfer balance.
    function settleHolderRewards(Program storage p, address token_, address absolute_, uint256 shares_)
        private
        returns (State storage position_)
    {
        SettleHolderRewardsCache memory c;
        c.balance = LedgerLib.balanceOf(absolute_, false);
        if (shares_ > c.balance) revert IStakingRewardToken.InsufficientStake();
        store().positions[token_][absolute_] =
            currentHolderRewardState(store().positions[token_][absolute_], p.state, c.balance, p.halfLife);
        position_ = store().positions[token_][absolute_];
        if (shares_ == 0) return position_;
        c.pending = FixedPointMathLib.fullMulDiv(position_.pending, shares_, c.balance);
        if (c.pending == 0) return position_;
        if (position_.total == p.state.total && shares_ == c.balance) {
            // The last reward-unit holder keeps all backing on a full exit.
            position_.pending = 0;
            p.state.pending = 0;
            return position_;
        }
        c.available = position_.total - position_.pending;
        // Q = F * U / (U - A). Burn Q total units and F pending units, preserving the
        // exiting holder's available R (up to rounding) while repricing surviving units.
        c.cancelled = FixedPointMathLib.fullMulDivUp(c.pending, p.state.total, p.state.total - c.available);
        position_.total -= c.cancelled;
        position_.pending -= c.pending;
        p.state.total -= c.cancelled;
        // Aggregate and individual pending decay round independently.
        p.state.pending = p.state.pending > c.pending ? p.state.pending - c.pending : 0;
        if (p.state.pending > p.state.total) p.state.pending = p.state.total;
        emit IStakingRewardToken.Forfeited(token_, absolute_, c.pending, c.cancelled);
    }

    // -- Views --

    function stakingRewardToken(address token_)
        internal
        view
        returns (IStakingRewardToken.Configuration memory config_)
    {
        Program storage p = stakingRewardProgram(token_);
        config_.tokenAddress = token_;
        config_.totalSupply = LedgerLib.totalSupply(token_);
        config_.stakingAccount = p.stakingAccount;
        config_.stakingLedger = LedgerLib.ledger(p.stakingAccount);
        config_.stakedBalance = LedgerLib.balanceOf(p.stakingAccount, false);
        config_.rewardLedger = p.rewardLedger;
        config_.rewardAccount = LedgerLib.toAddress(p.rewardLedger, REWARDS, token_);
        config_.halfLife = p.halfLife;
        State memory state_ = currentRewardState(p);
        config_.rewards = rewardBalances(state_, state_.total, LedgerLib.balanceOf(config_.rewardAccount, false));
    }

    function rewardsOf(address token_, address holder_) internal view returns (IStakingRewardToken.Rewards memory) {
        Program storage p = stakingRewardProgram(token_);
        State memory state_ = currentRewardState(p);
        address absolute_ = LedgerLib.toAddress(token_, holder_);
        return rewardBalances(
            currentHolderRewardState(
                store().positions[token_][absolute_], state_, LedgerLib.balanceOf(absolute_, false), p.halfLife
            ),
            state_.total,
            LedgerLib.balanceOf(LedgerLib.toAddress(p.rewardLedger, REWARDS, token_), false)
        );
    }

    function rewardBalances(State memory state_, uint256 total_, uint256 balance_)
        private
        pure
        returns (IStakingRewardToken.Rewards memory rewards_)
    {
        rewards_.totalUnits = state_.total;
        rewards_.pendingUnits = state_.pending;
        if (total_ == 0) return rewards_;
        rewards_.total = FixedPointMathLib.fullMulDiv(state_.total, balance_, total_);
        rewards_.pending = FixedPointMathLib.fullMulDiv(state_.pending, balance_, total_);
        rewards_.available = FixedPointMathLib.fullMulDiv(state_.total - state_.pending, balance_, total_);
    }
}
