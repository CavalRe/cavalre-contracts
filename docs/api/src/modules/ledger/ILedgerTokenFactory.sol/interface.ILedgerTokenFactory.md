# ILedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/ILedgerTokenFactory.sol)


## Functions
### createInternalToken


```solidity
function createInternalToken(TokenMetadata[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);
```

### createClaimToken


```solidity
function createClaimToken(address absoluteClaimAccount, TokenMetadata memory token)
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

