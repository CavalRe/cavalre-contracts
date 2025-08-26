# Router
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/modules/Router.sol)

**Inherits:**
[Module](/src/modules/Module.sol/abstract.Module.md)


## Functions
### constructor


```solidity
constructor(address owner_);
```

### commands


```solidity
function commands() public pure override returns (bytes4[] memory);
```

### fallback


```solidity
fallback() external payable;
```

### receive


```solidity
receive() external payable;
```

### getCommands


```solidity
function getCommands(address _module) public returns (bytes4[] memory);
```

### addModule


```solidity
function addModule(address _module) external;
```

### removeModule


```solidity
function removeModule(address _module) external;
```

### owner


```solidity
function owner(address _module) public view returns (address);
```

### module


```solidity
function module(bytes4 _selector) public view returns (address);
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

### RouterCreated

```solidity
event RouterCreated(address indexed router);
```

## Errors
### CommandAlreadySet

```solidity
error CommandAlreadySet(bytes4 _command, address _module);
```

### CommandNotFound

```solidity
error CommandNotFound(bytes4 _command);
```

### ModuleNotFound

```solidity
error ModuleNotFound(address _module);
```

