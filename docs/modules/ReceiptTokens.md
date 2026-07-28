# Receipt Tokens

## Summary

A receipt token is a Ledger-native token whose supply represents receipts on the balance of one registered Ledger leaf account.

Receipt tokens are not receipts on other tokens directly. They are receipts on Ledger accounts. The referenced account's Ledger tree determines the receipted root asset, account polarity, and current account balance.

```text
receipt token -> registered Ledger leaf account
receipt account -> root asset + polarity + balance
```

Ledger records the reference. Consuming protocols define valuation, minting, burning, settlement, and whether a receipt token is acceptable in a given protocol role.

## Terms

- **absolute address**: the canonical Ledger account address derived from its absolute parent and a relative child address.
- **relative address**: the local child account address supplied under a parent.
- **root**: a depth-1 group account representing one token tree.
- **receipt token**: a `TokenKind.Receipt` root.
- **receipt account**: the registered Ledger leaf referenced by a receipt token.

For a receipt-token creation call, `parent_` is an absolute parent account and `addr_` is a relative child account. Ledger derives the referenced absolute receipt account:

```solidity
receiptAccount = LedgerLib.toAddress(parent_, addr_);
```

## V1 Decisions

- first deployment only; no deployed-state migration
- all registered roots are debit groups
- receipt token roots are debit groups
- receipt accounts must be registered Ledger leaves
- group-account and root-account receipts are rejected
- nested receipts are rejected
- receipt tokens have exact `TokenKind.Receipt` classification and are not `isInternal`
- receipt tokens cannot be wrapped or unwrapped as external custody assets
- root token creation does not accept root credit polarity
- old boolean flag constants are removed
- downstream packages must migrate from raw flag-bit checks to helpers

## Flag Model

Ledger flags encode two classifications.

`AccountKind` describes whether an address is unregistered, a group account, or a leaf ledger account, including debit/credit polarity:

```solidity
enum AccountKind {
    Unregistered, // 0
    DebitGroup,   // 1
    CreditGroup,  // 2
    DebitLedger,  // 3
    CreditLedger  // 4
}
```

`TokenKind` describes the token type of a registered root:

```solidity
enum TokenKind {
    Unregistered, // 0 / non-root / no token semantics
    Native,       // 1
    External,     // 2
    Internal,     // 3
    Receipt         // 4
}
```

This avoids ambiguous interpretations such as `!isGroup(flags)` meaning either "ledger account" or "unregistered address".

All registered roots are encoded as:

```text
accountKind(rootFlags) == AccountKind.DebitGroup
depth(rootFlags) == 1
```

Credit polarity remains available for non-root group accounts and leaf ledger accounts.

## Flag Packing

Current packing:

```solidity
uint256 constant ACCOUNT_KIND_SHIFT = 0;
uint256 constant ACCOUNT_KIND_MASK = uint256(0x07) << ACCOUNT_KIND_SHIFT;

uint256 constant TOKEN_KIND_SHIFT = 3;
uint256 constant TOKEN_KIND_MASK = uint256(0x07) << TOKEN_KIND_SHIFT;

uint256 constant FLAG_DEPTH_SHIFT = 8;
uint256 constant FLAG_DEPTH_MASK = uint256(0xff) << FLAG_DEPTH_SHIFT;
uint256 constant PACK_ADDR_SHIFT = 96;
```

The packed address slot has two roles:

```text
non-root account: packed address = parent account
non-receipt token root:   packed address = zero
receipt token root:       packed address = receipt account
```

Root detection must therefore ignore the packed address and use shape/depth:

```solidity
isRoot(flags_) == depth(flags_) == 1 && isGroup(flags_)
```

`parent(flags_)` returns zero for roots, including receipt token roots. Use `receiptAccount(flags_)` to decode a receipt token root's referenced account.

## Helpers

`LedgerLib` exposes enum accessors:

```solidity
function accountKind(uint256 flags_) internal pure returns (AccountKind);
function tokenKind(uint256 flags_) internal pure returns (TokenKind);
function packedAddress(uint256 flags_) internal pure returns (address);
```

Compatibility helpers are defined over the enums:

```solidity
isGroup(flags)      -> DebitGroup or CreditGroup
isLedger(flags)     -> DebitLedger or CreditLedger
isCredit(flags)     -> CreditGroup or CreditLedger
isInternal(flags)   -> TokenKind.Internal
isUnregisteredAccount(flags) -> AccountKind.Unregistered
isUnregisteredToken(flags)   -> TokenKind.Unregistered
isNative(flags)     -> TokenKind.Native
isExternal(flags)   -> TokenKind.External
isReceipt(flags)      -> TokenKind.Receipt
isRoot(flags)       -> depth(flags) == 1 && isGroup(flags)
parent(flags)       -> address(0) for roots, packedAddress(flags) otherwise
receiptAccount(flags) -> packedAddress(flags) for receipt token roots, address(0) otherwise
```

`isInternal(flags)` is exact to `TokenKind.Internal`. Receipt tokens are classified by `isReceipt(flags)`, and custody logic that needs externally wrapped assets should test `isExternal(flags) || isNative(flags)` explicitly.

## Receipt Token Model

A receipt token is a registered root with:

```text
accountKind(flags(receiptToken)) == AccountKind.DebitGroup
tokenKind(flags(receiptToken)) == TokenKind.Receipt
depth(flags(receiptToken)) == 1
packedAddress(flags(receiptToken)) == receiptAccount
```

It behaves like an internal Ledger token for balances, transfers, wrappers, and total supply. The root is self-wrapped at creation.

The receipt account is a registered Ledger leaf with:

```text
accountKind(flags(receiptAccount)) == AccountKind.DebitLedger
    or
accountKind(flags(receiptAccount)) == AccountKind.CreditLedger
```

Use existing Ledger primitives for derived data:

- receipted root: `LedgerLib.root(receiptAccount)`
- receipt-account flags: `LedgerLib.flags(receiptAccount)`
- receipt-account balance: `LedgerLib.balanceOf(receiptAccount, LedgerLib.isCredit(LedgerLib.flags(receiptAccount)))`
- total receipt supply: `LedgerLib.totalSupply(receiptToken)`

Ledger does not add one-line helpers for values already available through these primitives.

## Receipt Invariants

A valid receipt-token registration satisfies:

```solidity
accountKind(flags(receiptToken)) == AccountKind.DebitGroup;
tokenKind(flags(receiptToken)) == TokenKind.Receipt;
depth(flags(receiptToken)) == 1;
isLedger(flags(receiptAccount));
LedgerLib.root(receiptAccount) != receiptToken;
!isReceipt(flags(LedgerLib.root(receiptAccount)));
```

The receipt-account reference is immutable after registration.

V1 rejects:

- unregistered receipt accounts
- group-account receipts
- root-account receipts
- a receipt account inside the same receipt-token tree
- a receipt account whose root is itself a receipt token
- mutable receipt-account references
- recursive receipt valuation or cycle formation

## Token Impact

The enum refactor changes flag interpretation for every Ledger account. Intended behavior for native, external, and internal roots remains unchanged when callers use helpers instead of raw bit checks.

### Native Roots

```text
accountKind(rootFlags) == AccountKind.DebitGroup
tokenKind(rootFlags) == TokenKind.Native
depth(rootFlags) == 1
packedAddress(rootFlags) == address(0)
```

- `addNativeToken` remains idempotent.
- wrapper behavior remains unchanged.
- `wrap` requires exact `msg.value`.
- `unwrap` transfers native value to `msg.sender`.
- subaccounts keep debit/credit polarity through `AccountKind`.

### External Roots

```text
accountKind(rootFlags) == AccountKind.DebitGroup
tokenKind(rootFlags) == TokenKind.External
depth(rootFlags) == 1
packedAddress(rootFlags) == address(0)
```

- `addExternalToken(address[])` remains idempotent for matching ERC20 metadata.
- external roots are not self-wrapped; custody movement is handled by `wrap` / `unwrap`.
- `wrap` uses `safeTransferFrom`.
- `unwrap` uses `safeTransfer`.
- `isExternal(flags)` is an explicit `TokenKind.External` check.

### Internal Roots

```text
accountKind(rootFlags) == AccountKind.DebitGroup
tokenKind(rootFlags) == TokenKind.Internal
depth(rootFlags) == 1
packedAddress(rootFlags) == address(0)
```

- `LedgerTokenFactory.createInternalToken(TokenMetadata[])` creates debit roots only.
- internal roots remain self-wrapped.
- credit-side accounting remains represented by non-root `CreditGroup` and `CreditLedger` accounts.

### Receipt Token Roots

```text
accountKind(rootFlags) == AccountKind.DebitGroup
tokenKind(rootFlags) == TokenKind.Receipt
depth(rootFlags) == 1
packedAddress(rootFlags) == receiptAccount
```

- `LedgerTokenFactory.createReceiptToken(absoluteReceiptAccount, TokenMetadata)` creates debit roots only.
- receipt token root address derivation includes `(name, symbol, decimals, version)`.
- receipt token roots are self-wrapped.
- receipt token roots are classified by `isReceipt(flags)` and are not internal by `isInternal(flags)`.
- `wrap` and `unwrap` reject receipt token roots.
- Ledger records the reference account only; protocol economics live above Ledger.

### Subaccounts

Subaccounts do not need their own token kind. Token kind is derived from the root:

```solidity
tokenKind(flags(root(account_)))
```

For non-root accounts:

```text
packedAddress(accountFlags) == parent(account)
depth(accountFlags) > 1
accountKind(accountFlags) != AccountKind.Unregistered
```

## API Surface

`LedgerLib` receipt-token helpers:

```solidity
function isReceipt(uint256 flags_) internal pure returns (bool);
function receiptAccount(uint256 flags_) internal pure returns (address);
```

`LedgerTokenFactory` exposes:

```solidity
struct TokenMetadata {
    string name;
    string symbol;
    uint8 decimals;
    string version;
}

function createInternalToken(TokenMetadata[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);

function createReceiptToken(address absoluteReceiptAccount, TokenMetadata memory token)
    external
    returns (address tokenAddress, uint256 flags);
```

`LedgerTokenFactoryView` exposes deterministic token helpers:

```solidity
function tokenSalt(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    external
    pure
    returns (bytes32);

function predictToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    external
    view
    returns (address);
```

`Ledger` exposes root registration for external tokens through `addExternalToken(address[])`, but internal and receipt token creation live in `LedgerTokenFactory`.

`Tree` exposes debug/introspection helpers for enum flags and receipt token roots:

```solidity
function accountKind(uint256 flags_) external pure returns (LedgerLib.AccountKind);
function tokenKind(uint256 flags_) external pure returns (LedgerLib.TokenKind);
function packedAddress(uint256 flags_) external pure returns (address);
function isUnregisteredAccount(uint256 flags_) external pure returns (bool);
function isDebitGroup(uint256 flags_) external pure returns (bool);
function isCreditGroup(uint256 flags_) external pure returns (bool);
function isDebitLedger(uint256 flags_) external pure returns (bool);
function isCreditLedger(uint256 flags_) external pure returns (bool);
function isLedger(uint256 flags_) external pure returns (bool);
function isUnregisteredToken(uint256 flags_) external pure returns (bool);
function isInternal(uint256 flags_) external pure returns (bool);
function isReceipt(uint256 flags_) external pure returns (bool);
function receiptAccount(uint256 flags_) external pure returns (address);
```

## Migration Notes

There are no existing deployments. Here, migration means updating source code, tests, docs, and downstream packages.

Risky source-code migration points:

- `parent(uint256)`: no longer raw packed address for receipt token roots
- `isRoot(uint256)`: no longer requires packed parent to be zero
- `isExternal(uint256)`: explicit `TokenKind.External`, not a negation
- `createToken(...)`: renamed to `createInternalToken(...)`
- `createInternalToken(...)`: no longer accepts root credit polarity
- raw `FLAG_IS_*` bit reads: migrate to helpers or enum accessors

Removed boolean flag constants:

```solidity
FLAG_IS_GROUP
FLAG_IS_CREDIT
FLAG_IS_INTERNAL
FLAG_IS_NATIVE
FLAG_IS_REGISTERED
```

Use enum masks and helpers instead.

## Protocol Responsibilities

Protocols decide:

- whether a receipt token can be a target asset
- whether a receipt token can be a distribution asset
- whether a receipt token can be a reserve/deposit asset
- how receipt-account balances are valued
- how receipt supply is minted, burned, or settled

A protocol may be stricter than Ledger. For example, a pool can allow receipt tokens as target/distribution tokens while rejecting them as deposit reserve assets.

## Storage Compatibility

Receipt accounts do not add a new storage mapping. The referenced absolute receipt account is stored in the packed address slot of the receipt token root flags.

The v1 launch target is a fresh deployment. No old-flag compatibility layer is required.

## Required Coverage

Tests should cover:

- native root flags decode to `DebitGroup + Native`
- external root flags decode to `DebitGroup + External`
- internal root flags decode to `DebitGroup + Internal`
- receipt token root flags decode to `DebitGroup + Receipt`
- debit and credit subaccounts decode to `DebitLedger` / `CreditLedger`
- group subaccounts decode to `DebitGroup` / `CreditGroup`
- `parent(flags)` returns zero for all roots, including receipt token roots
- `receiptAccount(flags)` returns the packed reference only for receipt token roots
- `isRoot(flags)` depends on depth and group kind, not packed address
- transfer parent-walk behavior is unchanged
- wrap/unwrap behavior is unchanged for native/external roots
- wrap/unwrap reject internal and receipt token roots
- `createInternalToken(TokenMetadata[])`, `addNativeToken`, and `addExternalToken(address[])` remain idempotent
- `createInternalToken(TokenMetadata[])` creates debit roots only
- receipt token creation is idempotent
- receipt account cannot be unregistered
- receipt account cannot be a group account
- receipt account cannot be inside the same receipt-token tree
- receipt account cannot belong to a receipt-token root

## Non-Goals For V1

- root-account receipts
- group-account receipts
- mutable receipt-account references
- cross-router or cross-ledger proof receipts
- recursive valuation helpers in Ledger
- automatic redemption semantics in Ledger
