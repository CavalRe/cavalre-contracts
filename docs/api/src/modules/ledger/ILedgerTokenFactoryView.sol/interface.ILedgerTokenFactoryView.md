# ILedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/ILedgerTokenFactoryView.sol)


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

