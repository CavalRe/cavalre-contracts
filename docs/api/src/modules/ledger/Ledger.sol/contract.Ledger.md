# Ledger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/Ledger.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [Initializable](/node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol/abstract.Initializable.md), [ReentrancyGuard](/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)


## State Variables
### _decimals

```solidity
uint8 internal immutable _decimals
```


### _nativeName

```solidity
ShortString internal immutable _nativeName
```


### _nativeSymbol

```solidity
ShortString internal immutable _nativeSymbol
```


### _nativeDecimals

```solidity
uint8 internal immutable _nativeDecimals
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
constructor(uint8 decimals_, string memory nativeName_, string memory nativeSymbol_, uint8 nativeDecimals_) ;
```

### _initializableStorageSlot


```solidity
function _initializableStorageSlot() internal pure override returns (bytes32);
```

### _reentrancyGuardStorageSlot


```solidity
function _reentrancyGuardStorageSlot() internal pure override returns (bytes32);
```

### signatures


```solidity
function signatures() external pure virtual override returns (string[] memory _signatures);
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
function addSubAccountGroup(
    address root_,
    address holderParent_,
    address relative_,
    string memory name_,
    bool isCredit_
) external returns (address, uint256);
```

### addSubAccount


```solidity
function addSubAccount(address root_, address holderParent_, address relative_, string memory name_, bool isCredit_)
    external
    returns (address, uint256);
```

### addNativeToken


```solidity
function addNativeToken() external returns (uint256 _flags);
```

### addExternalToken


```solidity
function addExternalToken(address[] memory tokens_) external returns (uint256[] memory _flags);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address root_, address holderParent_, address relative_) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address root_, address holderParent_, address relative_) external returns (address);
```

### transfer


```solidity
function transfer(
    address root_,
    address fromHolderParent_,
    address from_,
    address toHolderParent_,
    address to_,
    uint256 amount_
) external;
```

### transfer


```solidity
function transfer(address root_, address fromHolderParent_, address toHolderParent_, address to_, uint256 amount_)
    external;
```

### wrap


```solidity
function wrap(address token_, uint256 amount_)
    external
    payable
    nonReentrant
    returns (address _token, bool _fromIsCredit, bool _toIsCredit);
```

### handleNative


```solidity
function handleNative() external payable nonReentrant;
```

### unwrap


```solidity
function unwrap(address token_, uint256 amount_)
    external
    payable
    nonReentrant
    returns (address _token, bool _fromIsCredit, bool _toIsCredit);
```

