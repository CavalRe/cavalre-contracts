# Dispatcher
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/dispatcher/Dispatcher.sol)

**Inherits:**
[IDispatcher](/modules/dispatcher/IDispatcher.sol/interface.IDispatcher.md)


## Functions
### constructor


```solidity
constructor(address owner_) ;
```

### fallback


```solidity
fallback() external payable;
```

### receive


```solidity
receive() external payable;
```

### addModule


```solidity
function addModule(address[] memory modules_) external override;
```

### removeModule


```solidity
function removeModule(address[] memory modules_) external override;
```

### owner


```solidity
function owner(address module_) external view override returns (address);
```

### module


```solidity
function module(bytes4 selector_) external view override returns (address);
```

### modules


```solidity
function modules() public view override returns (address[] memory);
```

### verifyModule


```solidity
function verifyModule(address module_)
    external
    pure
    override
    returns (bytes4[] memory selectors_, string[] memory signatures_);
```

### signatures


```solidity
function signatures(address module_) external pure override returns (string[] memory);
```

### selectors


```solidity
function selectors(address module_) external pure override returns (bytes4[] memory);
```

### commands


```solidity
function commands() external view override returns (DispatcherLib.Command[] memory);
```

### commands


```solidity
function commands(address[] calldata modules_) external pure override returns (DispatcherLib.Command[] memory);
```

