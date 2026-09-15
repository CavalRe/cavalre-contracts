// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TestLedger} from "./Ledger.t.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
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
    StakingRewardToken internal rewards;
    address internal stakeToken;
    address internal rewardToken;
    address internal receipt;
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
        (receipt,) = factory.createReceiptToken(
            LedgerLib.toAddress(stakeToken, BACKING), ILedgerTokenFactory.TokenMetadata("Staked S", "SR", 18, "1")
        );
        rewards.configureStakingRewardToken(receipt, rewardToken, HALF_LIFE);
        ledger.mint(stakeToken, stakeToken, ALICE, 1e30);
        ledger.mint(stakeToken, stakeToken, BOB, 1e30);
        ledger.mint(stakeToken, stakeToken, CAROL, 1e30);
        ledger.mint(rewardToken, rewardToken, address(this), 1e24);
    }

    function stakeFor(address holder_, uint256 amount_) internal {
        vm.prank(holder_);
        rewards.stake(receipt, amount_, amount_);
    }

    function assertRewards(address holder_, uint256 total_, uint256 pending_, uint256 available_) internal view {
        IStakingRewardToken.Rewards memory state_ = rewards.rewardsOf(receipt, holder_);
        assertApproxEqAbs(state_.total, total_, 1);
        assertApproxEqAbs(state_.pending, pending_, 1);
        assertApproxEqAbs(state_.available, available_, 1);
        assertLe(state_.pendingUnits, state_.totalUnits);
    }

    function testConfigurationUsesReceiptMetadata() public view {
        IStakingRewardToken.Configuration memory config_ = rewards.stakingRewardToken(receipt);
        assertEq(config_.receipt.tokenAddress, receipt);
        assertEq(config_.receipt.backingLedger, stakeToken);
        assertEq(config_.receipt.backingAccount, LedgerLib.toAddress(stakeToken, BACKING));
        assertEq(config_.rewardLedger, rewardToken);
        assertEq(config_.halfLife, HALF_LIFE);
        assertEq(config_.forfeitedBalance, 0);
    }

    function testConfigurationCannotChange() public {
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.AlreadyConfigured.selector, receipt));
        rewards.configureStakingRewardToken(receipt, rewardToken, 1 days);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        rewards.configureStakingRewardToken(receipt, rewardToken, HALF_LIFE);
    }

    function testInvalidConfiguration() public {
        ledger.addSubAccount(stakeToken, stakeToken, CAROL, "New Backing", false);
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(stakeToken, CAROL), ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1")
        );
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.configureStakingRewardToken(second_, rewardToken, 0);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.configureStakingRewardToken(second_, second_, HALF_LIFE);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.configureStakingRewardToken(second_, address(0), HALF_LIFE);
        // CAROL's pre-existing S balance also prevents configuring this backing account.
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.configureStakingRewardToken(second_, rewardToken, HALF_LIFE);
    }

    function testCannotAdoptAnExistingReceiptSupply() public {
        ledger.addSubAccount(stakeToken, stakeToken, address(0x52a), "New Backing", false);
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(stakeToken, address(0x52a)), ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1")
        );
        ledger.mint(second_, second_, ALICE, 1);
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.configureStakingRewardToken(second_, rewardToken, HALF_LIFE);
    }

    function testCannotUseCreditBacking() public {
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(stakeToken, LedgerLib.SOURCE_ADDRESS),
            ILedgerTokenFactory.TokenMetadata("Credit", "CREDIT", 18, "1")
        );
        vm.expectRevert(IStakingRewardToken.InvalidConfiguration.selector);
        rewards.configureStakingRewardToken(second_, rewardToken, HALF_LIFE);
    }

    function testCannotConfigureTwoProgramsOnOneBackingAccount() public {
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(stakeToken, BACKING), ILedgerTokenFactory.TokenMetadata("Duplicate", "DUP", 18, "1")
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector, LedgerLib.toAddress(stakeToken, BACKING)
            )
        );
        rewards.configureStakingRewardToken(second_, rewardToken, HALF_LIFE);
    }

    function testFundingRequiresStake() public {
        vm.expectRevert(IStakingRewardToken.NoStake.selector);
        rewards.reward(receipt, 100e6);
    }

    function testHalfLifeAndPartialClaims() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        assertRewards(ALICE, 100e6, 100e6, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.InsufficientRewards.selector);
        rewards.claim(receipt, 1);
        vm.warp(HALF_LIFE);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(receipt, 10e6), 10e6);
        assertRewards(ALICE, 90e6, 50e6, 40e6);
        vm.warp(2 * HALF_LIFE);
        assertRewards(ALICE, 90e6, 25e6, 65e6);
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 10e6);
    }

    function testNewStakeDoesNotReceivePreviouslyFundedRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(HALF_LIFE / 3);
        stakeFor(BOB, 100e18);
        vm.warp(HALF_LIFE);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertRewards(BOB, 0, 0, 0);
        rewards.reward(receipt, 60e6);
        assertRewards(ALICE, 130e6, 80e6, 50e6);
        assertRewards(BOB, 30e6, 30e6, 0);
    }

    function testForfeitureRepricesUnitsAndLaterFundingUsesUnitPrice() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(receipt, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.unstake(receipt, 100e18, 100e18), 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        rewards.reward(receipt, 30e6);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 120e6, 75e6, 45e6);
        vm.prank(ALICE);
        assertApproxEqAbs(rewards.claim(receipt, type(uint256).max), 30e6, 1);
    }

    function testPartialExitPreservesAvailableRewardValue() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(receipt, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(receipt, 50e18, 50e18);
        assertRewards(ALICE, 48e6, 18e6, 30e6);
        assertRewards(BOB, 72e6, 36e6, 36e6);
    }

    function testFinalHolderKeepsEarnedRewardsAndReservesForfeiture() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(receipt, 100e18, 100e18);
        assertRewards(ALICE, 50e6, 0, 50e6);
        assertEq(rewards.stakingRewardToken(receipt).forfeitedBalance, 50e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(receipt, type(uint256).max), 50e6);
        stakeFor(BOB, 100e18);
        assertRewards(BOB, 0, 0, 0);
        vm.prank(BOB);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, BOB));
        rewards.recycleRewards(receipt, 50e6);
        rewards.recycleRewards(receipt, 50e6);
        assertRewards(BOB, 50e6, 50e6, 0);
        assertEq(rewards.stakingRewardToken(receipt).forfeitedBalance, 0);
    }

    function testImmediateFinalExitAndRestart() public {
        stakeFor(ALICE, 3);
        rewards.reward(receipt, 7);
        vm.prank(ALICE);
        rewards.unstake(receipt, 3, 3);
        assertRewards(ALICE, 0, 0, 0);
        assertEq(rewards.stakingRewardToken(receipt).forfeitedBalance, 7);
        stakeFor(BOB, 5);
        rewards.reward(receipt, 13);
        assertRewards(BOB, 13, 13, 0);
    }

    function testFinalExitRetiresZeroValueUnitDust() public {
        stakeFor(ALICE, 3);
        rewards.reward(receipt, 1);
        vm.warp(1);
        vm.prank(ALICE);
        rewards.unstake(receipt, 3, 3);
        assertEq(rewards.stakingRewardToken(receipt).rewards.totalUnits, 0);
        stakeFor(BOB, 5);
        rewards.reward(receipt, 1);
        assertRewards(BOB, 1, 1, 0);
    }

    function testFullyAvailableFinalExitHasNoDivisionByZero() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(256 * HALF_LIFE);
        vm.prank(ALICE);
        rewards.unstake(receipt, 100e18, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(receipt, type(uint256).max), 100e6);
    }

    function testWrapperTransferSettlesBothHolders() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(receipt, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        IERC20(receipt).transfer(BOB, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 45e6, 45e6);
        assertEq(IERC20(receipt).balanceOf(BOB), 200e18);
        rewards.reward(receipt, 30e6);
        assertRewards(BOB, 120e6, 75e6, 45e6);
    }

    function testWrapperTransferFromSettlesRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        IERC20(receipt).approve(CAROL, 100e18);
        vm.prank(CAROL);
        IERC20(receipt).transferFrom(ALICE, BOB, 100e18);
        assertRewards(ALICE, 50e6, 0, 50e6);
        assertRewards(BOB, 0, 0, 0);
    }

    function testDirectLedgerTransferSettlesRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        ledger.transfer(receipt, receipt, receipt, BOB, 100e18);
        assertRewards(ALICE, 50e6, 0, 50e6);
        assertRewards(BOB, 0, 0, 0);
    }

    function testInternalLedgerTransfersToNestedHoldersSettleRewards() public {
        address group_ = address(0x601);
        ledger.addSubAccountGroup(receipt, receipt, group_, "Group", false);
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(HALF_LIFE);
        ledger.rawTransfer(receipt, receipt, ALICE, group_, BOB, 100e18);
        assertRewards(ALICE, 50e6, 0, 50e6);
        assertRewards(LedgerLib.toAddress(group_, BOB), 0, 0, 0);
        rewards.reward(receipt, 40e6);
        assertRewards(LedgerLib.toAddress(group_, BOB), 40e6, 40e6, 0);
        ledger.rawTransfer(receipt, group_, BOB, receipt, BOB, 100e18);
        assertRewards(BOB, 0, 0, 0);
    }

    function testSelfAndZeroTransfersDoNotForfeit() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        IERC20(receipt).transfer(ALICE, 100e18);
        IERC20(receipt).transfer(BOB, 0);
        vm.stopPrank();
        assertRewards(ALICE, 100e6, 50e6, 50e6);
    }

    function testCannotBypassReceiptMintOrBurnAccounting() public {
        stakeFor(ALICE, 100e18);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        ledger.mint(receipt, receipt, BOB, 1e18);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        ledger.transfer(receipt, receipt, receipt, LedgerLib.SOURCE_ADDRESS, 1e18);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        ledger.burn(receipt, receipt, ALICE, 1e18);
        assertEq(IERC20(receipt).totalSupply(), 100e18);
    }

    function testCannotDrainBackingOrRewardCustody() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector, LedgerLib.toAddress(stakeToken, BACKING)
            )
        );
        ledger.rawTransfer(stakeToken, stakeToken, BACKING, stakeToken, BOB, 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector,
                LedgerLib.toAddress(rewardToken, StakingRewardLib.REWARDS, receipt)
            )
        );
        ledger.rawTransfer(rewardToken, StakingRewardLib.REWARDS, receipt, rewardToken, BOB, 1);
        vm.expectRevert(IStakingRewardToken.UnauthorizedTransfer.selector);
        rewards.beforeLedgerTransfer(receipt, ALICE, BOB, false, false, 1);
    }

    function testBackingHolderCannotMintAgainstASelfTransfer() public {
        stakeFor(ALICE, 100e18);
        vm.prank(BACKING);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStakingRewardToken.AccountReserved.selector, LedgerLib.toAddress(stakeToken, BACKING)
            )
        );
        rewards.stake(receipt, 100e18, 0);
        assertEq(IERC20(receipt).totalSupply(), 100e18);
    }

    function testSlippageAndDonations() public {
        stakeFor(ALICE, 100e18);
        ledger.mint(stakeToken, stakeToken, address(this), 100e18);
        ledger.transfer(stakeToken, stakeToken, stakeToken, BACKING, 100e18);
        vm.prank(BOB);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewardToken.Slippage.selector, 50e18, 100e18));
        rewards.stake(receipt, 100e18, 100e18);
        vm.prank(BOB);
        assertEq(rewards.stake(receipt, 100e18, 50e18), 50e18);
        vm.prank(ALICE);
        assertEq(rewards.unstake(receipt, 100e18, 200e18), 200e18);
    }

    function testDifferentDecimalsAndNestedBacking() public {
        address group_ = address(0x602);
        ledger.addSubAccountGroup(rewardToken, rewardToken, group_, "Vaults", false);
        ledger.addSubAccount(rewardToken, group_, BACKING, "Backing", false);
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(rewardToken, group_, BACKING),
            ILedgerTokenFactory.TokenMetadata("Staked R", "SRR", 18, "1")
        );
        rewards.configureStakingRewardToken(second_, stakeToken, 1 days);
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
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(rewardToken, BACKING), ILedgerTokenFactory.TokenMetadata("Staked R", "SRR", 18, "1")
        );
        rewards.configureStakingRewardToken(second_, rewardToken, HALF_LIFE);
        ledger.mint(rewardToken, rewardToken, ALICE, 100e6);
        vm.prank(ALICE);
        rewards.stake(second_, 100e6, 100e18);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        rewards.claim(second_, 50e6);
        rewards.unstake(second_, 100e18, 100e6);
        vm.stopPrank();
        assertEq(IERC20(rewardToken).balanceOf(ALICE), 150e6);
        assertEq(rewards.stakingRewardToken(second_).forfeitedBalance, 50e6);
        assertEq(rewards.stakingRewardToken(receipt).forfeitedBalance, 0);
    }

    function testNativeStakeUsesExistingLedgerCustody() public {
        address native_ = LedgerLib.NATIVE_ADDRESS;
        ledger.addNativeToken();
        ledger.addSubAccount(native_, native_, BACKING, "Backing", false);
        (address second_,) = factory.createReceiptToken(
            LedgerLib.toAddress(native_, BACKING), ILedgerTokenFactory.TokenMetadata("Staked ETH", "SRETH", 18, "1")
        );
        rewards.configureStakingRewardToken(second_, rewardToken, HALF_LIFE);
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
        c.alice = rewards.rewardsOf(receipt, ALICE);
        c.bob = rewards.rewardsOf(receipt, BOB);
        c.carol = rewards.rewardsOf(receipt, CAROL);
        c.config = rewards.stakingRewardToken(receipt);
        assertEq(c.alice.totalUnits + c.bob.totalUnits + c.carol.totalUnits, c.config.rewards.totalUnits);
        assertLe(c.alice.total + c.bob.total + c.carol.total, c.config.rewards.total);
        assertEq(c.config.rewards.total + c.config.forfeitedBalance + claimed_, funded_);
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
            rewards.reward(receipt, amount_);
            if (i_ == 3) stakeFor(CAROL, 1e25);
            if (i_ == 6) {
                c.receipts = IERC20(receipt).balanceOf(ALICE) / 2;
                vm.prank(ALICE);
                IERC20(receipt).transfer(BOB, c.receipts);
            }
            c.available = rewards.rewardsOf(receipt, BOB).available;
            if (c.available != 0) {
                vm.prank(BOB);
                c.claimed += rewards.claim(receipt, c.available);
            }
            assertConservation(c.funded, c.claimed);
        }
        c.receipts = IERC20(receipt).balanceOf(ALICE);
        c.available = rewards.rewardsOf(receipt, ALICE).available;
        vm.prank(ALICE);
        rewards.unstake(receipt, c.receipts, 0);
        assertApproxEqAbs(rewards.rewardsOf(receipt, ALICE).available, c.available, 1);
        c.receipts = IERC20(receipt).balanceOf(BOB);
        vm.prank(BOB);
        rewards.unstake(receipt, c.receipts, 0);
        c.receipts = IERC20(receipt).balanceOf(CAROL);
        vm.prank(CAROL);
        rewards.unstake(receipt, c.receipts, 0);
        assertConservation(c.funded, c.claimed);
        vm.warp(block.timestamp + 256 * HALF_LIFE);
        address[3] memory holders_ = [ALICE, BOB, CAROL];
        for (uint256 i_; i_ < holders_.length; ++i_) {
            if (rewards.rewardsOf(receipt, holders_[i_]).totalUnits == 0) continue;
            vm.prank(holders_[i_]);
            c.claimed += rewards.claim(receipt, type(uint256).max);
        }
        assertConservation(c.funded, c.claimed);
        assertEq(rewards.stakingRewardToken(receipt).rewards.totalUnits, 0);
    }

    function testFuzzCheckpointTimingDoesNotChangeEntitlement(uint256 elapsed_, uint256 split_) public {
        elapsed_ = bound(elapsed_, 2, 10 * HALF_LIFE);
        split_ = bound(split_, 1, elapsed_ - 1);
        stakeFor(ALICE, 100e18);
        rewards.reward(receipt, 100e6);
        uint256 snapshot_ = vm.snapshotState();
        vm.warp(elapsed_);
        IStakingRewardToken.Rewards memory expected_ = rewards.rewardsOf(receipt, ALICE);
        vm.revertToState(snapshot_);
        vm.warp(split_);
        // A new holder action checkpoints aggregate state without touching Alice.
        stakeFor(BOB, 1e18);
        vm.warp(elapsed_);
        IStakingRewardToken.Rewards memory actual_ = rewards.rewardsOf(receipt, ALICE);
        assertEq(actual_.totalUnits, expected_.totalUnits);
        assertApproxEqAbs(actual_.pending, expected_.pending, 1);
        assertApproxEqAbs(actual_.available, expected_.available, 1);
    }
}
