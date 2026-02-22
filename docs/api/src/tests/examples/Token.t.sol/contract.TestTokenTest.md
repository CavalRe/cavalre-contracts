# TestTokenTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4beb1bb5ec51300e77fe11434272324aa08bfb7c/tests/examples/Token.t.sol)

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

