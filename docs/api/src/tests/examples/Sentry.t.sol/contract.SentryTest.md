# SentryTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/tests/examples/Sentry.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### dispatcher

```solidity
Dispatcher dispatcher
```


### sentry

```solidity
Sentry sentry
```


### dispatcherAddress

```solidity
address dispatcherAddress
```


### sentryAddress

```solidity
address sentryAddress
```


### alice

```solidity
address alice = address(1)
```


### bob

```solidity
address bob = address(2)
```


### charlie

```solidity
address charlie = address(3)
```


### success

```solidity
bool success
```


### data

```solidity
bytes data
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testSentryInit


```solidity
function testSentryInit() public view;
```

### testSentryOwner


```solidity
function testSentryOwner() public view;
```

### testSentryWrongOwner


```solidity
function testSentryWrongOwner() public;
```

### testSentryTransferOwnership


```solidity
function testSentryTransferOwnership() public;
```

