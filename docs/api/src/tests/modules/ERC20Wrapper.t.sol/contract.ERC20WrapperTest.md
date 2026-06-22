# ERC20WrapperTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/864c40b9986bd124ebb2cf2fd60ea0a56f3c0024/tests/modules/ERC20Wrapper.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### DEFAULT_SOURCE_NAME

```solidity
string internal constant DEFAULT_SOURCE_NAME = "Source"
```


### router

```solidity
Router internal router
```


### ledgers

```solidity
TestLedger internal ledgers
```


### tree

```solidity
Tree internal tree
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


### source_

```solidity
address internal source_
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testERC20WrapperInit


```solidity
function testERC20WrapperInit() public view;
```

### testERC20WrapperMetadata


```solidity
function testERC20WrapperMetadata() public view;
```

### testERC20WrapperCreateInternalToken


```solidity
function testERC20WrapperCreateInternalToken() public;
```

### testERC20WrapperClaimRootMintTransferBurn


```solidity
function testERC20WrapperClaimRootMintTransferBurn() public;
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

