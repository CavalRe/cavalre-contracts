# LedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/LedgerTokenFactory.sol)

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

### createInternalTokens


```solidity
function createInternalTokens(ILedgerTokenFactory.TokenMetadata[] memory tokens_)
    external
    returns (address[] memory _tokenAddresses, uint256[] memory _flags);
```

### createShareTokens

Create share tokens in input order; any failed item reverts the entire batch.


```solidity
function createShareTokens(ILedgerTokenFactory.ShareTokenConfig[] memory tokens_)
    external
    returns (address[] memory _tokenAddresses, uint256[] memory _flags);
```

