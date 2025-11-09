# Module.sol

The `Module` contract is an abstract base for CavalRe modules. It provides access control, delegation checks, and a storage namespace for module-specific ownership using the `Store` struct.

It is paired with a `Lib` library that defines the storage layout and access method using a fixed storage slot.

## Storage Layout

```solidity
struct Store {
    mapping(address => address) owners;
}
```

The storage slot is namespaced using:

```solidity
keccak256("cavalre.storage.Module")
```

## Key Functions

### `function selectors() public pure virtual returns (bytes4[] memory)`

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

The `Router` contract is the immutable dispatcher in CavalRe's modular architecture. It inherits from `Module` and assigns modules to function selectors using a mapping defined in its own `Store` struct.

## Storage Layout

```solidity
struct Store {
    mapping(bytes4 => address) modules;
}
```

The mapping is stored under a unique storage slot derived from:

```solidity
keccak256("cavalre.storage.Router")
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
function selectors() public pure override returns (bytes4[] memory) {
    return new bytes4 ;
}
```

This means the `Router` itself does not handle application logic — it only manages and delegates to modules.

## Design Notes

- Built atop `Module.sol`, the Router shares access control logic.
- Command-module relationships are mutable (you can add/remove modules).
- The Router itself is designed to be immutable — it delegates to upgradeable modules via `delegatecall`.
