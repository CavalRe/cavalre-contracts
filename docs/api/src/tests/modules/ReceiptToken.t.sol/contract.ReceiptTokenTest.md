# ReceiptTokenTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/tests/modules/ReceiptToken.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### dispatcher_

```solidity
Dispatcher internal dispatcher_
```


### app_

```solidity
ReceiptApplication internal app_
```


### factory_

```solidity
LedgerTokenFactory internal factory_
```


### prediction_

```solidity
LedgerTokenFactoryView internal prediction_
```


### receipt_

```solidity
ReceiptToken internal receipt_
```


### token_

```solidity
ReceiptWrapper internal token_
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
function create(bool credit_, uint8 backingDecimals_, uint8 receiptDecimals_, bool source_) internal;
```

### metadata


```solidity
function metadata(uint8 decimals_) internal pure returns (ILedgerTokenFactory.TokenMetadata memory);
```

### testReceiptRegistrationPacksBackingAndKeepsRootParent


```solidity
function testReceiptRegistrationPacksBackingAndKeepsRootParent() public;
```

### testPackedBackingPersistsAcrossViewReplacement


```solidity
function testPackedBackingPersistsAcrossViewReplacement() public;
```

### testReceiptBackingImmutableAndReplayPreservesAccounting


```solidity
function testReceiptBackingImmutableAndReplayPreservesAccounting() public;
```

### testReceiptViewReturnsNestedBackingSnapshot


```solidity
function testReceiptViewReturnsNestedBackingSnapshot() public;
```

### testReceiptViewRejectsNonReceiptAndOldLedgerViewSelectorIsAbsent


```solidity
function testReceiptViewRejectsNonReceiptAndOldLedgerViewSelectorIsAbsent() public;
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

### testRegisteredSourceCannotBeIssuedReceipts


```solidity
function testRegisteredSourceCannotBeIssuedReceipts() public;
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

### testOccupiedReceiptPredictionRejected


```solidity
function testOccupiedReceiptPredictionRejected() public;
```

### testBackingReferenceDoesNotExposePublicIssuanceOrRelease


```solidity
function testBackingReferenceDoesNotExposePublicIssuanceOrRelease() public;
```

### testFuzzProportionalRedemption


```solidity
function testFuzzProportionalRedemption(uint96 initial_, uint96 gain_, uint96 part_) public;
```

