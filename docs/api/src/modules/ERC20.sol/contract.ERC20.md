# ERC20
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4104c9a5fb1b403d7a1bc8bdf3c0f7c85335ff70/modules/ERC20.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md), [Initializable](/node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol/abstract.Initializable.md)


## State Variables
### INITIALIZABLE_STORAGE

```solidity
bytes32 private constant INITIALIZABLE_STORAGE =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.ERC20.Initializable")) - 1)) & ~bytes32(uint256(0xff))
```


## Functions
### _initializableStorageSlot


```solidity
function _initializableStorageSlot() internal pure override returns (bytes32);
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory _selectors);
```

### initializeERC20


```solidity
function initializeERC20() external initializer;
```

### name


```solidity
function name() external view returns (string memory);
```

### symbol


```solidity
function symbol() external view returns (string memory);
```

### decimals


```solidity
function decimals() external view returns (uint8);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address owner_) external view returns (uint256);
```

### allowance


```solidity
function allowance(address owner_, address spender_) external view returns (uint256);
```

### approve


```solidity
function approve(address spender_, uint256 amount_) external returns (bool);
```

### increaseAllowance


```solidity
function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool);
```

### decreaseAllowance


```solidity
function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool);
```

### forceApprove


```solidity
function forceApprove(address spender_, uint256 amount_) external returns (bool);
```

### transfer


```solidity
function transfer(address to_, uint256 amount_) external returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from_, address to_, uint256 amount_) external returns (bool);
```

### _approve


```solidity
function _approve(address owner_, address spender_, uint256 amount_) private;
```

