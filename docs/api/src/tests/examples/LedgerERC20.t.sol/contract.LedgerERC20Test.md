# LedgerERC20Test
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/tests/examples/LedgerERC20.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### dispatcher

```solidity
Dispatcher dispatcher
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

### testERC20TransferToSelfEmitsNoLedgerMutationEvents


```solidity
function testERC20TransferToSelfEmitsNoLedgerMutationEvents() public;
```

### testERC20ZeroTransferEmitsCreditAndDebitEvents


```solidity
function testERC20ZeroTransferEmitsCreditAndDebitEvents() public;
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

