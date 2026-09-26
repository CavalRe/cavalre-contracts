// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ERC20Wrapper} from "../ledger/ERC20Wrapper.sol";
import {IStakingRewards} from "./IStakingRewards.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {StakingRewardsLib} from "./StakingRewardsLib.sol";
import {ReentrancyGuard} from "../../utilities/ReentrancyGuard.sol";

contract StakingRewards is Dispatchable, ReentrancyGuard {
    bytes32 private constant REENTRANCY_GUARD_STORAGE = keccak256(
        abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken.ReentrancyGuard")) - 1)
    ) & ~bytes32(uint256(0xff));

    function _reentrancyGuardStorageSlot() internal pure override returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }

    function signatures() external pure virtual override returns (string[] memory signatures_) {
        signatures_ = new string[](11);
        signatures_[0] = "stake(address,uint256,uint256)";
        signatures_[1] = "unstake(address,uint256,uint256)";
        signatures_[2] = "reward(address,uint256)";
        signatures_[3] = "claim(address)";
        signatures_[4] = "stakingRewardToken(address)";
        signatures_[5] = "rewardsOf(address,address)";
        signatures_[6] = "rewardsOfAccount(address,address,address)";
        signatures_[7] = "transfer(address,address,address,uint256)";
        signatures_[8] = "settleStakeTransfer(address,address,address,bool,bool,uint256)";
        signatures_[9] = "reward(address,address,uint256)";
        signatures_[10] = "claim(address,address)";
    }

    function selectors() external pure virtual override returns (bytes4[] memory selectors_) {
        uint256 n_;
        selectors_ = new bytes4[](11);
        selectors_[n_++] = IStakingRewards.stake.selector;
        selectors_[n_++] = IStakingRewards.unstake.selector;
        selectors_[n_++] = bytes4(keccak256("reward(address,uint256)"));
        selectors_[n_++] = bytes4(keccak256("claim(address)"));
        selectors_[n_++] = IStakingRewards.stakingRewardToken.selector;
        selectors_[n_++] = IStakingRewards.rewardsOf.selector;
        selectors_[n_++] = IStakingRewards.rewardsOfAccount.selector;
        selectors_[n_++] = IStakingRewards.transfer.selector;
        selectors_[n_++] = IStakingRewards.settleStakeTransfer.selector;
        selectors_[n_++] = bytes4(keccak256("reward(address,address,uint256)"));
        selectors_[n_++] = bytes4(keccak256("claim(address,address)"));
        if (n_ != selectors_.length) revert InvalidCommandsLength(n_);
    }

    function stake(address token_, uint256 amount_, uint256 minimumShares_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardsLib.stake(token_, msg.sender, amount_, minimumShares_);
    }

    function unstake(address token_, uint256 shares_, uint256 minimumStake_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardsLib.unstake(token_, msg.sender, shares_, minimumStake_);
    }

    /// @notice Contribute the caller's reward-ledger tokens to a program's pending reward backing.
    /// @dev Uses the caller's ordinary reward-ledger wallet balance, not their staking balance.
    /// The contribution is allocated proportionally to existing stake through the program's accumulators.
    /// @param token_ SR wrapper address selecting the program; its configuration determines the reward asset.
    /// @param amount_ Contribution in raw reward-ledger token units.
    function reward(address token_, uint256 amount_) external nonReentrant {
        enforceIsDelegated();
        StakingRewardsLib.reward(token_, msg.sender, amount_);
    }

    /// @notice Fund pending rewards directly from the caller's wallet or staking leaf.
    /// @dev Only the caller's own direct leaf under a ledger root or registered Stake group is accessible publicly.
    /// Application modules must separately authorize internal pool or custody accounts before using the library.
    /// @param token_ SR wrapper identifying the program receiving funding.
    /// @param funderParent_ Absolute parent of the caller's funding leaf in the reward ledger.
    /// @param amount_ Contribution in raw reward-ledger token units; funding from Stake applies exit forfeiture.
    function reward(address token_, address funderParent_, uint256 amount_) external nonReentrant {
        enforceIsDelegated();
        StakingRewardsLib.Program storage p = StakingRewardsLib.stakingRewardProgram(token_);
        enforceRewardHolderParent(LedgerLib.ledger(p.rewardGroup), funderParent_);
        StakingRewardsLib.reward(token_, funderParent_, msg.sender, amount_);
    }

    /// @notice Pay all of the caller's available rewards into their reward-ledger wallet account.
    /// @dev Settles vesting first, retains remaining pending rewards, and leaves the caller's stake in place.
    /// The payout is not automatically deposited into another staking program.
    /// @param token_ SR wrapper address selecting the program whose rewards are being claimed.
    /// @return Amount paid in raw reward-ledger token units, rounded down from the redeemed reward units.
    function claim(address token_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardsLib.claim(token_, msg.sender);
    }

    /// @notice Collect all available rewards directly into the caller's wallet or staking leaf.
    /// @dev Paying into Stake lets the recipient hold the reward as an SR token. Ledger hooks settle the
    /// recipient's existing rewards before the incoming payout begins earning; remaining pending rewards are retained.
    /// @param token_ SR wrapper identifying the program whose rewards are being claimed.
    /// @param recipientParent_ Absolute parent of the caller's payout leaf in the configured reward ledger.
    /// @return Payout in raw reward-ledger token units, rounded down from the redeemed reward units.
    function claim(address token_, address recipientParent_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        StakingRewardsLib.Program storage p = StakingRewardsLib.stakingRewardProgram(token_);
        enforceRewardHolderParent(LedgerLib.ledger(p.rewardGroup), recipientParent_);
        return StakingRewardsLib.claim(token_, p.stakingGroup, msg.sender, recipientParent_, msg.sender);
    }

    /// @dev A caller controls its direct root or SR staking leaf. Sharing a relative key with a deeper custody
    /// account does not authorize spending it. The library separately validates ledger membership and debit-leaf kind.
    function enforceRewardHolderParent(address ledger_, address parent_) private view {
        if (parent_ == ledger_) return;
        StakingRewardsLib.Store storage s = StakingRewardsLib.store();
        address token_ = s.reservedAccounts[parent_];
        if (token_ == address(0) || s.programs[token_].stakingGroup != parent_) revert ILedger.InvalidAccountGroup();
    }

    function transfer(address token_, address from_, address to_, uint256 amount_) external nonReentrant {
        enforceIsDelegated();
        if (msg.sender != token_) revert IStakingRewards.UnauthorizedTransfer();
        StakingRewardsLib.Program storage p = StakingRewardsLib.stakingRewardProgram(token_);
        address stakingLedger_ = LedgerLib.ledger(p.stakingGroup);
        (uint256 fromFlags_, address fromAbsolute_) =
            StakingRewardsLib.enforceDebitAccount(stakingLedger_, p.stakingGroup, from_);
        (uint256 toFlags_,) = StakingRewardsLib.enforceDebitAccount(stakingLedger_, p.stakingGroup, to_);
        if (from_ != to_ && amount_ != 0 && StakingRewardsLib.store().reservedAccounts[fromAbsolute_] != address(0)) {
            revert IStakingRewards.AccountReserved(fromAbsolute_);
        }
        if (amount_ > LedgerLib.balanceOf(fromAbsolute_, false)) revert IStakingRewards.InsufficientStake();
        LedgerLib.transfer(stakingLedger_, fromFlags_, from_, toFlags_, to_, amount_);
        if (from_ == to_ || amount_ == 0) ERC20Wrapper(token_).emitTransfer(from_, to_, amount_);
    }

    /// @dev LedgerLib invokes this through the Dispatcher before its internal posting.
    function settleStakeTransfer(
        address token_,
        address from_,
        address to_,
        bool fromOutside_,
        bool toOutside_,
        uint256 amount_
    ) external {
        enforceIsDelegated();
        if (msg.sender != address(this)) revert IStakingRewards.UnauthorizedTransfer();
        StakingRewardsLib.settleTransferRewards(token_, from_, to_, fromOutside_, toOutside_, amount_);
    }

    function stakingRewardToken(address token_) external view returns (IStakingRewards.Configuration memory) {
        return StakingRewardsLib.stakingRewardToken(token_);
    }

    function rewardsOf(address token_, address holder_) external view returns (IStakingRewards.Rewards memory) {
        return StakingRewardsLib.rewardsOf(token_, holder_);
    }

    function rewardsOfAccount(address token_, address parent_, address relative_)
        external
        view
        returns (IStakingRewards.Rewards memory)
    {
        return StakingRewardsLib.rewardsOfAccount(token_, parent_, relative_);
    }
}
