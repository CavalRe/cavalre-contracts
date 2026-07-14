# DispatcherTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/tests/modules/Dispatcher.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md), [ContextUpgradeable](/node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol/abstract.ContextUpgradeable.md)


## State Variables
### alice

```solidity
address alice = address(1)
```


### bob

```solidity
address bob = address(2)
```


### carol

```solidity
address carol = address(3)
```


### dispatcher

```solidity
Dispatcher dispatcher
```


### foo

```solidity
Foo foo
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testDispatcherInit


```solidity
function testDispatcherInit() public view;
```

### testDispatcherAddModule


```solidity
function testDispatcherAddModule() public;
```

### testDispatcherVerifyModule


```solidity
function testDispatcherVerifyModule() public view;
```

### testDispatcherCallModule


```solidity
function testDispatcherCallModule() public;
```

### testDispatcherRemoveModule


```solidity
function testDispatcherRemoveModule() public;
```

### testDispatcherRedeployModule


```solidity
function testDispatcherRedeployModule() public;
```

### testDispatcherCannotRemoveStaleModule


```solidity
function testDispatcherCannotRemoveStaleModule() public;
```

