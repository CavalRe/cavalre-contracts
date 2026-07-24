# LedgerView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/LedgerView.sol)

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
function name(address absolute_) external view returns (string memory);
```

### symbol


```solidity
function symbol(address absolute_) external view returns (string memory);
```

### decimals


```solidity
function decimals(address absolute_) external view returns (uint8);
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
function rootAt(uint256 index_) external view returns (address);
```

### roots


```solidity
function roots(uint256 start_, uint256 limit_) external view returns (address[] memory);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address root_, address holderParent_, address relative_) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address root_, address holderParent_, address relative_) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address root_, address holderParent_, address relative_) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address root_) external view returns (uint256);
```

### isClaim


```solidity
function isClaim(address root_) external view returns (bool);
```

### claimAccountOf


```solidity
function claimAccountOf(address root_) external view returns (address);
```

