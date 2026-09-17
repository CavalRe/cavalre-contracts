# ReceiptToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/receipt/ReceiptToken.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [IReceiptToken](/modules/receipt/IReceiptToken.sol/interface.IReceiptToken.md)

Permissionless self-cancellation only. Applications expose authorized issue/redeem settlement.


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

Cancel the caller's raw receipt quantity without releasing backing.

Zero amounts revert. Cancelling the entire supply leaves any backing unassigned.


```solidity
function cancelReceipt(address token_, uint256 receipts_) external;
```

### cancelReceipt

Registered wrapper callback; the wrapper authenticates the holder.

Only the token's registered wrapper may call this overload; ERC20 allowance alone is insufficient.


```solidity
function cancelReceipt(address token_, address holder_, uint256 receipts_) external;
```

