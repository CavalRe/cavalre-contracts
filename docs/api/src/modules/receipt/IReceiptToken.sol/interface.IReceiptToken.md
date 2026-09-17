# IReceiptToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/receipt/IReceiptToken.sol)


## Functions
### cancelReceipt

Cancel the caller's raw receipt quantity without releasing backing.

Zero amounts revert. Cancelling the entire supply leaves any backing unassigned.


```solidity
function cancelReceipt(address token, uint256 receipts) external;
```

### cancelReceipt

Registered wrapper callback; the wrapper authenticates the holder.

Only the token's registered wrapper may call this overload; ERC20 allowance alone is insufficient.


```solidity
function cancelReceipt(address token, address holder, uint256 receipts) external;
```

## Events
### ReceiptIssued

```solidity
event ReceiptIssued(address indexed token, address indexed holder, uint256 receipts, uint256 backing);
```

### ReceiptRedeemed

```solidity
event ReceiptRedeemed(address indexed token, address indexed holder, uint256 receipts, uint256 backing);
```

### ReceiptCancelled

```solidity
event ReceiptCancelled(address indexed token, address indexed holder, uint256 receipts);
```

## Errors
### InvalidReceiptState

```solidity
error InvalidReceiptState(uint256 supply, uint256 backing);
```

### InvalidReceiptHolder

```solidity
error InvalidReceiptHolder(address holder);
```

### InvalidReceiptAmount

```solidity
error InvalidReceiptAmount();
```

### InvalidSettlement

```solidity
error InvalidSettlement();
```

### UnsupportedDecimalDifference

```solidity
error UnsupportedDecimalDifference();
```

