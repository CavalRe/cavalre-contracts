# ReceiptToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/c13afbe04b25a0f1a9e4978856e437faf4de4c45/modules/receipt/ReceiptToken.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [IReceiptToken](/modules/receipt/IReceiptToken.sol/interface.IReceiptToken.md)

Wrapper-authorized cancellation. Applications expose authorized issue/redeem settlement.


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### cancelReceipt

Cancel raw receipt units without releasing backing; the wrapper authenticates the holder.

Only the token's registered wrapper may call; ERC20 allowance alone is insufficient.
Zero amounts revert. Cancelling the entire supply leaves any backing unassigned.


```solidity
function cancelReceipt(address token_, address holder_, uint256 receipts_) external;
```

