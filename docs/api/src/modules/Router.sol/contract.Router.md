# Router
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d6e6c8bec73fd15a0c08c70187d6e2f4481e1b46/modules/Router.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md)


## Functions
### constructor


```solidity
constructor(address owner_) ;
```

### selectors


```solidity
function selectors() public pure override returns (bytes4[] memory);
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
function getCommands(address module_) public returns (bytes4[] memory);
```

### addModule


```solidity
function addModule(address module_) external;
```

### removeModule


```solidity
function removeModule(address module_) external;
```

### owner


```solidity
function owner(address module_) public view returns (address);
```

### module


```solidity
function module(bytes4 selector_) public view returns (address);
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

### GetCommandsFailed

```solidity
error GetCommandsFailed(address module);
```

### ModuleNotFound

```solidity
error ModuleNotFound(address _module);
```

