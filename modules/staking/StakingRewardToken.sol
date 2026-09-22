// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ERC20Wrapper} from "../ledger/ERC20Wrapper.sol";
import {IStakingRewardToken} from "./IStakingRewardToken.sol";
import {StakingRewardLib} from "./StakingRewardLib.sol";
import {ReentrancyGuard} from "../../utilities/ReentrancyGuard.sol";

contract StakingRewardToken is Dispatchable, ReentrancyGuard {
    bytes32 private constant REENTRANCY_GUARD_STORAGE = keccak256(
        abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken.ReentrancyGuard")) - 1)
    ) & ~bytes32(uint256(0xff));

    function _reentrancyGuardStorageSlot() internal pure override returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }

    function signatures() external pure virtual override returns (string[] memory signatures_) {
        signatures_ = new string[](9);
        signatures_[0] = "stake(address,uint256,uint256)";
        signatures_[1] = "unstake(address,uint256,uint256)";
        signatures_[2] = "reward(address,uint256)";
        signatures_[3] = "claim(address)";
        signatures_[4] = "stakingRewardToken(address)";
        signatures_[5] = "rewardsOf(address,address)";
        signatures_[6] = "rewardsOfAccount(address,address,address)";
        signatures_[7] = "transfer(address,address,address,uint256)";
        signatures_[8] = "settleStakeTransfer(address,address,address,bool,bool,uint256)";
    }

    function selectors() external pure virtual override returns (bytes4[] memory selectors_) {
        uint256 n_;
        selectors_ = new bytes4[](9);
        selectors_[n_++] = IStakingRewardToken.stake.selector;
        selectors_[n_++] = IStakingRewardToken.unstake.selector;
        selectors_[n_++] = IStakingRewardToken.reward.selector;
        selectors_[n_++] = IStakingRewardToken.claim.selector;
        selectors_[n_++] = IStakingRewardToken.stakingRewardToken.selector;
        selectors_[n_++] = IStakingRewardToken.rewardsOf.selector;
        selectors_[n_++] = IStakingRewardToken.rewardsOfAccount.selector;
        selectors_[n_++] = IStakingRewardToken.transfer.selector;
        selectors_[n_++] = IStakingRewardToken.settleStakeTransfer.selector;
        if (n_ != 9) revert InvalidCommandsLength(n_);
    }

    function stake(address token_, uint256 amount_, uint256 minimumShares_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardLib.stake(token_, msg.sender, amount_, minimumShares_);
    }

    function unstake(address token_, uint256 shares_, uint256 minimumStake_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardLib.unstake(token_, msg.sender, shares_, minimumStake_);
    }

    function reward(address token_, uint256 amount_) external nonReentrant {
        enforceIsDelegated();
        StakingRewardLib.reward(token_, msg.sender, amount_);
    }

    function claim(address token_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardLib.claim(token_, msg.sender);
    }

    function transfer(address token_, address from_, address to_, uint256 amount_) external nonReentrant {
        enforceIsDelegated();
        if (msg.sender != token_) revert IStakingRewardToken.UnauthorizedTransfer();
        StakingRewardLib.Program storage p = StakingRewardLib.stakingRewardProgram(token_);
        address stakingLedger_ = LedgerLib.ledger(p.stakingGroup);
        (uint256 fromFlags_, address fromAbsolute_) =
            StakingRewardLib.enforceDebitAccount(stakingLedger_, p.stakingGroup, from_);
        (uint256 toFlags_,) = StakingRewardLib.enforceDebitAccount(stakingLedger_, p.stakingGroup, to_);
        if (from_ != to_ && amount_ != 0 && StakingRewardLib.store().reservedAccounts[fromAbsolute_] != address(0)) {
            revert IStakingRewardToken.AccountReserved(fromAbsolute_);
        }
        if (amount_ > LedgerLib.balanceOf(fromAbsolute_, false)) revert IStakingRewardToken.InsufficientStake();
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
        if (msg.sender != address(this)) revert IStakingRewardToken.UnauthorizedTransfer();
        StakingRewardLib.settleTransferRewards(token_, from_, to_, fromOutside_, toOutside_, amount_);
    }

    function stakingRewardToken(address token_) external view returns (IStakingRewardToken.Configuration memory) {
        return StakingRewardLib.stakingRewardToken(token_);
    }

    function rewardsOf(address token_, address holder_) external view returns (IStakingRewardToken.Rewards memory) {
        return StakingRewardLib.rewardsOf(token_, holder_);
    }

    function rewardsOfAccount(address token_, address parent_, address relative_)
        external
        view
        returns (IStakingRewardToken.Rewards memory)
    {
        return StakingRewardLib.rewardsOfAccount(token_, parent_, relative_);
    }
}
