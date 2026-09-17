# ReceiptWrapper
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/8126c41d141271ba2bd8fd7c518c8901746dfe38/modules/receipt/ReceiptWrapper.sol)

**Inherits:**
[ERC20Wrapper](/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol/abstract.ERC20Wrapper.md)

ERC20 receipt surface. Settlement belongs to the consuming application's module.

Adds no storage. Metadata and allowances use shared ERC20Wrapper behavior; balances,
supply and backing remain in Ledger. Install ReceiptToken/ReceiptTokenView for the added calls.


## Functions
### constructor


```solidity
constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
    ERC20Wrapper(dispatcher_, name_, symbol_, decimals_);
```

### receiptState

Current backing reference, backing balance and supply in their respective raw units.


```solidity
function receiptState() external view returns (IReceiptTokenView.State memory);
```

### convertToReceipts

Quote raw receipts for raw backing, rounding down; no backing is moved.


```solidity
function convertToReceipts(uint256 backing_) external view returns (uint256);
```

### convertToBacking

Quote raw backing for raw receipts, rounding down; no receipts are burned.


```solidity
function convertToBacking(uint256 receipts_) external view returns (uint256);
```

### cancel

Burn only the caller's receipts without releasing backing.

ERC20 approvals do not permit cancelling another holder's receipts.


```solidity
function cancel(uint256 receipts_) external;
```

