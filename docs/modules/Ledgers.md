# Ledger.sol

`modules/Ledger.sol` implements CavalRe’s hierarchical double-entry ledger module.

## Scope

- token/account metadata (`name`, `symbol`, `decimals`)
- account tree management (`addSubAccount*`, `removeSubAccount*`)
- account flags (`isGroup`, `isCredit`, `isInternal`, `isNative`, `isRegistered`)
- balances + routed transfers
- wrapper-facing transfer hooks
- library-level wrap/unwrap settlement flows
- canonical-root ERC20 surface via `modules/ERC20.sol`

## Key Model

- every token ledger has a root
- canonical root is `address(this)`
- subaccounts are deterministic addresses derived from parent + label/address
- name-form `addSubAccount*` helpers delegate to addr-form overloads using `toAddress(name_)`
- transfers perform a single coordinated upward walk from source and destination leaves
- leaf polarity determines which balance column (`debits` or `credits`) each path mutates
- when both paths converge on the same ancestor on the same side, remaining upward mutations cancel and the walk can stop early
- internal roots are created deterministically with `CREATE2` via `createToken(...)`, so `(name, symbol, decimals)` uniquely identifies the root and repeated calls are idempotent
- internal roots are self-wrapped at creation so the root address is immediately usable as an ERC20 surface
- native/external roots can be registered first and optionally wrapped later via `createWrapper`
- canonical root may also be wrapped via `createWrapper` when a separate wrapper surface is desired
- canonical root ERC20 UX is handled by `modules/ERC20.sol`, which reads metadata/supply/balances from `LedgerLib` and keeps allowances in `ERC20Lib`
- `effectiveFlags(parent_, addr_)` resolves both absolute address and effective flags for possibly-unregistered derived leaves
- `transfer(...)` returns the resolved root plus effective from/to flags
- `wrap(...)` / `unwrap(...)` are exposed on `Ledger` and return the resolved token plus effective from/to flags
- tree/root mutators are intended to be idempotent: exact replays return the same result or become no-ops, while conflicting replays revert

## Storage

Ledger storage lives in `libraries/LedgerLib.sol` (`LedgerLib.Store`) under an ERC-7201-style namespaced slot.

Core fields include:

- metadata maps (`name`, `symbol`, `decimals`)
- tree maps (`root`, `subs`, `subIndex`)
- wrapper map (`wrapper`) for token roots
- flags map (`flags`)
- balances maps (`debits`, `credits`)

Special addresses:

- `NATIVE_ADDRESS`
- `SOURCE_ADDRESS`

## Events

Primary ledger/accounting events:

- `BalanceUpdate`
- `Credit`
- `Debit`
- `LedgerAdded`
- `SubAccountAdded`
- `SubAccountGroupAdded`
- `SubAccountRemoved`
- `SubAccountGroupRemoved`

ERC20-style events are emitted by the canonical `ERC20` module or wrapper contracts (`Transfer`, `Approval`).

## Testing

Use Foundry tests under `tests/modules/`:

```bash
forge test --match-path tests/modules/Ledger.t.sol
forge test --match-path tests/modules/ERC20.t.sol
forge test --match-path tests/modules/ERC20Wrapper.t.sol
```

For authoritative API details, use generated docs in `docs/api/`.
