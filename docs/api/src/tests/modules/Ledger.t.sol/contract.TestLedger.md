# TestLedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/3a4fcfc9619f01f0afd3feb42acd82ec72eed095/tests/modules/Ledger.t.sol)

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

