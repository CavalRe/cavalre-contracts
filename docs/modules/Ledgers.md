# Ledger.sol

`modules/ledger/Ledger.sol` implements CavalRe’s hierarchical double-entry ledger module.

## Scope

- token/account metadata (`name`, `symbol`, `decimals`)
- account tree management (`addSubAccount*`, `removeSubAccount*`)
- balances + routed transfers
- wrapper-facing transfer hooks
- default-source registration per root
- native/external root registration
- library-level wrap/unwrap settlement flows
- deterministic internal/share token root creation via `modules/ledger/LedgerTokenFactory.sol`
- canonical-root ERC20 surface via `examples/LedgerERC20.sol`
- topology/debug surface via `modules/tree/TreeView.sol`

## Key Model

- every token ledger has a root
- canonical root is `address(this)`
- every registered root is a debit group
- token-kind packing, registration and reads use `LedgerLib.TokenKind`: `Unregistered` (0), `Native` (1), `External` (2), and `Internal` (3)
- shares are ordinary internal tokens; `ShareTokenLib` stores their immutable backing references in its own namespace
- account shape and polarity are encoded as `LedgerLib.AccountKind`: `DebitGroup`, `CreditGroup`, `DebitLedger`, or `CreditLedger`
- subaccounts are deterministic addresses derived from parent + label/address
- name-form `addSubAccount*` helpers delegate to addr-form overloads using `toAddress(name_)`
- transfers perform a single coordinated upward walk from source and destination leaves
- leaf polarity determines which balance column (`debits` or `credits`) each path mutates
- when both paths converge on the same ancestor on the same side, remaining upward mutations cancel and the walk can stop early
- internal roots are created deterministically with `CREATE2` via `LedgerTokenFactory.createInternalTokens(TokenMetadata[])`, so `(name, symbol, decimals, version)` uniquely identifies the root and repeated calls are idempotent
- internal roots use `ERC20Wrapper`; share roots use `ShareToken`, inheriting the shared ERC20 surface
- share conversion and issue/redeem/cancel composition live in `modules/share`; see [Share tokens](ShareTokens.md)
- native/external roots are registered as ledger roots without self-wrapped ERC20 surfaces
- share token roots are created with `LedgerTokenFactory.createShareTokens(ShareTokenConfig[])`, reference one registered absolute Ledger leaf account outside their own token tree, and are deterministic by `(name, symbol, decimals, version)`
- canonical root ERC20 UX is handled by `examples/LedgerERC20.sol`, which reads metadata/supply/balances from `LedgerLib` and keeps allowances in `LedgerERC20Lib`
- every root auto-registers `LedgerLib.SOURCE_ADDRESS` / `Source` as its default credit source leaf
- `address(0)` is not a registered Ledger holder; it is reserved for ERC20 mint/burn event projection
- `effectiveFlags(ledger_, parent_, relative_)` takes an absolute parent and returns `(effectiveFlags, originalFlags, absoluteAddress)` for possibly-unregistered derived leaves
- `transfer(...)` returns the resolved root plus effective from/to flags
- the six-argument `transfer(...)` is an authorized wrapper/canonical-ERC20 callback; the public five-argument overload is removed
- the callback rejects credit accounts at either endpoint; trusted modules use `LedgerLib.transfer(...)` for authorized accounting
- `wrap(token_, amount_)` mints from the default source into `msg.sender`
- `unwrap(token_, amount_)` burns from `msg.sender` back into the default source
- `LedgerLib.wrap(...)` / `unwrap(...)` only apply to external/native debit roots; internal and share token roots revert
- tree/root mutators are intended to be idempotent: exact replays return the same result or become no-ops, while conflicting replays revert

## Address Derivation

Ledger account addresses are deterministic identifiers, not externally owned
accounts.

`LedgerLib.toAddress(name_)` derives a relative subaccount address from a
human-readable name. This is a child key. It is not a complete position in the
ledger tree until it is anchored under a parent.

`LedgerLib.toAddress(g, r)` computes `H(g,r)` by hashing the 40 packed bytes
of the absolute parent `g` and relative child `r`, then keeping the low 160 bits.
Accounting is recursive: `a2 = H(L,r2)`, `a3 = H(a2,r3)`, `a4 = H(a3,r4)`.
There is no separate token-local holder derivation or three-argument address
overload. Mutation/view callers validate that the supplied parent `g` belongs to
ledger `L`; the ledger is not an additional input to the account hash.

All parent arguments are absolute accounting addresses. Registration and removal
return absolute child addresses. Every packed address identifies the absolute
parent; ledger roots pack `ROOT_ADDRESS`. `Store.custody` replaces the former
`Store.ledger` mapping at the same field position; packed flag fields are unchanged.
Unregistered effective leaves inherit their supplied registered parent's polarity
and depth. Their accounting path is carried in memory, without a per-leaf registry.

The enclosing global Root makes token roots stored depth 2. Their direct children
are stored depth 3 (depth 2 in the custody design article). For `a2 = H(L,h)`,
ERC20 `balanceOf(h)` reads the normal balance: debits minus credits for a debit
custodian, credits minus debits for a credit custodian. Both aggregate sides count.
The root's equal debit and credit aggregates remain total supply; root normal
balance is zero. Custody balances are not a new supply definition.

Public wrapper transfers require direct debit leaves at both endpoints, including
registered leaves. Credit accounts, including Source, are rejected even for zero
amounts. Groups cannot transfer their
subtrees through the wrapper. A holder numerically equal to a deeper accounting
address identifies a separate direct account. Authorized modules move deeper
balances with explicit absolute parents. Self-transfers emit without changing
balances or checking the available balance; `transferFrom` still consumes allowance.

## Storage

Ledger storage lives in `modules/ledger/LedgerLib.sol` (`LedgerLib.Store`) under an ERC-7201-style namespaced slot.

Core fields include:

- metadata maps (`name`, `symbol`, `decimals`)
- tree maps (`custody`, `subs`, `subIndex`)
- wrapper map (`wrapper`) for token roots
- flags map (`flags`) containing `AccountKind`, `TokenKind`, depth, and a packed address slot
- balances maps (`debits`, `credits`)

`custody[absolute]` stores the absolute direct child of the ledger that contains
each registered account. Direct children point to themselves; deeper accounts
inherit their parent's custodian. Removal clears the entry. Ledger roots have no
custody entry and are identified by their stored depth-2 group flags.

`ledger(absolute)` reads the custodian's packed parent to derive the ledger,
without a second per-account ledger mapping. It returns the root itself for a
ledger root and zero for an unregistered address. Effective unregistered leaves
resolve custody using their explicit parent context without storing an entry.
ERC20 event projection uses this custody reference without walking ancestors;
balance aggregation still follows the actual accounting path.

Special addresses:

- `NATIVE_ADDRESS`
- per-root default credit source leaf at `LedgerLib.SOURCE_ADDRESS` / `Source`
- every account's packed address identifies its absolute parent; ledger roots pack `ROOT_ADDRESS`

## Events

Primary ledger/accounting events:

- `Credit`
- `Debit`
- `LedgerAdded`
- `SubAccountAdded`
- `SubAccountGroupAdded`
- `SubAccountRemoved`
- `SubAccountGroupRemoved`

ERC20-style `Transfer` events are emitted by self-wrapped internal/share token
contracts through `ERC20Wrapper.emitTransfer(...)`. The Ledger accounting stream
is `Credit` / `Debit`.

Resolve each endpoint's direct-child custodian and use its polarity:

| From | To | ERC20 event |
| --- | --- | --- |
| Debit | Debit | `Transfer(h_from,h_to,amount)` |
| Credit | Credit | `Transfer(h_to,h_from,amount)` |
| Credit | Debit | `Transfer(0,h_to,amount)` |
| Debit | Credit | `Transfer(h_from,0,amount)` |

Endpoint polarities still govern internal accounting. All successful projected
self-transfers, deep internal movements and zero transfers retain their events.
Native Credit/Debit logs continue to identify absolute accounting endpoints.

## Testing

Use Foundry tests under `tests/modules/`:

```bash
forge test --match-path tests/modules/Ledger.t.sol
forge test --match-path tests/modules/ERC20Wrapper.t.sol
```

Use `Tree` for visualization/debug:

```solidity
tree.debugTree(root_);
tree.debugTrees(roots_);
```

For authoritative API details, use generated docs in `docs/api/`.
