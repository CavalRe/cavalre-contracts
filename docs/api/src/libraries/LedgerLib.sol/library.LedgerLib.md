# LedgerLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/27a8b6bea99c34fd7ef12952ab488aa1d4998a37/libraries/LedgerLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff))
```


### MAX_DEPTH

```solidity
uint8 internal constant MAX_DEPTH = 10
```


### TOTAL_ADDRESS

```solidity
address internal constant TOTAL_ADDRESS = 0xa763678a2e868D872d408672C9f80B77F4d1d14B
```


### RESERVE_ADDRESS

```solidity
address internal constant RESERVE_ADDRESS = 0x3a9097D216F9D5859bE6b3918F997A8823E92984
```


### NATIVE_ADDRESS

```solidity
address internal constant NATIVE_ADDRESS = 0xE0092BfAe8c1A1d8CB953ed67bd42A4861E423F9
```


### UNALLOCATED_ADDRESS

```solidity
address internal constant UNALLOCATED_ADDRESS = 0xCb7943b1c8232a1F49aFDe9B865B7fB4C5870738
```


### FLAG_IS_GROUP

```solidity
uint256 constant FLAG_IS_GROUP = 1 << 0
```


### FLAG_IS_CREDIT

```solidity
uint256 constant FLAG_IS_CREDIT = 1 << 1
```


### FLAG_IS_INTERNAL

```solidity
uint256 constant FLAG_IS_INTERNAL = 1 << 2
```


### FLAG_IS_NATIVE

```solidity
uint256 constant FLAG_IS_NATIVE = 1 << 3
```


### FLAG_IS_WRAPPER

```solidity
uint256 constant FLAG_IS_WRAPPER = 1 << 4
```


### FLAG_IS_REGISTERED

```solidity
uint256 constant FLAG_IS_REGISTERED = 1 << 5
```


### PACK_ADDR_SHIFT

```solidity
uint256 constant PACK_ADDR_SHIFT = 96
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage _s);
```

### checkZeroAddress


```solidity
function checkZeroAddress(address addr_) internal pure;
```

### isZeroAddress


```solidity
function isZeroAddress(address addr_) internal pure returns (bool);
```

### flags


```solidity
function flags(
    address wrapper_,
    bool isGroup_,
    bool isCredit_,
    bool isInternal_,
    bool isNative_,
    bool isWrapper_,
    bool isRegistered_
) internal pure returns (uint256 _flags);
```

### flags


```solidity
function flags(address addr_) internal view returns (uint256);
```

### wrapper


```solidity
function wrapper(uint256 flags_) internal pure returns (address);
```

### isGroup


```solidity
function isGroup(uint256 flags_) internal pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags_) internal pure returns (bool);
```

### isInternal


```solidity
function isInternal(uint256 flags_) internal pure returns (bool);
```

### isNative


```solidity
function isNative(uint256 flags_) internal pure returns (bool);
```

### isWrapper


```solidity
function isWrapper(uint256 flags_) internal pure returns (bool);
```

### isRegistered


```solidity
function isRegistered(uint256 flags_) internal pure returns (bool);
```

### isExternal


```solidity
function isExternal(uint256 flags_) internal pure returns (bool);
```

### isValidString


```solidity
function isValidString(string memory str_) internal pure returns (bool);
```

### checkString


```solidity
function checkString(string memory str_) internal pure;
```

### toAddress


```solidity
function toAddress(string memory name_) internal pure returns (address);
```

### toAddress


```solidity
function toAddress(address parent_, address ledger_) internal pure returns (address);
```

### toAddress


```solidity
function toAddress(address parent_, string memory name_) internal pure returns (address);
```

### checkRoots


```solidity
function checkRoots(address a_, address b_) internal view returns (address);
```

### name


```solidity
function name(address addr_, string memory name_) internal;
```

### symbol


```solidity
function symbol(address addr_, string memory symbol_) internal;
```

### decimals


```solidity
function decimals(address addr_, uint8 decimals_) internal;
```

### name


```solidity
function name(address addr_) internal view returns (string memory);
```

### symbol


```solidity
function symbol(address addr_) internal view returns (string memory);
```

### decimals


```solidity
function decimals(address addr_) internal view returns (uint8);
```

### root


```solidity
function root(address addr_) internal view returns (address _root);
```

### parent


```solidity
function parent(address addr_) internal view returns (address);
```

### subAccounts


```solidity
function subAccounts(address addr_) internal view returns (address[] memory);
```

### subAccount


```solidity
function subAccount(address parent_, uint256 index_) internal view returns (address);
```

### hasSubAccount


```solidity
function hasSubAccount(address addr_) internal view returns (bool);
```

### subAccountIndex


```solidity
function subAccountIndex(address parent_, address addr_) internal view returns (uint32);
```

### balanceOf


```solidity
function balanceOf(address addr_) internal view returns (uint256);
```

### hasBalance


```solidity
function hasBalance(address addr_) internal view returns (bool);
```

### accountTypeRootAddress


```solidity
function accountTypeRootAddress(address addr_, bool isCredit_) internal pure returns (address);
```

### scale


```solidity
function scale(address token_, bool isCredit_) internal view returns (uint256);
```

### scale


```solidity
function scale(address token_) internal view returns (uint256);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent_, string memory name_, bool isCredit_) internal returns (address _sub);
```

### addSubAccount


```solidity
function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
    internal
    returns (address _sub);
```

### addLedger


```solidity
function addLedger(
    address root_,
    address wrapper_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    bool isCredit_,
    bool isInternal_
) internal;
```

### createNativeWrapper


```solidity
function createNativeWrapper(string memory nativeTokenName_, string memory nativeTokenSymbol_)
    internal
    returns (address wrapper_);
```

### createWrappedToken


```solidity
function createWrappedToken(address token_)
    internal
    returns (address _wrapper, string memory _name, string memory _symbol, uint8 _decimals);
```

### createInternalToken


```solidity
function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, bool isCredit_)
    internal
    returns (address wrapper_);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent_, string memory name_) internal returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent_, address addr_) internal returns (address);
```

### debit


```solidity
function debit(address parent_, address addr_, uint256 amount_) internal returns (address _root);
```

### credit


```solidity
function credit(address parent_, address addr_, uint256 amount_) internal returns (address _root);
```

### wrap


```solidity
function wrap(address token_, uint256 amount_, address sourceParent_, address source_) internal;
```

### unwrap


```solidity
function unwrap(address token_, uint256 amount_, address sourceParent_, address source_) internal;
```

### transfer


```solidity
function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
    internal
    returns (bool);
```

### reallocate


```solidity
function reallocate(address fromToken_, address toToken_, uint256 amount_) internal;
```

## Structs
### Store

```solidity
struct Store {
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => address) root;
    mapping(address sub => address) parent;
    mapping(address parent => address[]) subs;
    mapping(address sub => uint32) subIndex;
    mapping(address => uint256) flags;
    mapping(address => uint256) balance;
}
```

