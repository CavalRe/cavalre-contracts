// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TestLedger} from "./Ledger.t.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {ILedgerTransferHook} from "../../modules/ledger/ILedgerTransferHook.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {LedgerTokenFactory} from "../../modules/ledger/LedgerTokenFactory.sol";
import {ILedgerTokenFactory} from "../../modules/ledger/ILedgerTokenFactory.sol";
import {StakingRewardToken} from "../../modules/staking/StakingRewardToken.sol";
import {IStakingRewardToken} from "../../modules/staking/IStakingRewardToken.sol";
import {StakingRewardLib} from "../../modules/staking/StakingRewardLib.sol";

contract StakingRewardTokenTest is Test {
    Dispatcher internal dispatcher;
    TestLedger internal ledger;
    LedgerView internal ledgerView;
    LedgerTokenFactory internal factory;
    address internal factoryImplementation;
    ILedgerTokenFactory.TokenMetadata internal metadata;
    StakingRewardToken internal rewards;
    address internal stakeToken;
    address internal rewardToken;
    address internal srToken;
    address internal constant ALICE = address(0xa11ce);
    address internal constant BOB = address(0xb0b);
    address internal constant CAROL = address(0xca201);
    address internal constant BACKING = address(0x51a);
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
        rewards = StakingRewardToken(address(dispatcher));
        ledger.initializeTestLedger();

        ILedgerTokenFactory.TokenMetadata[] memory tokens_ = new ILedgerTokenFactory.TokenMetadata[](2);
        tokens_[0] = ILedgerTokenFactory.TokenMetadata("Stake", "S", 18, "1");
        tokens_[1] = ILedgerTokenFactory.TokenMetadata("Reward", "R", 6, "1");
        (address[] memory addresses_,) = factory.createInternalToken(tokens_);
        stakeToken = addresses_[0];
        rewardToken = addresses_[1];
        ledger.addSubAccount(stakeToken, stakeToken, BACKING, "Backing", false);
        metadata = ILedgerTokenFactory.TokenMetadata("Staked S", "SR", 18, "1");
        (srToken,) = rewards.createStakingRewardToken(
            stakeToken, rewardToken, LedgerLib.toAddress(stakeToken, BACKING), HALF_LIFE, metadata
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

    function assertRewards(address holder_, uint256 total_, uint256 pending_, uint256 available_) internal view {
        IStakingRewardToken.Rewards memory state_ = rewards.rewardsOf(srToken, holder_);
        assertApproxEqAbs(state_.total, total_, 1);
        assertApproxEqAbs(state_.pending, pending_, 1);
        assertApproxEqAbs(state_.available, available_, 1);
        assertLe(state_.pendingUnits, state_.totalUnits);
    }

    function testConfigurationOwnedBySR() public {
        stakeFor(ALICE, 100e18);
        IStakingRewardToken.Configuration memory config_ = rewards.stakingRewardToken(srToken);
        assertEq(config_.tokenAddress, srToken);
        assertEq(config_.stakingLedger, stakeToken);
        assertEq(config_.stakingAccount, LedgerLib.toAddress(stakeToken, BACKING));
        assertEq(config_.totalSupply, 100e18);
        assertEq(config_.stakedBalance, 100e18);
        assertEq(config_.rewardLedger, rewardToken);
        assertEq(config_.rewardAccount, LedgerLib.toAddress(rewardToken, StakingRewardLib.REWARDS, srToken));
        assertEq(config_.halfLife, HALF_LIFE);
    }

    function testConfigurationCannotChange() public {
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(
            stakeToken, rewardToken, LedgerLib.toAddress(stakeToken, BACKING), 1 days, metadata
        );
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(
            stakeToken, stakeToken, LedgerLib.toAddress(stakeToken, BACKING), HALF_LIFE, metadata
        );
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(stakeToken, rewardToken, address(0), HALF_LIFE, metadata);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(
            rewardToken, rewardToken, LedgerLib.toAddress(stakeToken, BACKING), HALF_LIFE, metadata
        );
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        rewards.createStakingRewardToken(
            stakeToken, rewardToken, LedgerLib.toAddress(stakeToken, BACKING), HALF_LIFE, metadata
        );
    }

    function testCreationIsIdempotentWithoutResettingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        (address token_, uint256 flags_) = rewards.createStakingRewardToken(
            stakeToken, rewardToken, LedgerLib.toAddress(stakeToken, BACKING), HALF_LIFE, metadata
        );
        assertEq(token_, srToken);
        assertTrue(LedgerLib.isInternal(flags_));
        assertFalse(LedgerLib.isReceipt(flags_));
        assertEq(IERC20(token_).totalSupply(), 100e18);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, token_));
        ledgerView.receiptToken(token_);
    }

    function testCreationDoesNotRequireFactoryModule() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = factoryImplementation;
        dispatcher.removeModule(modules_);
        ledger.addSubAccount(stakeToken, stakeToken, address(0x52a), "New Backing", false);
        (address second_, uint256 flags_) = rewards.createStakingRewardToken(
            stakeToken,
            rewardToken,
            LedgerLib.toAddress(stakeToken, address(0x52a)),
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1")
        );
        assertTrue(LedgerLib.isInternal(flags_));
        vm.prank(ALICE);
        rewards.stake(second_, 100e18, 100e18);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        assertEq(rewards.claim(second_, 50e6), 50e6);
        assertEq(rewards.unstake(second_, 100e18, 100e18), 100e18);
        assertEq(rewards.claim(second_, type(uint256).max), 50e6);
        vm.stopPrank();
    }

    function testModuleFitsDeploymentLimit() public {
        assertLe(address(new StakingRewardToken()).code.length, 24_576);
    }

    function testSROperationsSettleWithoutDispatchingTransferHook() public {
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(ILedgerTransferHook.beforeLedgerTransfer.selector), 0);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        assertEq(rewards.claim(srToken, 50e6), 50e6);
        assertEq(rewards.unstake(srToken, 100e18, 100e18), 100e18);
        assertEq(rewards.claim(srToken, type(uint256).max), 50e6);
        vm.stopPrank();
        assertRewards(ALICE, 0, 0, 0);
        assertConservation(100e6, 100e6);
    }

    function testInvalidConfiguration() public {
        address backing_ = LedgerLib.toAddress(stakeToken, address(0x52a));
        ledger.addSubAccount(stakeToken, stakeToken, address(0x52a), "New Backing", false);
        ILedgerTokenFactory.TokenMetadata memory metadata_ = ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1");
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(stakeToken, rewardToken, backing_, 0, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(rewardToken, rewardToken, backing_, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(stakeToken, address(0), backing_, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(stakeToken, rewardToken, address(0), HALF_LIFE, metadata_);
        ledger.mint(stakeToken, stakeToken, address(0x52a), 1);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(stakeToken, rewardToken, backing_, HALF_LIFE, metadata_);
    }

    function testCannotAdoptAnExistingTokenSupply() public {
        ledger.addSubAccount(stakeToken, stakeToken, address(0x52a), "New Backing", false);
        ILedgerTokenFactory.TokenMetadata[] memory tokens_ = new ILedgerTokenFactory.TokenMetadata[](1);
        tokens_[0] = ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1");
        (address[] memory addresses_,) = factory.createInternalToken(tokens_);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(
            stakeToken, addresses_[0], LedgerLib.toAddress(stakeToken, address(0x52a)), HALF_LIFE, tokens_[0]
        );
        ledger.mint(addresses_[0], addresses_[0], ALICE, 1);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(
            stakeToken, rewardToken, LedgerLib.toAddress(stakeToken, address(0x52a)), HALF_LIFE, tokens_[0]
        );
    }

    function testCannotUseCreditBacking() public {
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(
            stakeToken,
            rewardToken,
            LedgerLib.toAddress(stakeToken, LedgerLib.SOURCE_ADDRESS),
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
            stakeToken,
            rewardToken,
            LedgerLib.toAddress(stakeToken, BACKING),
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Duplicate", "DUP", 18, "1")
        );
    }

    function testFundingRequiresStake() public {
        vm.expectRevert(IStakingRewardToken.NoStake.selector);
        rewards.reward(srToken, 100e6);
    }

    function testHalfLifeAndPartialClaims() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        assertRewards(ALICE, 100e6, 100e6, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.InsufficientRewards.selector);
        rewards.claim(srToken, 1);
        vm.warp(HALF_LIFE);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken, 10e6), 10e6);
        assertRewards(ALICE, 90e6, 50e6, 40e6);
        vm.warp(2 * HALF_LIFE);
        assertRewards(ALICE, 90e6, 25e6, 65e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 10e6);
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

    function testForfeitureRepricesUnitsAndLaterFundingUsesUnitPrice() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.unstake(srToken, 100e18, 100e18), 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        rewards.reward(srToken, 30e6);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 120e6, 75e6, 45e6);
        vm.prank(ALICE);
        assertApproxEqAbs(rewards.claim(srToken, type(uint256).max), 30e6, 1);
    }

    function testPartialExitPreservesAvailableRewardValue() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 50e18);
        assertRewards(ALICE, 48e6, 18e6, 30e6);
        assertRewards(BOB, 72e6, 36e6, 36e6);
    }

    function testFinalHolderReceivesAllRemainingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        uint256 units_ = rewards.rewardsOf(srToken, ALICE).totalUnits;
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertEq(rewards.rewardsOf(srToken, ALICE).totalUnits, units_);
        assertEq(rewards.stakingRewardToken(srToken).rewards.totalUnits, units_);
        assertEq(rewards.stakingRewardToken(srToken).rewards.pendingUnits, 0);
        assertConservation(100e6, 0);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken, type(uint256).max), 100e6);
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
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 50e18);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertConservation(100e6, 0);
        vm.prank(ALICE);
        rewards.unstake(srToken, 50e18, 50e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertConservation(100e6, 0);
    }

    function testLastStakerForfeitsToExitedRewardHolder() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        vm.prank(BOB);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 75e6, 0, 75e6);
        assertRewards(BOB, 45e6, 0, 45e6);
        assertConservation(120e6, 0);
        vm.prank(ALICE);
        uint256 claimed_ = rewards.claim(srToken, type(uint256).max);
        vm.prank(BOB);
        claimed_ += rewards.claim(srToken, type(uint256).max);
        assertEq(claimed_, 120e6);
        assertConservation(120e6, claimed_);
    }

    function testNewStakerDoesNotPreventFinalRewardHolderRelease() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        stakeFor(BOB, 100e18);
        vm.prank(ALICE);
        rewards.unstake(srToken, 100e18, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 0, 0, 0);
        rewards.reward(srToken, 50e6);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 50e6, 50e6, 0);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken, type(uint256).max), 100e6);
        assertRewards(BOB, 50e6, 50e6, 0);
        assertConservation(150e6, 100e6);
    }

    function testImmediateFinalExitAndRestart() public {
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 7);
        vm.prank(ALICE);
        rewards.unstake(srToken, 3, 3);
        assertRewards(ALICE, 7, 0, 7);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken, type(uint256).max), 7);
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
        assertEq(rewards.claim(srToken, type(uint256).max), 1);
        assertEq(rewards.stakingRewardToken(srToken).rewards.totalUnits, 0);
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
        assertEq(rewards.claim(srToken, type(uint256).max), 100e6);
    }

    function testWrapperTransferSettlesBothHolders() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        assertEq(IERC20(srToken).balanceOf(BOB), 200e18);
        rewards.reward(srToken, 30e6);
        assertRewards(BOB, 120e6, 75e6, 45e6);
    }

    function testWrapperTransferFromSettlesRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        IERC20(srToken).approve(CAROL, 100e18);
        vm.prank(CAROL);
        IERC20(srToken).transferFrom(ALICE, BOB, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 0, 0, 0);
    }

    function testDirectLedgerTransferSettlesRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        ledger.transfer(srToken, srToken, srToken, BOB, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 0, 0, 0);
    }

    function testInternalLedgerTransfersToNestedHoldersSettleRewards() public {
        address group_ = address(0x601);
        ledger.addSubAccountGroup(srToken, srToken, group_, "Group", false);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        ledger.rawTransfer(srToken, srToken, ALICE, group_, BOB, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(LedgerLib.toAddress(group_, BOB), 0, 0, 0);
        rewards.reward(srToken, 40e6);
        assertRewards(LedgerLib.toAddress(group_, BOB), 40e6, 40e6, 0);
        ledger.rawTransfer(srToken, group_, BOB, srToken, BOB, 100e18);
        assertRewards(BOB, 0, 0, 0);
    }

    function testSelfAndZeroTransfersDoNotForfeit() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        IERC20(srToken).transfer(ALICE, 100e18);
        IERC20(srToken).transfer(BOB, 0);
        vm.stopPrank();
        assertRewards(ALICE, 100e6, 50e6, 50e6);
    }

    function testCannotBypassSRMintOrBurnAccounting() public {
        stakeFor(ALICE, 100e18);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        ledger.mint(srToken, srToken, BOB, 1e18);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        ledger.transfer(srToken, srToken, srToken, LedgerLib.SOURCE_ADDRESS, 1e18);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        ledger.burn(srToken, srToken, ALICE, 1e18);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
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
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector, LedgerLib.toAddress(stakeToken, BACKING)
            )
        );
        ledger.rawTransfer(stakeToken, stakeToken, BACKING, stakeToken, BOB, 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector,
                LedgerLib.toAddress(rewardToken, StakingRewardLib.REWARDS, srToken)
            )
        );
        ledger.rawTransfer(rewardToken, StakingRewardLib.REWARDS, srToken, rewardToken, BOB, 1);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        rewards.beforeLedgerTransfer(srToken, ALICE, BOB, false, false, 1);
    }

    function testBackingHolderCannotMintAgainstASelfTransfer() public {
        stakeFor(ALICE, 100e18);
        vm.prank(BACKING);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector, LedgerLib.toAddress(stakeToken, BACKING)
            )
        );
        rewards.stake(srToken, 100e18, 0);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
    }

    function testSlippageAndDonations() public {
        stakeFor(ALICE, 100e18);
        ledger.mint(stakeToken, stakeToken, address(this), 100e18);
        ledger.transfer(stakeToken, stakeToken, stakeToken, BACKING, 100e18);
        vm.prank(BOB);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.Slippage.selector, 50e18, 100e18));
        rewards.stake(srToken, 100e18, 100e18);
        vm.prank(BOB);
        assertEq(rewards.stake(srToken, 100e18, 50e18), 50e18);
        vm.prank(ALICE);
        assertEq(rewards.unstake(srToken, 100e18, 200e18), 200e18);
    }

    function testDifferentDecimalsAndNestedBacking() public {
        address group_ = address(0x602);
        ledger.addSubAccountGroup(rewardToken, rewardToken, group_, "Vaults", false);
        ledger.addSubAccount(rewardToken, group_, BACKING, "Backing", false);
        (address second_,) = rewards.createStakingRewardToken(
            rewardToken,
            stakeToken,
            LedgerLib.toAddress(rewardToken, group_, BACKING),
            1 days,
            ILedgerTokenFactory.TokenMetadata("Staked R", "SRR", 18, "1")
        );
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.startPrank(ALICE);
        assertEq(rewards.stake(second_, 100e6, 100e18), 100e18);
        assertEq(rewards.unstake(second_, 50e18, 50e6), 50e6);
        vm.stopPrank();
        assertEq(IERC20(second_).balanceOf(ALICE), 50e18);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 50e6);
    }

    function testStakeAndRewardCanUseTheSameLedger() public {
        ledger.addSubAccount(rewardToken, rewardToken, BACKING, "Backing", false);
        (address second_,) = rewards.createStakingRewardToken(
            rewardToken,
            rewardToken,
            LedgerLib.toAddress(rewardToken, BACKING),
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Staked R", "SRR", 18, "1")
        );
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.prank(ALICE);
        rewards.stake(second_, 100e6, 100e18);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        rewards.claim(second_, 50e6);
        rewards.unstake(second_, 100e18, 100e6);
        assertEq(rewards.claim(second_, type(uint256).max), 50e6);
        vm.stopPrank();
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 200e6);
        assertEq(rewards.stakingRewardToken(second_).rewards.totalUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.totalUnits, 0);
    }

    function testStakingAnotherSRTokenSettlesBothAssetTransfers() public {
        ledger.addSubAccount(srToken, srToken, BACKING, "Nested Backing", false);
        (address second_,) = rewards.createStakingRewardToken(
            srToken,
            rewardToken,
            LedgerLib.toAddress(srToken, BACKING),
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Staked SR", "SRSR", 18, "1")
        );
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.stake(second_, 100e18, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        assertRewards(BACKING, 0, 0, 0);
        rewards.reward(srToken, 30e6);
        assertRewards(BACKING, 15e6, 15e6, 0);
        vm.prank(ALICE);
        rewards.unstake(second_, 100e18, 100e18);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(second_).totalSupply(), 0);
        assertRewards(BACKING, 0, 0, 0);
        assertRewards(ALICE, 33_333_333, 0, 33_333_333);
        assertRewards(BOB, 116_666_666, 66_666_666, 50e6);
        assertConservation(150e6, 0);
    }

    struct NestedRewardCache {
        address token;
        address holder;
        IStakingRewardToken.Rewards beforeClaim;
        IStakingRewardToken.Rewards afterClaim;
    }

    function testRewardingAnotherSRTokenSettlesFundingAndClaimTransfers() public {
        NestedRewardCache memory c;
        ledger.addSubAccount(stakeToken, stakeToken, address(0x52a), "New Backing", false);
        (c.token,) = rewards.createStakingRewardToken(
            stakeToken,
            srToken,
            LedgerLib.toAddress(stakeToken, address(0x52a)),
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("SR Rewards", "SRREW", 18, "1")
        );
        c.holder = LedgerLib.toAddress(StakingRewardLib.REWARDS, c.token);
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.prank(CAROL);
        rewards.stake(c.token, 100e18, 100e18);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.reward(c.token, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        assertRewards(c.holder, 0, 0, 0);
        rewards.reward(srToken, 30e6);
        vm.warp(2 * HALF_LIFE);
        c.beforeClaim = rewards.rewardsOf(srToken, c.holder);
        assertRewards(c.holder, 15e6, 7.5e6, 7.5e6);
        vm.prank(CAROL);
        assertEq(rewards.claim(c.token, 50e18), 50e18);
        c.afterClaim = rewards.rewardsOf(srToken, c.holder);
        assertLt(c.afterClaim.totalUnits, c.beforeClaim.totalUnits);
        assertEq(c.afterClaim.pendingUnits, c.beforeClaim.pendingUnits / 2);
        assertApproxEqAbs(c.afterClaim.available, c.beforeClaim.available, 1);
        assertEq(IERC20(srToken).balanceOf(CAROL), 50e18);
        assertRewards(CAROL, 0, 0, 0);
    }

    function testNativeStakeUsesExistingLedgerCustody() public {
        address native_ = LedgerLib.NATIVE_ADDRESS;
        ledger.addNativeToken();
        ledger.addSubAccount(native_, native_, BACKING, "Backing", false);
        (address second_,) = rewards.createStakingRewardToken(
            native_,
            rewardToken,
            LedgerLib.toAddress(native_, BACKING),
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
        assertEq(c.alice.totalUnits + c.bob.totalUnits + c.carol.totalUnits, c.config.rewards.totalUnits);
        assertLe(c.alice.total + c.bob.total + c.carol.total, c.config.rewards.total);
        assertEq(c.config.rewards.total + claimed_, funded_);
        assertLe(c.alice.pendingUnits, c.alice.totalUnits);
        assertLe(c.bob.pendingUnits, c.bob.totalUnits);
        assertLe(c.carol.pendingUnits, c.carol.totalUnits);
    }

    struct FuzzCache {
        uint256 funded;
        uint256 claimed;
        uint256 available;
        uint256 receipts;
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
                c.receipts = IERC20(srToken).balanceOf(ALICE) / 2;
                vm.prank(ALICE);
                IERC20(srToken).transfer(BOB, c.receipts);
            }
            c.available = rewards.rewardsOf(srToken, BOB).available;
            if (c.available != 0) {
                vm.prank(BOB);
                c.claimed += rewards.claim(srToken, c.available);
            }
            assertConservation(c.funded, c.claimed);
        }
        c.receipts = IERC20(srToken).balanceOf(ALICE);
        c.available = rewards.rewardsOf(srToken, ALICE).available;
        vm.prank(ALICE);
        rewards.unstake(srToken, c.receipts, 0);
        assertApproxEqAbs(rewards.rewardsOf(srToken, ALICE).available, c.available, 1);
        c.receipts = IERC20(srToken).balanceOf(BOB);
        vm.prank(BOB);
        rewards.unstake(srToken, c.receipts, 0);
        c.receipts = IERC20(srToken).balanceOf(CAROL);
        vm.prank(CAROL);
        rewards.unstake(srToken, c.receipts, 0);
        assertConservation(c.funded, c.claimed);
        vm.warp(block.timestamp + 256 * HALF_LIFE);
        address[3] memory holders_ = [ALICE, BOB, CAROL];
        for (uint256 i_; i_ < holders_.length; ++i_) {
            if (rewards.rewardsOf(srToken, holders_[i_]).totalUnits == 0) continue;
            vm.prank(holders_[i_]);
            c.claimed += rewards.claim(srToken, type(uint256).max);
        }
        assertConservation(c.funded, c.claimed);
        assertEq(rewards.stakingRewardToken(srToken).rewards.totalUnits, 0);
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
        assertEq(actual_.totalUnits, expected_.totalUnits);
        assertApproxEqAbs(actual_.pending, expected_.pending, 1);
        assertApproxEqAbs(actual_.available, expected_.available, 1);
    }
}
