# Dispatchable
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/dispatcher/Dispatchable.sol)


## State Variables
### __self

```solidity
address internal immutable __self = address(this)
```


## Functions
### signatures


```solidity
function signatures() external pure virtual returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors() external pure virtual returns (bytes4[] memory _selectors);
```

### enforceIsOwner


```solidity
function enforceIsOwner() internal view;
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

