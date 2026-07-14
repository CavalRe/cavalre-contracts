# Ledger.sol

`modules/ledger/Ledger.sol` implements CavalRe’s hierarchical double-entry ledger module.

## Scope

- token/account metadata (`name`, `symbol`, `decimals`)
- account tree management (`addSubAccount*`, `removeSubAccount*`)
- balances + routed transfers
- wrapper-facing transfer hooks
- default-source registration per root
- library-level wrap/unwrap settlement flows
- canonical-root ERC20 surface via `examples/LedgerERC20.sol`
- topology/debug surface via `modules/tree/TreeView.sol`

## Key Model

- every token ledger has a root
- canonical root is `address(this)`
- every registered root is a debit group
- root token type is encoded as `LedgerLib.TokenKind`: `Native`, `External`, `Internal`, or `Claim`
- account shape and polarity are encoded as `LedgerLib.AccountKind`: `DebitGroup`, `CreditGroup`, `DebitLedger`, or `CreditLedger`
- subaccounts are deterministic addresses derived from parent + label/address
- name-form `addSubAccount*` helpers delegate to addr-form overloads using `toAddress(name_)`
- transfers perform a single coordinated upward walk from source and destination leaves
- leaf polarity determines which balance column (`debits` or `credits`) each path mutates
- when both paths converge on the same ancestor on the same side, remaining upward mutations cancel and the walk can stop early
- internal roots are created deterministically with `CREATE2` via `createInternalToken(...)`, so `(name, symbol, decimals)` uniquely identifies the root and repeated calls are idempotent
- internal and claim roots are self-wrapped at creation so the root address is immediately usable as an ERC20 surface
- native/external roots are registered as ledger roots without self-wrapped ERC20 surfaces
- claim roots are created with `createClaimToken(...)`, reference one registered non-claim Ledger leaf account, and are deterministic by `(name, symbol, decimals, claimAccount)`
- canonical root ERC20 UX is handled by `examples/LedgerERC20.sol`, which reads metadata/supply/balances from `LedgerLib` and keeps allowances in `LedgerERC20Lib`
- every root also auto-registers `address(0)` / `Zero Address` as its default credit source leaf
- `effectiveFlags(parent_, addr_)` returns `(effectiveFlags, originalFlags, absoluteAddress)` for possibly-unregistered derived leaves
- `transfer(...)` returns the resolved root plus effective from/to flags
- 5-arg `transfer(...)` is wrapper/canonical-ERC20 plumbing; 4-arg `transfer(...)` is direct user path
- both transfer paths reject wrong-polarity sources after `LedgerLib.transfer(...)` resolves effective flags
- `wrap(token_, amount_)` mints from the default source into `msg.sender`
- `unwrap(token_, amount_)` burns from `msg.sender` back into the default source
- `LedgerLib.wrap(...)` / `unwrap(...)` only apply to external/native debit roots; internal and claim roots revert
- tree/root mutators are intended to be idempotent: exact replays return the same result or become no-ops, while conflicting replays revert

## Address Derivation

Ledger account addresses are deterministic identifiers, not externally owned
accounts.

`LedgerLib.toAddress(name_)` derives a relative subaccount address from a
human-readable name. This is a child key. It is not a complete position in the
ledger tree until it is anchored under a parent.

`LedgerLib.toAddress(parent_, relative_)` derives the canonical absolute address
for a specific point in the ledger tree. This is the primary tree identity:

```solidity
absolute = LedgerLib.toAddress(parent, relative);
```

`LedgerLib.toAddress(parent_, name_)` is the convenience form:

```solidity
LedgerLib.toAddress(parent, LedgerLib.toAddress(name));
```

Use the two-step form when the distinction between a named relative subaccount
and its absolute tree location matters for readability.

## Storage

Ledger storage lives in `modules/ledger/LedgerLib.sol` (`LedgerLib.Store`) under an ERC-7201-style namespaced slot.

Core fields include:

- metadata maps (`name`, `symbol`, `decimals`)
- tree maps (`root`, `subs`, `subIndex`)
- wrapper map (`wrapper`) for token roots
- flags map (`flags`) containing `AccountKind`, `TokenKind`, depth, and a packed address slot
- balances maps (`debits`, `credits`)

Special addresses:

- `NATIVE_ADDRESS`
- per-root default credit source leaf at `address(0)` / `Zero Address`
- claim root packed address slot stores the referenced absolute claim account

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

ERC20-style `Transfer` events are emitted by self-wrapped internal/claim token
contracts through `ERC20Wrapper.emitTransfer(...)`. The Ledger accounting stream
is `Credit` / `Debit`.

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
