# TreeLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/df3844c9f1ae77a79f53c275e50e3d3e12c811a6/libraries/TreeLib.sol)


## Functions
### logTree


```solidity
function logTree(
    Ledger ledgers_,
    address parent_,
    address addr_,
    string memory prefix_,
    bool isFirst_,
    bool isLast_
) internal view;
```

### debugTree


```solidity
function debugTree(Ledger ledgers, address root) internal view;
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

