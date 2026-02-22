# Sentry
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/27a8b6bea99c34fd7ef12952ab488aa1d4998a37/examples/Sentry.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md)


## Functions
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

