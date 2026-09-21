# ShareApplication
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/tests/modules/ShareToken.t.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)

Authorized non-token backing settlement composed directly with share issuance/redemption.


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

### moveBacking


```solidity
function moveBacking(address token_, uint256 amount_, bool add_) internal;
```

### addBacking


```solidity
function addBacking(address token_, uint256 amount_, bool bad_) internal;
```

### releaseBacking


```solidity
function releaseBacking(address token_, uint256 amount_, bool bad_) internal;
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
function redeem(address token_, uint256 amount_, bool bad_) external returns (uint256 backing_);
```

### changeBacking


```solidity
function changeBacking(address token_, uint256 amount_, bool add_) external;
```

### issueAt


```solidity
function issueAt(address token_, address parent_, address relative_, uint256 amount_) external returns (uint256);
```

### redeemAt


```solidity
function redeemAt(address token_, address parent_, address relative_, uint256 amount_)
    external
    returns (uint256 backing_);
```

### cancelAt


```solidity
function cancelAt(address token_, address parent_, address relative_, uint256 amount_) external;
```

### holderFlags


```solidity
function holderFlags(address token_, address holder_) external view returns (uint256);
```

