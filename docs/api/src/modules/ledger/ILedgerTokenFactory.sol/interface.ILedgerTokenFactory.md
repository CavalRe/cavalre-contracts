# ILedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/ILedgerTokenFactory.sol)


## Functions
### createInternalTokens


```solidity
function createInternalTokens(TokenMetadata[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);
```

### createShareTokens

Create share tokens in input order; any failed item reverts the entire batch.


```solidity
function createShareTokens(ShareTokenConfig[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);
```

## Structs
### TokenMetadata

```solidity
struct TokenMetadata {
    string name;
    string symbol;
    uint8 decimals;
    string version;
}
```

### ShareTokenConfig

```solidity
struct ShareTokenConfig {
    address backingAccount;
    TokenMetadata metadata;
}
```

