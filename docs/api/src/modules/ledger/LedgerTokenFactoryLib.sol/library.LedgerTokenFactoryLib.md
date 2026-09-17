# LedgerTokenFactoryLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/ledger/LedgerTokenFactoryLib.sol)


## Functions
### tokenSalt


```solidity
function tokenSalt(ILedgerTokenFactory.TokenMetadata memory token_) internal pure returns (bytes32);
```

### predictToken

Predict an ordinary internal ERC20Wrapper; receipts use different creation bytecode.


```solidity
function predictToken(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address _token);
```

### predictReceiptToken

Predict a ReceiptWrapper using shared metadata identity and dedicated creation bytecode.

Backing is not part of the salt. Reusing metadata with different backing must fail registration.


```solidity
function predictReceiptToken(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address);
```

### createInternalToken


```solidity
function createInternalToken(ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

### createReceiptToken

Deploy or replay a receipt wrapper and register its immutable backing through receipt code.

Trusted internal composition: the consuming module must authorize token creation.


```solidity
function createReceiptToken(address absoluteReceiptAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

