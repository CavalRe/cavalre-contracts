# TreeLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/1f2cb104122a5862baec82617fdfb23657167993/modules/tree/TreeLib.sol)


## Functions
### node


```solidity
function node(address ledger_, address parent_, address relative_) internal view returns (TreeNode memory _node);
```

### tree


```solidity
function tree(address ledger_) internal view returns (TreeNode[] memory _nodes);
```

### count


```solidity
function count(address ledger_, address parent_, address relative_) internal view returns (uint256 _count);
```

### fill


```solidity
function fill(address ledger_, address parent_, address relative_, TreeNode[] memory nodes_, uint256 n_)
    internal
    view
    returns (uint256 _n);
```

### logTree


```solidity
function logTree(
    address ledger_,
    address parent_,
    address relative_,
    string memory prefix_,
    bool isFirst_,
    bool isLast_
) internal view;
```

### debugTree


```solidity
function debugTree(address ledger_) internal view;
```

### debugTrees


```solidity
function debugTrees(address[] memory ledgers_) internal view;
```

## Structs
### TreeCache

```solidity
struct TreeCache {
    bool isLedger;
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
    address parent;
    address relative;
    string name;
    bool isCredit;
    uint256 debit;
    uint256 credit;
}
```

