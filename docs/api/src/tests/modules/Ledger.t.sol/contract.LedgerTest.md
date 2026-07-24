# LedgerTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/tests/modules/Ledger.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### isVerbose

```solidity
bool isVerbose
```


### dispatcher

```solidity
Dispatcher dispatcher
```


### ledger

```solidity
TestLedger ledger
```


### ledgerTokenFactory

```solidity
LedgerTokenFactory ledgerTokenFactory
```


### ledgerTokenFactoryView

```solidity
LedgerTokenFactoryView ledgerTokenFactoryView
```


### ledgerView

```solidity
LedgerView ledgerView
```


### tree

```solidity
TreeView tree
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

### createInternalToken


```solidity
function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    internal
    returns (address _tokenAddress, uint256 _flags);
```

### createClaimToken


```solidity
function createClaimToken(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address root_,
    address holderParent_,
    address relative_,
    string memory version_
) internal returns (address _tokenAddress, uint256 _flags);
```

### addExternalToken


```solidity
function addExternalToken(address token_) internal returns (uint256 _flags);
```

### testLedgerInit


```solidity
function testLedgerInit() public;
```

### testNativeWrapperNotCreatedDuringInit


```solidity
function testNativeWrapperNotCreatedDuringInit() public view;
```

### testLedgerAddNativeTokenIsIdempotentWithoutWrapper


```solidity
function testLedgerAddNativeTokenIsIdempotentWithoutWrapper() public;
```

### testLedgerRootRegistryListsRegisteredRoots


```solidity
function testLedgerRootRegistryListsRegisteredRoots() public view;
```

### testLedgerRootRegistryTracksAllRootTypesWithoutDuplicates


```solidity
function testLedgerRootRegistryTracksAllRootTypesWithoutDuplicates() public;
```

### testLedgerAddNativeTokenUsesConfiguredNativeDecimals


```solidity
function testLedgerAddNativeTokenUsesConfiguredNativeDecimals() public;
```

### testLedgerCreateInternalTokenDoesNotRegisterUnderRoot


```solidity
function testLedgerCreateInternalTokenDoesNotRegisterUnderRoot() public;
```

### testLedgerTokenFactoryViewPredictsCreatedToken


```solidity
function testLedgerTokenFactoryViewPredictsCreatedToken() public;
```

### testLedgerCreateInternalTokenIsIdempotent


```solidity
function testLedgerCreateInternalTokenIsIdempotent() public;
```

### testLedgerCreateInternalTokenVersionChangesAddressOnly


```solidity
function testLedgerCreateInternalTokenVersionChangesAddressOnly() public;
```

### testLedgerCreateClaimTokenIsIdempotent


```solidity
function testLedgerCreateClaimTokenIsIdempotent() public;
```

### testLedgerCreateClaimTokenVersionChangesAddressOnly


```solidity
function testLedgerCreateClaimTokenVersionChangesAddressOnly() public;
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

### testLedgerAddExternalTokenIsIdempotentWithoutWrapper


```solidity
function testLedgerAddExternalTokenIsIdempotentWithoutWrapper() public;
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

### testLedgerWrapExternalTokenUsesExplicitPayer


```solidity
function testLedgerWrapExternalTokenUsesExplicitPayer() public;
```

### testLedgerWrapExternalTokenRejectsDirectValue


```solidity
function testLedgerWrapExternalTokenRejectsDirectValue() public;
```

### testLedgerWrapRejectsFeeOnTransferToken


```solidity
function testLedgerWrapRejectsFeeOnTransferToken() public;
```

### testLedgerUnwrapRejectsFeeOnTransferToken


```solidity
function testLedgerUnwrapRejectsFeeOnTransferToken() public;
```

### testLedgerHandleNativeWrapsMsgValueToSender


```solidity
function testLedgerHandleNativeWrapsMsgValueToSender() public;
```

### testLedgerWrapNativeRejectsExplicitNonCallerPayer


```solidity
function testLedgerWrapNativeRejectsExplicitNonCallerPayer() public;
```

### testLedgerUnwrapNativeUsesExplicitRecipient


```solidity
function testLedgerUnwrapNativeUsesExplicitRecipient() public;
```

### testDispatcherReceiveWrapsNativeToOriginalSender


```solidity
function testDispatcherReceiveWrapsNativeToOriginalSender() public;
```

### testLedgerEnforceNativeValue


```solidity
function testLedgerEnforceNativeValue() public;
```

### testLedgerUnwrapExternalToken


```solidity
function testLedgerUnwrapExternalToken() public;
```

### testLedgerUnwrapExternalTokenUsesExplicitRecipient


```solidity
function testLedgerUnwrapExternalTokenUsesExplicitRecipient() public;
```

### testLedgerUnwrapExternalTokenRevertsWhenUndercollateralized


```solidity
function testLedgerUnwrapExternalTokenRevertsWhenUndercollateralized() public;
```

### testLedgerUnwrapExternalTokenRejectsDirectValue


```solidity
function testLedgerUnwrapExternalTokenRejectsDirectValue() public;
```

### testLedgerUnwrapNativeRevertsWhenUndercollateralized


```solidity
function testLedgerUnwrapNativeRevertsWhenUndercollateralized() public;
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

### testLedgerWrap


```solidity
function testLedgerWrap() public;
```

### testLedgerWrapUsesExplicitSourceNotCaller


```solidity
function testLedgerWrapUsesExplicitSourceNotCaller() public;
```

### testLedgerWrapInvalidSourceParentReverts


```solidity
function testLedgerWrapInvalidSourceParentReverts() public;
```

### testLedgerWrapCrossRootSourceRevertsDifferentRoots


```solidity
function testLedgerWrapCrossRootSourceRevertsDifferentRoots() public;
```

### testLedgerWrapRequiresCreditSourceAndDebitDestination


```solidity
function testLedgerWrapRequiresCreditSourceAndDebitDestination() public;
```

### testLedgerUnwrapToDifferentEmptyCreditSourceReverts


```solidity
function testLedgerUnwrapToDifferentEmptyCreditSourceReverts() public;
```

### testLedgerUnwrapRequiresDebitSourceAndCreditDestination


```solidity
function testLedgerUnwrapRequiresDebitSourceAndCreditDestination() public;
```

### testLedgerUnwrapDoesNotRequireCallerLedgerBalance


```solidity
function testLedgerUnwrapDoesNotRequireCallerLedgerBalance() public;
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

### testLedgerExplicitTransferAuthenticatesBeforeAccounting


```solidity
function testLedgerExplicitTransferAuthenticatesBeforeAccounting() public;
```

### testLedgerTransferAcrossSiblingBranchesPreservesAncestorBalance


```solidity
function testLedgerTransferAcrossSiblingBranchesPreservesAncestorBalance() public;
```

### testLedgerTransferUsesLeafPolarityThroughMixedPolarityParents


```solidity
function testLedgerTransferUsesLeafPolarityThroughMixedPolarityParents() public;
```

### testLedgerDeepTransferDoesNotEmitLegacyTransferEvent


```solidity
function testLedgerDeepTransferDoesNotEmitLegacyTransferEvent() public;
```

### testLedgerDeepTransferEmitsCreditAndDebitEvents


```solidity
function testLedgerDeepTransferEmitsCreditAndDebitEvents() public;
```

### testLedgerTransferRejectsCreditFromParent


```solidity
function testLedgerTransferRejectsCreditFromParent() public;
```

### testLedgerTransferAllowsBurnToZeroAddress


```solidity
function testLedgerTransferAllowsBurnToZeroAddress() public;
```

### testLedgerTransferRejectsMintFromZeroAddress


```solidity
function testLedgerTransferRejectsMintFromZeroAddress() public;
```

### testLedgerTransferRejectsMintFromCreditLeaf


```solidity
function testLedgerTransferRejectsMintFromCreditLeaf() public;
```

### testLedgerTransferAllowsBurnToCreditLeaf


```solidity
function testLedgerTransferAllowsBurnToCreditLeaf() public;
```

### testLedgerTransferAllowsCreditToCredit


```solidity
function testLedgerTransferAllowsCreditToCredit() public;
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

