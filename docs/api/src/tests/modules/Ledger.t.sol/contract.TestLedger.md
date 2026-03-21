# TestLedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/60feb3a156b5466ba1b6f8ec3f8f965b7f89c2de/tests/modules/Ledger.t.sol)

**Inherits:**
[Ledger](/modules/Ledger.sol/contract.Ledger.md)


## State Variables
### LEDGER_NAME

```solidity
string internal constant LEDGER_NAME = "Ledger"
```


### LEDGER_SYMBOL

```solidity
string internal constant LEDGER_SYMBOL = "LEDGER"
```


## Functions
### constructor


```solidity
constructor(uint8 decimals_) Ledger(decimals_, "Ethereum", "ETH");
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory _selectors);
```

### initializeTestLedger


```solidity
function initializeTestLedger() external initializer;
```

### mint


```solidity
function mint(address toParent_, address to_, uint256 amount_) external;
```

### burn


```solidity
function burn(address fromParent_, address from_, uint256 amount_) external;
```

### receive


```solidity
receive() external payable;
```

