# LedgerInternalBalancesTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/tests/modules/LedgerInternalBalances.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)

Preserve internal mixed-polarity postings without adding a group solvency constraint.


## Constants
### L

```solidity
address private constant L = address(0x100)
```


### G

```solidity
address private constant G = address(0x200)
```


### D

```solidity
address private constant D = address(0x300)
```


### C

```solidity
address private constant C = address(0x400)
```


### WALLET

```solidity
address private constant WALLET = address(0x500)
```


## Functions
### custodyBalance


```solidity
function custodyBalance() external view returns (uint256);
```

### testValidPostingMakesDebitCustodyNormalBalanceNegative


```solidity
function testValidPostingMakesDebitCustodyNormalBalanceNegative() public;
```

