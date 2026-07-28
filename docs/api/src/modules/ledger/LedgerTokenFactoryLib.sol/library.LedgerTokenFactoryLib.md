# LedgerTokenFactoryLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/ledger/LedgerTokenFactoryLib.sol)


## Functions
### tokenSalt


```solidity
function tokenSalt(ILedgerTokenFactory.TokenMetadata memory token_) internal pure returns (bytes32);
```

### predictToken


```solidity
function predictToken(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address _token);
```

### createInternalToken


```solidity
function createInternalToken(ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

### createReceiptToken


```solidity
function createReceiptToken(address absoluteReceiptAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

