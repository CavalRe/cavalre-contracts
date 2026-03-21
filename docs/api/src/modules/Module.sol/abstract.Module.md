# Module
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/60feb3a156b5466ba1b6f8ec3f8f965b7f89c2de/modules/Module.sol)


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

