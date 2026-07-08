# LedgerTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/49d54302ba16f305aa5ba0622c305165383e18ed/tests/modules/Ledger.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### isVerbose

```solidity
bool isVerbose
```


### DEFAULT_SOURCE_NAME

```solidity
string internal constant DEFAULT_SOURCE_NAME = "Source"
```


### router

```solidity
Router router
```


### ledger

```solidity
TestLedger ledger
```


### tree

```solidity
Tree tree
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


### _1

```solidity
address _1 = LedgerLib.toAddress("1")
```


### _10

```solidity
address _10 = LedgerLib.toAddress("10")
```


### _11

```solidity
address _11 = LedgerLib.toAddress("11")
```


### _100

```solidity
address _100 = LedgerLib.toAddress("100")
```


### _101

```solidity
address _101 = LedgerLib.toAddress("101")
```


### _110

```solidity
address _110 = LedgerLib.toAddress("110")
```


### _111

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


### source_

```solidity
address source_
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

### testNativeWrapperNotCreatedDuringInit


```solidity
function testNativeWrapperNotCreatedDuringInit() public view;
```

### testLedgerAddNativeTokenAndCreateWrapper


```solidity
function testLedgerAddNativeTokenAndCreateWrapper() public;
```

### testLedgerAddNativeTokenUsesConfiguredNativeDecimals


```solidity
function testLedgerAddNativeTokenUsesConfiguredNativeDecimals() public;
```

### testLedgerCreateWrapperCanonicalRootIsIdempotent


```solidity
function testLedgerCreateWrapperCanonicalRootIsIdempotent() public;
```

### testLedgerCreateWrapperInternalRootIsIdempotent


```solidity
function testLedgerCreateWrapperInternalRootIsIdempotent() public;
```

### testLedgerCreateInternalTokenDoesNotRegisterUnderRoot


```solidity
function testLedgerCreateInternalTokenDoesNotRegisterUnderRoot() public;
```

### testLedgerCreateInternalTokenIsIdempotent


```solidity
function testLedgerCreateInternalTokenIsIdempotent() public;
```

### testLedgerCreateClaimTokenIsIdempotent


```solidity
function testLedgerCreateClaimTokenIsIdempotent() public;
```

### testLedgerWrapRejectsClaimRoot


```solidity
function testLedgerWrapRejectsClaimRoot() public;
```

### testLedgerUnwrapRejectsClaimRoot


```solidity
function testLedgerUnwrapRejectsClaimRoot() public;
```

### testLedgerCreateClaimTokenRejectsUnregisteredClaimAccount


```solidity
function testLedgerCreateClaimTokenRejectsUnregisteredClaimAccount() public;
```

### testLedgerCreateClaimTokenRejectsGroupClaimAccount


```solidity
function testLedgerCreateClaimTokenRejectsGroupClaimAccount() public;
```

### testLedgerCreateClaimTokenRejectsNestedClaimRoot


```solidity
function testLedgerCreateClaimTokenRejectsNestedClaimRoot() public;
```

### testLedgerAddExternalTokenAndCreateWrapperAreIdempotent


```solidity
function testLedgerAddExternalTokenAndCreateWrapperAreIdempotent() public;
```

### testLedgerRootFlagsByTokenType


```solidity
function testLedgerRootFlagsByTokenType() public view;
```

### testLedgerEffectiveFlags


```solidity
function testLedgerEffectiveFlags() public;
```

### testLedgerBalanceOfUsesEffectivePolarity


```solidity
function testLedgerBalanceOfUsesEffectivePolarity() public;
```

### testPackedParentAndWrapperMapping


```solidity
function testPackedParentAndWrapperMapping() public view;
```

### testLedgerAddSubAccountGroup


```solidity
function testLedgerAddSubAccountGroup() public;
```

### testLedgerAddSubAccountGroupAddressFormIsIdempotent


```solidity
function testLedgerAddSubAccountGroupAddressFormIsIdempotent() public;
```

### testLedgerAddSubAccountGroupRejectsFundedDebitLeaf


```solidity
function testLedgerAddSubAccountGroupRejectsFundedDebitLeaf() public;
```

### testLedgerAddSubAccountGroupRejectsFundedCreditLeaf


```solidity
function testLedgerAddSubAccountGroupRejectsFundedCreditLeaf() public;
```

### testLedgerAddSubAccountNameDelegatesToAddressForm


```solidity
function testLedgerAddSubAccountNameDelegatesToAddressForm() public;
```

### testLedgerAddSubAccountIsIdempotent


```solidity
function testLedgerAddSubAccountIsIdempotent() public;
```

### testLedgerAddSubAccountRegistersFundedDebitLeaf


```solidity
function testLedgerAddSubAccountRegistersFundedDebitLeaf() public;
```

### testLedgerAddSubAccountRejectsFundedDebitLeafAsCredit


```solidity
function testLedgerAddSubAccountRejectsFundedDebitLeafAsCredit() public;
```

### testLedgerAddSubAccountRejectsFundedCreditLeafAsDebit


```solidity
function testLedgerAddSubAccountRejectsFundedCreditLeafAsDebit() public;
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

### testLedgerRemoveSubAccountGroupIsIdempotent


```solidity
function testLedgerRemoveSubAccountGroupIsIdempotent() public;
```

### testLedgerRemoveSubAccountGroupAddressForm


```solidity
function testLedgerRemoveSubAccountGroupAddressForm() public;
```

### testLedgerRemoveSubAccountNameDelegatesToAddressForm


```solidity
function testLedgerRemoveSubAccountNameDelegatesToAddressForm() public;
```

### testLedgerRemoveSubAccountIsIdempotent


```solidity
function testLedgerRemoveSubAccountIsIdempotent() public;
```

### testLedgerRemoveSubAccountMissingGroupIsIdempotent


```solidity
function testLedgerRemoveSubAccountMissingGroupIsIdempotent() public;
```

### testLedgerRemoveSubAccountMissingLeafIsIdempotent


```solidity
function testLedgerRemoveSubAccountMissingLeafIsIdempotent() public;
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

### testLedgerWrapExternalToken


```solidity
function testLedgerWrapExternalToken() public;
```

### testLedgerWrapExternalTokenRejectsDirectValue


```solidity
function testLedgerWrapExternalTokenRejectsDirectValue() public;
```

### testLedgerEnforceNativeValue


```solidity
function testLedgerEnforceNativeValue() public;
```

### testLedgerUnwrapExternalToken


```solidity
function testLedgerUnwrapExternalToken() public;
```

### testLedgerUnwrapExternalTokenRejectsDirectValue


```solidity
function testLedgerUnwrapExternalTokenRejectsDirectValue() public;
```

### testLedgerUnwrapExternalTokenAfterNativeWrapAllowsCallValue


```solidity
function testLedgerUnwrapExternalTokenAfterNativeWrapAllowsCallValue() public;
```

### testLedgerWrapExternalTokenAfterNativeWrapAllowsCallValue


```solidity
function testLedgerWrapExternalTokenAfterNativeWrapAllowsCallValue() public;
```

### testLedgerWrapClaimRootReverts


```solidity
function testLedgerWrapClaimRootReverts() public;
```

### testLedgerUnwrapClaimRootReverts


```solidity
function testLedgerUnwrapClaimRootReverts() public;
```

### testLedgerTransfer


```solidity
function testLedgerTransfer() public;
```

### testLedgerTransferAcrossSiblingBranchesPreservesAncestorBalance


```solidity
function testLedgerTransferAcrossSiblingBranchesPreservesAncestorBalance() public;
```

### testLedgerTransferRejectsCreditFromParent


```solidity
function testLedgerTransferRejectsCreditFromParent() public;
```

### testLedgerTransferInsufficientBalanceReportsDeepUnregisteredLeafContext


```solidity
function testLedgerTransferInsufficientBalanceReportsDeepUnregisteredLeafContext() public;
```

## Errors
### InvalidInitialization

```solidity
error InvalidInitialization();
```

