# TestLedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/tests/modules/Ledger.t.sol)

**Inherits:**
[Ledger](/modules/ledger/Ledger.sol/contract.Ledger.md)


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
constructor(uint8 decimals_, uint8 nativeDecimals_) Ledger(decimals_, "Ethereum", "ETH", nativeDecimals_);
```

### signatures


```solidity
function signatures() external pure virtual override returns (string[] memory _signatures);
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

### enforceNativeValue


```solidity
function enforceNativeValue(uint256 expected_) external payable;
```

### wrapThenUnwrap


```solidity
function wrapThenUnwrap(address payToken_, uint256 payAmount_, address recToken_, uint256 recAmount_)
    external
    payable;
```

### wrapThenWrap


```solidity
function wrapThenWrap(address nativeToken_, uint256 nativeAmount_, address externalToken_, uint256 externalAmount_)
    external
    payable;
```

### rawTransfer


```solidity
function rawTransfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_) external;
```

### receive


```solidity
receive() external payable;
```

