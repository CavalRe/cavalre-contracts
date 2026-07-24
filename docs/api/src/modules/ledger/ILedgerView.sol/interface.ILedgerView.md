# ILedgerView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/ILedgerView.sol)


## Functions
### name


```solidity
function name(address absolute) external view returns (string memory);
```

### symbol


```solidity
function symbol(address absolute) external view returns (string memory);
```

### decimals


```solidity
function decimals(address absolute) external view returns (uint8);
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

### rootCount


```solidity
function rootCount() external view returns (uint256);
```

### rootAt


```solidity
function rootAt(uint256 index) external view returns (address);
```

### roots


```solidity
function roots(uint256 start, uint256 limit) external view returns (address[] memory);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address root, address holderParent, address relative) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address root, address holderParent, address relative) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address root, address holderParent, address relative) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address root) external view returns (uint256);
```

### isClaim


```solidity
function isClaim(address root) external view returns (bool);
```

### claimAccountOf


```solidity
function claimAccountOf(address root) external view returns (address);
```

