# TestTokenTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4104c9a5fb1b403d7a1bc8bdf3c0f7c85335ff70/tests/examples/Token.t.sol)

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

