// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStakingRewardToken} from "./IStakingRewardToken.sol";
import {StakingRewardWrapper} from "./StakingRewardWrapper.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {LedgerTokenFactoryLib} from "../ledger/LedgerTokenFactoryLib.sol";
import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";
import {ShareTokenLib} from "../share/ShareTokenLib.sol";
import {ERC20Wrapper} from "../ledger/ERC20Wrapper.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library StakingRewardLib {
    struct Checkpoint {
        // Outstanding unclaimed units (hat U) and pending units (hat P), not token amounts.
        uint256 unclaimedUnits;
        uint256 pendingUnits;
        // phi^(hat U): cumulative issued reward units per raw staked token.
        uint256 unclaimedAccumulator;
        // exp(-r * updatedAt) * phi^(hat P): the decaying pending accumulator.
        uint256 pendingAccumulator;
        uint256 updatedAt;
    }

    struct Program {
        address stakingGroup;
        address rewardGroup;
        address rewardShareToken;
        uint256 halfLife;
        // Outstanding reward units are the reward ShareToken's supply, not a second stored balance.
        uint256 pendingUnits;
        uint256 unclaimedAccumulator;
        uint256 pendingAccumulator;
        uint256 updatedAt;
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

    function store() internal pure returns (Store storage s) {
        bytes32 position_ = STORE_POSITION;
        assembly {
            s.slot := position_
        }
    }

    // -- Configuration --

    struct CreateStakingRewardTokenCache {
        address stakingLedger;
        address rewardLedger;
        address rewardAccount;
        uint256 flags;
        uint256 rewardDecimals;
    }

    function createStakingRewardToken(
        address stakingGroup_,
        address rewardGroup_,
        uint256 halfLife_,
        ILedgerTokenFactory.TokenMetadata memory metadata_
    ) internal returns (address token_) {
        CreateStakingRewardTokenCache memory c;
        bytes32 salt_ = LedgerTokenFactoryLib.tokenSalt(metadata_);
        bytes memory creationCode_ = abi.encodePacked(
            type(StakingRewardWrapper).creationCode,
            abi.encode(address(this), metadata_.name, metadata_.symbol, metadata_.decimals)
        );
        token_ = Create2.computeAddress(salt_, keccak256(creationCode_));
        Program storage p = store().programs[token_];
        if (p.halfLife != 0) {
            if (p.stakingGroup != stakingGroup_ || p.rewardGroup != rewardGroup_ || p.halfLife != halfLife_) {
                revert IStakingRewardToken.AlreadyConfigured(token_);
            }
            return token_;
        }
        if (
            token_.code.length != 0 || !LedgerLib.isValidString(metadata_.name)
                || !LedgerLib.isValidString(metadata_.symbol)
        ) {
            revert ILedger.InvalidToken(token_, metadata_.name, metadata_.symbol, metadata_.decimals);
        }
        c.stakingLedger = LedgerLib.ledger(stakingGroup_);
        c.rewardLedger = LedgerLib.ledger(rewardGroup_);
        c.flags = LedgerLib.flags(stakingGroup_);
        if (
            halfLife_ == 0 || c.stakingLedger == address(0) || c.rewardLedger == address(0)
                || !LedgerLib.isDebitGroup(c.flags) || LedgerLib.isLedger(c.flags)
                || !LedgerLib.isDebitGroup(LedgerLib.flags(rewardGroup_))
                || LedgerLib.isLedger(LedgerLib.flags(rewardGroup_))
                || metadata_.decimals != LedgerLib.decimals(c.stakingLedger)
                || LedgerLib.debitBalanceOf(stakingGroup_) != 0 || LedgerLib.creditBalanceOf(stakingGroup_) != 0
        ) revert IStakingRewardToken.InvalidConfiguration();
        // Reward backing must not contribute to this program's staking aggregate.
        for (
            address ancestor_ = rewardGroup_;
            ancestor_ != LedgerLib.ROOT_ADDRESS;
            ancestor_ = LedgerLib.parent(LedgerLib.flags(ancestor_))
        ) {
            if (ancestor_ == stakingGroup_) revert IStakingRewardToken.InvalidConfiguration();
        }
        c.rewardDecimals = uint256(LedgerLib.decimals(c.rewardLedger)) + 36;
        if (c.rewardDecimals > type(uint8).max) revert IStakingRewardToken.InvalidConfiguration();
        token_ = address(
            new StakingRewardWrapper{salt: salt_}(address(this), metadata_.name, metadata_.symbol, metadata_.decimals)
        );
        (c.rewardAccount,) = LedgerLib.addSubAccount(c.rewardLedger, rewardGroup_, token_, "Rewards", false);
        protectCustodyAccount(token_, stakingGroup_);
        protectCustodyAccount(token_, c.rewardAccount);
        // Reward shares retain SR's raw 1e36 precision. The wrapper address makes their identity program-specific.
        // The bound above guarantees the uint8 metadata conversion is exact.
        // forge-lint: disable-next-line(unsafe-typecast)
        (p.rewardShareToken,) = LedgerTokenFactoryLib.createShareToken(
            c.rewardAccount,
            ILedgerTokenFactory.TokenMetadata(
                "Staking Reward Shares", "SR-REWARD", uint8(c.rewardDecimals), Strings.toHexString(token_)
            )
        );
        LedgerLib.addSubAccount(p.rewardShareToken, p.rewardShareToken, token_, "SR custody", false);
        p.stakingGroup = stakingGroup_;
        p.rewardGroup = rewardGroup_;
        p.halfLife = halfLife_;
        p.updatedAt = block.timestamp;
        emit IStakingRewardToken.StakingRewardTokenCreated(
            token_, stakingGroup_, rewardGroup_, p.rewardShareToken, halfLife_
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
        checkpoint_ = Checkpoint(
            LedgerLib.totalSupply(p.rewardShareToken),
            p.pendingUnits,
            p.unclaimedAccumulator,
            p.pendingAccumulator,
            p.updatedAt
        );
        uint256 elapsed_ = block.timestamp - p.updatedAt;
        if (elapsed_ == 0) return checkpoint_;
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

    // -- Staking Accounts --

    struct StakingBackingCache {
        address ledger;
        address parent;
        uint256 flags;
        uint256 balance;
    }

    function stakingBacking(address token_) private view returns (StakingBackingCache memory c) {
        address absolute_ = stakingRewardProgram(token_).stakingGroup;
        c.ledger = LedgerLib.ledger(absolute_);
        c.flags = LedgerLib.flags(absolute_);
        c.parent = absolute_;
        c.balance = LedgerLib.balanceOf(absolute_, false);
    }

    /// @dev Rewards and stake ownership belong to debit leaves. A custody group's
    /// aggregate balance does not create a second reward position or authorize a claim.
    function enforceDebitAccount(address token_, address parent_, address relative_)
        internal
        view
        returns (uint256 flags_, address absolute_)
    {
        (flags_,, absolute_) = LedgerLib.effectiveFlags(token_, parent_, relative_);
        if (relative_ == address(0) || relative_ == LedgerLib.SOURCE_ADDRESS || !LedgerLib.isDebitLedger(flags_)) {
            revert ILedger.InvalidLedgerAccount(absolute_);
        }
    }

    function stake(address token_, address holder_, uint256 amount_, uint256 minimum_) internal returns (uint256) {
        StakingBackingCache memory c = stakingBacking(token_);
        if (amount_ == 0) revert IStakingRewardToken.ZeroAmount();
        if (amount_ < minimum_) revert IStakingRewardToken.Slippage(amount_, minimum_);
        (uint256 walletFlags_, address walletAbsolute_) = enforceDebitAccount(c.ledger, c.ledger, holder_);
        if (store().reservedAccounts[walletAbsolute_] != address(0)) {
            revert IStakingRewardToken.AccountReserved(walletAbsolute_);
        }
        (uint256 stakingFlags_, address stakingAbsolute_) = enforceDebitAccount(c.ledger, c.parent, holder_);
        // Entry eligibility starts only after the holder's old stake has been checkpointed.
        settleTransferRewards(token_, walletAbsolute_, stakingAbsolute_, true, false, amount_);
        LedgerLib.transfer(c.ledger, walletFlags_, holder_, stakingFlags_, holder_, amount_);
        ERC20Wrapper(token_).emitTransfer(address(0), holder_, amount_);
        emit IStakingRewardToken.Staked(token_, holder_, amount_, amount_);
        return amount_;
    }

    function unstake(address token_, address holder_, uint256 amount_, uint256 minimum_) internal returns (uint256) {
        return unstake(token_, stakingRewardProgram(token_).stakingGroup, holder_, holder_, amount_, minimum_);
    }

    /// @dev The consuming module authorizes the explicit staking leaf and payout recipient.
    function unstake(
        address token_,
        address parent_,
        address relative_,
        address recipient_,
        uint256 amount_,
        uint256 minimum_
    ) internal returns (uint256) {
        StakingBackingCache memory c = stakingBacking(token_);
        (uint256 holderFlags_, address holderAbsolute_) = enforceDebitAccount(c.ledger, parent_, relative_);
        // Explicit internal accounts must belong to this program's staking subtree.
        address ancestor_ = parent_;
        while (ancestor_ != c.parent && ancestor_ != c.ledger) ancestor_ = LedgerLib.parent(LedgerLib.flags(ancestor_));
        if (ancestor_ != c.parent) revert ILedger.InvalidLedgerAccount(holderAbsolute_);
        if (amount_ == 0) revert IStakingRewardToken.ZeroAmount();
        if (amount_ < minimum_) revert IStakingRewardToken.Slippage(amount_, minimum_);
        (uint256 recipientFlags_, address recipientAbsolute_) = enforceDebitAccount(c.ledger, c.ledger, recipient_);
        settleTransferRewards(token_, holderAbsolute_, recipientAbsolute_, false, true, amount_);
        LedgerLib.transfer(c.ledger, holderFlags_, relative_, recipientFlags_, recipient_, amount_);
        ERC20Wrapper(token_).emitTransfer(parent_ == c.parent ? relative_ : holderAbsolute_, address(0), amount_);
        emit IStakingRewardToken.Unstaked(token_, parent_ == c.parent ? relative_ : holderAbsolute_, amount_, amount_);
        return amount_;
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
        address rewardLedger_ = LedgerLib.ledger(p.rewardGroup);
        (uint256 funderFlags_, address absolute_) = enforceDebitAccount(rewardLedger_, rewardLedger_, funder_);
        if (store().reservedAccounts[absolute_] != address(0)) revert IStakingRewardToken.AccountReserved(absolute_);
        (uint256 rewardFlags_,, address rewardAbsolute_) =
            LedgerLib.effectiveFlags(rewardLedger_, p.rewardGroup, token_);
        c.supply = LedgerLib.balanceOf(p.stakingGroup, false);
        if (c.supply == 0) revert IStakingRewardToken.NoStake();
        c.balance = LedgerLib.balanceOf(rewardAbsolute_, false);
        Checkpoint memory checkpoint_ = currentRewardCheckpoint(p);
        LedgerLib.transfer(rewardLedger_, funderFlags_, funder_, rewardFlags_, token_, amount_);
        if (
            LedgerLib.balanceOf(rewardAbsolute_, false) != c.balance + amount_
                || LedgerLib.totalSupply(p.rewardShareToken) != checkpoint_.unclaimedUnits
        ) revert IStakingRewardToken.InvalidConfiguration();
        c.units = ShareTokenLib.issue(p.rewardShareToken, p.rewardShareToken, token_, amount_);
        c.increment = c.units / c.supply;
        if (c.increment == 0) revert IStakingRewardToken.ZeroAmount();
        // Generic issuance floors the quote. SR additionally quantizes allocation to whole
        // units per raw stake; remove only the unallocatable remainder from the same custody.
        if (c.units % c.supply != 0) {
            ShareTokenLib.cancel(p.rewardShareToken, p.rewardShareToken, token_, c.units % c.supply);
        }
        c.units = c.increment * c.supply;
        if (LedgerLib.totalSupply(p.rewardShareToken) != checkpoint_.unclaimedUnits + c.units) {
            revert IStakingRewardToken.InvalidConfiguration();
        }
        p.pendingUnits = checkpoint_.pendingUnits + c.units;
        p.unclaimedAccumulator = checkpoint_.unclaimedAccumulator + c.increment;
        p.pendingAccumulator = checkpoint_.pendingAccumulator + c.increment;
        p.updatedAt = checkpoint_.updatedAt;
        emit IStakingRewardToken.Rewarded(token_, funder_, amount_, c.units);
    }

    struct ClaimCache {
        address absolute;
        address rewardLedger;
        address rewardAbsolute;
        uint256 rewardFlags;
        uint256 balance;
        uint256 supply;
        uint256 availableUnits;
    }

    function claim(address token_, address holder_) internal returns (uint256 claimed_) {
        return claim(token_, stakingRewardProgram(token_).stakingGroup, holder_, holder_);
    }

    /// @dev The consuming module authorizes the explicit staking leaf and payout recipient.
    function claim(address token_, address parent_, address relative_, address recipient_)
        internal
        returns (uint256 claimed_)
    {
        Program storage p = stakingRewardProgram(token_);
        ClaimCache memory c;
        (, c.absolute) = enforceDebitAccount(LedgerLib.ledger(p.stakingGroup), parent_, relative_);
        address ancestor_ = parent_;
        while (ancestor_ != p.stakingGroup && !LedgerLib.isLedger(LedgerLib.flags(ancestor_))) {
            ancestor_ = LedgerLib.parent(LedgerLib.flags(ancestor_));
        }
        if (ancestor_ != p.stakingGroup) revert ILedger.InvalidLedgerAccount(c.absolute);
        Checkpoint storage position_ = settleHolderRewards(p, token_, c.absolute, 0);
        c.availableUnits = position_.unclaimedUnits - position_.pendingUnits;
        if (c.availableUnits == 0) revert IStakingRewardToken.InsufficientRewards();
        c.rewardLedger = LedgerLib.ledger(p.rewardGroup);
        (c.rewardFlags,, c.rewardAbsolute) = LedgerLib.effectiveFlags(c.rewardLedger, p.rewardGroup, token_);
        c.balance = LedgerLib.balanceOf(c.rewardAbsolute, false);
        c.supply = LedgerLib.totalSupply(p.rewardShareToken);
        claimed_ = FixedPointMathLib.fullMulDiv(c.availableUnits, c.balance, c.supply);
        position_.unclaimedUnits = position_.pendingUnits;
        // SR clears available entitlements even when integer rounding produces no payout.
        if (claimed_ == 0) {
            ShareTokenLib.cancel(p.rewardShareToken, p.rewardShareToken, token_, c.availableUnits);
        } else if (ShareTokenLib.redeem(p.rewardShareToken, p.rewardShareToken, token_, c.availableUnits) != claimed_) {
            revert IStakingRewardToken.InvalidConfiguration();
        }
        if (p.pendingUnits > c.supply - c.availableUnits) p.pendingUnits = c.supply - c.availableUnits;
        (uint256 recipientFlags_,) = enforceDebitAccount(c.rewardLedger, c.rewardLedger, recipient_);
        LedgerLib.transfer(c.rewardLedger, c.rewardFlags, token_, recipientFlags_, recipient_, claimed_);
        if (
            LedgerLib.balanceOf(c.rewardAbsolute, false) != c.balance - claimed_
                || LedgerLib.totalSupply(p.rewardShareToken) != c.supply - c.availableUnits
        ) revert IStakingRewardToken.InvalidConfiguration();
        emit IStakingRewardToken.Claimed(
            token_, parent_ == p.stakingGroup ? relative_ : c.absolute, claimed_, c.availableUnits
        );
    }

    // -- Stake Transfers and Forfeiture --

    /// @dev SR operations settle rewards explicitly before changing actual stake balances.
    ///      Transfers behave as sender exits and receiver entries; accrued rewards stay with the sender.
    function settleTransferRewards(
        address token_,
        address from_,
        address to_,
        bool fromIsCredit_,
        bool toIsCredit_,
        uint256 amount_
    ) internal {
        if (from_ == to_ || amount_ == 0) return;
        Program storage p = stakingRewardProgram(token_);
        if (!toIsCredit_) settleHolderRewards(p, token_, to_, 0);
        if (!fromIsCredit_) settleHolderRewards(p, token_, from_, amount_);
    }

    struct SettleHolderRewardsCache {
        uint256 balance;
        uint256 pendingUnits;
        uint256 availableUnits;
        uint256 cancelledUnits;
    }

    /// @dev Checkpoint one holder and apply outgoing stake using its pre-transfer balance.
    function settleHolderRewards(Program storage p, address token_, address absolute_, uint256 amount_)
        internal
        returns (Checkpoint storage position_)
    {
        SettleHolderRewardsCache memory c;
        c.balance = LedgerLib.balanceOf(absolute_, false);
        if (amount_ > c.balance) revert IStakingRewardToken.InsufficientStake();
        Checkpoint memory checkpoint_ = currentRewardCheckpoint(p);
        store().positions[token_][absolute_] =
            currentHolderRewardCheckpoint(store().positions[token_][absolute_], checkpoint_, c.balance, p.halfLife);
        p.pendingUnits = checkpoint_.pendingUnits;
        p.pendingAccumulator = checkpoint_.pendingAccumulator;
        p.updatedAt = checkpoint_.updatedAt;
        position_ = store().positions[token_][absolute_];
        if (amount_ == 0) return position_;
        c.pendingUnits = FixedPointMathLib.fullMulDiv(position_.pendingUnits, amount_, c.balance);
        if (c.pendingUnits == 0) return position_;
        if (position_.unclaimedUnits == checkpoint_.unclaimedUnits && amount_ == c.balance) {
            // A full exit by the final reward-entitlement holder releases pending rewards;
            // the shares stay in custody until that holder claims all remaining backing.
            position_.pendingUnits = 0;
            p.pendingUnits = 0;
            return position_;
        }
        c.availableUnits = position_.unclaimedUnits - position_.pendingUnits;
        c.cancelledUnits = FixedPointMathLib.fullMulDivUp(
            c.pendingUnits, checkpoint_.unclaimedUnits, checkpoint_.unclaimedUnits - c.availableUnits
        );
        position_.unclaimedUnits -= c.cancelledUnits;
        position_.pendingUnits -= c.pendingUnits;
        ShareTokenLib.cancel(p.rewardShareToken, p.rewardShareToken, token_, c.cancelledUnits);
        p.pendingUnits = p.pendingUnits > c.pendingUnits ? p.pendingUnits - c.pendingUnits : 0;
        if (p.pendingUnits > checkpoint_.unclaimedUnits - c.cancelledUnits) {
            p.pendingUnits = checkpoint_.unclaimedUnits - c.cancelledUnits;
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
        config_.stakingGroup = p.stakingGroup;
        config_.stakingLedger = LedgerLib.ledger(p.stakingGroup);
        config_.totalSupply = LedgerLib.balanceOf(p.stakingGroup, false);
        config_.stakedBalance = config_.totalSupply;
        config_.rewardGroup = p.rewardGroup;
        config_.rewardLedger = LedgerLib.ledger(p.rewardGroup);
        config_.rewardAccount = LedgerLib.toAddress(p.rewardGroup, token_);
        config_.rewardShareToken = p.rewardShareToken;
        config_.halfLife = p.halfLife;
        Checkpoint memory checkpoint_ = currentRewardCheckpoint(p);
        config_.rewards =
            rewardBalances(checkpoint_, checkpoint_.unclaimedUnits, LedgerLib.balanceOf(config_.rewardAccount, false));
    }

    function rewardsOf(address token_, address holder_) internal view returns (IStakingRewardToken.Rewards memory) {
        return rewardsOfAccount(token_, stakingRewardProgram(token_).stakingGroup, holder_);
    }

    function rewardsOfAccount(address token_, address parent_, address relative_)
        internal
        view
        returns (IStakingRewardToken.Rewards memory)
    {
        Program storage p = stakingRewardProgram(token_);
        (, address absolute_) = enforceDebitAccount(LedgerLib.ledger(p.stakingGroup), parent_, relative_);
        address ancestor_ = parent_;
        while (ancestor_ != p.stakingGroup && !LedgerLib.isLedger(LedgerLib.flags(ancestor_))) {
            ancestor_ = LedgerLib.parent(LedgerLib.flags(ancestor_));
        }
        if (ancestor_ != p.stakingGroup) revert ILedger.InvalidLedgerAccount(absolute_);
        Checkpoint memory checkpoint_ = currentRewardCheckpoint(p);
        return rewardBalances(
            currentHolderRewardCheckpoint(
                store().positions[token_][absolute_], checkpoint_, LedgerLib.balanceOf(absolute_, false), p.halfLife
            ),
            checkpoint_.unclaimedUnits,
            LedgerLib.balanceOf(LedgerLib.toAddress(p.rewardGroup, token_), false)
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
