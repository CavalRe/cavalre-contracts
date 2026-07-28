# LedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/ledger/LedgerTokenFactory.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### signatures


```solidity
function signatures() external pure virtual override returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory _selectors);
```

### createInternalToken


```solidity
function createInternalToken(ILedgerTokenFactory.TokenMetadata[] memory tokens_)
    external
    returns (address[] memory _tokenAddresses, uint256[] memory _flags);
```

### createReceiptToken


```solidity
function createReceiptToken(address absoluteReceiptAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
    external
    returns (address _tokenAddress, uint256 _flags);
```

