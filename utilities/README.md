# Utilities

This folder contains shadow wrappers for OpenZeppelin contracts used to support module-specific behavior in a diamond-style `Router/Module` architecture.

## Purpose

When using `delegatecall` in a modular system, all modules share the same storage layout as the calling Router. To avoid storage slot collisions, these utilities override OpenZeppelin defaults to enforce **per-module storage isolation**.

## Included Contracts

### `Initializable`

Shadow version of `OpenZeppelin Initializable` with a custom `_initializableStorageSlot()`:

- Prevents different modules from sharing the same initialization flag.
- Enables safe use of `initializer` and `reinitializer` modifiers across modules.
- Must be subclassed to provide a unique storage slot per module.

Use in module contracts instead of `@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol`.

### `ReentrancyGuard`

Shadow version of `OpenZeppelin ReentrancyGuardTransient` with a custom `_reentrancyGuardStorageSlot()`:

- Prevents reentrancy guard storage collisions between modules.
- Works safely with `nonReentrant` in modular systems.
- Must be subclassed to specify a unique guard slot per module.

Use in module contracts instead of `@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol`.

## Usage

Example in a module:

```solidity
import {Initializable} from "../utilities/Initializable.sol";
import {ReentrancyGuard} from "../utilities/ReentrancyGuard.sol";

contract MyModule is Initializable, ReentrancyGuard {
    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return keccak256("mymodule.initializable.slot");
    }

    function _reentrancyGuardStorageSlot() internal pure override returns (bytes32) {
        return keccak256("mymodule.reentrancy.slot");
    }
}
````

Each module must define unique storage slots to ensure safe, independent operation when called via `delegatecall`.

## Notes

These contracts inherit the full functionality of their OpenZeppelin counterparts, including `initializer`, `reinitializer`, and `nonReentrant`. The only difference is that they override the internal storage slot accessors and revert by default.

This design forces each module to explicitly define its own unique storage slot, preventing storage collisions in a `delegatecall`-based modular architecture.


