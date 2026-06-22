# Tree
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/864c40b9986bd124ebb2cf2fd60ea0a56f3c0024/modules/Tree.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md)


## Functions
### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory _selectors);
```

### root


```solidity
function root(address addr_) external view returns (address);
```

### parent


```solidity
function parent(address addr_) external view returns (address);
```

### flags


```solidity
function flags(address addr_) external view returns (uint256);
```

### wrapper


```solidity
function wrapper(address token_) external view returns (address);
```

### tree


```solidity
function tree(address root_) external view returns (TreeLib.TreeNode[] memory);
```

### treeNode


```solidity
function treeNode(address root_) external view returns (TreeLib.TreeNode memory);
```

### treeNode


```solidity
function treeNode(address parent_, address addr_) external view returns (TreeLib.TreeNode memory);
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

### isGroup


```solidity
function isGroup(uint256 flags_) external pure returns (bool);
```

### isLedger


```solidity
function isLedger(uint256 flags_) external pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags_) external pure returns (bool);
```

### effectiveFlags


```solidity
function effectiveFlags(address parent_, address addr_) external view returns (address, uint256);
```

### isInternal


```solidity
function isInternal(uint256 flags_) external pure returns (bool);
```

### isNative


```solidity
function isNative(uint256 flags_) external pure returns (bool);
```

### isRegistered


```solidity
function isRegistered(uint256 flags_) external pure returns (bool);
```

### isExternal


```solidity
function isExternal(uint256 flags_) external pure returns (bool);
```

### isRoot


```solidity
function isRoot(uint256 flags_) external pure returns (bool);
```

### isClaim


```solidity
function isClaim(uint256 flags_) external pure returns (bool);
```

### claimAccount


```solidity
function claimAccount(uint256 flags_) external pure returns (address);
```

### subAccounts


```solidity
function subAccounts(address parent_) external view returns (address[] memory);
```

### hasSubAccount


```solidity
function hasSubAccount(address parent_) external view returns (bool);
```

### subAccountIndex


```solidity
function subAccountIndex(address parent_, address addr_) external view returns (uint32);
```

### debugTree


```solidity
function debugTree(address root_) external view;
```

### debugTrees


```solidity
function debugTrees(address[] memory roots_) external view;
```

