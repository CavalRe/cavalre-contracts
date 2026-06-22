# ERC20Test
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/864c40b9986bd124ebb2cf2fd60ea0a56f3c0024/tests/modules/ERC20.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### DEFAULT_SOURCE_NAME

```solidity
string internal constant DEFAULT_SOURCE_NAME = "Source"
```


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


### source_

```solidity
address source_
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

### testERC20TransferRejectsCanonicalCreditLeafSender


```solidity
function testERC20TransferRejectsCanonicalCreditLeafSender() public;
```

### testERC20TransferFromRejectsCanonicalCreditLeafSender


```solidity
function testERC20TransferFromRejectsCanonicalCreditLeafSender() public;
```

## Errors
### InvalidInitialization

```solidity
error InvalidInitialization();
```

