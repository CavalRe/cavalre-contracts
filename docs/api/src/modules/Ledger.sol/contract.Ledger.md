# Ledger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/864c40b9986bd124ebb2cf2fd60ea0a56f3c0024/modules/Ledger.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md), [Initializable](/node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol/abstract.Initializable.md), [ReentrancyGuard](/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md), [ILedger](/interfaces/ILedger.sol/interface.ILedger.md)


## State Variables
### _decimals

```solidity
uint8 internal immutable _decimals
```


### _defaultSourceAddress

```solidity
address internal immutable _defaultSourceAddress
```


### _defaultSourceName

```solidity
ShortString internal immutable _defaultSourceName
```


### _nativeName

```solidity
ShortString internal immutable _nativeName
```


### _nativeSymbol

```solidity
ShortString internal immutable _nativeSymbol
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
constructor(
    uint8 decimals_,
    string memory nativeName_,
    string memory nativeSymbol_,
    string memory defaultSourceName_
) ;
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
function initializeLedger_unchained(string memory name_, string memory symbol_) public onlyInitializing;
```

### initializeLedger


```solidity
function initializeLedger(string memory name_, string memory symbol_) external initializer;
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent_, string memory name_, bool isCredit_)
    external
    returns (address, uint256);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent_, address addr_, string memory name_, bool isCredit_)
    external
    returns (address, uint256);
```

### addSubAccount


```solidity
function addSubAccount(address parent_, string memory name_, bool isCredit_) external returns (address, uint256);
```

### addSubAccount


```solidity
function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
    external
    returns (address, uint256);
```

### addNativeToken


```solidity
function addNativeToken() external returns (uint256 _flags);
```

### addExternalToken


```solidity
function addExternalToken(address token_) external returns (uint256 _flags);
```

### createInternalToken


```solidity
function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_)
    external
    returns (address _token, uint256 _flags);
```

### createClaimToken


```solidity
function createClaimToken(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address parent_,
    address addr_
) external returns (address _token, uint256 _flags);
```

### createWrapper


```solidity
function createWrapper(address token_) external returns (address _wrapper, uint256 _flags);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent_, string memory name_) external returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent_, address addr_) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent_, string memory name_) external returns (address);
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

### nativeName


```solidity
function nativeName() external view returns (string memory);
```

### nativeSymbol


```solidity
function nativeSymbol() external view returns (string memory);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address parent_, address owner_) external view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address parent_, address owner_) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address parent_, address owner_) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address token_) external view returns (uint256);
```

### isClaim


```solidity
function isClaim(address token_) external view returns (bool);
```

### claimAccountOf


```solidity
function claimAccountOf(address token_) external view returns (address);
```

### transfer


```solidity
function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
    external
    returns (address _root, uint256 _fromFlags, uint256 _toFlags);
```

### transfer


```solidity
function transfer(address fromParent_, address toParent_, address to_, uint256 amount_)
    external
    returns (address _root, uint256 _fromFlags, uint256 _toFlags);
```

### wrap


```solidity
function wrap(address token_, uint256 amount_)
    external
    payable
    nonReentrant
    returns (address _token, uint256 _fromFlags, uint256 _toFlags);
```

### unwrap


```solidity
function unwrap(address token_, uint256 amount_)
    external
    payable
    nonReentrant
    returns (address _token, uint256 _fromFlags, uint256 _toFlags);
```

