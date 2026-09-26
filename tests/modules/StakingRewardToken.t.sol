// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {Vm} from "forge-std/src/Vm.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {TestLedger} from "./Ledger.t.sol";
import {Dispatchable} from "../../modules/dispatcher/Dispatchable.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {ERC20Wrapper} from "../../modules/ledger/ERC20Wrapper.sol";
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {ShareTokenView} from "../../modules/share/ShareTokenView.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {LedgerTokenFactory} from "../../modules/ledger/LedgerTokenFactory.sol";
import {ILedgerTokenFactory} from "../../modules/ledger/ILedgerTokenFactory.sol";
import {StakingRewardToken} from "../../modules/staking/StakingRewardToken.sol";
import {StakingRewardWrapper} from "../../modules/staking/StakingRewardWrapper.sol";
import {IStakingRewardToken} from "../../modules/staking/IStakingRewardToken.sol";
import {StakingRewardLib} from "../../modules/staking/StakingRewardLib.sol";

contract NestedStakingApplication is Dispatchable {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](4);
        signatures_[0] = "claimAt(address,address,address,address)";
        signatures_[1] = "unstakeAt(address,address,address,address,uint256)";
        signatures_[2] = "rewardAt(address,address,address,uint256)";
        signatures_[3] = "claimTo(address,address,address,address,address)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](4);
        selectors_[0] = this.claimAt.selector;
        selectors_[1] = this.unstakeAt.selector;
        selectors_[2] = this.rewardAt.selector;
        selectors_[3] = this.claimTo.selector;
    }

    function claimAt(address token_, address parent_, address relative_, address recipient_)
        external
        returns (uint256)
    {
        enforceIsOwner();
        return StakingRewardLib.claim(token_, parent_, relative_, recipient_);
    }

    function unstakeAt(address token_, address parent_, address relative_, address recipient_, uint256 shares_)
        external
        returns (uint256)
    {
        enforceIsOwner();
        return StakingRewardLib.unstake(token_, parent_, relative_, recipient_, shares_, 0);
    }

    function rewardAt(address token_, address parent_, address funder_, uint256 amount_) external {
        enforceIsOwner();
        StakingRewardLib.reward(token_, parent_, funder_, amount_);
    }

    function claimTo(address token_, address parent_, address relative_, address recipientParent_, address recipient_)
        external
        returns (uint256)
    {
        enforceIsOwner();
        return StakingRewardLib.claim(token_, parent_, relative_, recipientParent_, recipient_);
    }
}

contract StakingRewardTokenTest is Test {
    Dispatcher internal dispatcher;
    TestLedger internal ledger;
    LedgerView internal ledgerView;
    LedgerTokenFactory internal factory;
    address internal factoryImplementation;
    ILedgerTokenFactory.TokenMetadata internal metadata;
    IStakingRewardToken internal rewards;
    address internal stakeToken;
    address internal rewardToken;
    address internal srToken;
    address internal stakingGroup;
    address internal rewardGroup;
    address internal stakeRewardGroup;
    address internal constant ALICE = address(0xa11ce);
    address internal constant BOB = address(0xb0b);
    address internal constant CAROL = address(0xca201);
    address internal constant BACKING = address(0x51a);
    address internal constant REWARDS = address(0x52b);
    uint256 internal constant HALF_LIFE = 7 days;

    function setUp() public {
        dispatcher = new Dispatcher(address(this));
        address[] memory modules_ = new address[](4);
        modules_[0] = address(new TestLedger(18, 18));
        modules_[1] = address(new LedgerTokenFactory());
        factoryImplementation = modules_[1];
        modules_[2] = address(new LedgerView());
        modules_[3] = address(new StakingRewardToken());
        dispatcher.addModule(modules_);
        ledger = TestLedger(payable(address(dispatcher)));
        factory = LedgerTokenFactory(address(dispatcher));
        ledgerView = LedgerView(address(dispatcher));
        rewards = IStakingRewardToken(address(dispatcher));
        ledger.initializeTestLedger();

        ILedgerTokenFactory.TokenMetadata[] memory tokens_ = new ILedgerTokenFactory.TokenMetadata[](2);
        tokens_[0] = ILedgerTokenFactory.TokenMetadata("Stake", "S", 18, "1");
        tokens_[1] = ILedgerTokenFactory.TokenMetadata("Reward", "R", 6, "1");
        (address[] memory addresses_,) = factory.createInternalTokens(tokens_);
        stakeToken = addresses_[0];
        rewardToken = addresses_[1];
        (stakingGroup,) = ledger.addSubAccountGroup(stakeToken, stakeToken, BACKING, "Staking", false);
        (rewardGroup,) = ledger.addSubAccountGroup(rewardToken, rewardToken, REWARDS, "Rewards", false);
        (stakeRewardGroup,) = ledger.addSubAccountGroup(stakeToken, stakeToken, REWARDS, "Rewards", false);
        metadata = ILedgerTokenFactory.TokenMetadata("Staked S", "SR", 18, "1");
        srToken = rewards.createStakingRewardToken(
            LedgerLib.toAddress(stakeToken, BACKING), rewardGroup, HALF_LIFE, metadata
        );
        ledger.mint(stakeToken, stakeToken, ALICE, 1e30);
        ledger.mint(stakeToken, stakeToken, BOB, 1e30);
        ledger.mint(stakeToken, stakeToken, CAROL, 1e30);
        ledger.mint(rewardToken, rewardToken, address(this), 1e24);
    }

    function stakeFor(address holder_, uint256 amount_) internal {
        vm.prank(holder_);
        rewards.stake(srToken, amount_, amount_);
    }

    function assertRewards(address holder_, uint256 unclaimed_, uint256 pending_, uint256 available_) internal view {
        IStakingRewardToken.Rewards memory state_ = rewards.rewardsOf(srToken, holder_);
        assertApproxEqAbs(state_.unclaimed, unclaimed_, 1);
        assertApproxEqAbs(state_.pending, pending_, 1);
        assertApproxEqAbs(state_.available, available_, 1);
        assertLe(state_.pendingUnits, state_.unclaimedUnits);
    }

    function testConfigurationOwnedBySR() public {
        uint256 underlyingSupply_ = IERC20(stakeToken).totalSupply();
        stakeFor(ALICE, 100e18);
        IStakingRewardToken.Configuration memory config_ = rewards.stakingRewardToken(srToken);
        assertEq(config_.tokenAddress, srToken);
        assertEq(config_.stakingLedger, stakeToken);
        assertEq(config_.stakingGroup, LedgerLib.toAddress(stakeToken, BACKING));
        assertEq(config_.totalSupply, 100e18);
        assertEq(config_.stakedBalance, 100e18);
        assertEq(config_.rewardLedger, rewardToken);
        assertEq(config_.rewardAccount, LedgerLib.toAddress(LedgerLib.toAddress(rewardToken, REWARDS), srToken));
        assertEq(config_.halfLife, HALF_LIFE);
        assertEq(IERC20(stakeToken).totalSupply(), underlyingSupply_);
        assertEq(ledgerView.balanceOf(stakeToken, stakingGroup, ALICE), 100e18);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
        assertEq(IERC20(config_.rewardShareToken).totalSupply(), 0);
    }

    function testConfigurationCannotChange() public {
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(stakingGroup, rewardGroup, 1 days, metadata);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(stakingGroup, stakeRewardGroup, HALF_LIFE, metadata);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(address(0), rewardGroup, HALF_LIFE, metadata);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(stakeRewardGroup, rewardGroup, HALF_LIFE, metadata);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        rewards.createStakingRewardToken(stakingGroup, rewardGroup, HALF_LIFE, metadata);
    }

    function testCreationIsIdempotentWithoutResettingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        address token_ = rewards.createStakingRewardToken(
            LedgerLib.toAddress(stakeToken, BACKING), rewardGroup, HALF_LIFE, metadata
        );
        assertEq(token_, srToken);
        assertEq(ledgerView.totalSupply(token_), 0);
        assertEq(IERC20(token_).totalSupply(), 100e18);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new ShareTokenView());
        dispatcher.addModule(modules_);
        assertFalse(ShareTokenView(address(dispatcher)).isShareToken(token_));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, token_));
        ShareTokenView(address(dispatcher)).shareTokenState(token_);
    }

    function testExistingFactoryCreatesSRAndRuntimeRemainsIndependent() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = factoryImplementation;
        assertEq(dispatcher.module(ILedgerTokenFactory.createStakingRewardToken.selector), factoryImplementation);
        ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x52a), "New Staking", false);
        address second_ = factory.createStakingRewardToken(
            LedgerLib.toAddress(stakeToken, address(0x52a)),
            rewardGroup,
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1")
        );
        dispatcher.removeModule(modules_);
        assertEq(ledgerView.totalSupply(second_), 0);
        vm.prank(ALICE);
        rewards.stake(second_, 100e18, 100e18);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        assertEq(rewards.claim(second_), 50e6);
        assertEq(rewards.unstake(second_, 100e18, 100e18), 100e18);
        assertEq(rewards.claim(second_), 50e6);
        vm.stopPrank();
    }

    function testModuleFitsDeploymentLimit() public {
        assertLe(address(new StakingRewardToken()).code.length, 24_576);
        assertLe(address(new LedgerTokenFactory()).code.length, 24_576);
    }

    function testSROperationsSettleWithoutDispatchingTransferHook() public {
        bytes4 formerHook_ = bytes4(keccak256("beforeLedgerTransfer(address,address,address,bool,bool,uint256)"));
        assertEq(dispatcher.module(formerHook_), address(0));
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(formerHook_), 0);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        assertEq(rewards.claim(srToken), 50e6);
        assertEq(rewards.unstake(srToken, 100e18, 100e18), 100e18);
        assertEq(rewards.claim(srToken), 50e6);
        vm.stopPrank();
        assertRewards(ALICE, 0, 0, 0);
        assertConservation(100e6, 100e6);
    }

    function testInvalidConfiguration() public {
        (address group_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x52a), "New Staking", false);
        ILedgerTokenFactory.TokenMetadata memory metadata_ = ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1");
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, rewardGroup, 0, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(stakeToken, rewardGroup, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, rewardToken, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, address(0), HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(address(0), rewardGroup, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, group_, HALF_LIFE, metadata_);
        (address nested_,) = ledger.addSubAccountGroup(stakeToken, group_, REWARDS, "Rewards", false);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, nested_, HALF_LIFE, metadata_);
        metadata_.decimals = 6;
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, rewardGroup, HALF_LIFE, metadata_);
        metadata_.decimals = 18;
        ledger.mint(stakeToken, group_, ALICE, 1);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, rewardGroup, HALF_LIFE, metadata_);
    }

    function testCannotAdoptAnExistingTokenSupply() public {
        (address group_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x52a), "New Staking", false);
        ILedgerTokenFactory.TokenMetadata memory metadata_ = ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1");
        bytes memory creationCode_ = abi.encodePacked(
            type(StakingRewardWrapper).creationCode,
            abi.encode(address(dispatcher), metadata_.name, metadata_.symbol, metadata_.decimals)
        );
        address predicted_ = Create2.computeAddress(
            keccak256(abi.encode(metadata_.name, metadata_.symbol, metadata_.decimals, metadata_.version)),
            keccak256(creationCode_),
            address(dispatcher)
        );
        ledger.mint(stakeToken, group_, ALICE, 1);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(group_, rewardGroup, HALF_LIFE, metadata_);
        assertEq(predicted_.code.length, 0);
        assertEq(ledgerView.balanceOf(stakeToken, group_, ALICE), 1);
        ledger.burn(stakeToken, group_, ALICE, 1);
        address token_ = rewards.createStakingRewardToken(group_, rewardGroup, HALF_LIFE, metadata_);
        assertEq(token_, predicted_);
        assertEq(IERC20(token_).totalSupply(), 0);
        // The wrapper has no principal ledger: raw mint/burn cannot create or destroy stakes.
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledger.mint(token_, token_, ALICE, 1);
        assertEq(IERC20(token_).totalSupply(), 0);
    }

    function testCannotUseCreditBacking() public {
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(
            LedgerLib.toAddress(stakeToken, LedgerLib.SOURCE_ADDRESS),
            rewardGroup,
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Credit", "CREDIT", 18, "1")
        );
    }

    function testCannotConfigureTwoProgramsOnOneBackingAccount() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector, LedgerLib.toAddress(stakeToken, BACKING)
            )
        );
        rewards.createStakingRewardToken(
            LedgerLib.toAddress(stakeToken, BACKING),
            rewardGroup,
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Duplicate", "DUP", 18, "1")
        );
    }

    function testFundingRequiresStake() public {
        vm.expectRevert(IStakingRewardToken.NoStake.selector);
        rewards.reward(srToken, 100e6);
    }

    struct ClaimAllCache {
        IStakingRewardToken.Rewards beforeClaim;
        IStakingRewardToken.Rewards afterClaim;
    }

    function testClaimAllLeavesOnlyPendingUnits() public {
        ClaimAllCache memory c;
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        assertRewards(ALICE, 100e6, 100e6, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.InsufficientRewards.selector);
        rewards.claim(srToken);
        vm.warp(HALF_LIFE);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        c.beforeClaim = rewards.rewardsOf(srToken, ALICE);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 50e6);
        c.afterClaim = rewards.rewardsOf(srToken, ALICE);
        assertEq(c.afterClaim.pendingUnits, c.beforeClaim.pendingUnits);
        assertEq(c.afterClaim.unclaimedUnits, c.afterClaim.pendingUnits);
        assertEq(c.afterClaim.available, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.pendingUnits, c.beforeClaim.pendingUnits);
        assertRewards(ALICE, 50e6, 50e6, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.InsufficientRewards.selector);
        rewards.claim(srToken);
        vm.warp(2 * HALF_LIFE);
        assertRewards(ALICE, 50e6, 25e6, 25e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 25e6);
        assertRewards(ALICE, 25e6, 25e6, 0);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 75e6);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertConservation(100e6, 75e6);
    }

    function testClaimAllClearsAvailableUnitsWhenTokenPayoutRoundsToZero() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 1);
        vm.warp(HALF_LIFE);
        assertEq(rewards.rewardsOf(srToken, ALICE).available, 0);
        assertGt(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, rewards.rewardsOf(srToken, ALICE).pendingUnits);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 0);
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, StakingRewardLib.UNIT_SCALE / 2);
        assertEq(rewards.rewardsOf(srToken, ALICE).pendingUnits, StakingRewardLib.UNIT_SCALE / 2);
        assertConservation(1, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.InsufficientRewards.selector);
        rewards.claim(srToken);
        vm.startPrank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertEq(rewards.claim(srToken), 1);
        vm.stopPrank();
        assertConservation(1, 1);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, 0);
    }

    function testNewStakeDoesNotReceivePreviouslyFundedRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE / 3);
        stakeFor(BOB, 100e18);
        vm.warp(HALF_LIFE);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertRewards(BOB, 0, 0, 0);
        rewards.reward(srToken, 60e6);
        assertRewards(ALICE, 130e6, 80e6, 50e6);
        assertRewards(BOB, 30e6, 30e6, 0);
    }

    function testForfeiturePreservesUnitsAndLaterFundingUsesUnitPrice() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.unstake(srToken, 100e18, 100e18), 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 60e6, 30e6);
        rewards.reward(srToken, 30e6);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 120e6, 90e6, 30e6);
        vm.prank(ALICE);
        assertApproxEqAbs(rewards.claim(srToken), 30e6, 1);
    }

    function testPartialExitPreservesAvailableRewardValue() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 50e18);
        assertRewards(ALICE, 50e6, 20e6, 30e6);
        assertRewards(BOB, 70e6, 40e6, 30e6);
    }

    function testFinalHolderReceivesAllRemainingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        uint256 units_ = rewards.rewardsOf(srToken, ALICE).unclaimedUnits;
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, units_);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, units_);
        assertEq(rewards.stakingRewardToken(srToken).rewards.pendingUnits, 0);
        assertConservation(100e6, 0);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 100e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 100e6);
        assertConservation(100e6, 100e6);
        stakeFor(BOB, 100e18);
        assertRewards(BOB, 0, 0, 0);
        rewards.reward(srToken, 50e6);
        assertRewards(BOB, 50e6, 50e6, 0);
        assertConservation(150e6, 100e6);
    }

    function testPartialSoleHolderExitRetainsPendingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        bytes32 checkpointBefore_ = checkpointHash(ALICE);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 50e18);
        assertTrue(checkpointHash(ALICE) != checkpointBefore_);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertConservation(100e6, 0);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 50e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertConservation(100e6, 0);
    }

    function testLastStakerReleasePreservesExitedHolderRewards() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 60e6, 30e6);
        vm.prank(BOB);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 0, 90e6);
        assertConservation(120e6, 0);
        vm.prank(ALICE);
        uint256 claimed_ = rewards.claim(srToken);
        vm.prank(BOB);
        claimed_ += rewards.claim(srToken);
        assertEq(claimed_, 120e6);
        assertConservation(120e6, claimed_);
    }

    function testNewStakerPreventsFinalStakerRelease() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        stakeFor(BOB, 100e18);
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 0, 0, 0);
        assertRewards(BOB, 100e6, 100e6, 0);
        rewards.reward(srToken, 50e6);
        assertRewards(BOB, 150e6, 150e6, 0);
        vm.prank(BOB);
        rewards.unstake(srToken, 100e18, 0);
        vm.prank(BOB);
        assertEq(rewards.claim(srToken), 150e6);
        assertConservation(150e6, 150e6);
    }

    function testImmediateFinalExitAndRestart() public {
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 7);
        vm.prank(ALICE);
        rewards.unstake(srToken, 3, 3);
        assertRewards(ALICE, 7, 0, 7);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 7);
        stakeFor(BOB, 5);
        rewards.reward(srToken, 13);
        assertRewards(BOB, 13, 13, 0);
        assertConservation(20, 7);
    }

    function testFinalExitMakesSmallPendingRewardClaimable() public {
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 1);
        vm.warp(1);
        vm.prank(ALICE);
        rewards.unstake(srToken, 3, 3);
        assertRewards(ALICE, 1, 0, 1);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 1);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, 0);
        stakeFor(BOB, 5);
        rewards.reward(srToken, 1);
        assertRewards(BOB, 1, 1, 0);
        assertConservation(2, 1);
    }

    function testFullyAvailableFinalExitHasNoDivisionByZero() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(256 * HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 100e6);
    }

    function testWrapperTransferSettlesBothHolders() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.expectCall(
            address(dispatcher), abi.encodeCall(IStakingRewardToken.transfer, (srToken, ALICE, BOB, 100e18)), 1
        );
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(ILedger.transfer.selector), 0);
        vm.prank(ALICE);
        vm.expectEmit(true, true, false, true, stakeToken);
        emit ERC20Wrapper.Transfer(BACKING, BACKING, 100e18);
        vm.expectEmit(true, true, false, true, srToken);
        emit ERC20Wrapper.Transfer(ALICE, BOB, 100e18);
        IERC20(srToken).transfer(BOB, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 60e6, 30e6);
        assertEq(IERC20(srToken).balanceOf(BOB), 200e18);
        rewards.reward(srToken, 30e6);
        assertRewards(BOB, 120e6, 90e6, 30e6);
    }

    function testWrapperTransferFromAppliesLastStakerRelease() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(CAROL);
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InsufficientAllowance.selector, srToken, ALICE, CAROL, 0, 100e18)
        );
        IERC20(srToken).transferFrom(ALICE, BOB, 100e18);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertRewards(BOB, 0, 0, 0);
        vm.prank(ALICE);
        IERC20(srToken).approve(CAROL, 100e18);
        vm.expectCall(
            address(dispatcher), abi.encodeCall(IStakingRewardToken.transfer, (srToken, ALICE, BOB, 100e18)), 1
        );
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(ILedger.transfer.selector), 0);
        vm.prank(CAROL);
        IERC20(srToken).transferFrom(ALICE, BOB, 100e18);
        assertEq(IERC20(srToken).allowance(ALICE, CAROL), 0);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 0, 0, 0);

        vm.prank(ALICE);
        IERC20(srToken).approve(CAROL, 1);
        vm.prank(CAROL);
        vm.expectRevert(IStakingRewardToken.InsufficientStake.selector);
        IERC20(srToken).transferFrom(ALICE, BOB, 1);
        assertEq(IERC20(srToken).allowance(ALICE, CAROL), 1);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 0, 0, 0);

        vm.prank(BOB);
        IERC20(srToken).approve(CAROL, type(uint256).max);
        vm.prank(CAROL);
        IERC20(srToken).transferFrom(BOB, ALICE, 1);
        assertEq(IERC20(srToken).allowance(BOB, CAROL), type(uint256).max);
    }

    function testDirectLedgerTransferIsUnavailable() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        bytes4 selector_ = bytes4(keccak256("transfer(address,address,address,address,uint256)"));
        vm.prank(ALICE);
        (bool success_, bytes memory data_) =
            address(dispatcher).call(abi.encodeWithSelector(selector_, srToken, srToken, srToken, BOB, 100e18));
        assertFalse(success_);
        assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, selector_));
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(srToken).balanceOf(BOB), 0);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertRewards(BOB, 0, 0, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        rewards.transfer(srToken, ALICE, BOB, 1);
        vm.prank(stakeToken);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        rewards.transfer(srToken, ALICE, BOB, 1);
        vm.prank(stakeToken);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.NotStakingRewardToken.selector, stakeToken));
        rewards.transfer(stakeToken, ALICE, BOB, 1);
    }

    function testInternalLedgerTransfersToNestedAccountsSettleRewards() public {
        address group_ = address(0x601);
        (group_,) = ledger.addSubAccountGroup(stakeToken, stakingGroup, group_, "Group", false);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        ledger.rawTransfer(stakeToken, stakingGroup, ALICE, group_, BOB, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).unclaimed, 0);
        rewards.reward(srToken, 40e6);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).unclaimed, 40e6);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).pending, 40e6);
        ledger.rawTransfer(stakeToken, group_, BOB, stakingGroup, BOB, 100e18);
        assertRewards(BOB, 0, 0, 0);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).available, 40e6);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).pending, 0);
        assertEq(IERC20(srToken).balanceOf(BOB), 100e18);
    }

    function testSelfAndZeroTransfersDoNotForfeit() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        vm.expectEmit(true, true, false, true, srToken);
        emit ERC20Wrapper.Transfer(ALICE, ALICE, 100e18);
        IERC20(srToken).transfer(ALICE, 100e18);
        vm.expectEmit(true, true, false, true, srToken);
        emit ERC20Wrapper.Transfer(ALICE, BOB, 0);
        IERC20(srToken).transfer(BOB, 0);
        vm.expectRevert(IStakingRewardToken.InsufficientStake.selector);
        IERC20(srToken).transfer(ALICE, 100e18 + 1);
        vm.stopPrank();
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        address[2] memory forbidden_ = [address(0), LedgerLib.SOURCE_ADDRESS];
        for (uint256 i_; i_ < forbidden_.length; ++i_) {
            bytes memory error_ = abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(stakingGroup, forbidden_[i_])
            );
            vm.prank(ALICE);
            vm.expectRevert(error_);
            IERC20(srToken).transfer(forbidden_[i_], 0);
            vm.prank(srToken);
            vm.expectRevert(error_);
            rewards.transfer(srToken, forbidden_[i_], ALICE, 0);
        }
    }

    function testCannotBypassSRMintOrBurnAccounting() public {
        stakeFor(ALICE, 100e18);
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledger.mint(srToken, srToken, BOB, 1e18);
        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(stakingGroup, LedgerLib.SOURCE_ADDRESS)
            )
        );
        IERC20(srToken).transfer(LedgerLib.SOURCE_ADDRESS, 1e18);
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledger.burn(srToken, srToken, ALICE, 1e18);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
        assertEq(ledgerView.balanceOf(stakeToken, stakingGroup, ALICE), 100e18);
    }

    function testCannotUnstakeAnotherHoldersShares() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(BOB);
        vm.expectRevert(IStakingRewardToken.InsufficientStake.selector);
        rewards.unstake(srToken, 150e18, 0);
        vm.expectRevert(IStakingRewardToken.InsufficientStake.selector);
        rewards.unstake(srToken, 201e18, 0);
        vm.stopPrank();
        vm.prank(CAROL);
        vm.expectRevert(IStakingRewardToken.InsufficientStake.selector);
        rewards.unstake(srToken, 1e18, 0);
        assertEq(IERC20(srToken).totalSupply(), 200e18);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(srToken).balanceOf(BOB), 100e18);
        assertRewards(ALICE, 60e6, 30e6, 30e6);
        assertRewards(BOB, 60e6, 30e6, 30e6);
        assertConservation(120e6, 0);
    }

    function testCannotDrainBackingOrRewardCustody() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.prank(BACKING);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, stakingGroup));
        IERC20(stakeToken).transfer(BOB, 1);
        vm.prank(REWARDS);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, rewardGroup));
        IERC20(rewardToken).transfer(BOB, 1);
        // A numeric accounting address used as an ERC20 holder resolves to a different wallet account.
        address rewardAccount_ = LedgerLib.toAddress(rewardGroup, srToken);
        vm.prank(rewardAccount_);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InsufficientBalance.selector,
                rewardToken,
                rewardToken,
                LedgerLib.toAddress(rewardToken, rewardAccount_),
                1
            )
        );
        IERC20(rewardToken).transfer(BOB, 1);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, srToken), 100e6);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        bytes4 formerHook_ = bytes4(keccak256("beforeLedgerTransfer(address,address,address,bool,bool,uint256)"));
        (bool success_, bytes memory data_) =
            address(dispatcher).call(abi.encodeWithSelector(formerHook_, srToken, ALICE, BOB, false, false, 1));
        assertFalse(success_);
        assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, formerHook_));
    }

    function testBackingHolderCannotMintAgainstASelfTransfer() public {
        stakeFor(ALICE, 100e18);
        vm.prank(BACKING);
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(stakeToken, BACKING))
        );
        rewards.stake(srToken, 100e18, 0);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
    }

    function testSlippageAndDonations() public {
        stakeFor(ALICE, 100e18);
        ledger.mint(stakeToken, stakeToken, address(this), 100e18);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, stakingGroup));
        IERC20(stakeToken).transfer(BACKING, 100e18);
        vm.prank(BOB);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.Slippage.selector, 100e18, 101e18));
        rewards.stake(srToken, 100e18, 101e18);
        vm.prank(BOB);
        assertEq(rewards.stake(srToken, 100e18, 100e18), 100e18);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(srToken).totalSupply(), 200e18);
        rewards.reward(srToken, 100e6);
        ledger.rawTransfer(rewardToken, rewardToken, address(this), rewardGroup, srToken, 25e6);
        assertRewards(ALICE, 62.5e6, 62.5e6, 0);
        assertRewards(BOB, 62.5e6, 62.5e6, 0);
        vm.prank(ALICE);
        assertEq(rewards.unstake(srToken, 100e18, 100e18), 100e18);
        assertEq(IERC20(srToken).balanceOf(BOB), 100e18);
        assertConservation(125e6, 0);
    }

    function testDifferentDecimalsAndNestedBacking() public {
        address group_ = address(0x602);
        (group_,) = ledger.addSubAccountGroup(rewardToken, rewardToken, group_, "Vaults", false);
        ledger.addSubAccountGroup(rewardToken, group_, BACKING, "Staking", false);
        address second_ = rewards.createStakingRewardToken(
            LedgerLib.toAddress(group_, BACKING),
            stakeRewardGroup,
            1 days,
            ILedgerTokenFactory.TokenMetadata("Staked R", "SRR", 6, "1")
        );
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.startPrank(ALICE);
        assertEq(rewards.stake(second_, 100e6, 100e6), 100e6);
        assertEq(rewards.unstake(second_, 50e6, 50e6), 50e6);
        vm.stopPrank();
        assertEq(IERC20(second_).balanceOf(ALICE), 50e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 50e6);
    }

    function testStakeAndRewardCanUseTheSameLedger() public {
        ledger.addSubAccountGroup(rewardToken, rewardToken, BACKING, "Staking", false);
        address second_ = rewards.createStakingRewardToken(
            LedgerLib.toAddress(rewardToken, BACKING),
            rewardGroup,
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Staked R", "SRR", 6, "1")
        );
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.prank(ALICE);
        rewards.stake(second_, 100e6, 100e6);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        rewards.claim(second_);
        rewards.unstake(second_, 100e6, 100e6);
        assertEq(rewards.claim(second_), 50e6);
        vm.stopPrank();
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 200e6);
        assertEq(rewards.stakingRewardToken(second_).rewards.unclaimedUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, 0);
    }

    // -- Explicit Reward Accounts --

    function createRewardStakeProgram() internal returns (address token_, address group_) {
        (group_,) = ledger.addSubAccountGroup(rewardToken, rewardToken, BACKING, "Reward Stake", false);
        token_ = factory.createStakingRewardToken(
            group_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Staked Reward", "SRR", 6, "explicit")
        );
    }

    function testFundingFromStakeAllocatesAfterExitAndPreservesAvailableRewards() public {
        (address token_, address group_) = createRewardStakeProgram();
        ledger.mint(rewardToken, rewardToken, ALICE, 120e6);
        ledger.mint(rewardToken, rewardToken, BOB, 120e6);
        vm.prank(ALICE);
        rewards.stake(token_, 120e6, 0);
        vm.prank(BOB);
        rewards.stake(token_, 120e6, 0);
        rewards.reward(token_, 120e6);
        vm.warp(HALF_LIFE);

        // Alice exits half her stake to fund the program. Her forfeited 15 pending rewards go 5/10 to
        // Alice/Bob; the new 60 goes 20/40, using the remaining 60/120 stake. Each retains 30 available.
        vm.prank(ALICE);
        rewards.reward(token_, group_, 60e6);
        IStakingRewardToken.Rewards memory alice_ = rewards.rewardsOf(token_, ALICE);
        IStakingRewardToken.Rewards memory bob_ = rewards.rewardsOf(token_, BOB);
        assertApproxEqAbs(alice_.pending, 40e6, 1);
        assertApproxEqAbs(alice_.available, 30e6, 1);
        assertApproxEqAbs(bob_.pending, 80e6, 1);
        assertApproxEqAbs(bob_.available, 30e6, 1);
        assertEq(IERC20(token_).balanceOf(ALICE), 60e6);
        assertEq(IERC20(token_).totalSupply(), 180e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 0);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, token_), 180e6);
        assertEq(rewards.stakingRewardToken(token_).rewards.unclaimedUnits, 180e6 * StakingRewardLib.UNIT_SCALE);
    }

    function testClaimDirectlyIntoSameProgramStake() public {
        (address token_, address group_) = createRewardStakeProgram();
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.prank(ALICE);
        rewards.stake(token_, 100e6, 0);
        rewards.reward(token_, 100e6);
        vm.warp(HALF_LIFE);

        vm.prank(ALICE);
        assertEq(rewards.claim(token_, group_), 50e6);
        assertEq(IERC20(token_).balanceOf(ALICE), 150e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 0);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, token_), 50e6);
        IStakingRewardToken.Rewards memory state_ = rewards.rewardsOf(token_, ALICE);
        assertEq(state_.pending, 50e6);
        assertEq(state_.available, 0);
        assertEq(state_.unclaimedUnits, 50e6 * StakingRewardLib.UNIT_SCALE);
    }

    function testCrossProgramStakeFundingAndClaimsDoNotStakeRewardBacking() public {
        (address token_, address group_) = createRewardStakeProgram();
        ledger.mint(rewardToken, rewardToken, BOB, 120e6);
        vm.prank(BOB);
        rewards.stake(token_, 120e6, 0);
        stakeFor(ALICE, 100e18);
        rewards.reward(token_, 120e6);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);

        // Claiming one program's income gives Alice a new position in the reward token's SR program.
        // Bob keeps the old program income; Alice's newly received stake starts with no historical rewards.
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken, group_), 50e6);
        assertEq(IERC20(token_).balanceOf(ALICE), 50e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 0);
        assertEq(rewards.rewardsOf(token_, ALICE).unclaimedUnits, 0);
        assertEq(rewards.rewardsOf(token_, BOB).available, 60e6);
        assertRewards(ALICE, 50e6, 50e6, 0);

        // Funding another program from Bob's SR balance settles his exit, without crediting that program's
        // backing as a new staker in the reward token's program.
        vm.prank(BOB);
        rewards.reward(srToken, group_, 60e6);
        assertEq(IERC20(token_).balanceOf(BOB), 60e6);
        assertEq(IERC20(token_).totalSupply(), 110e6);
        assertEq(IERC20(rewardToken).balanceOf(BOB), 0);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, srToken), 110e6);
        assertEq(IERC20(token_).balanceOf(srToken), 0);
        assertEq(rewards.rewardsOf(token_, srToken).unclaimedUnits, 0);
        assertEq(rewards.rewardsOf(token_, BOB).available, 60e6);
        assertRewards(ALICE, 110e6, 110e6, 0);
    }

    function testFundingAllRemainingStakeRevertsWithoutReleasingPendingRewards() public {
        (address token_, address group_) = createRewardStakeProgram();
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.prank(ALICE);
        rewards.stake(token_, 100e6, 0);
        rewards.reward(token_, 100e6);
        vm.warp(HALF_LIFE);
        bytes32 before_ = rewardAccountState(token_);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.NoStake.selector);
        rewards.reward(token_, group_, 100e6);
        assertEq(rewardAccountState(token_), before_);
    }

    function testPublicExplicitAccountsRejectCustodyParentsAndWrongLedger() public {
        (address group_,) = ledger.addSubAccountGroup(rewardToken, rewardToken, CAROL, "Custody", false);
        ledger.mint(rewardToken, group_, ALICE, 100e6);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);

        // The caller's address appearing below a custody group does not authorize that internal account.
        vm.startPrank(ALICE);
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        rewards.reward(srToken, group_, 1);
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        rewards.claim(srToken, group_);
        vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, rewardToken, stakingGroup));
        rewards.reward(srToken, stakingGroup, 1);
        vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, rewardToken, stakingGroup));
        rewards.claim(srToken, stakingGroup);
        vm.stopPrank();
        assertEq(ledgerView.balanceOf(rewardToken, group_, ALICE), 100e6);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
    }

    function testExplicitAccountsRejectCreditAndGroupLeaves() public {
        (, address group_) = createRewardStakeProgram();
        (address credit_,) = ledger.addSubAccount(rewardToken, group_, ALICE, "Credit", true);
        (address custody_,) = ledger.addSubAccountGroup(rewardToken, group_, BOB, "Custody", false);
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, credit_));
        rewards.reward(srToken, group_, 1);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, credit_));
        rewards.claim(srToken, group_);
        vm.stopPrank();
        vm.startPrank(BOB);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, custody_));
        rewards.reward(srToken, group_, 1);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, custody_));
        rewards.claim(srToken, group_);
        vm.stopPrank();
        assertRewards(ALICE, 50e6, 25e6, 25e6);
        assertRewards(BOB, 50e6, 25e6, 25e6);
    }

    function testApplicationUsesPoolIdentityForExplicitFundingAndClaimAccounts() public {
        (address rewardSR_, address rewardStake_) = createRewardStakeProgram();
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new NestedStakingApplication());
        dispatcher.addModule(modules_);
        NestedStakingApplication app_ = NestedStakingApplication(address(dispatcher));
        (address pool_,) =
            ledger.addSubAccountGroup(address(dispatcher), address(dispatcher), address(0xcafe), "Pool", false);
        assertEq(pool_, LedgerLib.toAddress(address(dispatcher), address(0xcafe)));
        stakeFor(ALICE, 100e18);
        ledger.rawTransfer(stakeToken, stakingGroup, ALICE, stakingGroup, pool_, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        app_.claimTo(srToken, stakingGroup, pool_, rewardStake_, pool_);
        assertEq(app_.claimTo(srToken, stakingGroup, pool_, rewardStake_, pool_), 50e6);
        assertEq(IERC20(rewardSR_).balanceOf(pool_), 50e6);
        assertEq(IERC20(rewardToken).balanceOf(pool_), 0);
        assertEq(rewards.rewardsOf(rewardSR_, pool_).unclaimedUnits, 0);

        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        app_.rewardAt(srToken, rewardStake_, pool_, 20e6);
        app_.rewardAt(srToken, rewardStake_, pool_, 20e6);
        assertEq(IERC20(rewardSR_).balanceOf(pool_), 30e6);
        assertEq(rewards.rewardsOf(srToken, pool_).pending, 70e6);
        assertEq(rewards.rewardsOf(srToken, pool_).available, 0);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, srToken), 70e6);

        address backing_ = LedgerLib.toAddress(rewardGroup, srToken);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AccountReserved.selector, backing_));
        app_.rewardAt(srToken, rewardGroup, srToken, 1);
    }

    function rewardAccountState(address token_) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                rewards.stakingRewardToken(token_),
                rewards.rewardsOf(token_, ALICE),
                rewards.rewardsOf(token_, BOB),
                IERC20(token_).balanceOf(ALICE),
                IERC20(token_).balanceOf(BOB),
                IERC20(rewardToken).balanceOf(ALICE),
                IERC20(rewardToken).balanceOf(BOB),
                IERC20(rewardToken).totalSupply(),
                ledgerView.balanceOf(rewardToken, rewardGroup, token_)
            )
        );
    }

    function testFuzzDirectFundingAndClaimMatchComposedOperations(
        uint256 aliceStake_,
        uint256 bobStake_,
        uint256 funding_,
        uint256 elapsed_
    ) public {
        (address token_, address group_) = createRewardStakeProgram();
        aliceStake_ = bound(aliceStake_, 1e6, 1e18);
        bobStake_ = bound(bobStake_, 1e6, 1e18);
        funding_ = bound(funding_, 1, aliceStake_);
        elapsed_ = bound(elapsed_, 1, 4 * HALF_LIFE);
        ledger.mint(rewardToken, rewardToken, ALICE, aliceStake_);
        ledger.mint(rewardToken, rewardToken, BOB, bobStake_);
        vm.prank(ALICE);
        rewards.stake(token_, aliceStake_, 0);
        vm.prank(BOB);
        rewards.stake(token_, bobStake_, 0);
        rewards.reward(token_, 1e18);
        vm.warp(elapsed_);
        uint256 snapshot_ = vm.snapshotState();

        vm.startPrank(ALICE);
        rewards.reward(token_, group_, funding_);
        uint256 claimed_ = rewards.claim(token_, group_);
        vm.stopPrank();
        bytes32 direct_ = rewardAccountState(token_);
        assertTrue(vm.revertToStateAndDelete(snapshot_));

        // An independent composition uses the existing exit, wallet funding, wallet claim, and entry APIs.
        // Identical state proves direct routing preserves forfeiture, vesting, reward units, and token balances.
        vm.startPrank(ALICE);
        rewards.unstake(token_, funding_, 0);
        rewards.reward(token_, funding_);
        assertEq(rewards.claim(token_), claimed_);
        if (claimed_ != 0) rewards.stake(token_, claimed_, 0);
        vm.stopPrank();
        assertEq(rewardAccountState(token_), direct_);
    }

    function testCannotStakeAnotherSRToken() public {
        (address innerGroup_,) = ledger.addSubAccountGroup(stakeToken, stakingGroup, BACKING, "Nested", false);
        (innerGroup_,) = ledger.addSubAccountGroup(stakeToken, innerGroup_, BACKING, "Staking", false);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AccountReserved.selector, stakingGroup));
        factory.createStakingRewardToken(
            innerGroup_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Staked SR", "SRSR", 18, "1")
        );
    }

    function testCannotRewardAnotherSRToken() public {
        (address secondGroup_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x52a), "Second", false);
        (address innerGroup_,) = ledger.addSubAccountGroup(stakeToken, stakingGroup, REWARDS, "Nested", false);
        (innerGroup_,) = ledger.addSubAccountGroup(stakeToken, innerGroup_, REWARDS, "Rewards", false);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AccountReserved.selector, stakingGroup));
        factory.createStakingRewardToken(
            secondGroup_, innerGroup_, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("SR Rewards", "SRREW", 18, "1")
        );
    }

    function testCannotUseStakingGroupAsRewardGroup() public {
        (address secondGroup_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x991), "Second", false);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AccountReserved.selector, stakingGroup));
        factory.createStakingRewardToken(
            secondGroup_, stakingGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("SR Rewards", "SRS", 18, "1")
        );
    }

    function testCannotCreateOuterSRAboveExistingStakingGroup() public {
        (address outerGroup_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x992), "Outer", false);
        (address innerGroup_,) = ledger.addSubAccountGroup(stakeToken, outerGroup_, BACKING, "Nested", false);
        (innerGroup_,) = ledger.addSubAccountGroup(stakeToken, innerGroup_, BACKING, "Inner", false);
        address inner_ = factory.createStakingRewardToken(
            innerGroup_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Inner SR", "ISR", 18, "1")
        );
        // A zero balance must not let a later program turn the inner asset into SR.
        assertEq(IERC20(inner_).totalSupply(), 0);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AccountReserved.selector, innerGroup_));
        factory.createStakingRewardToken(
            outerGroup_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Outer SR", "OSR", 18, "1")
        );
        vm.prank(ALICE);
        rewards.stake(inner_, 100e18, 0);
        assertEq(IERC20(inner_).balanceOf(ALICE), 100e18);
    }

    function testCannotCreateOuterSRAboveExistingRewardBacking() public {
        (address outerGroup_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x993), "Outer", false);
        (address innerGroup_,) = ledger.addSubAccountGroup(stakeToken, outerGroup_, REWARDS, "Rewards", false);
        (address secondGroup_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x994), "Second", false);
        address second_ = factory.createStakingRewardToken(
            secondGroup_, innerGroup_, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Inner Rewards", "ISR", 18, "1")
        );
        address backing_ = LedgerLib.toAddress(innerGroup_, second_);
        assertEq(ledgerView.balanceOf(stakeToken, innerGroup_, second_), 0);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AccountReserved.selector, backing_));
        factory.createStakingRewardToken(
            outerGroup_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Outer SR", "OSR", 18, "1")
        );
        vm.prank(ALICE);
        rewards.stake(second_, 100e18, 0);
        vm.prank(BOB);
        rewards.reward(second_, 100e18);
        assertEq(rewards.rewardsOf(second_, ALICE).pending, 100e18);
    }

    function testCannotUseRegisteredSRWrapperAsStakeOrRewardToken() public {
        // Registering the wrapper as an external root must not bypass the subtree guard.
        address[] memory tokens_ = new address[](1);
        tokens_[0] = srToken;
        ledger.addExternalToken(tokens_);
        (address srGroup_,) = ledger.addSubAccountGroup(srToken, srToken, BACKING, "SR Assets", false);
        (address secondGroup_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x995), "Second", false);
        ILedgerTokenFactory.TokenMetadata memory metadata_ = ILedgerTokenFactory.TokenMetadata("Nested", "NSR", 18, "1");
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        factory.createStakingRewardToken(srGroup_, rewardGroup, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        factory.createStakingRewardToken(secondGroup_, srGroup_, HALF_LIFE, metadata_);
    }

    function testIndependentProgramsAllowOrdinaryNestedAccounts() public {
        (address group_,) = ledger.addSubAccountGroup(stakeToken, stakeToken, address(0x996), "Programs", false);
        (address leftGroup_,) = ledger.addSubAccountGroup(stakeToken, group_, ALICE, "Left", false);
        (address rightGroup_,) = ledger.addSubAccountGroup(stakeToken, group_, BOB, "Right", false);
        (address custody_,) = ledger.addSubAccountGroup(stakeToken, leftGroup_, BACKING, "Custody", false);
        ledger.addSubAccount(stakeToken, custody_, ALICE, "Alice", false);
        address left_ = factory.createStakingRewardToken(
            leftGroup_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Left SR", "LSR", 18, "1")
        );
        address right_ = factory.createStakingRewardToken(
            rightGroup_, rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Right SR", "RSR", 18, "1")
        );
        vm.startPrank(ALICE);
        rewards.stake(left_, 100e18, 0);
        rewards.stake(right_, 50e18, 0);
        vm.stopPrank();
        assertEq(IERC20(left_).balanceOf(ALICE), 100e18);
        assertEq(IERC20(right_).balanceOf(ALICE), 50e18);
    }

    function testNativeStakeUsesExistingLedgerCustody() public {
        address native_ = LedgerLib.NATIVE_ADDRESS;
        ledger.addNativeToken();
        ledger.addSubAccountGroup(native_, native_, BACKING, "Staking", false);
        address second_ = rewards.createStakingRewardToken(
            LedgerLib.toAddress(native_, BACKING),
            rewardGroup,
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Staked ETH", "SRETH", 18, "1")
        );
        vm.deal(ALICE, 100e18);
        vm.startPrank(ALICE);
        ledger.wrap{value: 100e18}(native_, 100e18);
        rewards.stake(second_, 100e18, 100e18);
        assertEq(address(dispatcher).balance, 100e18);
        rewards.unstake(second_, 100e18, 100e18);
        ledger.unwrap(native_, 100e18);
        vm.stopPrank();
        assertEq(ALICE.balance, 100e18);
        assertEq(address(dispatcher).balance, 0);
    }

    // 40 units aged one half-life, followed by 60 newly funded units.
    function seedEightyPendingTwentyAvailable() internal {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 40e6);
        vm.warp(HALF_LIFE);
        rewards.reward(srToken, 60e6);
        assertRewards(ALICE, 100e6, 80e6, 20e6);
    }

    function testArticleExitedHolderExcludedFromForfeiture() public {
        stakeFor(ALICE, 1e18);
        rewards.reward(srToken, 20e6);
        vm.prank(ALICE);
        rewards.unstake(srToken, 1e18, 0);
        stakeFor(BOB, 1e18);
        stakeFor(CAROL, 1e18);
        rewards.reward(srToken, 80e6);
        uint256 supply_ = rewards.stakingRewardToken(srToken).rewards.unclaimedUnits;
        vm.prank(BOB);
        rewards.unstake(srToken, 1e18, 0);
        assertRewards(ALICE, 20e6, 0, 20e6);
        assertRewards(BOB, 0, 0, 0);
        assertRewards(CAROL, 80e6, 80e6, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, supply_);
        assertConservation(100e6, 0);
    }

    function testArticlePartialUnstake() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(BOB, 50e18);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 0);
        assertRewards(ALICE, 80e6, 60e6, 20e6);
        assertRewards(BOB, 20e6, 20e6, 0);
        assertConservation(100e6, 0);
    }

    function testArticleSoleUnitOwnerIsNotFinalStaker() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(BOB, 100e18);
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 0);
        assertRewards(ALICE, 20e6, 0, 20e6);
        assertRewards(BOB, 80e6, 80e6, 0);
        vm.prank(BOB);
        rewards.unstake(srToken, 100e18, 0);
        assertRewards(ALICE, 20e6, 0, 20e6);
        assertRewards(BOB, 80e6, 0, 80e6);
        assertConservation(100e6, 0);
    }

    function testPartialAndFullTransferRedistributeToRemainingStake() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(CAROL, 75e18);
        uint256 snapshot_ = vm.snapshotState();
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 25e18);
        assertRewards(ALICE, 90e6, 70e6, 20e6);
        assertRewards(BOB, 0, 0, 0);
        assertRewards(CAROL, 10e6, 10e6, 0);
        assertEq(IERC20(srToken).balanceOf(ALICE), 75e18);
        assertConservation(100e6, 0);
        vm.revertToState(snapshot_);
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 100e18);
        assertRewards(ALICE, 20e6, 0, 20e6);
        assertRewards(BOB, 0, 0, 0);
        assertRewards(CAROL, 80e6, 80e6, 0);
        assertConservation(100e6, 0);
    }

    function testPartialTransferRewardsOnlyRecipientsExistingStake() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(BOB, 25e18);
        stakeFor(CAROL, 25e18);
        vm.expectEmit(true, true, false, true, address(dispatcher));
        emit IStakingRewardToken.Forfeited(
            srToken, LedgerLib.toAddress(stakingGroup, ALICE), 40e6 * StakingRewardLib.UNIT_SCALE, 0
        );
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 50e18);
        // Retained stake is 50:25:25; Bob's incoming 50 earns none of the forfeiture.
        assertRewards(ALICE, 80e6, 60e6, 20e6);
        assertRewards(BOB, 10e6, 10e6, 0);
        assertRewards(CAROL, 10e6, 10e6, 0);
        assertEq(IERC20(srToken).balanceOf(BOB), 75e18);
        assertEq(IERC20(srToken).totalSupply(), 150e18);
        assertConservation(100e6, 0);
        rewards.reward(srToken, 150e6);
        assertRewards(ALICE, 130e6, 110e6, 20e6);
        assertRewards(BOB, 85e6, 85e6, 0);
        assertRewards(CAROL, 35e6, 35e6, 0);
        assertConservation(250e6, 0);
    }

    function testFullSupplyTransferReleasesResidualAndPreservesExitedRewards() public {
        stakeFor(CAROL, 1);
        rewards.reward(srToken, 2);
        vm.prank(CAROL);
        rewards.unstake(srToken, 1, 0);
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 1);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 1);
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 3);
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, StakingRewardLib.UNIT_SCALE);
        assertEq(rewards.rewardsOf(srToken, ALICE).pendingUnits, 0);
        assertEq(rewards.rewardsOf(srToken, BOB).unclaimedUnits, 0);
        assertEq(rewards.rewardsOf(srToken, BOB).pendingUnits, 0);
        assertRewards(CAROL, 2, 0, 2);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.pendingUnits, 0);
        assertEq(IERC20(srToken).totalSupply(), 3);
        assertConservation(3, 0);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 1);
        vm.prank(CAROL);
        assertEq(rewards.claim(srToken), 2);
        rewards.reward(srToken, 6);
        assertRewards(BOB, 6, 6, 0);
        assertConservation(9, 3);
        vm.prank(BOB);
        rewards.unstake(srToken, 3, 0);
        vm.prank(BOB);
        assertEq(rewards.claim(srToken), 6);
        assertConservation(9, 9);
    }

    function testPartialSoleHolderTransferRetainsExactPending() public {
        stakeFor(ALICE, 7);
        rewards.reward(srToken, 1);
        vm.warp(HALF_LIFE);
        IStakingRewardToken.Rewards memory before_ = rewards.rewardsOf(srToken, ALICE);
        uint256 residual_ = rewards.stakingRewardToken(srToken).allocationRemainderUnits;
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 4);
        IStakingRewardToken.Rewards memory after_ = rewards.rewardsOf(srToken, ALICE);
        assertEq(after_.unclaimedUnits, before_.unclaimedUnits);
        assertEq(after_.pendingUnits, before_.pendingUnits);
        assertEq(rewards.rewardsOf(srToken, BOB).unclaimedUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, residual_);
        assertEq(IERC20(srToken).balanceOf(ALICE), 3);
        assertEq(IERC20(srToken).balanceOf(BOB), 4);
        assertConservation(1, 0);
    }

    function testTransferReentryPreservesAvailableAndExcludesIncomingStake() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(BOB, 100e18);
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 100e18);
        vm.prank(BOB);
        IERC20(srToken).transfer(ALICE, 100e18);
        assertRewards(ALICE, 20e6, 0, 20e6);
        assertRewards(BOB, 80e6, 80e6, 0);
        rewards.reward(srToken, 100e6);
        assertRewards(ALICE, 70e6, 50e6, 20e6);
        assertRewards(BOB, 130e6, 130e6, 0);
        vm.warp(2 * HALF_LIFE);
        assertRewards(ALICE, 70e6, 25e6, 45e6);
        assertRewards(BOB, 130e6, 65e6, 65e6);
        assertConservation(200e6, 0);
    }

    function testArticleContinuedFundingDoesNotRestartVesting() public {
        stakeFor(ALICE, 100e18);
        uint256 previousAvailable_;
        uint256[4] memory expected_ = [uint256(50e6), 75e6, 87_500_000, 93_750_000];
        for (uint256 i_; i_ < expected_.length; ++i_) {
            rewards.reward(srToken, 100e6);
            vm.warp(block.timestamp + HALF_LIFE);
            uint256 available_ = rewards.rewardsOf(srToken, ALICE).available;
            assertEq(available_ - previousAvailable_, expected_[i_]);
            previousAvailable_ = available_;
        }
        assertConservation(400e6, 0);
    }

    function testSettlementSelectorRejectsExternalCallers() public {
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        rewards.settleStakeTransfer(srToken, ALICE, BOB, false, false, 1);
    }

    struct ReferencePosition {
        uint256 stake;
        uint256 units;
        uint256 pending;
    }

    struct ReferenceState {
        ReferencePosition[3] positions;
        uint256 stake;
        uint256 units;
        uint256 remainder;
        uint256 funded;
        uint256 stakeAdded;
    }

    // Independent eager reference: visit every holder on funding, vesting and
    // redistribution. No accumulator or checkpoint formula is used here.
    function referenceAllocate(ReferenceState memory model_, uint256 units_) internal pure {
        uint256 assigned_;
        for (uint256 j_; j_ < 3; ++j_) {
            uint256 part_ = units_ * model_.positions[j_].stake / model_.stake;
            model_.positions[j_].units += part_;
            model_.positions[j_].pending += part_;
            assigned_ += part_;
        }
        model_.remainder += units_ - assigned_;
    }

    function referenceStep(ReferenceState memory model_, uint256 random_) internal {
        address[3] memory holders_ = [ALICE, BOB, CAROL];
        uint256 actor_ = random_ % 3;
        uint256 action_ = (random_ >> 8) % 5;
        uint256 amount_ = 1 + (random_ >> 16) % 1000;
        if (action_ == 0 || model_.stake == 0) {
            stakeFor(holders_[actor_], amount_);
            model_.positions[actor_].stake += amount_;
            model_.stake += amount_;
            model_.stakeAdded += amount_;
        } else if (action_ == 1) {
            rewards.reward(srToken, amount_);
            model_.funded += amount_;
            model_.units += amount_ * StakingRewardLib.UNIT_SCALE;
            referenceAllocate(model_, amount_ * StakingRewardLib.UNIT_SCALE);
        } else if (action_ == 2) {
            uint256 halves_ = 1 + amount_ % 5;
            vm.warp(block.timestamp + halves_ * HALF_LIFE);
            for (uint256 j_; j_ < 3; ++j_) {
                model_.positions[j_].pending >>= halves_;
            }
        } else if (model_.positions[actor_].stake != 0) {
            uint256 beforeStake_ = model_.positions[actor_].stake;
            amount_ = (random_ >> 32) % 2 == 0 ? beforeStake_ : 1 + amount_ % beforeStake_;
            uint256 forfeited_ = model_.positions[actor_].pending * amount_ / beforeStake_;
            if (action_ == 3) {
                vm.prank(holders_[actor_]);
                IERC20(srToken).transfer(holders_[(actor_ + 1) % 3], amount_);
            } else {
                vm.prank(holders_[actor_]);
                rewards.unstake(srToken, amount_, 0);
            }
            // Exit and distribute eagerly before admitting the transferred principal.
            model_.positions[actor_].stake -= amount_;
            model_.stake -= amount_;
            if (model_.stake == 0) {
                model_.positions[actor_].pending = 0;
                model_.positions[actor_].units += model_.remainder;
                model_.remainder = 0;
            } else if (model_.stake != model_.positions[actor_].stake) {
                model_.positions[actor_].units -= forfeited_;
                model_.positions[actor_].pending -= forfeited_;
                referenceAllocate(model_, forfeited_);
            }
            if (action_ == 3) {
                model_.positions[(actor_ + 1) % 3].stake += amount_;
                model_.stake += amount_;
            }
        }
    }

    function testFuzzAgainstIndependentEagerReference(uint256 seed_) public {
        ReferenceState memory model_;
        address[3] memory holders_ = [ALICE, BOB, CAROL];
        for (uint256 step_; step_ < 80; ++step_) {
            seed_ = uint256(keccak256(abi.encode(seed_, step_)));
            referenceStep(model_, seed_);
            // Per allocation, integer-per-stake quantization loses < S units; the eager
            // per-holder model loses < 3. Each independent decay path adds < one
            // accumulator digit per elapsed checkpoint, multiplied by stake. Summing
            // over at most n paths for n actions gives this conservative O(n^2 S) bound.
            // These are internal units: 1 raw reward-token unit is 1e36 internal units.
            uint256 bound_ = 4 * (step_ + 1) ** 2 * (model_.stakeAdded + 3);
            uint256 pending_;
            for (uint256 j_; j_ < 3; ++j_) {
                IStakingRewardToken.Rewards memory actual_ = rewards.rewardsOf(srToken, holders_[j_]);
                assertEq(IERC20(srToken).balanceOf(holders_[j_]), model_.positions[j_].stake);
                assertApproxEqAbs(actual_.unclaimedUnits, model_.positions[j_].units, bound_);
                assertApproxEqAbs(actual_.pendingUnits, model_.positions[j_].pending, bound_);
                assertApproxEqAbs(
                    actual_.unclaimedUnits - actual_.pendingUnits,
                    model_.positions[j_].units - model_.positions[j_].pending,
                    2 * bound_
                );
                if (model_.positions[j_].stake == 0) assertEq(actual_.pendingUnits, 0);
                pending_ += actual_.pendingUnits;
            }
            assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, model_.units);
            assertApproxEqAbs(
                rewards.stakingRewardToken(srToken).rewards.pendingUnits,
                pending_,
                bound_ + rewards.stakingRewardToken(srToken).allocationRemainderUnits
            );
            assertConservation(model_.funded, 0);
        }
        for (uint256 j_; j_ < 3; ++j_) {
            uint256 stake_ = IERC20(srToken).balanceOf(holders_[j_]);
            if (stake_ == 0) continue;
            vm.prank(holders_[j_]);
            rewards.unstake(srToken, stake_, 0);
        }
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 0);
        uint256 claimed_;
        for (uint256 j_; j_ < 3; ++j_) {
            if (rewards.rewardsOf(srToken, holders_[j_]).unclaimedUnits == 0) continue;
            vm.prank(holders_[j_]);
            claimed_ += rewards.claim(srToken);
        }
        assertEq(claimed_, model_.funded);
        assertConservation(model_.funded, claimed_);
    }

    function checkpointHash(address holder_) internal view returns (bytes32 digest_) {
        bytes32 namespace_ = keccak256(abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken")) - 1))
            & ~bytes32(uint256(0xff));
        bytes32 program_ = keccak256(abi.encode(srToken, namespace_));
        bytes32 positions_ = keccak256(abi.encode(srToken, uint256(namespace_) + 1));
        bytes32 holderSlot_ = keccak256(abi.encode(LedgerLib.toAddress(stakingGroup, holder_), positions_));
        for (uint256 i_; i_ < 8; ++i_) {
            digest_ = keccak256(abi.encode(digest_, vm.load(address(dispatcher), bytes32(uint256(program_) + i_))));
        }
        for (uint256 i_; i_ < 5; ++i_) {
            digest_ = keccak256(abi.encode(digest_, vm.load(address(dispatcher), bytes32(uint256(holderSlot_) + i_))));
        }
    }

    function testSelfAndZeroTransfersLeaveRewardStorageUntouched() public {
        stakeFor(ALICE, 100);
        rewards.reward(srToken, 100);
        vm.warp(HALF_LIFE);
        bytes32 alice_ = checkpointHash(ALICE);
        bytes32 bob_ = checkpointHash(BOB);
        vm.startPrank(ALICE);
        IERC20(srToken).transfer(ALICE, 100);
        IERC20(srToken).transfer(BOB, 0);
        IERC20(srToken).approve(CAROL, 100);
        vm.stopPrank();
        vm.startPrank(CAROL);
        IERC20(srToken).transferFrom(ALICE, ALICE, 100);
        IERC20(srToken).transferFrom(ALICE, BOB, 0);
        vm.stopPrank();
        assertEq(IERC20(srToken).allowance(ALICE, CAROL), 0);
        assertEq(checkpointHash(ALICE), alice_);
        assertEq(checkpointHash(BOB), bob_);
    }

    function testTransferAndForfeitureDoNotPostRewardShares() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(BOB, 50e18);
        address shares_ = rewards.stakingRewardToken(srToken).rewardShareToken;
        vm.recordLogs();
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 25e18);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 0);
        Vm.Log[] memory logs_ = vm.getRecordedLogs();
        for (uint256 i_; i_ < logs_.length; ++i_) {
            assertTrue(logs_[i_].emitter != shares_);
            if (logs_[i_].topics.length > 1) {
                assertTrue(logs_[i_].topics[1] != bytes32(uint256(uint160(shares_))));
            }
        }
        assertConservation(100e6, 0);
    }

    function testAllocationResidualPreservesSupplyAndClearsOnFinalExit() public {
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 1);
        IStakingRewardToken.Configuration memory config_ = rewards.stakingRewardToken(srToken);
        assertEq(config_.rewards.unclaimedUnits, StakingRewardLib.UNIT_SCALE);
        assertEq(config_.allocationRemainderUnits, 1);
        stakeFor(BOB, 7);
        uint256 beforeSupply_ = config_.rewards.unclaimedUnits;
        vm.prank(ALICE);
        rewards.unstake(srToken, 3, 0);
        assertEq(rewards.rewardsOf(srToken, ALICE).pendingUnits, 0);
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, beforeSupply_);
        assertConservation(1, 0);
        vm.prank(BOB);
        rewards.unstake(srToken, 7, 0);
        assertEq(rewards.rewardsOf(srToken, BOB).unclaimedUnits, beforeSupply_);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 0);
        vm.prank(BOB);
        assertEq(rewards.claim(srToken), 1);
        assertConservation(1, 1);
    }

    struct ConservationCache {
        IStakingRewardToken.Rewards alice;
        IStakingRewardToken.Rewards bob;
        IStakingRewardToken.Rewards carol;
        IStakingRewardToken.Configuration config;
    }

    function assertConservation(uint256 funded_, uint256 claimed_) internal view {
        ConservationCache memory c;
        c.alice = rewards.rewardsOf(srToken, ALICE);
        c.bob = rewards.rewardsOf(srToken, BOB);
        c.carol = rewards.rewardsOf(srToken, CAROL);
        c.config = rewards.stakingRewardToken(srToken);
        assertEq(
            c.alice.unclaimedUnits + c.bob.unclaimedUnits + c.carol.unclaimedUnits + c.config.allocationRemainderUnits,
            c.config.rewards.unclaimedUnits
        );
        assertLe(c.alice.unclaimed + c.bob.unclaimed + c.carol.unclaimed, c.config.rewards.unclaimed);
        assertEq(c.config.rewards.unclaimed + claimed_, funded_);
        assertEq(IERC20(c.config.rewardShareToken).totalSupply(), c.config.rewards.unclaimedUnits);
        assertEq(IERC20(c.config.rewardShareToken).balanceOf(srToken), c.config.rewards.unclaimedUnits);
        assertEq(IERC20(srToken).totalSupply(), c.config.stakedBalance);
        assertLe(c.alice.pendingUnits, c.alice.unclaimedUnits);
        assertLe(c.bob.pendingUnits, c.bob.unclaimedUnits);
        assertLe(c.carol.pendingUnits, c.carol.unclaimedUnits);
    }

    struct FuzzCache {
        uint256 funded;
        uint256 claimed;
        uint256 available;
        uint256 shares;
    }

    function testFuzzConservationAcrossFundingTransfersClaimsAndExits(uint256 seed_) public {
        FuzzCache memory c;
        stakeFor(ALICE, bound(seed_, 1, 1e27));
        stakeFor(BOB, bound(uint256(keccak256(abi.encode(seed_, 1))), 1, 1e27));
        for (uint256 i_; i_ < 12; ++i_) {
            seed_ = uint256(keccak256(abi.encode(seed_, i_)));
            vm.warp(block.timestamp + seed_ % (2 * HALF_LIFE));
            uint256 amount_ = 1 + seed_ % 1e12;
            c.funded += amount_;
            rewards.reward(srToken, amount_);
            if (i_ == 3) stakeFor(CAROL, 1e25);
            if (i_ == 6) {
                c.shares = IERC20(srToken).balanceOf(ALICE) / 2;
                vm.prank(ALICE);
                IERC20(srToken).transfer(BOB, c.shares);
            }
            c.available = rewards.rewardsOf(srToken, BOB).available;
            if (c.available != 0) {
                vm.prank(BOB);
                c.claimed += rewards.claim(srToken);
            }
            assertConservation(c.funded, c.claimed);
        }
        c.shares = IERC20(srToken).balanceOf(ALICE);
        c.available = rewards.rewardsOf(srToken, ALICE).available;
        vm.prank(ALICE);
        rewards.unstake(srToken, c.shares, 0);
        assertApproxEqAbs(rewards.rewardsOf(srToken, ALICE).available, c.available, 1);
        c.shares = IERC20(srToken).balanceOf(BOB);
        vm.prank(BOB);
        rewards.unstake(srToken, c.shares, 0);
        c.shares = IERC20(srToken).balanceOf(CAROL);
        vm.prank(CAROL);
        rewards.unstake(srToken, c.shares, 0);
        assertConservation(c.funded, c.claimed);
        vm.warp(block.timestamp + 256 * HALF_LIFE);
        address[3] memory holders_ = [ALICE, BOB, CAROL];
        for (uint256 i_; i_ < holders_.length; ++i_) {
            if (rewards.rewardsOf(srToken, holders_[i_]).unclaimedUnits == 0) continue;
            vm.prank(holders_[i_]);
            c.claimed += rewards.claim(srToken);
        }
        assertConservation(c.funded, c.claimed);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, 0);
    }

    function testFuzzCheckpointTimingDoesNotChangeEntitlement(uint256 elapsed_, uint256 split_) public {
        elapsed_ = bound(elapsed_, 2, 10 * HALF_LIFE);
        split_ = bound(split_, 1, elapsed_ - 1);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        uint256 snapshot_ = vm.snapshotState();
        vm.warp(elapsed_);
        IStakingRewardToken.Rewards memory expected_ = rewards.rewardsOf(srToken, ALICE);
        vm.revertToState(snapshot_);
        vm.warp(split_);
        // A new holder action checkpoints aggregate state without touching Alice.
        stakeFor(BOB, 1e18);
        vm.warp(elapsed_);
        IStakingRewardToken.Rewards memory actual_ = rewards.rewardsOf(srToken, ALICE);
        assertEq(actual_.unclaimedUnits, expected_.unclaimedUnits);
        assertApproxEqAbs(actual_.pending, expected_.pending, 1);
        assertApproxEqAbs(actual_.available, expected_.available, 1);
    }

    function testNestedClaimAndUnstakeUseExplicitAccountingContext() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new NestedStakingApplication());
        dispatcher.addModule(modules_);
        NestedStakingApplication app_ = NestedStakingApplication(address(dispatcher));
        (address group_,) = ledger.addSubAccountGroup(stakeToken, stakingGroup, address(0x707), "Nested shares", false);
        stakeFor(ALICE, 100e18);
        ledger.rawTransfer(stakeToken, stakingGroup, ALICE, group_, BOB, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).available, 50e6);
        vm.prank(BOB);
        vm.expectRevert();
        app_.claimAt(srToken, group_, BOB, BOB);
        assertEq(app_.claimAt(srToken, group_, BOB, BOB), 50e6);
        assertEq(app_.unstakeAt(srToken, group_, BOB, BOB, 100e18), 100e18);
        assertEq(app_.claimAt(srToken, group_, BOB, BOB), 50e6);
        assertEq(IERC20(srToken).totalSupply(), 0);
        assertEq(ledgerView.balanceOf(stakeToken, group_, BOB), 0);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 0);
    }

    function testCustodyGroupCannotClaimDescendantRewards() public {
        (address group_,) = ledger.addSubAccountGroup(stakeToken, stakingGroup, CAROL, "Share custody", false);
        stakeFor(ALICE, 100e18);
        ledger.rawTransfer(stakeToken, stakingGroup, ALICE, group_, BOB, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        assertEq(IERC20(srToken).balanceOf(CAROL), 100e18);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).available, 50e6);

        bytes memory error_ = abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, group_);
        vm.prank(CAROL);
        vm.expectRevert(error_);
        IERC20(srToken).transfer(ALICE, 1);
        vm.prank(CAROL);
        IERC20(srToken).approve(ALICE, 1);
        vm.prank(ALICE);
        vm.expectRevert(error_);
        IERC20(srToken).transferFrom(CAROL, ALICE, 1);
        assertEq(IERC20(srToken).allowance(CAROL, ALICE), 1);
        assertEq(IERC20(srToken).balanceOf(CAROL), 100e18);
        vm.prank(CAROL);
        vm.expectRevert(error_);
        rewards.claim(srToken);
        vm.expectRevert(error_);
        rewards.rewardsOf(srToken, CAROL);
        vm.expectRevert(error_);
        rewards.rewardsOfAccount(srToken, stakingGroup, CAROL);
        assertEq(rewards.rewardsOfAccount(srToken, group_, BOB).available, 50e6);
        assertEq(IERC20(rewardToken).balanceOf(CAROL), 0);
    }

    function testPublicStakingOperationsRejectCreditAccounts() public {
        stakeFor(ALICE, 100e18);
        (address shareCredit_,) = ledger.addSubAccount(stakeToken, stakingGroup, CAROL, "Credit shares", true);
        (address stakeCredit_,) = ledger.addSubAccount(stakeToken, stakeToken, address(0x801), "Credit stake", true);
        (address rewardCredit_,) = ledger.addSubAccount(rewardToken, rewardToken, CAROL, "Credit reward", true);

        vm.prank(CAROL);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, shareCredit_));
        rewards.unstake(srToken, 10e18, 0);
        vm.prank(CAROL);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, shareCredit_));
        rewards.claim(srToken);
        vm.prank(address(0x801));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, stakeCredit_));
        rewards.stake(srToken, 10e18, 0);
        vm.prank(CAROL);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, rewardCredit_));
        rewards.reward(srToken, 10e6);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 100e18);
    }
}
