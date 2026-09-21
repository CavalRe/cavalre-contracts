# Share tokens

A share is an ordinary Internal-token Ledger debit group directly under Root
(depth 2), with a registered
`Source` credit leaf. Wallet holders use unregistered effective debit accounts;
issuance does not register them. Registered debit custody leaves, including nested
accounts, can also receive issuance, redeem and cancel shares. Issue and redeem
each take an explicit absolute parent and relative leaf. For direct wallet accounts,
the parent is the share token root and the relative key is the wallet. Wrapper transfer calls
remain restricted to direct accounts; they cannot spend a projected subtree.
Zero addresses, credit accounts and groups are invalid holders for these operations.
Ledger owns supply and balances.

ShareTokenLib stores one immutable absolute, registered backing leaf account
per share token in its own namespace. It can be nested, debit or credit, including
a Source account. Derive its ledger with `LedgerLib.ledger(backingAccount)` and read
its net balance using its registered polarity. The backing ledger need not be a
token: a Scale ledger can back LP shares. Groups, unregistered accounts and
accounts within the share's own ledger remain invalid backing references.

## Components and API

- `ShareToken` inherits `ERC20Wrapper`: shared metadata, allowances, balance
  views, transfers and Ledger-emitted ERC20 events. It adds `shareTokenState()`,
  `convertToShares(backing)` and `convertToBacking(shares)`.
- Install `ShareTokenView` for the corresponding token-address-parameterized
  views. `shareTokenState(token)` returns backing account, backing ledger, raw supply
  and raw backing quantity. Callers use `IShareTokenView.State` and the respective
  ledger decimals. No ERC20 interface
  is required on the backing ledger.
- ERC20 `transfer` and `transferFrom` require direct debit leaves at both endpoints.
  Credit accounts, including Source, are rejected even for zero amounts; a rejected
  `transferFrom` leaves allowance unchanged. Users cannot burn shares through ERC20
  transfers. There is no separate public cancellation endpoint or separate mutation
  module to install.
- `ShareTokenLib.issue(token, parent, relative, backing)` mints shares for backing
  the caller has already added and verified, returning the issued quantity.
- `ShareTokenLib.redeem(token, parent, relative, shares)` burns shares and
  returns the backing quantity the caller must release and verify.
- Both functions use explicit account context, with one implementation each.
  The parent is an absolute accounting group on the share ledger. Neither takes
  callback functions or opaque data. These remain trusted internal module APIs.
- Internal `cancel(token, parent, relative, shares)` burns without releasing backing.

No public generic issue/redeem/cancel endpoint exists: a backing reference is not
permission to spend or change that account. Consuming modules expose their own
authorized settlement endpoints and use the library.

## Settlement boundary

ShareTokenLib settles the share ledger through `LedgerLib.SOURCE_ADDRESS`:
issuance transfers from `<ShareToken>/Source` to the recipient; redemption
transfers from the recipient back to Source. Backing movements are direct calls
in the consuming module, with no settlement callback passed into ShareTokenLib.

For issuance, the caller snapshots supply/backing, adds backing, and verifies the
exact backing increase and unchanged supply before calling `issue`. The library
subtracts the supplied addition from the current backing balance to recover the
pre-addition ratio. Pricing against the balance after adding backing would issue
too few shares. The caller must not count existing backing as a new contribution.

For redemption, the caller snapshots supply/backing, calls `redeem`, releases the
returned backing quantity, then verifies the exact backing decrease and expected
supply decrease. ShareTokenLib emits `ShareRedeemed` when it burns the shares,
before the caller releases backing. A later settlement failure must revert the
whole transaction, including the burn and its events.

Consumers must perform these steps atomically, authorize issuance, holder burns
and backing movements, enforce slippage limits, and guard reentrancy across the
entire operation. The exact-delta checks now belong to the consuming module;
calling the internal share library alone does not verify backing settlement.
The `ShareApplication` in `tests/modules/ShareToken.t.sol` demonstrates the
sequence and rollback checks with a non-token Scale ledger.

Backing settlement can use Ledger postings or include external custody operations
as required by the application. ShareTokenLib does not choose funding/payout
accounts or invoke an ERC20 on a non-token backing ledger.

Share mint/burn operations resolve effective endpoint flags and pass them to the
single `LedgerLib.transfer` implementation. Ledger posting does not invoke SR
hooks; consuming modules own any required settlement. Public five-argument Ledger
transfer remains absent. ERC20 wrappers supply direct-account parents to the
authenticated six-argument callback; native/external receive, wrap and unwrap
behavior is preserved. The SR-owned public transfer path remains separate work.

## Arithmetic and boundary policy

All arguments/results are raw integer quantities in the corresponding ledger's
decimals. Exact full-precision integer `Math.mulDiv` rounds down:

```text
issued shares = added backing * existing supply / existing backing
released backing = redeemed shares * existing backing / existing supply
```

Existing ratios already incorporate decimals. Decimal rescaling only applies to
an empty share (both supply and backing zero): one whole share per whole
backing unit. Scaling up uses checked multiplication, scaling down floors. Decimal
differences above 77 revert instead of overflowing `10**difference`; equal decimal
counts, including zero, work. Results exceeding uint256 revert.

- Positive supply and backing use the existing ratio.
- Zero supply with positive backing rejects issuance/conversion: no implicit gift
  of orphan backing to a new first holder.
- Positive supply with zero backing rejects issuance. Redemption returns zero and
  can burn worthless shares; cancellation is also available.
- Zero-quantity conversions return zero for a valid share. Zero-quantity share-library
  mutations revert; ERC20 transfers retain their ordinary zero-amount behavior.
- Issuance that rounds to zero shares reverts. Redemption that rounds to zero
  with positive backing reverts; intentional donation uses cancellation.
- Full redemption releases all backing exactly. Partial-redemption rounding stays
  with remaining holders. The last holder receives the remainder.
- Cancellation reduces supply only. Cancelling the last share leaves orphan
  backing and blocks reinitialization until application policy resolves it.
- Pure conversion quotes may exceed supply; actual redemption cannot exceed
  supply or the authorized holder's balance.

The initial 1:1 unit ratio, donation/orphan recovery and recapitalization after
complete backing loss are explicit economic policy boundaries. Applications must
choose any recovery workflow; this foundation grants no recovery spending power.
There are no virtual shares or assets and no generic anti-donation mechanism.
Applications opening issuance to untrusted users must address first-deposit and
backing-donation economics and set minimum share/output amounts.

## Factory and storage

`LedgerTokenFactory.createShareTokens(ShareTokenConfig[])` deploys
`ShareToken` contracts. Each config pairs an absolute `backingAccount` with
its `TokenMetadata metadata`. The factory processes items in input order and
returns matching address and flags arrays. Any failure reverts the whole batch;
an empty batch returns empty arrays. Factory calls require the module owner.
`createInternalTokens(TokenMetadata[])` is the corresponding ordinary-token batch
API. Both library creation functions remain singular.

Shared metadata remains `(name, symbol, decimals, version)`, with the same metadata salt. Use
`LedgerTokenFactoryView.predictShareTokenAddress(name, symbol, decimals, version)`.
`predictERC20TokenAddress(...)` continues to predict ordinary internal `ERC20Wrapper` roots.
Different creation bytecode separates share/internal addresses for identical
metadata. Backing is intentionally not in the salt; recreating a share with
identical metadata and different backing reverts. Matching creation is idempotent;
an occupied, unregistered predicted address is rejected.

All repository share creation callers go through this factory library. SR
continues to create ordinary internal tokens.

`LedgerTokenFactoryLib.createShareToken` owns wrapper deployment, Ledger
registration and backing binding. It validates backing eligibility through
ShareTokenLib and creates a `TokenKind.Internal` ledger through
`LedgerLib.addLedger`, which always packs `ROOT_ADDRESS` as the parent. The immutable
token-to-backing binding lives in `ShareTokenLib.Store.backingAccounts`, under
the ERC-7201 namespace `cavalre.storage.ShareToken`. A zero entry means the token
is unregistered. There is no separate share bit or token kind.

Every Ledger packed address identifies its absolute parent. All ledger roots,
including shares, pack `ROOT_ADDRESS`; `LedgerLib.parent` reads that address
directly. Share backing no longer overloads the parent field.

`LedgerLib.TokenKind` contains Unregistered (0), Native (1), External (2) and
Internal (3). Flag packing and registration accept that enum; `LedgerLib.tokenKind`
and `TreeView.tokenKind` return it. LedgerLib has no share-specific code or
FloatLib dependency.

Share inspection is address-based: `ShareTokenView.isShareToken(address token)`
and `backingAccount(address token)` read share registration. Unknown addresses
and ordinary internal tokens return false / zero; `shareTokenState` rejects them.
Registration requires a registered backing leaf outside the share ledger;
Root, zero, unregistered accounts, groups and self-ledger accounts are invalid.
If an empty backing leaf is removed, the stored binding and share identity
remain, but share state reads and share-library operations reject the missing backing account.

Share registration explicitly checks the stored backing reference on replay;
Ledger checks matching metadata and flags. Identical registrations are idempotent,
while a changed backing reference or metadata reverts. An existing ordinary ledger
without a share registration cannot be adopted, even when its flags match.
The binding remains after complete redemption or cancellation. The backing ledger,
polarity, balance, share supply and holder balances are all derived from Ledger.

Ledger stores custody instead of ledger references at the same mapping position;
see [Ledger storage](Ledgers.md#storage). Ledger's namespace and packed bit positions,
and Dispatcher storage are unchanged.
ShareTokenLib adds only the backing-account mapping in its own namespace. The
wrapper only inherits shared ERC20 metadata/allowance storage; it adds no
accounting storage.
