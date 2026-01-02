# TestLedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/tests/modules/Ledger.t.sol)

**Inherits:**
[Ledger](/modules/Ledger.sol/contract.Ledger.md)


## Functions
### constructor


```solidity
constructor(uint8 decimals_) Ledger(decimals_);
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory _selectors);
```

### initializeTestLedger


```solidity
function initializeTestLedger(string memory nativeTokenSymbol_) external initializer;
```

### mint


```solidity
function mint(address toParent_, address to_, uint256 amount_) external;
```

### burn


```solidity
function burn(address fromParent_, address from_, uint256 amount_) external;
```

### reallocate


```solidity
function reallocate(address fromToken_, address toToken_, uint256 amount_) external;
```

### receive


```solidity
receive() external payable;
```

