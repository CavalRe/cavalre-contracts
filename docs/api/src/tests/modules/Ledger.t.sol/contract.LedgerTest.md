# LedgerTest

[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/tests/modules/Ledger.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)

## State Variables

### router

```solidity
Router router
```

### ledgers

```solidity
TestLedger ledgers
```

### alice

```solidity
address alice = address(0xA11CE)
```

### bob

```solidity
address bob = address(0xB0B)
```

### charlie

```solidity
address charlie = address(0xCA11)
```

### native

```solidity
address native = LedgerLib.NATIVE_ADDRESS
```

### testLedger

```solidity
address testLedger
```

### externalToken

```solidity
MockERC20 externalToken
```

### unlistedToken

```solidity
MockERC20 unlistedToken
```

### externalWrapper

```solidity
address externalWrapper
```

### \_1

```solidity
address _1 = LedgerLib.toAddress("1")
```

### \_10

```solidity
address _10 = LedgerLib.toAddress("10")
```

### \_11

```solidity
address _11 = LedgerLib.toAddress("11")
```

### \_100

```solidity
address _100 = LedgerLib.toAddress("100")
```

### \_101

```solidity
address _101 = LedgerLib.toAddress("101")
```

### \_110

```solidity
address _110 = LedgerLib.toAddress("110")
```

### \_111

```solidity
address _111 = LedgerLib.toAddress("111")
```

### r1

```solidity
address r1
```

### r10

```solidity
address r10
```

### r11

```solidity
address r11
```

### r100

```solidity
address r100
```

### r101

```solidity
address r101
```

### r110

```solidity
address r110
```

### r111

```solidity
address r111
```

## Functions

### setUp

```solidity
function setUp() public;
```

### testLedgerInit

```solidity
function testLedgerInit() public;
```

### testLedgerAddSubAccountGroup

```solidity
function testLedgerAddSubAccountGroup() public;
```

### testLedgerAddSubAccountZeroParentReverts

```solidity
function testLedgerAddSubAccountZeroParentReverts() public;
```

### testLedgerAddSubAccountEmptyNameReverts

```solidity
function testLedgerAddSubAccountEmptyNameReverts() public;
```

### testLedgerRemoveSubAccountHappyPath

```solidity
function testLedgerRemoveSubAccountHappyPath() public;
```

### testLedgerRemoveSubAccountThatDoesNotExistReverts

```solidity
function testLedgerRemoveSubAccountThatDoesNotExistReverts() public;
```

### testLedgerRemoveSubAccountWithChildrenReverts

```solidity
function testLedgerRemoveSubAccountWithChildrenReverts() public;
```

### testLedgerRemoveSubAccountWithBalanceReverts

```solidity
function testLedgerRemoveSubAccountWithBalanceReverts() public;
```

### testLedgerRemoveSubAccountInvalidAddresses

```solidity
function testLedgerRemoveSubAccountInvalidAddresses() public;
```

### testLedgerRemoveUpdatesSiblingIndices

```solidity
function testLedgerRemoveUpdatesSiblingIndices() public;
```

### testLedgerParents

```solidity
function testLedgerParents() public view;
```

### testLedgerHasSubAccount

```solidity
function testLedgerHasSubAccount() public view;
```

### testLedgerMint

```solidity
function testLedgerMint() public;
```

### testLedgerBurn

```solidity
function testLedgerBurn() public;
```

### testLedgerReallocate

```solidity
function testLedgerReallocate() public;
```

### testLedgerWrap

```solidity
function testLedgerWrap() public;
```

### testLedgerWrapNative

```solidity
function testLedgerWrapNative() public;
```

### testLedgerWrapReentrancyGuard

```solidity
function testLedgerWrapReentrancyGuard() public;
```

### testLedgerWrapNativeIncorrectValue

```solidity
function testLedgerWrapNativeIncorrectValue() public;
```

### testLedgerWrapNonNativeRejectsValue

```solidity
function testLedgerWrapNonNativeRejectsValue() public;
```

### testLedgerUnwrapNative

```solidity
function testLedgerUnwrapNative() public;
```

### testLedgerUnwrapNativeRejectsValue

```solidity
function testLedgerUnwrapNativeRejectsValue() public;
```

### testLedgerUnwrapNonNativeRejectsValue

```solidity
function testLedgerUnwrapNonNativeRejectsValue() public;
```

### testLedgerTransfer

```solidity
function testLedgerTransfer() public;
```

## Errors

### InvalidInitialization

```solidity
error InvalidInitialization();
```
