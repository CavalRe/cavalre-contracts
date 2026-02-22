# ReentrancyGuard
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4beb1bb5ec51300e77fe11434272324aa08bfb7c/utilities/ReentrancyGuard.sol)

**Inherits:**
[ReentrancyGuardTransient](/node_modules/@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol/abstract.ReentrancyGuardTransient.md)

Must be used instead of OpenZeppelin's ReentrancyGuardTransient directly in module contracts.

Shadow version of OpenZeppelin's ReentrancyGuardTransient to support module-specific storage slots.
This contract overrides the default `_reentrancyGuardStorageSlot` behavior to enforce separate
storage slots for each module in a diamond-style Router/Module architecture.
Without this override, all modules that inherit OpenZeppelin's ReentrancyGuardTransient would use the
same storage slot, leading to collisions when using delegatecall.


## Functions
### _reentrancyGuardStorageSlot


```solidity
function _reentrancyGuardStorageSlot() internal pure virtual override returns (bytes32);
```

