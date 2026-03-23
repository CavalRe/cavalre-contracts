# TestTokenTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/716535f21df26e2431fe11fe8288f267361b03c3/tests/examples/Token.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### token

```solidity
TestToken token
```


### router

```solidity
Router router
```


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


## Functions
### setUp


```solidity
function setUp() public;
```

### testTestTokenInitialize


```solidity
function testTestTokenInitialize() public;
```

### testTestTokenMint


```solidity
function testTestTokenMint() public;
```

### testTestTokenBurn


```solidity
function testTestTokenBurn() public;
```

## Errors
### InvalidInitialization

```solidity
error InvalidInitialization();
```

### NotInitializing

```solidity
error NotInitializing();
```

