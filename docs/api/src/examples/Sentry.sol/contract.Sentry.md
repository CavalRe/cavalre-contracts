# Sentry
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/examples/Sentry.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### signatures


```solidity
function signatures() public pure virtual override returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors() public pure virtual override returns (bytes4[] memory _selectors);
```

### transferOwnership


```solidity
function transferOwnership(address _module, address _newOwner) external;
```

### acceptOwnership


```solidity
function acceptOwnership(address _module) external;
```

### renouceOwnership


```solidity
function renouceOwnership(address _module) external;
```

### confirmRenounceOwnership


```solidity
function confirmRenounceOwnership(address _module) external;
```

### pendingOwner


```solidity
function pendingOwner(address _module) external view returns (address);
```

## Events
### OwnershipTransferStarted

```solidity
event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
```

## Errors
### OwnableInvalidOwner

```solidity
error OwnableInvalidOwner(address owner);
```

