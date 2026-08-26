# ILedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/40317fddb0f44411366b7cf99393417793c80ea2/modules/ledger/ILedgerTokenFactory.sol)


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

