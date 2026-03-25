# ReentrancyGuard
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/3a4fcfc9619f01f0afd3feb42acd82ec72eed095/utilities/ReentrancyGuard.sol)

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

