# Claim Tokens

## Summary

A claim token is a Ledger-native token whose supply represents claims on the balance of one registered Ledger leaf account.

Claim tokens are not claims on other tokens directly. They are claims on Ledger accounts. The referenced account's Ledger tree determines the claimed root asset, account polarity, and current account balance.

```text
claim token -> registered Ledger leaf account
claim account -> root asset + polarity + balance
```

Ledger records the reference. Consuming protocols define valuation, minting, burning, settlement, and whether a claim token is acceptable in a given protocol role.

## Terms

- **absolute address**: the canonical Ledger account address derived from its absolute parent and a relative child address.
- **relative address**: the local child account address supplied under a parent.
- **root**: a depth-1 group account representing one token tree.
- **claim token**: a `TokenKind.Claim` root.
- **claim account**: the registered Ledger leaf referenced by a claim token.

For a claim-token creation call, `parent_` is an absolute parent account and `addr_` is a relative child account. Ledger derives the referenced absolute claim account:

```solidity
claimAccount = LedgerLib.toAddress(parent_, addr_);
```

## V1 Decisions

- first deployment only; no deployed-state migration
- all registered roots are debit groups
- claim roots are debit groups
- claim accounts must be registered Ledger leaves
- group-account and root-account claims are rejected
- nested claims are rejected
- claim tokens have exact `TokenKind.Claim` classification and are not `isInternal`
- claim tokens cannot be wrapped or unwrapped as external custody assets
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
    Claim         // 4
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
non-claim root:   packed address = zero
claim root:       packed address = claim account
```

Root detection must therefore ignore the packed address and use shape/depth:

```solidity
isRoot(flags_) == depth(flags_) == 1 && isGroup(flags_)
```

`parent(flags_)` returns zero for roots, including claim roots. Use `claimAccount(flags_)` to decode a claim root's referenced account.

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
isClaim(flags)      -> TokenKind.Claim
isRoot(flags)       -> depth(flags) == 1 && isGroup(flags)
parent(flags)       -> address(0) for roots, packedAddress(flags) otherwise
claimAccount(flags) -> packedAddress(flags) for claim roots, address(0) otherwise
```

`isInternal(flags)` is exact to `TokenKind.Internal`. Claim tokens are classified by `isClaim(flags)`, and custody logic that needs externally wrapped assets should test `isExternal(flags) || isNative(flags)` explicitly.

## Claim Token Model

A claim token is a registered root with:

```text
accountKind(flags(claimToken)) == AccountKind.DebitGroup
tokenKind(flags(claimToken)) == TokenKind.Claim
depth(flags(claimToken)) == 1
packedAddress(flags(claimToken)) == claimAccount
```

It behaves like an internal Ledger token for balances, transfers, wrappers, and total supply. The root is self-wrapped at creation.

The claim account is a registered Ledger leaf with:

```text
accountKind(flags(claimAccount)) == AccountKind.DebitLedger
    or
accountKind(flags(claimAccount)) == AccountKind.CreditLedger
```

Use existing Ledger primitives for derived data:

- claimed root: `LedgerLib.root(claimAccount)`
- claim-account flags: `LedgerLib.flags(claimAccount)`
- claim-account balance: `LedgerLib.balanceOf(claimAccount, LedgerLib.isCredit(LedgerLib.flags(claimAccount)))`
- total claim supply: `LedgerLib.totalSupply(claimToken)`

Ledger does not add one-line helpers for values already available through these primitives.

## Claim Invariants

A valid claim-token registration satisfies:

```solidity
accountKind(flags(claimToken)) == AccountKind.DebitGroup;
tokenKind(flags(claimToken)) == TokenKind.Claim;
depth(flags(claimToken)) == 1;
isLedger(flags(claimAccount));
LedgerLib.root(claimAccount) != claimToken;
!isClaim(flags(LedgerLib.root(claimAccount)));
```

The claim-account reference is immutable after registration.

V1 rejects:

- unregistered claim accounts
- group-account claims
- root-account claims
- a claim account inside the same claim-token tree
- a claim account whose root is itself a claim token
- mutable claim-account references
- recursive claim valuation or cycle formation

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

### Claim Roots

```text
accountKind(rootFlags) == AccountKind.DebitGroup
tokenKind(rootFlags) == TokenKind.Claim
depth(rootFlags) == 1
packedAddress(rootFlags) == claimAccount
```

- `LedgerTokenFactory.createClaimToken(absoluteClaimAccount, TokenMetadata)` creates debit roots only.
- claim root address derivation includes `(name, symbol, decimals, version)`.
- claim roots are self-wrapped.
- claim roots are classified by `isClaim(flags)` and are not internal by `isInternal(flags)`.
- `wrap` and `unwrap` reject claim roots.
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

`LedgerLib` claim-token helpers:

```solidity
function isClaim(uint256 flags_) internal pure returns (bool);
function claimAccount(uint256 flags_) internal pure returns (address);
function claimAccount(address token_) internal view returns (address);
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

function createClaimToken(address absoluteClaimAccount, TokenMetadata memory token)
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

`Ledger` exposes root registration for external tokens through `addExternalToken(address[])`, but internal and claim token creation live in `LedgerTokenFactory`.

`Tree` exposes debug/introspection helpers for enum flags and claim roots:

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
function isClaim(uint256 flags_) external pure returns (bool);
function claimAccount(uint256 flags_) external pure returns (address);
```

## Migration Notes

There are no existing deployments. Here, migration means updating source code, tests, docs, and downstream packages.

Risky source-code migration points:

- `parent(uint256)`: no longer raw packed address for claim roots
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

- whether a claim token can be a target asset
- whether a claim token can be a distribution asset
- whether a claim token can be a reserve/deposit asset
- how claim-account balances are valued
- how claim supply is minted, burned, or settled

A protocol may be stricter than Ledger. For example, a pool can allow claim tokens as target/distribution tokens while rejecting them as deposit reserve assets.

## Storage Compatibility

Claim accounts do not add a new storage mapping. The referenced absolute claim account is stored in the packed address slot of the claim root flags.

The v1 launch target is a fresh deployment. No old-flag compatibility layer is required.

## Required Coverage

Tests should cover:

- native root flags decode to `DebitGroup + Native`
- external root flags decode to `DebitGroup + External`
- internal root flags decode to `DebitGroup + Internal`
- claim root flags decode to `DebitGroup + Claim`
- debit and credit subaccounts decode to `DebitLedger` / `CreditLedger`
- group subaccounts decode to `DebitGroup` / `CreditGroup`
- `parent(flags)` returns zero for all roots, including claim roots
- `claimAccount(flags)` returns the packed reference only for claim roots
- `isRoot(flags)` depends on depth and group kind, not packed address
- transfer parent-walk behavior is unchanged
- wrap/unwrap behavior is unchanged for native/external roots
- wrap/unwrap reject internal and claim roots
- `createInternalToken(TokenMetadata[])`, `addNativeToken`, and `addExternalToken(address[])` remain idempotent
- `createInternalToken(TokenMetadata[])` creates debit roots only
- claim token creation is idempotent
- claim account cannot be unregistered
- claim account cannot be a group account
- claim account cannot be inside the same claim-token tree
- claim account cannot belong to a claim-token root

## Non-Goals For V1

- root-account claims
- group-account claims
- mutable claim-account references
- cross-router or cross-ledger proof claims
- recursive valuation helpers in Ledger
- automatic redemption semantics in Ledger
