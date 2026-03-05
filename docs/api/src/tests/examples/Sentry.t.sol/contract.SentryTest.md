# SentryTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/eff46231d5d2a3b339a6c933eb930a9826eedb42/tests/examples/Sentry.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### router

```solidity
Router router
```


### sentry

```solidity
Sentry sentry
```


### routerAddress

```solidity
address routerAddress
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

