# ShareTokenLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/share/ShareTokenLib.sol)

Share arithmetic and share issuance/burns for trusted consuming modules.

Shares are Internal ledgers with a backing reference in this library's namespaced storage.
Ledger owns parent topology, supply and balances; its packed address always identifies the parent.
Callers perform and verify backing movements, authorize issuance and holder burns, enforce
slippage, and guard reentrancy across the entire operation. A backing reference grants no spending rights.


## Constants
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.ShareToken")) - 1)) & ~bytes32(uint256(0xff))
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

### backingAccount

Registered absolute backing account, or zero for an unregistered share token.


```solidity
function backingAccount(address token_) internal view returns (address);
```

### isShareToken

Whether token_ has a registered backing account.


```solidity
function isShareToken(address token_) internal view returns (bool);
```

### enforceShareTokenBackingAccount

Backing must be a registered leaf outside the share's own ledger. Nested debit/credit
leaves and Source accounts are valid; their ledger need not be a token (for example, Scale).


```solidity
function enforceShareTokenBackingAccount(address token_, address backingAccount_) internal view;
```

### shareTokenState

Read current raw supply and the backing account's net balance from Ledger.

Backing uses its own ledger's decimals and its registered debit/credit polarity.


```solidity
function shareTokenState(address token_) internal view returns (IShareTokenView.State memory state_);
```

### convertDecimals

Initialization only: scale down floors and scale up uses checked multiplication.
10**difference must fit uint256; the scaled result must fit as well.


```solidity
function convertDecimals(uint256 amount_, uint8 fromDecimals_, uint8 toDecimals_) private pure returns (uint256);
```

### convertToShares

Quote raw shares for a raw backing quantity, rounding down.

Positive supply and backing use backing_ * supply / backing; decimals are already in
that ratio. Only a completely empty share initializes at one whole share per whole
backing unit. A mismatched zero state rejects positive input rather than assigning orphan
backing to a new holder or issuing against a fully depleted account. Zero input quotes zero.


```solidity
function convertToShares(address token_, uint256 backing_) internal view returns (uint256);
```

### convertToBacking

Quote raw backing for raw shares, rounding down.

A full-supply quote returns all backing exactly; partial rounding stays with remaining
holders. Live supply with zero backing quotes zero. Both-zero state uses decimal-adjusted
1:1 units; zero supply with positive backing rejects positive input. This is a quantity quote,
not a balance check: redeem separately enforces available supply and holder balance.


```solidity
function convertToBacking(address token_, uint256 shares_) internal view returns (uint256);
```

### enforceShareTokenAccount

Accept effective debit leaves and registered debit leaves with explicit absolute parent context.
Reject zero, credit accounts (including Source), and groups.


```solidity
function enforceShareTokenAccount(address token_, address parent_, address relative_)
    private
    view
    returns (uint256 flags_);
```

### issue

Issue shares for backing_ already added by the caller, using the ratio before that addition.

The caller must add and verify exactly backing_ with unchanged share supply immediately
before calling, in the same transaction. This function only mints shares from their Source.
Zero/dust issuance reverts, rolling back the caller's preceding backing movement as well.


```solidity
function issue(address token_, address parent_, address relative_, uint256 backing_)
    internal
    returns (uint256 shares_);
```

### redeem

Burn authorized holder shares into Source and return their pre-burn backing quote.

The caller must release and verify exactly the returned backing immediately afterward,
in the same transaction, and verify the expected supply decrease. This function does not move backing.
Complete redemption quotes the remainder; fully depleted shares can redeem for zero.


```solidity
function redeem(address token_, address parent_, address relative_, uint256 shares_)
    internal
    returns (uint256 backing_);
```

### cancel

Burn shares without settling or releasing backing.

The caller must authorize the holder burn. Cancelling the last share leaves orphan
backing, so positive issuance remains blocked until an authorized application resolves it.


```solidity
function cancel(address token_, address parent_, address relative_, uint256 shares_) internal;
```

## Structs
### Store

```solidity
struct Store {
    mapping(address token => address backingAccount) backingAccounts;
}
```

