# IReceiptToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/c13afbe04b25a0f1a9e4978856e437faf4de4c45/modules/receipt/IReceiptToken.sol)


## Functions
### cancelReceipt

Cancel raw receipt units without releasing backing; the wrapper authenticates the holder.

Only the token's registered wrapper may call; ERC20 allowance alone is insufficient.
Zero amounts revert. Cancelling the entire supply leaves any backing unassigned.


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

