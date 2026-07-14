# LedgerView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/modules/ledger/LedgerView.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [ILedgerView](/modules/ledger/ILedgerView.sol/interface.ILedgerView.md)


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory s);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory s);
```

### name


```solidity
function name(address a) external view returns (string memory);
```

### symbol


```solidity
function symbol(address a) external view returns (string memory);
```

### decimals


```solidity
function decimals(address a) external view returns (uint8);
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
function debitBalanceOf(address p, address a) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address p, address a) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address p, address a) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address t) external view returns (uint256);
```

### isClaim


```solidity
function isClaim(address t) external view returns (bool);
```

### claimAccountOf


```solidity
function claimAccountOf(address t) external view returns (address);
```

