# TreeLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/tree/TreeLib.sol)


## Functions
### node


```solidity
function node(address root_, address holderParent_, address relative_)
    internal
    view
    returns (TreeNode memory _node);
```

### tree


```solidity
function tree(address root_) internal view returns (TreeNode[] memory _nodes);
```

### count


```solidity
function count(address root_, address holderParent_, address relative_) internal view returns (uint256 _count);
```

### fill


```solidity
function fill(address root_, address holderParent_, address relative_, TreeNode[] memory nodes_, uint256 n_)
    internal
    view
    returns (uint256 _n);
```

### logTree


```solidity
function logTree(
    address root_,
    address holderParent_,
    address relative_,
    string memory prefix_,
    bool isFirst_,
    bool isLast_
) internal view;
```

### debugTree


```solidity
function debugTree(address root_) internal view;
```

### debugTrees


```solidity
function debugTrees(address[] memory roots_) internal view;
```

## Structs
### TreeCache

```solidity
struct TreeCache {
    bool isRoot;
    address addr;
    uint256 flags;
    uint256 balance;
    string label;
    bool isGroup;
    string subPrefix;
    address[] subs;
}
```

### TreeNode

```solidity
struct TreeNode {
    address holderParent;
    address relative;
    string name;
    bool isCredit;
    uint256 debit;
    uint256 credit;
}
```

