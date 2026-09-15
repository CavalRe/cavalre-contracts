// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedgerTransferHook} from "../ledger/ILedgerTransferHook.sol";
import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";
import {IStakingRewardToken} from "./IStakingRewardToken.sol";
import {StakingRewardLib} from "./StakingRewardLib.sol";
import {ReentrancyGuard} from "../../utilities/ReentrancyGuard.sol";

contract StakingRewardToken is Dispatchable, ReentrancyGuard, IStakingRewardToken, ILedgerTransferHook {
    bytes32 private constant REENTRANCY_GUARD_STORAGE = keccak256(
        abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken.ReentrancyGuard")) - 1)
    ) & ~bytes32(uint256(0xff));

    function _reentrancyGuardStorageSlot() internal pure override returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }

    function signatures() external pure virtual override returns (string[] memory signatures_) {
        signatures_ = new string[](9);
        signatures_[0] = "createStakingRewardToken(address,address,address,uint256,(string,string,uint8,string))";
        signatures_[1] = "stake(address,uint256,uint256)";
        signatures_[2] = "unstake(address,uint256,uint256)";
        signatures_[3] = "reward(address,uint256)";
        signatures_[4] = "claim(address,uint256)";
        signatures_[5] = "recycleRewards(address,uint256)";
        signatures_[6] = "stakingRewardToken(address)";
        signatures_[7] = "rewardsOf(address,address)";
        signatures_[8] = "beforeLedgerTransfer(address,address,address,bool,bool,uint256)";
    }

    function selectors() external pure virtual override returns (bytes4[] memory selectors_) {
        uint256 n_;
        selectors_ = new bytes4[](9);
        selectors_[n_++] = IStakingRewardToken.createStakingRewardToken.selector;
        selectors_[n_++] = IStakingRewardToken.stake.selector;
        selectors_[n_++] = IStakingRewardToken.unstake.selector;
        selectors_[n_++] = IStakingRewardToken.reward.selector;
        selectors_[n_++] = IStakingRewardToken.claim.selector;
        selectors_[n_++] = IStakingRewardToken.recycleRewards.selector;
        selectors_[n_++] = IStakingRewardToken.stakingRewardToken.selector;
        selectors_[n_++] = IStakingRewardToken.rewardsOf.selector;
        selectors_[n_++] = ILedgerTransferHook.beforeLedgerTransfer.selector;
        if (n_ != 9) revert InvalidCommandsLength(n_);
    }

    function createStakingRewardToken(
        address stakingLedger_,
        address rewardLedger_,
        address stakingAccount_,
        uint256 halfLife_,
        ILedgerTokenFactory.TokenMetadata memory metadata_
    ) external nonReentrant returns (address, uint256) {
        enforceIsOwner();
        return StakingRewardLib.create(stakingLedger_, rewardLedger_, stakingAccount_, halfLife_, metadata_);
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
        StakingRewardLib.reward(token_, msg.sender, amount_, false);
    }

    function claim(address token_, uint256 amount_) external nonReentrant returns (uint256) {
        enforceIsDelegated();
        return StakingRewardLib.claim(token_, msg.sender, amount_);
    }

    function recycleRewards(address token_, uint256 amount_) external nonReentrant {
        enforceIsOwner();
        StakingRewardLib.reward(token_, msg.sender, amount_, true);
    }

    function stakingRewardToken(address token_) external view returns (Configuration memory) {
        return StakingRewardLib.configuration(token_);
    }

    function rewardsOf(address token_, address holder_) external view returns (Rewards memory) {
        return StakingRewardLib.rewardsOf(token_, holder_);
    }

    function beforeLedgerTransfer(
        address ledger_,
        address from_,
        address to_,
        bool fromIsCredit_,
        bool toIsCredit_,
        uint256 amount_
    ) external {
        enforceIsDelegated();
        if (msg.sender != address(this)) revert UnauthorizedTransfer();
        StakingRewardLib.beforeTransfer(ledger_, from_, to_, fromIsCredit_, toIsCredit_, amount_);
    }
}
