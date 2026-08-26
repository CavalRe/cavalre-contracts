# ILedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/40317fddb0f44411366b7cf99393417793c80ea2/modules/ledger/ILedgerTokenFactoryView.sol)


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

