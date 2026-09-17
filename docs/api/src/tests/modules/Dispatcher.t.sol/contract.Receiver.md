# Receiver
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5316bd1d9e8e7ab1df82167844d0b85518ce76e4/tests/modules/Dispatcher.t.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### receive


```solidity
receive() external payable;
```

### fallback


```solidity
fallback() external payable;
```

## Events
### Received

```solidity
event Received(address sender, uint256 value);
```

## Errors
### ReceiveRejected

```solidity
error ReceiveRejected();
```

