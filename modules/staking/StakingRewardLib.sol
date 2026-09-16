// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStakingRewardToken} from "./IStakingRewardToken.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {LedgerTokenFactoryLib} from "../ledger/LedgerTokenFactoryLib.sol";
import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

library StakingRewardLib {
    struct Checkpoint {
        // Outstanding unclaimed units (hat U) and pending units (hat P), not token amounts.
        uint256 unclaimedUnits;
        uint256 pendingUnits;
        // phi^(hat U): cumulative issued units per share.
        uint256 unclaimedAccumulator;
        // exp(-r * updatedAt) * phi^(hat P): the decaying pending accumulator.
        uint256 pendingAccumulator;
        uint256 updatedAt;
    }

    struct Program {
        address rewardLedger;
        uint256 halfLife;
        Checkpoint checkpoint;
        address stakingAccount;
    }

    struct Store {
        mapping(address token => Program) programs;
        mapping(address token => mapping(address absolute => Checkpoint)) positions;
        mapping(address absolute => address token) reservedAccounts;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken")) - 1)) & ~bytes32(uint256(0xff));

    // Accumulator increments are integral units per raw share. Quantizing issuance to supply * increment
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
        p.checkpoint.updatedAt = block.timestamp;
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

    function currentRewardCheckpoint(Program storage p) internal view returns (Checkpoint memory checkpoint_) {
        checkpoint_ = p.checkpoint;
        uint256 elapsed_ = block.timestamp - checkpoint_.updatedAt;
        checkpoint_.pendingUnits = applyHalfLife(checkpoint_.pendingUnits, elapsed_, p.halfLife);
        checkpoint_.pendingAccumulator = applyHalfLife(checkpoint_.pendingAccumulator, elapsed_, p.halfLife);
        checkpoint_.updatedAt = block.timestamp;
    }

    struct CurrentHolderRewardCheckpointCache {
        uint256 elapsed;
        uint256 pendingAccumulator;
    }

    function currentHolderRewardCheckpoint(
        Checkpoint memory position_,
        Checkpoint memory checkpoint_,
        uint256 balance_,
        uint256 halfLife_
    ) private view returns (Checkpoint memory) {
        CurrentHolderRewardCheckpointCache memory c;
        c.elapsed = block.timestamp - position_.updatedAt;
        c.pendingAccumulator = applyHalfLife(position_.pendingAccumulator, c.elapsed, halfLife_);
        position_.unclaimedUnits += balance_ * (checkpoint_.unclaimedAccumulator - position_.unclaimedAccumulator);
        position_.pendingUnits = applyHalfLife(position_.pendingUnits, c.elapsed, halfLife_);
        // Independently rounded decay paths can differ by their final precision digits.
        // A negative delta cannot represent newly funded rewards.
        if (checkpoint_.pendingAccumulator > c.pendingAccumulator) {
            position_.pendingUnits += balance_ * (checkpoint_.pendingAccumulator - c.pendingAccumulator);
        }
        if (position_.pendingUnits > position_.unclaimedUnits) position_.pendingUnits = position_.unclaimedUnits;
        position_.unclaimedAccumulator = checkpoint_.unclaimedAccumulator;
        position_.pendingAccumulator = checkpoint_.pendingAccumulator;
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
        uint256 increment;
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
        p.checkpoint = currentRewardCheckpoint(p);
        c.units = p.checkpoint.unclaimedUnits == 0
            ? FixedPointMathLib.fullMulDiv(amount_, UNIT_SCALE, 1)
            : FixedPointMathLib.fullMulDiv(amount_, p.checkpoint.unclaimedUnits, c.balance);
        c.increment = c.units / c.supply;
        if (c.increment == 0) revert IStakingRewardToken.ZeroAmount();
        c.units = c.increment * c.supply;
        p.checkpoint.unclaimedUnits += c.units;
        p.checkpoint.pendingUnits += c.units;
        // Accumulate issued units, not R amounts: forfeiture can change R per unit.
        p.checkpoint.unclaimedAccumulator += c.increment;
        p.checkpoint.pendingAccumulator += c.increment;
        LedgerLib.transfer(p.rewardLedger, p.rewardLedger, funder_, REWARDS, token_, amount_, settleTransferRewards);
        emit IStakingRewardToken.Rewarded(token_, funder_, amount_, c.units);
    }

    struct ClaimCache {
        address absolute;
        uint256 balance;
        uint256 availableUnits;
    }

    function claim(address token_, address holder_) internal returns (uint256 claimed_) {
        Program storage p = stakingRewardProgram(token_);
        ClaimCache memory c;
        c.absolute = LedgerLib.toAddress(token_, holder_);
        p.checkpoint = currentRewardCheckpoint(p);
        Checkpoint storage position_ = settleHolderRewards(p, token_, c.absolute, 0);
        c.availableUnits = position_.unclaimedUnits - position_.pendingUnits;
        if (c.availableUnits == 0) revert IStakingRewardToken.InsufficientRewards();
        c.balance = LedgerLib.balanceOf(LedgerLib.toAddress(p.rewardLedger, REWARDS, token_), false);
        claimed_ = FixedPointMathLib.fullMulDiv(c.availableUnits, c.balance, p.checkpoint.unclaimedUnits);
        position_.unclaimedUnits = position_.pendingUnits;
        p.checkpoint.unclaimedUnits -= c.availableUnits;
        if (p.checkpoint.pendingUnits > p.checkpoint.unclaimedUnits) {
            p.checkpoint.pendingUnits = p.checkpoint.unclaimedUnits;
        }
        LedgerLib.transfer(p.rewardLedger, REWARDS, token_, p.rewardLedger, holder_, claimed_, settleTransferRewards);
        emit IStakingRewardToken.Claimed(token_, holder_, claimed_, c.availableUnits);
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
        p.checkpoint = currentRewardCheckpoint(p);
        if (!toIsCredit_) settleHolderRewards(p, ledger_, to_, 0);
        if (!fromIsCredit_) settleHolderRewards(p, ledger_, from_, amount_);
    }

    struct SettleHolderRewardsCache {
        uint256 balance;
        uint256 pendingUnits;
        uint256 availableUnits;
        uint256 cancelledUnits;
    }

    /// @dev Checkpoint one holder and apply any outgoing shares using the same pre-transfer balance.
    function settleHolderRewards(Program storage p, address token_, address absolute_, uint256 shares_)
        private
        returns (Checkpoint storage position_)
    {
        SettleHolderRewardsCache memory c;
        c.balance = LedgerLib.balanceOf(absolute_, false);
        if (shares_ > c.balance) revert IStakingRewardToken.InsufficientStake();
        store().positions[token_][absolute_] =
            currentHolderRewardCheckpoint(store().positions[token_][absolute_], p.checkpoint, c.balance, p.halfLife);
        position_ = store().positions[token_][absolute_];
        if (shares_ == 0) return position_;
        c.pendingUnits = FixedPointMathLib.fullMulDiv(position_.pendingUnits, shares_, c.balance);
        if (c.pendingUnits == 0) return position_;
        if (position_.unclaimedUnits == p.checkpoint.unclaimedUnits && shares_ == c.balance) {
            // The last reward-unit holder keeps all backing on a full exit.
            position_.pendingUnits = 0;
            p.checkpoint.pendingUnits = 0;
            return position_;
        }
        c.availableUnits = position_.unclaimedUnits - position_.pendingUnits;
        // Cancel unclaimed units to preserve the holder's available R (up to rounding)
        // while repricing surviving units. The reward backing remains in its Ledger account.
        c.cancelledUnits = FixedPointMathLib.fullMulDivUp(
            c.pendingUnits, p.checkpoint.unclaimedUnits, p.checkpoint.unclaimedUnits - c.availableUnits
        );
        position_.unclaimedUnits -= c.cancelledUnits;
        position_.pendingUnits -= c.pendingUnits;
        p.checkpoint.unclaimedUnits -= c.cancelledUnits;
        // Aggregate and individual pending decay round independently.
        p.checkpoint.pendingUnits =
            p.checkpoint.pendingUnits > c.pendingUnits ? p.checkpoint.pendingUnits - c.pendingUnits : 0;
        if (p.checkpoint.pendingUnits > p.checkpoint.unclaimedUnits) {
            p.checkpoint.pendingUnits = p.checkpoint.unclaimedUnits;
        }
        emit IStakingRewardToken.Forfeited(token_, absolute_, c.pendingUnits, c.cancelledUnits);
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
        Checkpoint memory checkpoint_ = currentRewardCheckpoint(p);
        config_.rewards =
            rewardBalances(checkpoint_, checkpoint_.unclaimedUnits, LedgerLib.balanceOf(config_.rewardAccount, false));
    }

    function rewardsOf(address token_, address holder_) internal view returns (IStakingRewardToken.Rewards memory) {
        Program storage p = stakingRewardProgram(token_);
        Checkpoint memory checkpoint_ = currentRewardCheckpoint(p);
        address absolute_ = LedgerLib.toAddress(token_, holder_);
        return rewardBalances(
            currentHolderRewardCheckpoint(
                store().positions[token_][absolute_], checkpoint_, LedgerLib.balanceOf(absolute_, false), p.halfLife
            ),
            checkpoint_.unclaimedUnits,
            LedgerLib.balanceOf(LedgerLib.toAddress(p.rewardLedger, REWARDS, token_), false)
        );
    }

    function rewardBalances(Checkpoint memory checkpoint_, uint256 unclaimedUnits_, uint256 balance_)
        private
        pure
        returns (IStakingRewardToken.Rewards memory rewards_)
    {
        rewards_.unclaimedUnits = checkpoint_.unclaimedUnits;
        rewards_.pendingUnits = checkpoint_.pendingUnits;
        if (unclaimedUnits_ == 0) return rewards_;
        rewards_.unclaimed = FixedPointMathLib.fullMulDiv(checkpoint_.unclaimedUnits, balance_, unclaimedUnits_);
        rewards_.pending = FixedPointMathLib.fullMulDiv(checkpoint_.pendingUnits, balance_, unclaimedUnits_);
        rewards_.available = FixedPointMathLib.fullMulDiv(
            checkpoint_.unclaimedUnits - checkpoint_.pendingUnits, balance_, unclaimedUnits_
        );
    }
}
