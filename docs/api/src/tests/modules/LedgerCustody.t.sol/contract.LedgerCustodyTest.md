# LedgerCustodyTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/tests/modules/LedgerCustody.t.sol)

**Inherits:**
[ERC20WrapperTest](/tests/modules/ERC20Wrapper.t.sol/contract.ERC20WrapperTest.md)


## Functions
### makeCustodian


```solidity
function makeCustodian(address holder_, bool credit_) internal returns (Custodian memory c);
```

### assertSupply


```solidity
function assertSupply() internal view;
```

### testFuzzCustodianProjection


```solidity
function testFuzzCustodianProjection(bool fromCredit_, bool toCredit_, bool fromLeafCredit_, bool toLeafCredit_)
    public;
```

### testRecursiveDeepEffectiveLeavesAndNoAccountingAlias


```solidity
function testRecursiveDeepEffectiveLeavesAndNoAccountingAlias() public;
```

### testRecursiveAddressRejectsFormerHolderFlattening


```solidity
function testRecursiveAddressRejectsFormerHolderFlattening() public;
```

### testSelfInternalAndZeroEventsKeepCustodyBalances


```solidity
function testSelfInternalAndZeroEventsKeepCustodyBalances() public;
```

### testPublicCustodyRestrictionsAndSelfTransferAllowance


```solidity
function testPublicCustodyRestrictionsAndSelfTransferAllowance() public;
```

### testFuzzCustodyConservationAcrossPostings


```solidity
function testFuzzCustodyConservationAcrossPostings(uint256 seed_) public;
```

### testFuzzExternalAndNativeWrappingPreserveRootSupply


```solidity
function testFuzzExternalAndNativeWrappingPreserveRootSupply(uint96 amount_) public;
```

## Structs
### Custodian

```solidity
struct Custodian {
    address holder;
    address absolute;
    bool credit;
}
```

