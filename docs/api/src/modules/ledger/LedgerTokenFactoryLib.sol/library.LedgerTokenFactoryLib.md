# LedgerTokenFactoryLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/LedgerTokenFactoryLib.sol)


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

### createClaimToken


```solidity
function createClaimToken(address absoluteClaimAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
    internal
    returns (address _token, uint256 _flags);
```

