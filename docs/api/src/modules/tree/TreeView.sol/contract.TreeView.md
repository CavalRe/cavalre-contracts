# TreeView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/tree/TreeView.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### checkLedgerParent


```solidity
function checkLedgerParent(address ledger_, address parent_) private view;
```

### signatures


```solidity
function signatures() external pure override returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory _selectors);
```

### ledger


```solidity
function ledger(address absolute_) external view returns (address);
```

### flags


```solidity
function flags(address absolute_) external view returns (uint256);
```

### wrapper


```solidity
function wrapper(address ledger_) external view returns (address);
```

### tree


```solidity
function tree(address ledger_) external view returns (TreeLib.TreeNode[] memory);
```

### treeNode


```solidity
function treeNode(address ledger_) external view returns (TreeLib.TreeNode memory);
```

### treeNode


```solidity
function treeNode(address ledger_, address parent_, address relative_)
    external
    view
    returns (TreeLib.TreeNode memory);
```

### accountKind


```solidity
function accountKind(uint256 flags_) external pure returns (LedgerLib.AccountKind);
```

### tokenKind


```solidity
function tokenKind(uint256 flags_) external pure returns (LedgerLib.TokenKind);
```

### packedAddress


```solidity
function packedAddress(uint256 flags_) external pure returns (address);
```

### isUnregisteredAccount


```solidity
function isUnregisteredAccount(uint256 flags_) external pure returns (bool);
```

### isDebitGroup


```solidity
function isDebitGroup(uint256 flags_) external pure returns (bool);
```

### isCreditGroup


```solidity
function isCreditGroup(uint256 flags_) external pure returns (bool);
```

### isDebitLedger


```solidity
function isDebitLedger(uint256 flags_) external pure returns (bool);
```

### isCreditLedger


```solidity
function isCreditLedger(uint256 flags_) external pure returns (bool);
```

### isGroup


```solidity
function isGroup(uint256 flags_) external pure returns (bool);
```

### isLedgerAccount


```solidity
function isLedgerAccount(uint256 flags_) external pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags_) external pure returns (bool);
```

### effectiveFlags


```solidity
function effectiveFlags(address ledger_, address parent_, address relative_)
    external
    view
    returns (uint256, uint256, address);
```

### isUnregisteredToken


```solidity
function isUnregisteredToken(uint256 flags_) external pure returns (bool);
```

### isInternal


```solidity
function isInternal(uint256 flags_) external pure returns (bool);
```

### isNative


```solidity
function isNative(uint256 flags_) external pure returns (bool);
```

### isExternal


```solidity
function isExternal(uint256 flags_) external pure returns (bool);
```

### isLedger


```solidity
function isLedger(uint256 flags_) external pure returns (bool);
```

### isReceipt


```solidity
function isReceipt(uint256 flags_) external pure returns (bool);
```

### receiptAccount


```solidity
function receiptAccount(uint256 flags_) external pure returns (address);
```

### subAccounts


```solidity
function subAccounts(address absolute_) external view returns (address[] memory);
```

### hasSubAccount


```solidity
function hasSubAccount(address absolute_) external view returns (bool);
```

### subAccountIndex


```solidity
function subAccountIndex(address absolute_) external view returns (uint32);
```

### debugTree


```solidity
function debugTree(address ledger_) external view;
```

### debugTrees


```solidity
function debugTrees(address[] memory ledgers_) external view;
```

