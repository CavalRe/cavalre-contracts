# Initializable
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/utilities/Initializable.sol)

**Inherits:**
OZInitializable

Must be used instead of OpenZeppelin's Initializable directly in module contracts.

*Shadow version of OpenZeppelin's Initializable to support module-specific initialization.
This contract overrides the default `_initializableStorageSlot` behavior to enforce separate
initialization storage slots for each module in a diamond-style Router/Module architecture.
Without this override, all modules that inherit OpenZeppelin's Initializable would use the
same storage slot for their initialization status, leading to collisions when using delegatecall.*


## Functions
### _initializableStorageSlot


```solidity
function _initializableStorageSlot() internal pure virtual override returns (bytes32);
```

