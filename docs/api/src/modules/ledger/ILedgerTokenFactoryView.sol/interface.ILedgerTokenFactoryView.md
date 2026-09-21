# ILedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/ILedgerTokenFactoryView.sol)


## Functions
### tokenSalt


```solidity
function tokenSalt(string memory name, string memory symbol, uint8 decimals, string memory version)
    external
    pure
    returns (bytes32);
```

### predictERC20TokenAddress


```solidity
function predictERC20TokenAddress(string memory name, string memory symbol, uint8 decimals, string memory version)
    external
    view
    returns (address token);
```

### predictShareTokenAddress


```solidity
function predictShareTokenAddress(string memory name, string memory symbol, uint8 decimals, string memory version)
    external
    view
    returns (address token);
```

