# ERC20Test
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/e9b2f507f0b2f5b63f28b4ef324f0d8c853d1aa9/tests/modules/ERC20.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### router

```solidity
Router router
```


### ledgers

```solidity
Ledger ledgers
```


### token

```solidity
ERC20 token
```


### minter

```solidity
MintModule minter
```


### alice

```solidity
address alice = address(0xA11CE)
```


### bob

```solidity
address bob = address(0xB0B)
```


### charlie

```solidity
address charlie = address(0xCA11)
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testERC20Init


```solidity
function testERC20Init() public;
```

### testERC20Transfer


```solidity
function testERC20Transfer() public;
```

### testERC20ApproveTransferFromAndAllowanceMutators


```solidity
function testERC20ApproveTransferFromAndAllowanceMutators() public;
```

## Errors
### InvalidInitialization

```solidity
error InvalidInitialization();
```

