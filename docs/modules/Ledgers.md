# Ledger.sol

`modules/Ledger.sol` implements CavalRe’s hierarchical double-entry ledger module.

## Scope

- token/account metadata (`name`, `symbol`, `decimals`)
- account tree management (`addSubAccount*`, `removeSubAccount*`)
- account flags (`isGroup`, `isCredit`, `isInternal`, `isNative`, `isWrapper`)
- balances + routed transfers
- wrapper-facing transfer hooks + wrap/unwrap flows
- canonical-root ERC20 surface via `modules/ERC20.sol`

## Key Model

- every token ledger has a root
- canonical root is `address(this)`
- subaccounts are deterministic addresses derived from parent + label/address
- transfers walk upward through the tree with debit/credit semantics
- internal roots are self-wrapped at creation so the root address is immediately usable as an ERC20 surface
- native/external roots can be registered first and optionally wrapped later via `createWrapper`
- canonical root ERC20 UX is handled by `modules/ERC20.sol`, which reads metadata/supply/balances from `LedgerLib` and keeps allowances in `ERC20Lib`

## Storage

Ledger storage lives in `libraries/LedgerLib.sol` (`LedgerLib.Store`) under an ERC-7201-style namespaced slot.

Core fields include:

- metadata maps (`name`, `symbol`, `decimals`)
- tree maps (`root`, `subs`, `subIndex`)
- wrapper map (`wrapper`) for token roots
- flags map (`flags`)
- balances maps (`debits`, `credits`)

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
