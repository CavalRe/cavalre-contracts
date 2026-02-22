# Ledger.sol

`modules/Ledger.sol` implements CavalRe’s hierarchical double-entry ledger module.

## Scope

- token/account metadata (`name`, `symbol`, `decimals`)
- account tree management (`addSubAccount*`, `removeSubAccount*`)
- account flags (`isGroup`, `isCredit`, `isInternal`, `isNative`, `isWrapper`)
- balances + routed transfers
- wrapper-facing transfer hooks + wrap/unwrap flows

## Key Model

- every token ledger has a root
- subaccounts are deterministic addresses derived from parent + label/address
- transfers walk upward through the tree with debit/credit semantics
- wrappers (`ERC20Wrapper`) expose ERC20-like UX while delegating ledger state updates to `Ledger`

## Storage

Ledger storage lives in `libraries/LedgerLib.sol` (`LedgerLib.Store`) under an ERC-7201-style namespaced slot.

Core fields include:

- metadata maps (`name`, `symbol`, `decimals`)
- tree maps (`root`, `parent`, `subs`, `subIndex`)
- flags map (`flags`)
- balances map (`balance`)

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
- `InternalApproval`

ERC20-style wrapper events are emitted by wrapper contracts (`Transfer`, `Approval`).

## Testing

Use Foundry tests under `tests/modules/`:

```bash
forge test --match-path tests/modules/Ledger.t.sol
forge test --match-path tests/modules/ERC20Wrapper.t.sol
```

For authoritative API details, use generated docs in `docs/api/`.
