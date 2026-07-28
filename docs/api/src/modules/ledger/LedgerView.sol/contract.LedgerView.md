# LedgerView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/ledger/LedgerView.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [ILedgerView](/modules/ledger/ILedgerView.sol/interface.ILedgerView.md)


## Functions
### checkLedgerParent


```solidity
function checkLedgerParent(address ledger_, address parent_) private view;
```

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

### ledgerCount


```solidity
function ledgerCount() external view returns (uint256);
```

### ledgerAt


```solidity
function ledgerAt(uint256 index_) external view returns (address);
```

### ledgers


```solidity
function ledgers(uint256 start_, uint256 limit_) external view returns (address[] memory);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address ledger_, address parent_, address relative_) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address ledger_, address parent_, address relative_) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address ledger_, address parent_, address relative_) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address ledger_) external view returns (uint256);
```

