# ILedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/ledger/ILedgerTokenFactoryView.sol)


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

### predictReceiptToken


```solidity
function predictReceiptToken(string memory name, string memory symbol, uint8 decimals, string memory version)
    external
    view
    returns (address token);
```

