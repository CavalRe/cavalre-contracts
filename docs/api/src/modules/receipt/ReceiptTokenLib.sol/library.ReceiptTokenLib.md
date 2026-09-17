# ReceiptTokenLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/c13afbe04b25a0f1a9e4978856e437faf4de4c45/modules/receipt/ReceiptTokenLib.sol)

Receipt arithmetic and Ledger accounting for trusted consuming modules.

Receipts are Internal ledgers whose packed address identifies a registered backing leaf.
Ledger owns the reference, supply and balances; this library adds no storage or receipt flag.
Callers authorize issuance, holder burns, and settlement independently, enforce slippage,
and guard reentrancy across their entire operation. A backing reference grants no spending rights.


## Functions
### isReceipt

Whether token_ currently resolves to a valid receipt ledger and backing leaf.


```solidity
function isReceipt(address token_) internal view returns (bool);
```

### receiptAccount

Return the absolute backing account, or zero if token_ does not identify a valid receipt.

Ledger stores the packed address opaquely; only receipt code interprets it as backing.
Ordinary internal ledgers pack Root, which is not an eligible backing leaf. For either kind
of Internal ledger, LedgerLib.parent still returns Root: the backing reference is not a parent.


```solidity
function receiptAccount(address token_) internal view returns (address backingAccount_);
```

### register

Register a deployed receipt wrapper as an Internal ledger backed by backingAccount_.

Trusted factory registration only. The caller must authorize creation and deploy token_.
Ledger creates the debit root and its credit Source. No holder registration is required.
Ledger rejects conflicting flags/metadata on replay,
preserving the backing reference and preventing adoption of an ordinary internal token.


```solidity
function register(address token_, address backingAccount_, ILedgerTokenFactory.TokenMetadata memory metadata_)
    internal
    returns (uint256 flags_);
```

### checkReceiptAccount

Backing must be a registered leaf outside the receipt's own ledger. Nested debit/credit
leaves and Source accounts are valid; their ledger need not be a token (for example, Scale).


```solidity
function checkReceiptAccount(address token_, address backingAccount_) internal view;
```

### receiptState

Read current raw supply and the backing account's net balance from Ledger.

Backing uses its own ledger's decimals and its registered debit/credit polarity.


```solidity
function receiptState(address token_) internal view returns (IReceiptTokenView.State memory state_);
```

### convertToReceipts

Quote raw receipts for a raw backing quantity, rounding down.

Positive supply and backing use backing_ * supply / backing; decimals are already in
that ratio. Only a completely empty receipt initializes at one whole receipt per whole
backing unit. A mismatched zero state rejects positive input rather than assigning orphan
backing to a new holder or issuing against a fully depleted account. Zero input quotes zero.


```solidity
function convertToReceipts(address token_, uint256 backing_) internal view returns (uint256);
```

### convertToBacking

Quote raw backing for raw receipts, rounding down.

A full-supply quote returns all backing exactly; partial rounding stays with remaining
holders. Live supply with zero backing quotes zero. Both-zero state uses decimal-adjusted
1:1 units; zero supply with positive backing rejects positive input. This is a quantity quote,
not a balance check: redeem separately enforces available supply and holder balance.


```solidity
function convertToBacking(address token_, uint256 receipts_) internal view returns (uint256);
```

### scale

Initialization only: scale down floors and scale up uses checked multiplication.
10**difference must fit uint256; the scaled result must fit as well.


```solidity
function scale(uint256 amount_, uint8 fromDecimals_, uint8 toDecimals_) private pure returns (uint256);
```

### issue

Issue receipts at the pre-settlement ratio after adding exactly backing_ to backing.

settle_(token_, backing_, data_) is trusted internal application code; data_ is opaque
to this library. It performs authorized token custody or non-token accounting as appropriate.
The callback must leave receipt supply unchanged. Zero/dust issuance reverts, and any failed
delta check rolls back settlement. Callers enforce slippage and reentrancy protection.


```solidity
function issue(
    address token_,
    address holder_,
    uint256 backing_,
    bytes memory data_,
    function(address, uint256, bytes memory) internal settle_
) internal returns (uint256 receipts_);
```

### redeem

Burn authorized holder receipts and settle the pre-burn proportional backing quote.

The caller authorizes the holder burn and backing release, checks slippage, and guards
reentrancy. Burn precedes settlement; settle_(token_, backing_, data_) must release exactly
the quoted backing without changing receipt supply further. Failure rolls back both steps.
Complete redemption releases the remainder; fully depleted receipts can redeem for zero.


```solidity
function redeem(
    address token_,
    address holder_,
    uint256 receipts_,
    bytes memory data_,
    function(address, uint256, bytes memory) internal settle_
) internal returns (uint256 backing_);
```

### cancel

Burn receipts without settling or releasing backing.

The caller must authorize the holder burn. Cancelling the last receipt leaves orphan
backing, so positive issuance remains blocked until an authorized application resolves it.


```solidity
function cancel(address token_, address holder_, uint256 receipts_) internal;
```

### checkHolder

Accept effective debit holders and registered debit leaves, including nested custody.
Reject zero, credit accounts (including Source), and groups.


```solidity
function checkHolder(address token_, address holder_) private view;
```

