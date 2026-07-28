# ILedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/ledger/ILedgerTokenFactory.sol)


## Functions
### createInternalToken


```solidity
function createInternalToken(TokenMetadata[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);
```

### createReceiptToken


```solidity
function createReceiptToken(address absoluteReceiptAccount, TokenMetadata memory token)
    external
    returns (address tokenAddress, uint256 flags);
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

