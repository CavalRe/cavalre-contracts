# ILedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/ledger/ILedgerTokenFactoryView.sol)


## Functions
### tokenSalt


```solidity
function tokenSalt(string memory name, string memory symbol, uint8 decimals, string memory version)
    external
    pure
    returns (bytes32);
```

### predictToken


```solidity
function predictToken(string memory name, string memory symbol, uint8 decimals, string memory version)
    external
    view
    returns (address token);
```

