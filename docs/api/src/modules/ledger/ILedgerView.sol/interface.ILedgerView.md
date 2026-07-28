# ILedgerView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/ledger/ILedgerView.sol)


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

### ledgerCount


```solidity
function ledgerCount() external view returns (uint256);
```

### ledgerAt


```solidity
function ledgerAt(uint256 index) external view returns (address);
```

### ledgers


```solidity
function ledgers(uint256 start, uint256 limit) external view returns (address[] memory);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address ledger, address parent, address relative) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address ledger, address parent, address relative) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address ledger, address parent, address relative) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address ledger) external view returns (uint256);
```

