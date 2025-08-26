# Module
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/modules/Module.sol)


## State Variables
### __self

```solidity
address internal immutable __self = address(this);
```


## Functions
### commands


```solidity
function commands() public pure virtual returns (bytes4[] memory _commands);
```

### enforceIsOwner


```solidity
function enforceIsOwner() internal view returns (Store storage s);
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

