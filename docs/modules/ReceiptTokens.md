# Receipt tokens

A receipt is an ordinary Internal-token Ledger debit group directly under Root
(depth 2), with a registered
`Source` credit leaf. Holders are unregistered effective debit accounts; issuance
does not register holders. Ledger owns supply and balances.

ReceiptTokenLib stores one immutable absolute, registered backing leaf account
in the receipt ledger's packed address field. It can be nested, debit or credit, including a
Source account. Derive its ledger with `LedgerLib.ledger(backingAccount)` and read
its net balance using its registered polarity. The backing ledger need not be a
token: a Scale ledger can back LP receipts. Groups, unregistered accounts and
accounts within the receipt's own ledger remain invalid backing references.

## Components and API

- `ReceiptWrapper` inherits `ERC20Wrapper`: shared metadata, allowances, balance
  views, transfers and Ledger-emitted ERC20 events. It adds `receiptState()`,
  `convertToReceipts(backing)`, `convertToBacking(receipts)` and `cancel(receipts)`.
- Install `ReceiptTokenView` for the corresponding token-address-parameterized
  views. `receiptState(token)` returns backing account, backing ledger, raw supply
  and raw backing quantity. This replaces the former Float-valued
  `LedgerView.receiptToken` / `LedgerLib.ReceiptToken` snapshot; callers use
  `IReceiptTokenView.State` and the respective ledger decimals. No ERC20 interface
  is required on the backing ledger.
- Install `ReceiptToken` for `cancelReceipt(token, receipts)` (caller only) and
  `cancelReceipt(token, holder, receipts)` (registered wrapper callback only).
  Wrapper cancellation always uses its caller; an ERC20 allowance does not grant
  another account cancellation rights.
- `ReceiptTokenLib.issue(token, holder, backing, data, settle)` and
  `redeem(token, holder, receipts, data, settle)` are internal composition APIs.
  They return the issued receipt quantity or released backing quantity.
  `cancel(token, holder, receipts)` burns without releasing backing.

No public generic issue/redeem endpoint exists: a backing reference is not
permission to spend or change that account. Consuming modules expose their own
authorized settlement endpoints and use the library.

## Settlement boundary

Issue reads the existing ratio, calls a trusted internal settlement callback to
add backing, verifies the exact backing increase and unchanged supply, then
transfers receipt Source credit into the holder's debit balance.

Redeem quotes the pre-burn ratio, burns the authorized holder's receipts, calls
settlement to release backing, then verifies the exact backing decrease and
expected supply. A mismatch reverts the entire operation. Callback type is
`function(address token, uint256 backing, bytes memory data) internal`.

Consumers must independently authorize issuance, holder burns and backing
movements, enforce slippage limits, and guard reentrancy across their entire
operation (including callbacks and external custody calls). Delta checks do not
replace authorization or reentrancy protection. Trusted installed modules can
already mutate Ledger; this library does not sandbox them.

Token-backed settlement can handle asset custody and Ledger transfers. Scale
settlement can update pool accounting without invoking an ERC20. The library
never assumes deposit/withdraw mechanics, counterparties or an external asset.
It never calls an arbitrary user-supplied settlement target.

Receipt mint/burn operations use the normal `LedgerLib.transfer` path, preserving
installed SR transfer hooks. Public five-argument Ledger transfer remains absent;
the authorized six-argument wrapper callback and native/external receive, wrap
and unwrap behavior are unchanged. SR integration is separate work.

## Arithmetic and boundary policy

All arguments/results are raw integer quantities in the corresponding ledger's
decimals. Exact full-precision integer `Math.mulDiv` rounds down:

```text
issued receipts = added backing * existing supply / existing backing
released backing = redeemed receipts * existing backing / existing supply
```

Existing ratios already incorporate decimals. Decimal rescaling only applies to
an empty receipt (both supply and backing zero): one whole receipt per whole
backing unit. Scaling up uses checked multiplication, scaling down floors. Decimal
differences above 77 revert instead of overflowing `10**difference`; equal decimal
counts, including zero, work. Results exceeding uint256 revert.

- Positive supply and backing use the existing ratio.
- Zero supply with positive backing rejects issuance/conversion: no implicit gift
  of orphan backing to a new first holder.
- Positive supply with zero backing rejects issuance. Redemption returns zero and
  can burn worthless receipts; cancellation is also available.
- Zero-quantity conversions return zero for a valid receipt. Zero mutations revert.
- Issuance that rounds to zero receipts reverts. Redemption that rounds to zero
  with positive backing reverts; intentional donation uses cancellation.
- Full redemption releases all backing exactly. Partial-redemption rounding stays
  with remaining holders. The last holder receives the remainder.
- Cancellation reduces supply only. Cancelling the last receipt leaves orphan
  backing and blocks reinitialization until application policy resolves it.
- Pure conversion quotes may exceed supply; actual redemption cannot exceed
  supply or the authorized holder's balance.

The initial 1:1 unit ratio, donation/orphan recovery and recapitalization after
complete backing loss are explicit economic policy boundaries. Applications must
choose any recovery workflow; this foundation grants no recovery spending power.
There are no virtual shares or assets and no generic anti-donation mechanism.
Applications opening issuance to untrusted users must address first-deposit and
backing-donation economics and set minimum receipt/output amounts.

## Factory and storage

`LedgerTokenFactory.createReceiptToken(absoluteBackingAccount, TokenMetadata)` now
deploys `ReceiptWrapper`. Shared metadata remains `(name, symbol, decimals,
version)`, with the same metadata salt. Use
`LedgerTokenFactoryView.predictReceiptToken(name, symbol, decimals, version)`.
`predictToken(...)` continues to predict ordinary internal `ERC20Wrapper` roots.
Different creation bytecode separates receipt/internal addresses for identical
metadata. Backing is intentionally not in the salt; recreating a receipt with
identical metadata and different backing reverts. Matching creation is idempotent;
an occupied, unregistered predicted address is rejected.

All repository receipt creation callers go through this factory library. SR
continues to create ordinary internal tokens.

ReceiptTokenLib owns registration and backing eligibility validation. Its internal
`register` function creates a `TokenKind.Internal` ledger through
`LedgerLib.addLedger`, supplying the backing account as the packed address.
No receipt discriminator, receipt bit, namespace or separate mapping exists.
An ordinary internal root packs `ROOT_ADDRESS`; a receipt root packs its backing
account. `LedgerLib.parent` still returns `ROOT_ADDRESS` for either root, so this
metadata does not change ledger topology.

`LedgerLib.TokenKind` contains Unregistered (0), Native (1), External (2) and
Internal (3). Flag packing and registration accept that enum; `LedgerLib.tokenKind`
and `TreeView.tokenKind` return it. LedgerLib has no receipt-specific code or
FloatLib dependency: it packs and reads the address without interpreting it.

Receipt inspection is address-based: `ReceiptTokenView.isReceipt(address token)`
and `receiptAccount(address token)` interpret the token's Ledger flags in receipt
code. A receipt must be an Internal ledger with a packed reference to a registered
backing leaf outside its own ledger. Root, zero, unregistered, group and self-ledger
references do not identify receipts. Unknown addresses and ordinary internal tokens
return false / zero; `receiptState` rejects them.

Ledger's registration replay checks preserve the backing reference: matching
metadata and flags are idempotent, while a changed backing reference or metadata
reverts. An existing ordinary internal root cannot be silently adopted because its
packed Root reference differs from the proposed backing account. The reference
remains after complete redemption or cancellation. The backing ledger, polarity,
balance, receipt supply and holder balances are all derived from Ledger.

Ledger and Dispatcher storage structs, slots and bit positions are unchanged.
Receipt code adds no storage. The wrapper only inherits shared ERC20
metadata/allowance storage; it adds no accounting storage.
