# Store

[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/modules/Ledger/Ledger.sol)

```solidity
struct Store {
    mapping(address => bool) isGroup;
    mapping(address sub => address) parent;
    mapping(address sub => uint32) subIndex;
    mapping(address parent => address[]) subs;
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => bool) isCredit;
    mapping(address => uint256) balance;
    mapping(address owner => mapping(address spender => uint256)) allowances;
}
```
