# ReceiptTokenView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/receipt/ReceiptTokenView.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [IReceiptTokenView](/modules/receipt/IReceiptTokenView.sol/interface.IReceiptTokenView.md)

Dispatcher read surface; receipt metadata and accounting are derived from Ledger.


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### isReceipt

Whether token is an Internal ledger with a valid packed backing reference.


```solidity
function isReceipt(address token_) external view returns (bool);
```

### receiptAccount

Absolute backing leaf, or zero for an unknown address or non-receipt ledger.


```solidity
function receiptAccount(address token_) external view returns (address);
```

### receiptState

Current Ledger accounting; reverts if token is not a valid receipt.


```solidity
function receiptState(address token_) external view returns (State memory);
```

### convertToReceipts

Raw receipt quote, rounded down; existing supply/backing determines the ratio.

Both-zero initialization is decimal-adjusted 1:1; positive input rejects mismatched zero states.


```solidity
function convertToReceipts(address token_, uint256 backing_) external view returns (uint256);
```

### convertToBacking

Raw backing quote, rounded down; a full-supply quote includes all remaining backing.

This does not check holder balance or authorize release. Existing supply with zero backing quotes zero.


```solidity
function convertToBacking(address token_, uint256 receipts_) external view returns (uint256);
```

