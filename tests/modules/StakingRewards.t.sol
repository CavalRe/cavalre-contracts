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
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {ShareTokenView} from "../../modules/share/ShareTokenView.sol";
import {TreeView} from "../../modules/tree/TreeView.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {LedgerTokenFactory} from "../../modules/ledger/LedgerTokenFactory.sol";
import {ILedgerTokenFactory} from "../../modules/ledger/ILedgerTokenFactory.sol";
import {StakingRewards} from "../../modules/staking/StakingRewards.sol";
import {StakingRewardsToken} from "../../modules/staking/StakingRewardsToken.sol";
import {IStakingRewards} from "../../modules/staking/IStakingRewards.sol";
import {StakingRewardsLib} from "../../modules/staking/StakingRewardsLib.sol";

/// @dev An authorized application composes SR accounting explicitly; Ledger remains generic.
contract StakingApplication is Dispatchable {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](5);
        signatures_[0] = "issueSR(address,address,uint256)";
        signatures_[1] = "exitSR(address,uint256)";
        signatures_[2] = "transferAt(address,address,address,address,address,uint256)";
        signatures_[3] = "rewardAt(address,address,address,uint256)";
        signatures_[4] = "claimTo(address,address,address,address,address)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](5);
        selectors_[0] = this.issueSR.selector;
        selectors_[1] = this.exitSR.selector;
        selectors_[2] = this.transferAt.selector;
        selectors_[3] = this.rewardAt.selector;
        selectors_[4] = this.claimTo.selector;
    }

    function issueSR(address token_, address holder_, uint256 amount_) external {
        enforceIsOwner();
        StakingRewardsLib.transfer(token_, token_, LedgerLib.SOURCE_ADDRESS, token_, holder_, amount_);
    }

    /// @dev Test application sale: move the caller's tokens into ineligible pool reserves.
    function exitSR(address token_, uint256 amount_) external returns (uint256) {
        address pool_ = LedgerLib.toAddress(token_, address(0x900));
        StakingRewardsLib.enforceHolder(token_, token_, msg.sender);
        StakingRewardsLib.transfer(token_, token_, msg.sender, pool_, address(0x901), amount_);
        return amount_;
    }

    function transferAt(
        address token_,
        address fromParent_,
        address from_,
        address toParent_,
        address to_,
        uint256 amount_
    ) external {
        enforceIsOwner();
        StakingRewardsLib.transfer(token_, fromParent_, from_, toParent_, to_, amount_);
    }

    function rewardAt(address token_, address parent_, address funder_, uint256 amount_) external {
        enforceIsOwner();
        StakingRewardsLib.reward(token_, parent_, funder_, amount_);
    }

    function claimTo(address token_, address parent_, address relative_, address recipientParent_, address recipient_)
        external
        returns (uint256)
    {
        enforceIsOwner();
        return StakingRewardsLib.claim(token_, parent_, relative_, recipientParent_, recipient_);
    }
}

contract StakingRewardsTest is Test {
    Dispatcher internal dispatcher;
    TestLedger internal ledger;
    LedgerView internal ledgerView;
    LedgerTokenFactory internal factory;
    address internal factoryImplementation;
    StakingApplication internal app;
    address internal pool;
    ILedgerTokenFactory.TokenMetadata internal metadata;
    IStakingRewards internal rewards;
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
    bytes4 internal constant REMOVED_SETTLEMENT_SELECTOR =
        bytes4(keccak256("settleStakeTransfer(address,address,address,bool,bool,uint256)"));

    function setUp() public {
        dispatcher = new Dispatcher(address(this));
        address[] memory modules_ = new address[](6);
        modules_[0] = address(new TestLedger(18, 18));
        modules_[1] = address(new LedgerTokenFactory());
        factoryImplementation = modules_[1];
        modules_[2] = address(new LedgerView());
        modules_[3] = address(new StakingRewards());
        modules_[4] = address(new TreeView());
        modules_[5] = address(new StakingApplication());
        dispatcher.addModule(modules_);
        ledger = TestLedger(payable(address(dispatcher)));
        factory = LedgerTokenFactory(address(dispatcher));
        ledgerView = LedgerView(address(dispatcher));
        rewards = IStakingRewards(address(dispatcher));
        app = StakingApplication(address(dispatcher));
        ledger.initializeTestLedger();
        ILedgerTokenFactory.TokenMetadata[] memory tokens_ = new ILedgerTokenFactory.TokenMetadata[](1);
        tokens_[0] = ILedgerTokenFactory.TokenMetadata("Reward", "R", 6, "1");
        (address[] memory addresses_,) = factory.createInternalTokens(tokens_);
        rewardToken = addresses_[0];
        (rewardGroup,) = ledger.addSubAccountGroup(rewardToken, rewardToken, REWARDS, "Rewards", false);
        metadata = ILedgerTokenFactory.TokenMetadata("Staked S", "SR", 18, "1");
        srToken = rewards.createStakingRewardToken(rewardGroup, HALF_LIFE, metadata);
        stakeToken = srToken;
        stakingGroup = srToken;
        stakeRewardGroup = LedgerLib.toAddress(srToken, StakingRewardsLib.REWARDS_ADDRESS);
        (pool,) = ledger.addSubAccountGroup(srToken, srToken, address(0x900), "Pool", false);
        ledger.addSubAccount(srToken, pool, address(0x901), "Reserves", false);
        ledger.mint(rewardToken, rewardToken, address(this), 1e24);
    }

    function stakeFor(address holder_, uint256 amount_) internal {
        app.issueSR(srToken, holder_, amount_);
    }

    function assertRewards(address holder_, uint256 unclaimed_, uint256 pending_, uint256 available_) internal view {
        IStakingRewards.Rewards memory state_ = rewards.rewardsOf(srToken, holder_);
        assertApproxEqAbs(state_.unclaimed, unclaimed_, 1);
        assertApproxEqAbs(state_.pending, pending_, 1);
        assertApproxEqAbs(state_.available, available_, 1);
        assertLe(state_.pendingUnits, state_.unclaimedUnits);
    }

    function testConfigurationOwnedBySR() public {
        stakeFor(ALICE, 100e18);
        IStakingRewards.Configuration memory config_ = rewards.stakingRewardToken(srToken);
        assertEq(config_.tokenAddress, srToken);
        assertEq(config_.stakingLedger, srToken);
        assertEq(config_.stakingGroup, srToken);
        assertEq(config_.totalSupply, 100e18);
        assertEq(config_.stakedBalance, 100e18);
        assertEq(config_.rewardLedger, rewardToken);
        assertEq(config_.rewardAccount, LedgerLib.toAddress(rewardGroup, srToken));
        assertEq(config_.halfLife, HALF_LIFE);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(srToken).totalSupply(), 100e18);
        assertEq(ledgerView.creditBalanceOf(srToken, srToken, StakingRewardsLib.STAKE_ADDRESS), 100e18);
        assertEq(ledgerView.creditBalanceOf(srToken, srToken, LedgerLib.SOURCE_ADDRESS), 0);
    }

    function testConfigurationCannotChange() public {
        vm.expectRevert(abi.encodeWithSelector(IStakingRewards.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(rewardGroup, 1 days, metadata);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewards.AlreadyConfigured.selector, srToken));
        rewards.createStakingRewardToken(stakeRewardGroup, HALF_LIFE, metadata);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        rewards.createStakingRewardToken(rewardGroup, HALF_LIFE, metadata);
    }

    function testCreationIsIdempotentWithoutResettingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        assertEq(rewards.createStakingRewardToken(rewardGroup, HALF_LIFE, metadata), srToken);
        assertEq(ledgerView.totalSupply(srToken), 100e18);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
    }

    function testExistingFactoryCreatesSRAndRuntimeRemainsIndependent() public {
        assertEq(dispatcher.module(ILedgerTokenFactory.createStakingRewardToken.selector), factoryImplementation);
        address second_ = factory.createStakingRewardToken(
            rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1")
        );
        address[] memory modules_ = new address[](1);
        modules_[0] = factoryImplementation;
        dispatcher.removeModule(modules_);
        app.issueSR(second_, ALICE, 100e18);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.claim(second_), 50e6);
        app.transferAt(second_, second_, ALICE, second_, StakingRewardsLib.STAKE_ADDRESS, 100e18);
        vm.prank(ALICE);
        assertEq(rewards.claim(second_), 50e6);
        assertEq(IERC20(second_).totalSupply(), 0);
    }

    function testModuleFitsDeploymentLimit() public {
        assertLe(address(new StakingRewards()).code.length, 24_576);
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
        assertEq(app.exitSR(srToken, 100e18), 100e18);
        assertEq(rewards.claim(srToken), 50e6);
        vm.stopPrank();
        assertRewards(ALICE, 0, 0, 0);
        assertConservation(100e6, 100e6);
    }

    function testInvalidConfiguration() public {
        ILedgerTokenFactory.TokenMetadata memory metadata_ = ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1");
        vm.expectRevert(IStakingRewards.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(rewardGroup, 0, metadata_);
        vm.expectRevert(IStakingRewards.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(rewardToken, HALF_LIFE, metadata_);
        vm.expectRevert(IStakingRewards.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(address(0), HALF_LIFE, metadata_);
    }

    function testCannotAdoptAnExistingTokenSupply() public {
        ILedgerTokenFactory.TokenMetadata memory metadata_ = ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1");
        address predicted_ = predictSR(metadata_);
        vm.etch(predicted_, hex"00");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidToken.selector, predicted_, "Second", "SR2", 18));
        rewards.createStakingRewardToken(rewardGroup, HALF_LIFE, metadata_);
        assertEq(ledgerView.totalSupply(predicted_), 0);
    }

    function testCannotUseCreditBacking() public {
        vm.expectRevert(IStakingRewards.InvalidConfiguration.selector);
        rewards.createStakingRewardToken(
            LedgerLib.toAddress(rewardToken, LedgerLib.SOURCE_ADDRESS),
            HALF_LIFE,
            ILedgerTokenFactory.TokenMetadata("Credit", "CREDIT", 18, "1")
        );
    }

    function testProgramsSharingRewardGroupHaveSeparateBacking() public {
        address second_ = factory.createStakingRewardToken(
            rewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Second", "SR2", 18, "1")
        );
        stakeFor(ALICE, 100e18);
        app.issueSR(second_, BOB, 100e18);
        rewards.reward(srToken, 100e6);
        rewards.reward(second_, 50e6);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, srToken), 100e6);
        assertEq(ledgerView.balanceOf(rewardToken, rewardGroup, second_), 50e6);
        assertRewards(ALICE, 100e6, 100e6, 0);
        assertEq(rewards.rewardsOf(second_, BOB).pending, 50e6);
    }

    function testFundingRequiresStake() public {
        vm.expectRevert(IStakingRewards.NoStake.selector);
        rewards.reward(srToken, 100e6);
    }

    struct ClaimAllCache {
        IStakingRewards.Rewards beforeClaim;
        IStakingRewards.Rewards afterClaim;
    }

    function testClaimAllLeavesOnlyPendingUnits() public {
        ClaimAllCache memory c;
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        assertRewards(ALICE, 100e6, 100e6, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewards.InsufficientRewards.selector);
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
        vm.expectRevert(IStakingRewards.InsufficientRewards.selector);
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
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, StakingRewardsLib.UNIT_SCALE / 2);
        assertEq(rewards.rewardsOf(srToken, ALICE).pendingUnits, StakingRewardsLib.UNIT_SCALE / 2);
        assertConservation(1, 0);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewards.InsufficientRewards.selector);
        rewards.claim(srToken);
        vm.startPrank(ALICE);
        app.exitSR(srToken, 100e18);
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
        assertEq(app.exitSR(srToken, 100e18), 100e18);
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
        app.exitSR(srToken, 50e18);
        assertRewards(ALICE, 50e6, 20e6, 30e6);
        assertRewards(BOB, 70e6, 40e6, 30e6);
    }

    function testFinalHolderReceivesAllRemainingRewards() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        uint256 units_ = rewards.rewardsOf(srToken, ALICE).unclaimedUnits;
        vm.prank(ALICE);
        app.exitSR(srToken, 100e18);
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
        app.exitSR(srToken, 50e18);
        assertTrue(checkpointHash(ALICE) != checkpointBefore_);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
        assertConservation(100e6, 0);
        vm.prank(ALICE);
        app.exitSR(srToken, 50e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertConservation(100e6, 0);
    }

    function testLastStakerReleasePreservesExitedHolderRewards() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        app.exitSR(srToken, 100e18);
        assertRewards(ALICE, 30e6, 0, 30e6);
        assertRewards(BOB, 90e6, 60e6, 30e6);
        vm.prank(BOB);
        app.exitSR(srToken, 100e18);
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
        app.exitSR(srToken, 100e18);
        assertRewards(ALICE, 0, 0, 0);
        assertRewards(BOB, 100e6, 100e6, 0);
        rewards.reward(srToken, 50e6);
        assertRewards(BOB, 150e6, 150e6, 0);
        vm.prank(BOB);
        app.exitSR(srToken, 100e18);
        vm.prank(BOB);
        assertEq(rewards.claim(srToken), 150e6);
        assertConservation(150e6, 150e6);
    }

    function testImmediateFinalExitAndRestart() public {
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 7);
        vm.prank(ALICE);
        app.exitSR(srToken, 3);
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
        app.exitSR(srToken, 3);
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
        app.exitSR(srToken, 100e18);
        assertRewards(ALICE, 100e6, 0, 100e6);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 100e6);
    }

    function testWrapperTransferSettlesBothHolders() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.expectCall(address(dispatcher), abi.encodeCall(IStakingRewards.transfer, (srToken, ALICE, BOB, 100e18)), 1);
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(ILedger.transfer.selector), 0);
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(REMOVED_SETTLEMENT_SELECTOR), 0);
        vm.prank(ALICE);
        vm.expectEmit(true, true, false, true, srToken);
        emit IERC20.Transfer(ALICE, BOB, 100e18);
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
        vm.expectCall(address(dispatcher), abi.encodeCall(IStakingRewards.transfer, (srToken, ALICE, BOB, 100e18)), 1);
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(ILedger.transfer.selector), 0);
        vm.expectCall(address(dispatcher), abi.encodeWithSelector(REMOVED_SETTLEMENT_SELECTOR), 0);
        vm.prank(CAROL);
        IERC20(srToken).transferFrom(ALICE, BOB, 100e18);
        assertEq(IERC20(srToken).allowance(ALICE, CAROL), 0);
        assertRewards(ALICE, 100e6, 0, 100e6);
        assertRewards(BOB, 0, 0, 0);

        vm.prank(ALICE);
        IERC20(srToken).approve(CAROL, 1);
        vm.prank(CAROL);
        vm.expectRevert(IStakingRewards.InsufficientStake.selector);
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
        vm.expectRevert(IStakingRewards.UnauthorizedTransfer.selector);
        rewards.transfer(srToken, ALICE, BOB, 1);
        vm.prank(rewardToken);
        vm.expectRevert(IStakingRewards.UnauthorizedTransfer.selector);
        rewards.transfer(srToken, ALICE, BOB, 1);
        vm.prank(rewardToken);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewards.NotStakingRewardToken.selector, rewardToken));
        rewards.transfer(rewardToken, ALICE, BOB, 1);
    }

    function testExplicitSRTransfersToReservesSettleButReservesDoNotEarn() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        app.transferAt(srToken, srToken, ALICE, pool, address(0x901), 100e18);
        app.transferAt(srToken, srToken, ALICE, pool, address(0x901), 100e18);
        assertRewards(ALICE, 25e6, 0, 25e6);
        assertRewards(BOB, 75e6, 50e6, 25e6);
        rewards.reward(srToken, 40e6);
        assertRewards(BOB, 115e6, 90e6, 25e6);
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(pool, address(0x901)))
        );
        rewards.rewardsOfAccount(srToken, pool, address(0x901));
        app.transferAt(srToken, pool, address(0x901), srToken, CAROL, 100e18);
        assertRewards(CAROL, 0, 0, 0);
        assertEq(IERC20(srToken).totalSupply(), 200e18);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 200e18);
    }

    function testSelfAndZeroTransfersDoNotForfeit() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(ALICE);
        vm.expectEmit(true, true, false, true, srToken);
        emit IERC20.Transfer(ALICE, ALICE, 100e18);
        IERC20(srToken).transfer(ALICE, 100e18);
        vm.expectEmit(true, true, false, true, srToken);
        emit IERC20.Transfer(ALICE, BOB, 0);
        IERC20(srToken).transfer(BOB, 0);
        vm.expectRevert(IStakingRewards.InsufficientStake.selector);
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

    function testPublicCallsCannotBypassSRMintOrBurnAccounting() public {
        stakeFor(ALICE, 100e18);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        app.issueSR(srToken, ALICE, 1);
        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(srToken, LedgerLib.SOURCE_ADDRESS)
            )
        );
        IERC20(srToken).transfer(LedgerLib.SOURCE_ADDRESS, 1);
        (uint256 fromFlags_,,) = TreeView(address(dispatcher)).effectiveFlags(srToken, srToken, ALICE);
        (uint256 toFlags_,,) = TreeView(address(dispatcher)).effectiveFlags(srToken, srToken, BOB);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(ILedger.Unauthorized.selector, ALICE));
        ILedger(address(dispatcher)).transfer(srToken, fromFlags_, ALICE, toFlags_, BOB, 1);
    }

    function testCannotUnstakeAnotherHoldersShares() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 120e6);
        vm.warp(HALF_LIFE);
        vm.startPrank(BOB);
        vm.expectRevert(IStakingRewards.InsufficientStake.selector);
        app.exitSR(srToken, 150e18);
        vm.expectRevert(IStakingRewards.InsufficientStake.selector);
        app.exitSR(srToken, 201e18);
        vm.stopPrank();
        vm.prank(CAROL);
        vm.expectRevert(IStakingRewards.InsufficientStake.selector);
        app.exitSR(srToken, 1e18);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 200e18);
        assertEq(IERC20(srToken).balanceOf(ALICE), 100e18);
        assertEq(IERC20(srToken).balanceOf(BOB), 100e18);
        assertRewards(ALICE, 60e6, 30e6, 30e6);
        assertRewards(BOB, 60e6, 30e6, 30e6);
        assertConservation(120e6, 0);
    }

    function testCannotDrainBackingOrRewardCustody() public {
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.prank(address(0x900));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, pool));
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

    function testPoolCustodianCannotSpendReservesThroughWrapper() public {
        app.transferAt(srToken, srToken, LedgerLib.SOURCE_ADDRESS, pool, address(0x901), 100e18);
        vm.prank(address(0x900));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, pool));
        IERC20(srToken).transfer(BOB, 100e18);
        assertEq(IERC20(srToken).balanceOf(address(0x900)), 100e18);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 0);
    }

    function testRewardDonationsPreserveShareValuation() public {
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 100e6);
        ledger.rawTransfer(rewardToken, rewardToken, address(this), rewardGroup, srToken, 25e6);
        assertRewards(ALICE, 62.5e6, 62.5e6, 0);
        assertRewards(BOB, 62.5e6, 62.5e6, 0);
        vm.prank(ALICE);
        app.exitSR(srToken, 100e18);
        assertConservation(125e6, 0);
    }

    function testDifferentDecimalsAndNestedRewardBacking() public {
        (address group_,) = ledger.addSubAccountGroup(rewardToken, rewardGroup, BACKING, "Nested Rewards", false);
        address second_ = factory.createStakingRewardToken(
            group_, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Six Decimals", "SIX", 6, "1")
        );
        app.issueSR(second_, ALICE, 100e6);
        rewards.reward(second_, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.claim(second_), 50e6);
        assertEq(IERC20(second_).balanceOf(ALICE), 100e6);
    }

    function testStakeAndRewardCanUseTheSameLedger() public {
        (address token_, address group_) = createRewardStakeProgram();
        app.issueSR(token_, ALICE, 100e6);
        fundSelf(token_, 100e6);
        assertEq(rewards.stakingRewardToken(token_).rewardLedger, token_);
        assertEq(rewards.stakingRewardToken(token_).rewardGroup, group_);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.claim(token_), 50e6);
        assertEq(IERC20(token_).balanceOf(ALICE), 150e6);
        assertEq(rewards.stakingRewardToken(token_).stakedBalance, 150e6);
    }

    // -- Explicit Reward Accounts --

    function predictSR(ILedgerTokenFactory.TokenMetadata memory metadata_) internal view returns (address) {
        return Create2.computeAddress(
            keccak256(abi.encode(metadata_.name, metadata_.symbol, metadata_.decimals, metadata_.version)),
            keccak256(
                abi.encodePacked(
                    type(StakingRewardsToken).creationCode,
                    abi.encode(address(dispatcher), metadata_.name, metadata_.symbol, metadata_.decimals)
                )
            ),
            address(dispatcher)
        );
    }

    function createRewardStakeProgram() internal returns (address token_, address group_) {
        ILedgerTokenFactory.TokenMetadata memory metadata_ =
            ILedgerTokenFactory.TokenMetadata("USD Cav", "USD.cav", 6, "1");
        token_ = predictSR(metadata_);
        group_ = LedgerLib.toAddress(token_, StakingRewardsLib.REWARDS_ADDRESS);
        assertEq(factory.createStakingRewardToken(group_, HALF_LIFE, metadata_), token_);
        // Keep the treasury subsidy out of eligible stake until distributed.
        (address treasury_,) = ledger.addSubAccountGroup(token_, token_, address(this), "Treasury", false);
        app.transferAt(token_, token_, LedgerLib.SOURCE_ADDRESS, treasury_, ALICE, 1e24);
    }

    function fundSelf(address token_, uint256 amount_) internal {
        app.rewardAt(token_, LedgerLib.toAddress(token_, address(this)), ALICE, amount_);
    }

    function testFundingFromStakeAllocatesAfterExitAndPreservesAvailableRewards() public {
        (address token_, address group_) = createRewardStakeProgram();
        app.issueSR(token_, ALICE, 120e6);
        app.issueSR(token_, BOB, 120e6);
        fundSelf(token_, 120e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        rewards.reward(token_, 60e6);
        assertApproxEqAbs(rewards.rewardsOf(token_, ALICE).pending, 40e6, 1);
        assertApproxEqAbs(rewards.rewardsOf(token_, ALICE).available, 30e6, 1);
        assertApproxEqAbs(rewards.rewardsOf(token_, BOB).pending, 80e6, 1);
        assertApproxEqAbs(rewards.rewardsOf(token_, BOB).available, 30e6, 1);
        assertEq(rewards.stakingRewardToken(token_).stakedBalance, 180e6);
        assertEq(ledgerView.balanceOf(token_, group_, token_), 180e6);
    }

    function testClaimDirectlyIntoSameProgramStake() public {
        (address token_, address group_) = createRewardStakeProgram();
        app.issueSR(token_, ALICE, 100e6);
        fundSelf(token_, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.claim(token_), 50e6);
        assertEq(IERC20(token_).balanceOf(ALICE), 150e6);
        assertEq(ledgerView.balanceOf(token_, group_, token_), 50e6);
        assertEq(rewards.rewardsOf(token_, ALICE).pending, 50e6);
        assertEq(rewards.rewardsOf(token_, ALICE).available, 0);
    }

    function testCrossProgramStakeFundingAndClaimsDoNotStakeRewardBacking() public {
        (address usd_, address group_) = createRewardStakeProgram();
        address cav_ = factory.createStakingRewardToken(
            group_, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Cav", "CAV", 18, "1")
        );
        app.issueSR(usd_, BOB, 120e6);
        app.issueSR(cav_, ALICE, 100e18);
        fundSelf(usd_, 120e6);
        app.rewardAt(cav_, LedgerLib.toAddress(usd_, address(this)), ALICE, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.claim(cav_), 50e6);
        assertEq(IERC20(usd_).balanceOf(ALICE), 50e6);
        assertEq(rewards.rewardsOf(usd_, ALICE).unclaimedUnits, 0);
        assertEq(rewards.rewardsOf(usd_, BOB).available, 60e6);
        vm.prank(BOB);
        rewards.reward(cav_, 60e6);
        assertEq(IERC20(usd_).balanceOf(BOB), 60e6);
        assertEq(rewards.stakingRewardToken(usd_).stakedBalance, 110e6);
        assertEq(ledgerView.balanceOf(usd_, group_, cav_), 110e6);
        assertEq(rewards.rewardsOf(usd_, cav_).unclaimedUnits, 0);
        assertEq(rewards.rewardsOf(cav_, ALICE).pending, 110e6);
    }

    function testFundingAllRemainingStakeRevertsWithoutReleasingPendingRewards() public {
        (address token_,) = createRewardStakeProgram();
        app.issueSR(token_, ALICE, 100e6);
        fundSelf(token_, 100e6);
        vm.warp(HALF_LIFE);
        bytes32 before_ = rewardAccountState(token_);
        vm.prank(ALICE);
        vm.expectRevert(IStakingRewards.NoStake.selector);
        rewards.reward(token_, 100e6);
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
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        rewards.reward(srToken, stakingGroup, 1);
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        rewards.claim(srToken, stakingGroup);
        vm.stopPrank();
        assertEq(ledgerView.balanceOf(rewardToken, group_, ALICE), 100e6);
        assertRewards(ALICE, 100e6, 50e6, 50e6);
    }

    function testExplicitAccountsRejectCreditAndGroupLeaves() public {
        (address credit_,) = ledger.addSubAccount(rewardToken, rewardToken, ALICE, "Credit", true);
        (address custody_,) = ledger.addSubAccountGroup(rewardToken, rewardToken, BOB, "Custody", false);
        stakeFor(ALICE, 100e18);
        stakeFor(BOB, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        address[2] memory holders_ = [ALICE, BOB];
        address[2] memory accounts_ = [credit_, custody_];
        for (uint256 i_; i_ < 2; ++i_) {
            vm.startPrank(holders_[i_]);
            vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, accounts_[i_]));
            rewards.reward(srToken, 1);
            vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, accounts_[i_]));
            rewards.claim(srToken);
            vm.stopPrank();
        }
    }

    function testApplicationCanFundFromPoolButPoolCannotClaimRewards() public {
        (address group_,) = ledger.addSubAccountGroup(rewardToken, rewardToken, address(0x900), "Pool", false);
        ledger.mint(rewardToken, group_, address(0x901), 100e6);
        stakeFor(ALICE, 100e18);
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, ALICE));
        app.rewardAt(srToken, group_, address(0x901), 100e6);
        app.rewardAt(srToken, group_, address(0x901), 100e6);
        assertRewards(ALICE, 100e6, 100e6, 0);
        vm.warp(HALF_LIFE);
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(pool, address(0x901)))
        );
        app.claimTo(srToken, pool, address(0x901), rewardToken, ALICE);
        assertEq(app.claimTo(srToken, srToken, ALICE, group_, address(0x901)), 50e6);
        assertEq(ledgerView.balanceOf(rewardToken, group_, address(0x901)), 50e6);
        vm.expectRevert(
            abi.encodeWithSelector(IStakingRewards.AccountReserved.selector, LedgerLib.toAddress(rewardGroup, srToken))
        );
        app.rewardAt(srToken, rewardGroup, srToken, 1);
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

    function testFuzzDefaultAndExplicitRootFundingClaimsMatch(
        uint256 alice_,
        uint256 bob_,
        uint256 funding_,
        uint256 elapsed_
    ) public {
        (address token_,) = createRewardStakeProgram();
        alice_ = bound(alice_, 1e6, 1e18);
        bob_ = bound(bob_, 1e6, 1e18);
        funding_ = bound(funding_, 1, alice_);
        elapsed_ = bound(elapsed_, 1, 4 * HALF_LIFE);
        app.issueSR(token_, ALICE, alice_);
        app.issueSR(token_, BOB, bob_);
        fundSelf(token_, 1e18);
        vm.warp(elapsed_);
        uint256 snapshot_ = vm.snapshotState();
        vm.startPrank(ALICE);
        rewards.reward(token_, funding_);
        uint256 claimed_ = rewards.claim(token_);
        vm.stopPrank();
        bytes32 direct_ = rewardAccountState(token_);
        assertTrue(vm.revertToStateAndDelete(snapshot_));
        vm.startPrank(ALICE);
        rewards.reward(token_, token_, funding_);
        assertEq(rewards.claim(token_, token_), claimed_);
        vm.stopPrank();
        assertEq(rewardAccountState(token_), direct_);
    }

    function testRemovedStakeSelectorIsUnavailable() public {
        bytes4 selector_ = bytes4(keccak256("stake(address,uint256,uint256)"));
        (bool success_, bytes memory data_) = address(dispatcher).call(abi.encodeWithSelector(selector_, srToken, 1, 0));
        assertFalse(success_);
        assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, selector_));
    }

    function testSRRewardBackingDoesNotEarnRecursively() public {
        (address token_, address group_) = createRewardStakeProgram();
        app.issueSR(token_, ALICE, 100e6);
        fundSelf(token_, 100e6);
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(group_, token_))
        );
        rewards.rewardsOfAccount(token_, group_, token_);
        assertEq(rewards.stakingRewardToken(token_).stakedBalance, 100e6);
        assertEq(rewards.rewardsOf(token_, ALICE).pending, 100e6);
    }

    function testCannotUseLedgerRootAsRewardGroup() public {
        vm.expectRevert(IStakingRewards.InvalidConfiguration.selector);
        factory.createStakingRewardToken(
            srToken, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Invalid", "BAD", 18, "1")
        );
    }

    function testRemovedUnstakeSelectorIsUnavailable() public {
        bytes4 selector_ = bytes4(keccak256("unstake(address,uint256,uint256)"));
        (bool success_, bytes memory data_) = address(dispatcher).call(abi.encodeWithSelector(selector_, srToken, 1, 0));
        assertFalse(success_);
        assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, selector_));
    }

    function testRemovedGroupCreationSelectorIsUnavailable() public {
        bytes4 selector_ =
            bytes4(keccak256("createStakingRewardToken(address,address,uint256,(string,string,uint8,string))"));
        assertEq(dispatcher.module(selector_), address(0));
    }

    function testRewardAssetMayBeAnSRLedger() public {
        address second_ = factory.createStakingRewardToken(
            stakeRewardGroup, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Second", "SR2", 6, "1")
        );
        app.issueSR(second_, ALICE, 100e6);
        stakeFor(BOB, 200e18);
        vm.prank(BOB);
        rewards.reward(second_, 100e18);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 100e18);
        assertEq(rewards.rewardsOf(second_, ALICE).pending, 100e18);
    }

    function testNestedReserveMovesLeaveStakeAndCheckpointsUnchanged() public {
        stakeFor(ALICE, 100e18);
        app.transferAt(srToken, srToken, LedgerLib.SOURCE_ADDRESS, pool, address(0x901), 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        bytes32 before_ = checkpointHash(ALICE);
        app.transferAt(srToken, pool, address(0x901), pool, address(0x902), 40e18);
        assertEq(checkpointHash(ALICE), before_);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 100e18);
        assertEq(IERC20(srToken).totalSupply(), 200e18);
    }

    function testNativeRewardUsesExistingLedgerCustody() public {
        address native_ = LedgerLib.NATIVE_ADDRESS;
        ledger.addNativeToken();
        (address group_,) = ledger.addSubAccountGroup(native_, native_, REWARDS, "Rewards", false);
        address second_ = factory.createStakingRewardToken(
            group_, HALF_LIFE, ILedgerTokenFactory.TokenMetadata("Native Rewards", "NATIVE", 18, "1")
        );
        app.issueSR(second_, ALICE, 100e18);
        vm.deal(address(this), 100 ether);
        ledger.wrap{value: 100 ether}(native_, 100 ether);
        rewards.reward(second_, 100 ether);
        vm.warp(HALF_LIFE);
        vm.prank(ALICE);
        assertEq(rewards.claim(second_), 50 ether);
        assertEq(ledgerView.balanceOf(native_, native_, ALICE), 50 ether);
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
        app.exitSR(srToken, 1e18);
        stakeFor(BOB, 1e18);
        stakeFor(CAROL, 1e18);
        rewards.reward(srToken, 80e6);
        uint256 supply_ = rewards.stakingRewardToken(srToken).rewards.unclaimedUnits;
        vm.prank(BOB);
        app.exitSR(srToken, 1e18);
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
        app.exitSR(srToken, 50e18);
        assertRewards(ALICE, 80e6, 60e6, 20e6);
        assertRewards(BOB, 20e6, 20e6, 0);
        assertConservation(100e6, 0);
    }

    function testArticleSoleUnitOwnerIsNotFinalStaker() public {
        seedEightyPendingTwentyAvailable();
        stakeFor(BOB, 100e18);
        vm.prank(ALICE);
        app.exitSR(srToken, 100e18);
        assertRewards(ALICE, 20e6, 0, 20e6);
        assertRewards(BOB, 80e6, 80e6, 0);
        vm.prank(BOB);
        app.exitSR(srToken, 100e18);
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
        emit IStakingRewards.Forfeited(
            srToken, LedgerLib.toAddress(stakingGroup, ALICE), 40e6 * StakingRewardsLib.UNIT_SCALE, 0
        );
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 50e18);
        // Retained stake is 50:25:25; Bob's incoming 50 earns none of the forfeiture.
        assertRewards(ALICE, 80e6, 60e6, 20e6);
        assertRewards(BOB, 10e6, 10e6, 0);
        assertRewards(CAROL, 10e6, 10e6, 0);
        assertEq(IERC20(srToken).balanceOf(BOB), 75e18);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 150e18);
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
        app.exitSR(srToken, 1);
        stakeFor(ALICE, 3);
        rewards.reward(srToken, 1);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 1);
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 3);
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, StakingRewardsLib.UNIT_SCALE);
        assertEq(rewards.rewardsOf(srToken, ALICE).pendingUnits, 0);
        assertEq(rewards.rewardsOf(srToken, BOB).unclaimedUnits, 0);
        assertEq(rewards.rewardsOf(srToken, BOB).pendingUnits, 0);
        assertRewards(CAROL, 2, 0, 2);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.pendingUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 3);
        assertConservation(3, 0);
        vm.prank(ALICE);
        assertEq(rewards.claim(srToken), 1);
        vm.prank(CAROL);
        assertEq(rewards.claim(srToken), 2);
        rewards.reward(srToken, 6);
        assertRewards(BOB, 6, 6, 0);
        assertConservation(9, 3);
        vm.prank(BOB);
        app.exitSR(srToken, 3);
        vm.prank(BOB);
        assertEq(rewards.claim(srToken), 6);
        assertConservation(9, 9);
    }

    function testPartialSoleHolderTransferRetainsExactPending() public {
        stakeFor(ALICE, 7);
        rewards.reward(srToken, 1);
        vm.warp(HALF_LIFE);
        IStakingRewards.Rewards memory before_ = rewards.rewardsOf(srToken, ALICE);
        uint256 residual_ = rewards.stakingRewardToken(srToken).allocationRemainderUnits;
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 4);
        IStakingRewards.Rewards memory after_ = rewards.rewardsOf(srToken, ALICE);
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

    function testRemovedSettlementSelectorIsUnavailable() public {
        // Neither an external caller nor a Dispatcher self-call can reach the removed hook.
        address[2] memory callers_ = [address(this), address(dispatcher)];
        for (uint256 i_; i_ < callers_.length; ++i_) {
            vm.prank(callers_[i_]);
            (bool success_, bytes memory data_) = address(dispatcher)
                .call(abi.encodeWithSelector(REMOVED_SETTLEMENT_SELECTOR, srToken, ALICE, BOB, false, false, 1));
            assertFalse(success_);
            assertEq(data_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, REMOVED_SETTLEMENT_SELECTOR));
        }
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
            model_.units += amount_ * StakingRewardsLib.UNIT_SCALE;
            referenceAllocate(model_, amount_ * StakingRewardsLib.UNIT_SCALE);
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
                app.exitSR(srToken, amount_);
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
                IStakingRewards.Rewards memory actual_ = rewards.rewardsOf(srToken, holders_[j_]);
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
            app.exitSR(srToken, stake_);
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
        app.exitSR(srToken, 50e18);
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
        IStakingRewards.Configuration memory config_ = rewards.stakingRewardToken(srToken);
        assertEq(config_.rewards.unclaimedUnits, StakingRewardsLib.UNIT_SCALE);
        assertEq(config_.allocationRemainderUnits, 1);
        stakeFor(BOB, 7);
        uint256 beforeSupply_ = config_.rewards.unclaimedUnits;
        vm.prank(ALICE);
        app.exitSR(srToken, 3);
        assertEq(rewards.rewardsOf(srToken, ALICE).pendingUnits, 0);
        assertEq(rewards.rewardsOf(srToken, ALICE).unclaimedUnits, 0);
        assertEq(rewards.stakingRewardToken(srToken).rewards.unclaimedUnits, beforeSupply_);
        assertConservation(1, 0);
        vm.prank(BOB);
        app.exitSR(srToken, 7);
        assertEq(rewards.rewardsOf(srToken, BOB).unclaimedUnits, beforeSupply_);
        assertEq(rewards.stakingRewardToken(srToken).allocationRemainderUnits, 0);
        vm.prank(BOB);
        assertEq(rewards.claim(srToken), 1);
        assertConservation(1, 1);
    }

    struct ConservationCache {
        IStakingRewards.Rewards alice;
        IStakingRewards.Rewards bob;
        IStakingRewards.Rewards carol;
        IStakingRewards.Configuration config;
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
        uint256 eligible_ =
            IERC20(srToken).balanceOf(ALICE) + IERC20(srToken).balanceOf(BOB) + IERC20(srToken).balanceOf(CAROL);
        assertEq(c.config.stakedBalance, eligible_);
        assertEq(IERC20(srToken).totalSupply(), eligible_ + ledgerView.balanceOf(srToken, srToken, address(0x900)));
        assertEq(
            ledgerView.creditBalanceOf(srToken, srToken, LedgerLib.SOURCE_ADDRESS),
            ledgerView.balanceOf(srToken, srToken, address(0x900))
        );
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
        app.exitSR(srToken, c.shares);
        assertApproxEqAbs(rewards.rewardsOf(srToken, ALICE).available, c.available, 1);
        c.shares = IERC20(srToken).balanceOf(BOB);
        vm.prank(BOB);
        app.exitSR(srToken, c.shares);
        c.shares = IERC20(srToken).balanceOf(CAROL);
        vm.prank(CAROL);
        app.exitSR(srToken, c.shares);
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
        IStakingRewards.Rewards memory expected_ = rewards.rewardsOf(srToken, ALICE);
        vm.revertToState(snapshot_);
        vm.warp(split_);
        // A new holder action checkpoints aggregate state without touching Alice.
        stakeFor(BOB, 1e18);
        vm.warp(elapsed_);
        IStakingRewards.Rewards memory actual_ = rewards.rewardsOf(srToken, ALICE);
        assertEq(actual_.unclaimedUnits, expected_.unclaimedUnits);
        assertApproxEqAbs(actual_.pending, expected_.pending, 1);
        assertApproxEqAbs(actual_.available, expected_.available, 1);
    }

    function testNestedReserveCannotClaimDespiteMatchingHolderKey() public {
        stakeFor(ALICE, 100e18);
        app.transferAt(srToken, srToken, LedgerLib.SOURCE_ADDRESS, pool, ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(pool, ALICE)));
        app.claimTo(srToken, pool, ALICE, rewardToken, ALICE);
        assertEq(app.claimTo(srToken, srToken, ALICE, rewardToken, ALICE), 50e6);
        assertEq(ledgerView.balanceOf(srToken, pool, ALICE), 100e18);
    }

    function testCustodyGroupCannotClaimDescendantRewards() public {
        app.transferAt(srToken, srToken, LedgerLib.SOURCE_ADDRESS, pool, BOB, 100e18);
        stakeFor(ALICE, 100e18);
        rewards.reward(srToken, 100e6);
        vm.warp(HALF_LIFE);
        vm.prank(address(0x900));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, pool));
        rewards.claim(srToken);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, pool));
        rewards.rewardsOf(srToken, address(0x900));
        assertRewards(ALICE, 100e6, 50e6, 50e6);
    }

    function testPublicSROperationsRejectCreditAccounts() public {
        stakeFor(ALICE, 100e18);
        address[2] memory credits_ = [LedgerLib.SOURCE_ADDRESS, StakingRewardsLib.STAKE_ADDRESS];
        for (uint256 i_; i_ < 2; ++i_) {
            bytes memory error_ = abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(srToken, credits_[i_])
            );
            vm.prank(ALICE);
            vm.expectRevert(error_);
            IERC20(srToken).transfer(credits_[i_], 1);
            vm.prank(credits_[i_]);
            vm.expectRevert(error_);
            rewards.claim(srToken);
            vm.expectRevert(error_);
            rewards.rewardsOf(srToken, credits_[i_]);
        }
    }

    /// @dev Check issuance and redemption through either credit leaf, for both eligible and reserve balances.
    function testFuzzCreditOffsetsAcrossIssuanceAndRedemption(uint128 amount_) public {
        uint256 value_ = bound(uint256(amount_), 1, 1e27);
        address[2] memory credits_ = [LedgerLib.SOURCE_ADDRESS, StakingRewardsLib.STAKE_ADDRESS];
        for (uint256 i_; i_ < credits_.length; ++i_) {
            app.transferAt(srToken, srToken, credits_[i_], srToken, ALICE, value_);
            assertEq(rewards.stakingRewardToken(srToken).stakedBalance, value_);
            assertEq(ledgerView.creditBalanceOf(srToken, srToken, LedgerLib.SOURCE_ADDRESS), 0);
            assertEq(IERC20(srToken).totalSupply(), value_);
            app.transferAt(srToken, srToken, ALICE, srToken, credits_[1 - i_], value_);
            assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 0);
            assertEq(IERC20(srToken).totalSupply(), 0);
            app.transferAt(srToken, srToken, credits_[i_], pool, address(0x901), value_);
            assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 0);
            assertEq(ledgerView.creditBalanceOf(srToken, srToken, LedgerLib.SOURCE_ADDRESS), value_);
            assertEq(IERC20(srToken).totalSupply(), value_);
            app.transferAt(srToken, pool, address(0x901), srToken, credits_[1 - i_], value_);
            assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 0);
            assertEq(ledgerView.creditBalanceOf(srToken, srToken, LedgerLib.SOURCE_ADDRESS), 0);
            assertEq(IERC20(srToken).totalSupply(), 0);
        }
    }

    function testWrapperEmitsExactlyOneTransfer() public {
        stakeFor(ALICE, 100);
        vm.recordLogs();
        vm.prank(ALICE);
        IERC20(srToken).transfer(BOB, 25);
        Vm.Log[] memory logs_ = vm.getRecordedLogs();
        uint256 count_;
        for (uint256 i_; i_ < logs_.length; ++i_) {
            if (logs_[i_].emitter != srToken || logs_[i_].topics[0] != keccak256("Transfer(address,address,uint256)")) {
                continue;
            }
            ++count_;
            assertEq(logs_[i_].topics[1], bytes32(uint256(uint160(ALICE))));
            assertEq(logs_[i_].topics[2], bytes32(uint256(uint160(BOB))));
            assertEq(abi.decode(logs_[i_].data, (uint256)), 25);
        }
        assertEq(count_, 1);
    }

    function testReservesCannotKeepEmptyProgramEligible() public {
        stakeFor(ALICE, 100);
        rewards.reward(srToken, 100);
        vm.prank(ALICE);
        app.exitSR(srToken, 100);
        assertEq(IERC20(srToken).totalSupply(), 100);
        assertEq(rewards.stakingRewardToken(srToken).stakedBalance, 0);
        assertRewards(ALICE, 100, 0, 100);
        vm.expectRevert(IStakingRewards.NoStake.selector);
        rewards.reward(srToken, 50);
        app.transferAt(srToken, pool, address(0x901), srToken, BOB, 100);
        rewards.reward(srToken, 50);
        assertRewards(BOB, 50, 50, 0);
        assertRewards(ALICE, 100, 0, 100);
    }
}
