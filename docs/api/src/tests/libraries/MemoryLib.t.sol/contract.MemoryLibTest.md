# MemoryLibTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/40317fddb0f44411366b7cf99393417793c80ea2/tests/libraries/MemoryLib.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## Constants
### ALICE

```solidity
address internal constant ALICE = address(0xA11CE)
```


### BOB

```solidity
address internal constant BOB = address(0xB0B)
```


### CAROL

```solidity
address internal constant CAROL = address(0xCA401)
```


### DAVE

```solidity
address internal constant DAVE = address(0xDA7E)
```


## Functions
### insertAddress


```solidity
function insertAddress(MemoryLib.AddressSet memory set_, address addr_) external pure;
```

### setAddressValue


```solidity
function setAddressValue(MemoryLib.AddressDict memory dict_, address addr_, uint256 value_) external pure;
```

### testAddressSetInsertAndContains


```solidity
function testAddressSetInsertAndContains() public pure;
```

### testAddressSetRejectsDuplicate


```solidity
function testAddressSetRejectsDuplicate() public;
```

### testAddressSetRejectsZeroAddress


```solidity
function testAddressSetRejectsZeroAddress() public;
```

### testAddressDictSetAndGet


```solidity
function testAddressDictSetAndGet() public pure;
```

### testAddressDictSetOverwritesExistingValue


```solidity
function testAddressDictSetOverwritesExistingValue() public pure;
```

### testAddressDictRejectsZeroAddress


```solidity
function testAddressDictRejectsZeroAddress() public;
```

