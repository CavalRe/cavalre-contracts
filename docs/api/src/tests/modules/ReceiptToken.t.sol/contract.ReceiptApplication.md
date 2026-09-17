# ReceiptApplication
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/tests/modules/ReceiptToken.t.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)

Example authorized application settlement against a non-token ledger; no ERC20 calls.


## Constants
### SCALE

```solidity
address internal constant SCALE = address(0x500)
```


### GROUP

```solidity
address internal constant GROUP = address(0x501)
```


### BACKING

```solidity
address internal constant BACKING = address(0x502)
```


### OFFSET

```solidity
address internal constant OFFSET = address(0x503)
```


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### configure


```solidity
function configure(bool credit_, uint8 decimals_, bool source_) external returns (address);
```

### issue


```solidity
function issue(address token_, address holder_, uint256 amount_, bool bad_) external returns (uint256);
```

### redeem


```solidity
function redeem(address token_, uint256 amount_, bool bad_) external returns (uint256);
```

### changeBacking


```solidity
function changeBacking(address token_, uint256 amount_, bool add_) external;
```

### holderFlags


```solidity
function holderFlags(address token_, address holder_) external view returns (uint256);
```

### addBacking


```solidity
function addBacking(address token_, uint256 amount_, bytes memory data_) internal;
```

### releaseBacking


```solidity
function releaseBacking(address token_, uint256 amount_, bytes memory data_) internal;
```

### moveBacking


```solidity
function moveBacking(address token_, uint256 amount_, bool add_) internal;
```

