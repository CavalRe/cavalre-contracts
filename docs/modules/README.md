# Module.sol

The `Module` contract is an abstract base for CavalRe modules. It provides access control, delegation checks, and shared ownership access through `ModuleLib.Store`.

It is paired with a `Lib` library that defines the storage layout and access method using a fixed storage slot.

## Storage Layout

```solidity
struct Store {
    mapping(address => address) owners;
}
```

The storage slot is namespaced using the ERC-7201-style pattern:

```solidity
keccak256(abi.encode(uint256(keccak256("cavalre.storage.Module")) - 1)) & ~bytes32(uint256(0xff))
```

## Key Functions

### `function selectors() external pure virtual returns (bytes4[] memory)`

Each module must override this function to return the list of function selectors it implements.

### `function enforceIsOwner() internal view returns (Store storage)`

Reverts with `OwnableUnauthorizedAccount(msg.sender)` if the caller is not the registered owner of this module.

### `function enforceIsDelegated() internal view`

Ensures the function is being called via `delegatecall`, not directly. Reverts with `NotDelegated()` if the call is direct.

### `function enforceNotDelegated() internal view`

Ensures the function is **not** being called via `delegatecall`. Reverts with `IsDelegated()` if called indirectly.

## Errors

- `OwnableUnauthorizedAccount(address)`
- `NotDelegated()`
- `IsDelegated()`

## Notes

This contract assumes the calling context may be either a direct call or a `delegatecall` through the `Router`, and provides hooks to enforce the correct mode.

# Router.sol

The `Router` contract is the immutable dispatcher in CavalRe's modular architecture. It inherits from `Module` and assigns modules to function selectors using a mapping defined in `RouterLib.Store`.

## Storage Layout

```solidity
struct Store {
    mapping(bytes4 => address) modules;
}
```

The mapping is stored under a unique ERC-7201-style slot derived from:

```solidity
keccak256(abi.encode(uint256(keccak256("cavalre.storage.Router")) - 1)) & ~bytes32(uint256(0xff))
```

## Events

- `CommandSet(bytes4 indexed command, address indexed module)`
- `ModuleAdded(address indexed module)`
- `ModuleRemoved(address indexed module)`
- `RouterCreated(address indexed router)`

## Errors

- `CommandAlreadySet(bytes4 command, address module)`
- `CommandNotFound(bytes4 command)`
- `ModuleNotFound(address module)`

## Constructor

```solidity
constructor(address owner_)
```

Sets a specified owner of the router’s context (via module storage), and emits `RouterCreated`.

## Function: `selectors()`

Returns the list of supported commands (selectors). In the base `Router` contract, this returns an empty array:

```solidity
function selectors() external pure override returns (bytes4[] memory) {
    return new bytes4[](0);
}
```

This means the `Router` itself does not handle application logic — it only manages and delegates to modules.

## Design Notes

- Built atop `Module.sol`, the Router shares access control logic.
- Command-module relationships are mutable (you can add/remove modules).
- The Router itself is designed to be immutable — it delegates to upgradeable modules via `delegatecall`.

# Ledger.sol

The `Ledger` module owns token-root registration, hierarchical account trees, and double-entry postings.

## Current Root Model

- canonical root is always registered at `address(this)` during `initializeLedger(...)`
- internal roots are self-wrapped at creation, so the returned root address is immediately an ERC20 surface
- internal root creation is deterministic and idempotent by `(name, symbol, decimals)`
- native and external roots can be registered first, then optionally wrapped later via `createWrapper(...)`
- canonical root may also be wrapped via `createWrapper(...)` if no `ERC20` module surface is present or a separate wrapper is desired
- `wrap(...)` / `unwrap(...)` depend on registered roots, not wrapper existence

## Responsibilities

- token metadata by root (`name`, `symbol`, `decimals`)
- tree management (`addSubAccount*`, `removeSubAccount*`)
- root discovery / flags / wrapper lookup
- transfer posting, wrap/unwrap, and total supply accounting

# ERC20.sol

The `ERC20` module is the optional ERC20 surface for the canonical root.

## Design Notes

- deployed as a module, so runtime address is the Router address via `delegatecall`
- metadata, balances, total supply, and transfer posting all route through `LedgerLib`
- allowances live in `ERC20Lib`
- this keeps canonical-root ERC20 behavior out of `LedgerLib` while preserving `address(this)` as canonical token address

## Further Reading

- [Ledger Notes](Ledgers.md)
- [ERC20 Notes](ERC20.md)
