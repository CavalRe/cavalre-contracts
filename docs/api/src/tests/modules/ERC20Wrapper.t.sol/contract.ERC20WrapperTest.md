# ERC20WrapperTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/tests/modules/ERC20Wrapper.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### TRANSFER_TOPIC

```solidity
bytes32 internal constant TRANSFER_TOPIC = keccak256("Transfer(address,address,uint256)")
```


### dispatcher

```solidity
Dispatcher internal dispatcher
```


### ledgers

```solidity
TestLedger internal ledgers
```


### ledgerView

```solidity
LedgerView internal ledgerView
```


### tree

```solidity
TreeView internal tree
```


### token

```solidity
ERC20Wrapper internal token
```


### externalToken

```solidity
MockERC20 internal externalToken
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

### testERC20WrapperTransferToSelfEmitsTransfer


```solidity
function testERC20WrapperTransferToSelfEmitsTransfer() public;
```

### testERC20WrapperZeroTransferEmitsTransfer


```solidity
function testERC20WrapperZeroTransferEmitsTransfer() public;
```

### testERC20WrapperTransferMatrix


```solidity
function testERC20WrapperTransferMatrix() public;
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

### _buildMatrixLegs


```solidity
function _buildMatrixLegs(uint160 base_, string memory prefix_) private returns (MatrixLeg[] memory legs_);
```

### _expectedWrapperTransfer


```solidity
function _expectedWrapperTransfer(MatrixLeg memory from_, MatrixLeg memory to_)
    private
    view
    returns (ExpectedWrapperTransfer memory expected_);
```

### _projectDebit


```solidity
function _projectDebit(MatrixLeg memory leg_) private view returns (address);
```

### _projectCreditForCreditTransfer


```solidity
function _projectCreditForCreditTransfer(MatrixLeg memory leg_) private view returns (address);
```

### _assertWrapperTransferLogs


```solidity
function _assertWrapperTransferLogs(ExpectedWrapperTransfer memory expected_, uint256 fromIndex_, uint256 toIndex_)
    private;
```

### _matrixCellLabel


```solidity
function _matrixCellLabel(string memory prefix_, uint256 fromIndex_, uint256 toIndex_)
    private
    pure
    returns (string memory);
```

### _matrixLabel


```solidity
function _matrixLabel(uint256 index_) private pure returns (string memory);
```

## Structs
### MatrixLeg

```solidity
struct MatrixLeg {
    address parent;
    address relative;
    uint8 depth;
    bool isCredit;
    bool isUnregistered;
}
```

### ExpectedWrapperTransfer

```solidity
struct ExpectedWrapperTransfer {
    bool emitted;
    address from;
    address to;
}
```

