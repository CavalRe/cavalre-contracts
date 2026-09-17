# IReceiptTokenView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/receipt/IReceiptTokenView.sol)


## Functions
### isReceipt

Whether token is an Internal ledger with a valid packed backing reference.


```solidity
function isReceipt(address token) external view returns (bool);
```

### receiptAccount

Absolute backing leaf, or zero for an unknown address or non-receipt ledger.


```solidity
function receiptAccount(address token) external view returns (address);
```

### receiptState

Current Ledger accounting; reverts if token is not a valid receipt.


```solidity
function receiptState(address token) external view returns (State memory);
```

### convertToReceipts

Raw receipt quote, rounded down; existing supply/backing determines the ratio.

Both-zero initialization is decimal-adjusted 1:1; positive input rejects mismatched zero states.


```solidity
function convertToReceipts(address token, uint256 backing) external view returns (uint256);
```

### convertToBacking

Raw backing quote, rounded down; a full-supply quote includes all remaining backing.

This does not check holder balance or authorize release. Existing supply with zero backing quotes zero.


```solidity
function convertToBacking(address token, uint256 receipts) external view returns (uint256);
```

## Structs
### State
A live Ledger snapshot; quantities are raw integers, not a common-decimal valuation.


```solidity
struct State {
    address backingAccount; // Absolute registered leaf; may be nested or credit-sided.
    address backingLedger; // Derived from backingAccount; need not expose an ERC20.
    uint256 supply; // Raw receipt units, using receipt-token decimals.
    uint256 backing; // Net balance in backingLedger decimals, using the leaf's polarity.
}
```

