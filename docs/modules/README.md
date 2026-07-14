# Dispatchable / Dispatcher

`Dispatchable` is the abstract base for CavalRe modules. `Dispatcher` is the immutable selector router that delegates calls into installed modules.

`DispatcherLib` defines shared dispatcher storage using a fixed ERC-7201-style slot.

## Storage Layout

```solidity
struct Store {
    address owner;
    mapping(bytes4 => address) modules;
}
```

## Key Functions

### `function selectors() external pure virtual returns (bytes4[] memory)`

Each module must override this function to return the list of function selectors it implements.

### `function enforceIsOwner() internal view`

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

Dispatchable contracts assume the calling context may be either a direct call or
a `delegatecall` through `Dispatcher`, and provide hooks to enforce the correct
mode.

# Dispatcher.sol

`Dispatcher` is the immutable dispatcher in CavalRe's modular architecture. It
assigns modules to function selectors using `DispatcherLib.Store`.

## Storage Layout

See storage layout above.

## Events

- `CommandSet(bytes4 indexed command, address indexed module)`
- `ModuleAdded(address indexed module)`
- `ModuleRemoved(address indexed module)`
- `DispatcherCreated(address indexed dispatcher)`

## Errors

- `CommandAlreadySet(bytes4 command, address module)`
- `CommandNotFound(bytes4 command)`
- `ModuleNotFound(address module)`

## Constructor

```solidity
constructor(address owner_)
```

Sets the dispatcher owner and emits `DispatcherCreated`.

## Function: `selectors()`

Returns the list of supported commands (selectors). In the base `Dispatcher` contract, this returns an empty array:

```solidity
function selectors() external pure override returns (bytes4[] memory) {
    return new bytes4[](0);
}
```

This means the `Dispatcher` itself does not handle application logic - it only manages and delegates to modules.

## Design Notes

- Command-module relationships are mutable (you can add/remove modules).
- The Dispatcher itself is designed to be immutable - it delegates to upgradeable modules via `delegatecall`.

# Ledger.sol

The `Ledger` module owns token-root registration, hierarchical account trees, and double-entry postings.

## Current Root Model

- canonical root is always registered at `address(this)` during `initializeLedger(...)`
- internal roots are self-wrapped at creation, so the returned root address is immediately an ERC20 surface
- claim roots are also self-wrapped at creation and reference one registered non-claim Ledger leaf account
- internal root creation happens through `createInternalToken(...)` and is deterministic/idempotent by `(name, symbol, decimals)`
- claim root creation happens through `createClaimToken(...)` and is deterministic/idempotent by `(name, symbol, decimals, claimAccount)`
- native and external roots are registered ledger roots without self-wrapped ERC20 surfaces
- canonical-root ERC20 behavior lives in the example ERC20 module when installed
- `LedgerLib.wrap(...)` / `LedgerLib.unwrap(...)` depend on registered roots, not wrapper existence
- external `Ledger.wrap(token_, amount_)` / `Ledger.unwrap(token_, amount_)` route through the per-root default source leaf
- wrap/unwrap are valid only for external/native debit roots; internal and claim roots revert
- direct/user and wrapper/ERC20 transfer paths both enforce canonical source polarity after `LedgerLib.transfer(...)`

## Responsibilities

- token metadata by root (`name`, `symbol`, `decimals`)
- tree management (`addSubAccount*`, `removeSubAccount*`)
- root registration + per-root default source registration
- claim-token reference registration
- transfer posting and total supply accounting
- wrap/unwrap settlement logic

# TreeView.sol

The `TreeView` module owns topology/debug reads for ledger trees.

## Responsibilities

- root / parent / flags / wrapper lookup
- enum flag decoding (`AccountKind`, `TokenKind`, packed address, claim account)
- effective flag resolution for possibly-unregistered leaves
- child enumeration (`subAccounts`, `hasSubAccount`, `subAccountIndex`)
- tree visualization via `debugTree(root_)` and `debugTrees(roots_)`

`TreeLib` now reads directly from `LedgerLib`; callers no longer pass a `Ledger` handle into `debugTree(s)`.

# LedgerERC20.sol

The example `LedgerERC20` module is the optional ERC20 surface for the canonical root.

## Design Notes

- deployed as a module, so runtime address is the Dispatcher address via `delegatecall`
- metadata, balances, total supply, and transfer posting all route through `LedgerLib`
- allowances live in `LedgerERC20Lib`
- this keeps canonical-root ERC20 behavior out of `LedgerLib` while preserving `address(this)` as canonical token address

## Further Reading

- [Ledger Notes](Ledgers.md)
- [Claim Token Notes](ClaimTokens.md)
- [ERC20 Notes](ERC20.md)
