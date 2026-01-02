# Ledger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/modules/Ledger.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md), [Initializable](/node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol/abstract.Initializable.md), [ReentrancyGuard](/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md), [ILedger](/interfaces/ILedger.sol/interface.ILedger.md)


## State Variables
### _decimals

```solidity
uint8 internal immutable _decimals
```


### REENTRANCY_GUARD_STORAGE

```solidity
bytes32 private constant REENTRANCY_GUARD_STORAGE = keccak256(
    abi.encode(uint256(keccak256("cavalre.storage.Ledger.ReentrancyGuard")) - 1)
) & ~bytes32(uint256(0xff))
```


### INITIALIZABLE_STORAGE

```solidity
bytes32 private constant INITIALIZABLE_STORAGE =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger.Initializable")) - 1)) & ~bytes32(uint256(0xff))
```


## Functions
### constructor


```solidity
constructor(uint8 decimals_) ;
```

### _initializableStorageSlot


```solidity
function _initializableStorageSlot() internal pure override returns (bytes32);
```

### _reentrancyGuardStorageSlot


```solidity
function _reentrancyGuardStorageSlot() internal pure override returns (bytes32);
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory _selectors);
```

### initializeLedger_unchained


```solidity
function initializeLedger_unchained(string memory nativeTokenSymbol_) public onlyInitializing;
```

### initializeLedger


```solidity
function initializeLedger(string memory nativeTokenSymbol_) external initializer;
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent_, string memory name_, bool isCredit_) external returns (address);
```

### addSubAccount


```solidity
function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
    external
    returns (address);
```

### createWrappedToken


```solidity
function createWrappedToken(address token_) external;
```

### createInternalToken


```solidity
function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, bool isCredit_)
    external
    returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent_, string memory name_) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent_, address addr_) external returns (address);
```

### name


```solidity
function name(address addr_) external view returns (string memory);
```

### symbol


```solidity
function symbol(address addr_) external view returns (string memory);
```

### decimals


```solidity
function decimals(address addr_) external view returns (uint8);
```

### root


```solidity
function root(address addr_) external view returns (address);
```

### parent


```solidity
function parent(address addr_) external view returns (address);
```

### flags


```solidity
function flags(address addr_) external view returns (uint256);
```

### wrapper


```solidity
function wrapper(address token_) external view returns (address);
```

### isGroup


```solidity
function isGroup(address addr_) external view returns (bool);
```

### isCredit


```solidity
function isCredit(address addr_) external view returns (bool);
```

### isInternal


```solidity
function isInternal(address addr_) external view returns (bool);
```

### subAccounts


```solidity
function subAccounts(address parent_) external view returns (address[] memory);
```

### hasSubAccount


```solidity
function hasSubAccount(address parent_) external view returns (bool);
```

### subAccountIndex


```solidity
function subAccountIndex(address parent_, address addr_) external view returns (uint32);
```

### balanceOf


```solidity
function balanceOf(address parent_, string memory subName_) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address parent_, address owner_) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address token_) external view returns (uint256);
```

### reserveAddress


```solidity
function reserveAddress(address token_) external view returns (address);
```

### scaleAddress


```solidity
function scaleAddress(address token_) external view returns (address);
```

### reserve


```solidity
function reserve(address token_) external view returns (uint256);
```

### scale


```solidity
function scale(address token_) external view returns (uint256);
```

### price


```solidity
function price(address token_) external view returns (Float);
```

### totalValue


```solidity
function totalValue(address token_) external view returns (Float);
```

### _enforceWrapperCaller


```solidity
function _enforceWrapperCaller(address parent_) private view;
```

### transfer


```solidity
function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
    external
    returns (bool);
```

### transfer


```solidity
function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external returns (bool);
```

### wrap


```solidity
function wrap(address token_, uint256 amount_) external payable nonReentrant;
```

### unwrap


```solidity
function unwrap(address token_, uint256 amount_) external payable nonReentrant;
```

