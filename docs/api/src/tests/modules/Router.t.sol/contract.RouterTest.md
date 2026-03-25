# RouterTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/3a4fcfc9619f01f0afd3feb42acd82ec72eed095/tests/modules/Router.t.sol)

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


### router

```solidity
Router router
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

### testRouterInit


```solidity
function testRouterInit() public view;
```

### testRouterAddModule


```solidity
function testRouterAddModule() public;
```

### testRouterCallModule


```solidity
function testRouterCallModule() public;
```

### testRouterRemoveModule


```solidity
function testRouterRemoveModule() public;
```

### testRouterRedeployModule


```solidity
function testRouterRedeployModule() public;
```

