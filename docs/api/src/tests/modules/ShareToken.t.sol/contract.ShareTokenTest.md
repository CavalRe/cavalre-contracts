# ShareTokenTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/tests/modules/ShareToken.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### dispatcher_

```solidity
Dispatcher internal dispatcher_
```


### app_

```solidity
ShareApplication internal app_
```


### factory_

```solidity
LedgerTokenFactory internal factory_
```


### prediction_

```solidity
LedgerTokenFactoryView internal prediction_
```


### token_

```solidity
ShareToken internal token_
```


### alice_

```solidity
address internal alice_ = address(0xa11ce)
```


### bob_

```solidity
address internal bob_ = address(0xb0b)
```


## Functions
### setUp


```solidity
function setUp() public;
```

### create


```solidity
function create(bool credit_, uint8 backingDecimals_, uint8 shareDecimals_, bool source_) internal;
```

### metadata


```solidity
function metadata(uint8 decimals_) internal pure returns (ILedgerTokenFactory.TokenMetadata memory);
```

### testShareTokenRegistrationStoresBackingAndPacksParent


```solidity
function testShareTokenRegistrationStoresBackingAndPacksParent() public;
```

### testBackingPersistsAcrossViewReplacement


```solidity
function testBackingPersistsAcrossViewReplacement() public;
```

### testShareTokenBackingImmutableAndReplayPreservesAccounting


```solidity
function testShareTokenBackingImmutableAndReplayPreservesAccounting() public;
```

### testShareTokenViewReturnsNestedBackingSnapshot


```solidity
function testShareTokenViewReturnsNestedBackingSnapshot() public;
```

### testShareTokenViewRejectsNonShareTokenAndOldLedgerViewSelectorIsAbsent


```solidity
function testShareTokenViewRejectsNonShareTokenAndOldLedgerViewSelectorIsAbsent() public;
```

### testDebitNonTokenBackingAndCompleteRedemption


```solidity
function testDebitNonTokenBackingAndCompleteRedemption() public;
```

### testCreditNestedBacking


```solidity
function testCreditNestedBacking() public;
```

### testSourceBacking


```solidity
function testSourceBacking() public;
```

### testCancellationAuthorizationAndOrphanBacking


```solidity
function testCancellationAuthorizationAndOrphanBacking() public;
```

### testRemovedCancellationSelectorCannotBurnShareTokens


```solidity
function testRemovedCancellationSelectorCannotBurnShareTokens() public;
```

### testRegisteredDebitCustodyShareTokenOperations


```solidity
function testRegisteredDebitCustodyShareTokenOperations() public;
```

### testNestedDebitCustodyShareTokenOperations


```solidity
function testNestedDebitCustodyShareTokenOperations() public;
```

### testUnauthorizedIssueAndRedemption


```solidity
function testUnauthorizedIssueAndRedemption() public;
```

### testBadSettlementRollsBack


```solidity
function testBadSettlementRollsBack() public;
```

### testRoundingAndZeroAmounts


```solidity
function testRoundingAndZeroAmounts() public;
```

### testZeroBackingLossAndDustRedemption


```solidity
function testZeroBackingLossAndDustRedemption() public;
```

### testDecimalDifferenceGuardAndZeroDecimals


```solidity
function testDecimalDifferenceGuardAndZeroDecimals() public;
```

### testFactoryPredictionIdempotenceAndInternalSeparation


```solidity
function testFactoryPredictionIdempotenceAndInternalSeparation() public;
```

### testSharedAllowanceAndRemovedTransferSelector


```solidity
function testSharedAllowanceAndRemovedTransferSelector() public;
```

### testInvalidShareTokenAccountsCannotIssueRedeemOrCancel


```solidity
function testInvalidShareTokenAccountsCannotIssueRedeemOrCancel() public;
```

### testInitialZeroDecimalsAndFloorIssuance


```solidity
function testInitialZeroDecimalsAndFloorIssuance() public;
```

### testFullPrecisionRatio


```solidity
function testFullPrecisionRatio() public;
```

### testInitializationScaleOverflow


```solidity
function testInitializationScaleOverflow() public;
```

### testOccupiedShareTokenPredictionRejected


```solidity
function testOccupiedShareTokenPredictionRejected() public;
```

### testBackingReferenceDoesNotExposePublicIssuanceOrRelease


```solidity
function testBackingReferenceDoesNotExposePublicIssuanceOrRelease() public;
```

### testFuzzProportionalRedemption


```solidity
function testFuzzProportionalRedemption(uint96 initial_, uint96 gain_, uint96 part_) public;
```

### assertShareTokenRoot


```solidity
function assertShareTokenRoot() internal view;
```

### testShareTokenCustodyProjectionAndPublicRestrictions


```solidity
function testShareTokenCustodyProjectionAndPublicRestrictions() public;
```

