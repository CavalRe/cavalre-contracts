# IDispatcher
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/dispatcher/IDispatcher.sol)


## Functions
### addModule


```solidity
function addModule(address[] memory modules_) external;
```

### removeModule


```solidity
function removeModule(address[] memory modules_) external;
```

### modules


```solidity
function modules() external view returns (address[] memory);
```

### owner


```solidity
function owner(address module_) external view returns (address);
```

### module


```solidity
function module(bytes4 selector_) external view returns (address);
```

### verifyModule


```solidity
function verifyModule(address module_)
    external
    pure
    returns (bytes4[] memory selectors_, string[] memory signatures_);
```

### signatures


```solidity
function signatures(address module_) external view returns (string[] memory);
```

### selectors


```solidity
function selectors(address module_) external view returns (bytes4[] memory);
```

### commands


```solidity
function commands() external view returns (DispatcherLib.Command[] memory);
```

### commands


```solidity
function commands(address[] calldata modules_) external view returns (DispatcherLib.Command[] memory);
```

## Events
### CommandSet

```solidity
event CommandSet(bytes4 indexed command, address indexed module);
```

### ModuleAdded

```solidity
event ModuleAdded(address indexed module);
```

### ModuleRemoved

```solidity
event ModuleRemoved(address indexed module);
```

### DispatcherCreated

```solidity
event DispatcherCreated(address indexed dispatcher);
```

## Errors
### CommandAlreadySet

```solidity
error CommandAlreadySet(bytes4 command, address module);
```

### CommandNotFound

```solidity
error CommandNotFound(bytes4 command);
```

### CommandInWrongModule

```solidity
error CommandInWrongModule(bytes4 command, address expectedModule, address actualModule);
```

### ModuleAlreadyAdded

```solidity
error ModuleAlreadyAdded(address module);
```

### ModuleNotFound

```solidity
error ModuleNotFound(address module);
```

### OwnableUnauthorizedAccount

```solidity
error OwnableUnauthorizedAccount(address account);
```

### InvalidSignaturesLength

```solidity
error InvalidSignaturesLength(uint256 expectedLength, uint256 actualLength);
```

### InvalidSignature

```solidity
error InvalidSignature(bytes4 selector, string signature);
```

