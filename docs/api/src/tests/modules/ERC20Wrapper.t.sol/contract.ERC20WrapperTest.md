# ERC20WrapperTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/tests/modules/ERC20Wrapper.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### router

```solidity
Router internal router
```


### ledgers

```solidity
TestLedger internal ledgers
```


### token

```solidity
ERC20Wrapper internal token
```


### externalToken

```solidity
MockERC20 internal externalToken
```


### externalWrapper

```solidity
ERC20Wrapper internal externalWrapper
```


### owner

```solidity
address internal owner = address(0xA11CE)
```


### alice

```solidity
address internal alice = address(0xB0B)
```


### bob

```solidity
address internal bob = address(0xCA11)
```


### carol

```solidity
address internal carol = address(0xD00D)
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testERC20WrapperMetadata


```solidity
function testERC20WrapperMetadata() public view;
```

### testERC20WrapperCreateToken


```solidity
function testERC20WrapperCreateToken() public;
```

### testERC20WrapperMintTransferBurn


```solidity
function testERC20WrapperMintTransferBurn() public;
```

### testERC20WrapperApproveTransferFromandAllowanceMutators


```solidity
function testERC20WrapperApproveTransferFromandAllowanceMutators() public;
```

### testERC20WrapperTransferFromExactAllowance


```solidity
function testERC20WrapperTransferFromExactAllowance() public;
```

### testWrappedExternalWrapperSurfaceMatchesLedger


```solidity
function testWrappedExternalWrapperSurfaceMatchesLedger() public;
```

### testWrappedExternalWrapperTransferThroughSurface


```solidity
function testWrappedExternalWrapperTransferThroughSurface() public;
```

### testERC20WrapperMintBurnEmitsTransfer


```solidity
function testERC20WrapperMintBurnEmitsTransfer() public;
```

### testERC20WrapperLedgerWrapperFunctionsUnauthorized


```solidity
function testERC20WrapperLedgerWrapperFunctionsUnauthorized() public;
```

### testERC20WrapperMultiHolderAccounting


```solidity
function testERC20WrapperMultiHolderAccounting() public;
```

