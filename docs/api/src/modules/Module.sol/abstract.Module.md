# Module
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d6e6c8bec73fd15a0c08c70187d6e2f4481e1b46/modules/Module.sol)


## State Variables
### __self

```solidity
address internal immutable __self = address(this)
```


## Functions
### selectors


```solidity
function selectors() external pure virtual returns (bytes4[] memory _selectors);
```

### enforceIsOwner


```solidity
function enforceIsOwner() internal view returns (ModuleLib.Store storage s);
```

### enforceIsDelegated


```solidity
function enforceIsDelegated() internal view;
```

### enforceNotDelegated


```solidity
function enforceNotDelegated() internal view;
```

## Errors
### OwnableUnauthorizedAccount

```solidity
error OwnableUnauthorizedAccount(address account);
```

### NotDelegated

```solidity
error NotDelegated();
```

### IsDelegated

```solidity
error IsDelegated();
```

### InvalidCommandsLength

```solidity
error InvalidCommandsLength(uint256 n);
```

