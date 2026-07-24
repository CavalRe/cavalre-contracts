# ERC20WrapperTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/tests/modules/ERC20Wrapper.t.sol)

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


### ledgerTokenFactory

```solidity
LedgerTokenFactory internal ledgerTokenFactory
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


### indexedHolders

```solidity
address[] internal indexedHolders
```


### indexedBalances

```solidity
mapping(address => uint256) internal indexedBalances
```


## Functions
### setUp


```solidity
function setUp() public;
```

### createInternalToken


```solidity
function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    internal
    returns (address _tokenAddress, uint256 _flags);
```

### createClaimToken


```solidity
function createClaimToken(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address root_,
    address holderParent_,
    address relative_,
    string memory version_
) internal returns (address _tokenAddress, uint256 _flags);
```

### addExternalToken


```solidity
function addExternalToken(address token_) internal returns (uint256 _flags);
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

### testERC20WrapperClaimRootTransferMatrix


```solidity
function testERC20WrapperClaimRootTransferMatrix() public;
```

### _assertTransferMatrix


```solidity
function _assertTransferMatrix(address root_, MatrixLeg[] memory froms, MatrixLeg[] memory tos) private;
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

### testERC20WrapperEtherscanStyleTransferIndexReconcilesHolders


```solidity
function testERC20WrapperEtherscanStyleTransferIndexReconcilesHolders() public;
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
function _buildMatrixLegs(address root_, uint160 base_, string memory prefix_)
    private
    returns (MatrixLeg[] memory legs_);
```

### _expectedWrapperTransfer


```solidity
function _expectedWrapperTransfer(MatrixLeg memory from_, MatrixLeg memory to_)
    private
    pure
    returns (ExpectedWrapperTransfer memory expected_);
```

### _holder


```solidity
function _holder(MatrixLeg memory leg_) private pure returns (address);
```

### _assertWrapperTransferLogs


```solidity
function _assertWrapperTransferLogs(
    address root_,
    ExpectedWrapperTransfer memory expected_,
    uint256 fromIndex_,
    uint256 toIndex_
) private;
```

### _indexTokenTransferLogs


```solidity
function _indexTokenTransferLogs(address token_, Vm.Log[] memory logs_) private;
```

### _assertExplorerEventAddressProjection


```solidity
function _assertExplorerEventAddressProjection(address token_, Vm.Log[] memory logs_, address registeredAccount_)
    private
    view;
```

### _isAllowedExplorerEventAddress


```solidity
function _isAllowedExplorerEventAddress(address account_, address registeredAccount_) private view returns (bool);
```

### _trackIndexedHolder


```solidity
function _trackIndexedHolder(address holder_) private;
```

### _assertIndexedHolder


```solidity
function _assertIndexedHolder(address token_, address holder_) private view;
```

### _indexedHolderCount


```solidity
function _indexedHolderCount() private view returns (uint256 count_);
```

### _indexedSupply


```solidity
function _indexedSupply() private view returns (uint256 supply_);
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

### MatrixBuildCache

```solidity
struct MatrixBuildCache {
    address debitGroupRelative;
    address creditGroupRelative;
    address debitGroup;
    address creditGroup;
    address r2d;
    address r2c;
    address rd;
    address rc;
    string debitGroupName;
    string creditGroupName;
    string r2dName;
    string r2cName;
    string rdName;
    string rcName;
}
```

