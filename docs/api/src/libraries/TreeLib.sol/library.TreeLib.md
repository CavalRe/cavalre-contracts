# TreeLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/e9b2f507f0b2f5b63f28b4ef324f0d8c853d1aa9/libraries/TreeLib.sol)


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

