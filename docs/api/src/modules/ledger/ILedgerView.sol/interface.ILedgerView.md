# ILedgerView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/modules/ledger/ILedgerView.sol)


## Functions
### name


```solidity
function name(address addr) external view returns (string memory);
```

### symbol


```solidity
function symbol(address addr) external view returns (string memory);
```

### decimals


```solidity
function decimals(address addr) external view returns (uint8);
```

### nativeName


```solidity
function nativeName() external view returns (string memory);
```

### nativeSymbol


```solidity
function nativeSymbol() external view returns (string memory);
```

### nativeDecimals


```solidity
function nativeDecimals() external view returns (uint8);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address parent, address owner) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address parent, address owner) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address parent, address owner) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address token) external view returns (uint256);
```

### isClaim


```solidity
function isClaim(address token) external view returns (bool);
```

### claimAccountOf


```solidity
function claimAccountOf(address token) external view returns (address);
```

