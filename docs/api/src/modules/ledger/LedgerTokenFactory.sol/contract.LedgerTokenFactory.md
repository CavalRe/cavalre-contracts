# LedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/LedgerTokenFactory.sol)

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

### createClaimToken


```solidity
function createClaimToken(address absoluteClaimAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
    external
    returns (address _tokenAddress, uint256 _flags);
```

