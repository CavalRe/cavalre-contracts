# StakingRewardTokenTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/tests/modules/StakingRewardToken.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## Constants
### ALICE

```solidity
address internal constant ALICE = address(0xa11ce)
```


### BOB

```solidity
address internal constant BOB = address(0xb0b)
```


### CAROL

```solidity
address internal constant CAROL = address(0xca201)
```


### BACKING

```solidity
address internal constant BACKING = address(0x51a)
```


### REWARDS

```solidity
address internal constant REWARDS = address(0x52b)
```


### HALF_LIFE

```solidity
uint256 internal constant HALF_LIFE = 7 days
```


## State Variables
### dispatcher

```solidity
Dispatcher internal dispatcher
```


### ledger

```solidity
TestLedger internal ledger
```


### ledgerView

```solidity
LedgerView internal ledgerView
```


### factory

```solidity
LedgerTokenFactory internal factory
```


### factoryImplementation

```solidity
address internal factoryImplementation
```


### metadata

```solidity
ILedgerTokenFactory.TokenMetadata internal metadata
```


### rewards

```solidity
IStakingRewardToken internal rewards
```


### stakeToken

```solidity
address internal stakeToken
```


### rewardToken

```solidity
address internal rewardToken
```


### srToken

```solidity
address internal srToken
```


### stakingGroup

```solidity
address internal stakingGroup
```


### rewardGroup

```solidity
address internal rewardGroup
```


### stakeRewardGroup

```solidity
address internal stakeRewardGroup
```


## Functions
### setUp


```solidity
function setUp() public;
```

### stakeFor


```solidity
function stakeFor(address holder_, uint256 amount_) internal;
```

### assertRewards


```solidity
function assertRewards(address holder_, uint256 unclaimed_, uint256 pending_, uint256 available_) internal view;
```

### testConfigurationOwnedBySR


```solidity
function testConfigurationOwnedBySR() public;
```

### testConfigurationCannotChange


```solidity
function testConfigurationCannotChange() public;
```

### testCreationIsIdempotentWithoutResettingRewards


```solidity
function testCreationIsIdempotentWithoutResettingRewards() public;
```

### testCreationDoesNotRequireFactoryModule


```solidity
function testCreationDoesNotRequireFactoryModule() public;
```

### testModuleFitsDeploymentLimit


```solidity
function testModuleFitsDeploymentLimit() public;
```

### testSROperationsSettleWithoutDispatchingTransferHook


```solidity
function testSROperationsSettleWithoutDispatchingTransferHook() public;
```

### testInvalidConfiguration


```solidity
function testInvalidConfiguration() public;
```

### testCannotAdoptAnExistingTokenSupply


```solidity
function testCannotAdoptAnExistingTokenSupply() public;
```

### testCannotUseCreditBacking


```solidity
function testCannotUseCreditBacking() public;
```

### testCannotConfigureTwoProgramsOnOneBackingAccount


```solidity
function testCannotConfigureTwoProgramsOnOneBackingAccount() public;
```

### testFundingRequiresStake


```solidity
function testFundingRequiresStake() public;
```

### testClaimAllLeavesOnlyPendingUnits


```solidity
function testClaimAllLeavesOnlyPendingUnits() public;
```

### testClaimAllClearsAvailableUnitsWhenTokenPayoutRoundsToZero


```solidity
function testClaimAllClearsAvailableUnitsWhenTokenPayoutRoundsToZero() public;
```

### testNewStakeDoesNotReceivePreviouslyFundedRewards


```solidity
function testNewStakeDoesNotReceivePreviouslyFundedRewards() public;
```

### testForfeiturePreservesUnitsAndLaterFundingUsesUnitPrice


```solidity
function testForfeiturePreservesUnitsAndLaterFundingUsesUnitPrice() public;
```

### testPartialExitPreservesAvailableRewardValue


```solidity
function testPartialExitPreservesAvailableRewardValue() public;
```

### testFinalHolderReceivesAllRemainingRewards


```solidity
function testFinalHolderReceivesAllRemainingRewards() public;
```

### testPartialSoleHolderExitRetainsPendingRewards


```solidity
function testPartialSoleHolderExitRetainsPendingRewards() public;
```

### testLastStakerReleasePreservesExitedHolderRewards


```solidity
function testLastStakerReleasePreservesExitedHolderRewards() public;
```

### testNewStakerPreventsFinalStakerRelease


```solidity
function testNewStakerPreventsFinalStakerRelease() public;
```

### testImmediateFinalExitAndRestart


```solidity
function testImmediateFinalExitAndRestart() public;
```

### testFinalExitMakesSmallPendingRewardClaimable


```solidity
function testFinalExitMakesSmallPendingRewardClaimable() public;
```

### testFullyAvailableFinalExitHasNoDivisionByZero


```solidity
function testFullyAvailableFinalExitHasNoDivisionByZero() public;
```

### testWrapperTransferSettlesBothHolders


```solidity
function testWrapperTransferSettlesBothHolders() public;
```

### testWrapperTransferFromSettlesRewards


```solidity
function testWrapperTransferFromSettlesRewards() public;
```

### testDirectLedgerTransferIsUnavailable


```solidity
function testDirectLedgerTransferIsUnavailable() public;
```

### testInternalLedgerTransfersToNestedAccountsSettleRewards


```solidity
function testInternalLedgerTransfersToNestedAccountsSettleRewards() public;
```

### testSelfAndZeroTransfersDoNotForfeit


```solidity
function testSelfAndZeroTransfersDoNotForfeit() public;
```

### testCannotBypassSRMintOrBurnAccounting


```solidity
function testCannotBypassSRMintOrBurnAccounting() public;
```

### testCannotUnstakeAnotherHoldersShares


```solidity
function testCannotUnstakeAnotherHoldersShares() public;
```

### testCannotDrainBackingOrRewardCustody


```solidity
function testCannotDrainBackingOrRewardCustody() public;
```

### testBackingHolderCannotMintAgainstASelfTransfer


```solidity
function testBackingHolderCannotMintAgainstASelfTransfer() public;
```

### testSlippageAndDonations


```solidity
function testSlippageAndDonations() public;
```

### testDifferentDecimalsAndNestedBacking


```solidity
function testDifferentDecimalsAndNestedBacking() public;
```

### testStakeAndRewardCanUseTheSameLedger


```solidity
function testStakeAndRewardCanUseTheSameLedger() public;
```

### testStakingAnotherSRTokenSettlesBothAssetTransfers


```solidity
function testStakingAnotherSRTokenSettlesBothAssetTransfers() public;
```

### testRewardingAnotherSRTokenSettlesFundingAndClaimTransfers


```solidity
function testRewardingAnotherSRTokenSettlesFundingAndClaimTransfers() public;
```

### testNestedRewardCustodyCannotSpendThroughOuterWrapper


```solidity
function testNestedRewardCustodyCannotSpendThroughOuterWrapper() public;
```

### testNativeStakeUsesExistingLedgerCustody


```solidity
function testNativeStakeUsesExistingLedgerCustody() public;
```

### seedEightyPendingTwentyAvailable


```solidity
function seedEightyPendingTwentyAvailable() internal;
```

### testArticleExitedHolderExcludedFromForfeiture


```solidity
function testArticleExitedHolderExcludedFromForfeiture() public;
```

### testArticlePartialUnstake


```solidity
function testArticlePartialUnstake() public;
```

### testArticleSoleUnitOwnerIsNotFinalStaker


```solidity
function testArticleSoleUnitOwnerIsNotFinalStaker() public;
```

### testArticlePartialAndFullTransfer


```solidity
function testArticlePartialAndFullTransfer() public;
```

### testArticleMixedPositions


```solidity
function testArticleMixedPositions() public;
```

### testArticleContinuedFundingDoesNotRestartVesting


```solidity
function testArticleContinuedFundingDoesNotRestartVesting() public;
```

### testSettlementSelectorRejectsExternalCallers


```solidity
function testSettlementSelectorRejectsExternalCallers() public;
```

### referenceAllocate


```solidity
function referenceAllocate(ReferenceState memory model_, uint256 units_) internal pure;
```

### referenceStep


```solidity
function referenceStep(ReferenceState memory model_, uint256 random_) internal;
```

### testFuzzAgainstIndependentEagerReference


```solidity
function testFuzzAgainstIndependentEagerReference(uint256 seed_) public;
```

### checkpointHash


```solidity
function checkpointHash(address holder_) internal view returns (bytes32 digest_);
```

### testSelfAndZeroTransfersLeaveRewardStorageUntouched


```solidity
function testSelfAndZeroTransfersLeaveRewardStorageUntouched() public;
```

### testTransferAndForfeitureDoNotPostRewardShares


```solidity
function testTransferAndForfeitureDoNotPostRewardShares() public;
```

### testAllocationResidualPreservesSupplyAndClearsOnFinalExit


```solidity
function testAllocationResidualPreservesSupplyAndClearsOnFinalExit() public;
```

### assertConservation


```solidity
function assertConservation(uint256 funded_, uint256 claimed_) internal view;
```

### testFuzzConservationAcrossFundingTransfersClaimsAndExits


```solidity
function testFuzzConservationAcrossFundingTransfersClaimsAndExits(uint256 seed_) public;
```

### testFuzzCheckpointTimingDoesNotChangeEntitlement


```solidity
function testFuzzCheckpointTimingDoesNotChangeEntitlement(uint256 elapsed_, uint256 split_) public;
```

### testNestedClaimAndUnstakeUseExplicitAccountingContext


```solidity
function testNestedClaimAndUnstakeUseExplicitAccountingContext() public;
```

### testCustodyGroupCannotClaimDescendantRewards


```solidity
function testCustodyGroupCannotClaimDescendantRewards() public;
```

### testPublicStakingOperationsRejectCreditAccounts


```solidity
function testPublicStakingOperationsRejectCreditAccounts() public;
```

## Structs
### ClaimAllCache

```solidity
struct ClaimAllCache {
    IStakingRewardToken.Rewards beforeClaim;
    IStakingRewardToken.Rewards afterClaim;
}
```

### NestedRewardCache

```solidity
struct NestedRewardCache {
    address token;
    address holder;
    IStakingRewardToken.Rewards beforeClaim;
    IStakingRewardToken.Rewards afterClaim;
}
```

### ReferencePosition

```solidity
struct ReferencePosition {
    uint256 stake;
    uint256 units;
    uint256 pending;
}
```

### ReferenceState

```solidity
struct ReferenceState {
    ReferencePosition[3] positions;
    uint256 stake;
    uint256 units;
    uint256 remainder;
    uint256 funded;
    uint256 stakeAdded;
}
```

### ConservationCache

```solidity
struct ConservationCache {
    IStakingRewardToken.Rewards alice;
    IStakingRewardToken.Rewards bob;
    IStakingRewardToken.Rewards carol;
    IStakingRewardToken.Configuration config;
}
```

### FuzzCache

```solidity
struct FuzzCache {
    uint256 funded;
    uint256 claimed;
    uint256 available;
    uint256 shares;
}
```

