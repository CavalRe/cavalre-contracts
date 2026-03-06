# ERC20Lib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/libraries/ERC20Lib.sol)

## Description

Namespaced storage + selector constants for the canonical-root ERC20 module.

`ERC20Lib` owns ERC20 allowance storage. Metadata, balances, supply, and transfer posting remain in `LedgerLib`.

## Structs
### Store

```solidity
struct Store {
    mapping(address => mapping(address => uint256)) allowances;
}
```

## Functions
### store

```solidity
function store() internal pure returns (Store storage s);
```
