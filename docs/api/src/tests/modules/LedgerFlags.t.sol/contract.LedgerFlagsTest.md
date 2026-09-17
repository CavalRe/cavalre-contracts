# LedgerFlagsTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/tests/modules/LedgerFlags.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### harness_

```solidity
LedgerKindHarness internal harness_ = new LedgerKindHarness()
```


## Functions
### testFuzzTypedKindPacking


```solidity
function testFuzzTypedKindPacking(uint8 kind_, address metadata_, uint8 depth_) public view;
```

### testUndefinedTokenKindRejected


```solidity
function testUndefinedTokenKindRejected() public;
```

### testInvalidEnumArgumentRejected


```solidity
function testInvalidEnumArgumentRejected() public;
```

