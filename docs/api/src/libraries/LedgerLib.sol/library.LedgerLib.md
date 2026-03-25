# LedgerLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/df3844c9f1ae77a79f53c275e50e3d3e12c811a6/libraries/LedgerLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff))
```


### NATIVE_ADDRESS

```solidity
address internal constant NATIVE_ADDRESS = 0xE0092BfAe8c1A1d8CB953ed67bd42A4861E423F9
```


### SOURCE_ADDRESS

```solidity
address internal constant SOURCE_ADDRESS = 0x245f14e61ecde591FD8B445DC8e2bF76da4505E6
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


### FLAG_IS_REGISTERED

```solidity
uint256 constant FLAG_IS_REGISTERED = 1 << 4
```


### FLAG_DEPTH_SHIFT

```solidity
uint256 constant FLAG_DEPTH_SHIFT = 8
```


### FLAG_DEPTH_MASK

```solidity
uint256 constant FLAG_DEPTH_MASK = uint256(0xff) << FLAG_DEPTH_SHIFT
```


### PACK_ADDR_SHIFT

```solidity
uint256 constant PACK_ADDR_SHIFT = 96
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

### isZeroAddress


```solidity
function isZeroAddress(address addr_) internal pure returns (bool);
```

### checkZeroAddress


```solidity
function checkZeroAddress(address addr_) internal pure;
```

### isValidString


```solidity
function isValidString(string memory str_) internal pure returns (bool);
```

### checkString


```solidity
function checkString(string memory str_) internal pure;
```

### checkRoots


```solidity
function checkRoots(address a_, address b_) internal view returns (address);
```

### flags


```solidity
function flags(
    address parent_,
    bool isGroup_,
    bool isCredit_,
    bool isInternal_,
    bool isNative_,
    bool isRegistered_,
    uint8 depth_
) internal pure returns (uint256 _flags);
```

### flags


```solidity
function flags(address addr_) internal view returns (uint256);
```

### parent


```solidity
function parent(uint256 flags_) internal pure returns (address);
```

### isGroup


```solidity
function isGroup(uint256 flags_) internal pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags_) internal pure returns (bool);
```

### effectiveFlags


```solidity
function effectiveFlags(address parent_, address addr_) internal view returns (address _current, uint256 _flags);
```

### isInternal


```solidity
function isInternal(uint256 flags_) internal pure returns (bool);
```

### isNative


```solidity
function isNative(uint256 flags_) internal pure returns (bool);
```

### isRegistered


```solidity
function isRegistered(uint256 flags_) internal pure returns (bool);
```

### depth


```solidity
function depth(uint256 flags_) internal pure returns (uint8);
```

### isExternal


```solidity
function isExternal(uint256 flags_) internal pure returns (bool);
```

### isRoot


```solidity
function isRoot(uint256 flags_) internal pure returns (bool);
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
function root(address addr_) internal view returns (address);
```

### parent


```solidity
function parent(address addr_) internal view returns (address);
```

### wrapper


```solidity
function wrapper(address addr_) internal view returns (address);
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

### debitBalanceOf


```solidity
function debitBalanceOf(address addr_) internal view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address addr_) internal view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address addr_) internal view returns (uint256);
```

### hasBalance


```solidity
function hasBalance(address addr_) internal view returns (bool);
```

### totalSupply


```solidity
function totalSupply(address token_) internal view returns (uint256 _supply);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent_, string memory name_, bool isCredit_)
    internal
    returns (address _addr, uint256 _flags);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent_, address addr_, string memory name_, bool isCredit_)
    internal
    returns (address _addr, uint256 _flags);
```

### addSubAccount


```solidity
function addSubAccount(address parent_, string memory name_, bool isCredit_)
    internal
    returns (address _addr, uint256 _flags);
```

### addSubAccount


```solidity
function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
    internal
    returns (address _addr, uint256 _flags);
```

### addLedger


```solidity
function addLedger(address root_, string memory name_, string memory symbol_, uint8 decimals_, bool isInternal_)
    internal
    returns (uint256 _flags);
```

### addNativeToken


```solidity
function addNativeToken() internal returns (uint256 _flags);
```

### addExternalToken


```solidity
function addExternalToken(address token_) internal returns (uint256 _flags);
```

### createToken


```solidity
function createToken(string memory name_, string memory symbol_, uint8 decimals_)
    internal
    returns (address _token, uint256 _flags);
```

### createWrapper


```solidity
function createWrapper(address token_) internal returns (address wrapper_, uint256 _flags);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent_, string memory name_) internal returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent_, address addr_) internal returns (address _addr);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent_, string memory name_) internal returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent_, address addr_) internal returns (address);
```

### debit


```solidity
function debit(address root_, address parent_, address addr_, uint256 amount_) internal;
```

### credit


```solidity
function credit(address root_, address parent_, address addr_, uint256 amount_) internal;
```

### _update


```solidity
function _update(
    AccountCache memory acct_,
    address root_,
    mapping(address => uint256) storage balances_,
    uint256 amount_,
    bool isIncreased_
) internal returns (uint256 _balance);
```

### transfer


```solidity
function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
    internal
    returns (address _root, uint256 _fromFlags, uint256 _toFlags);
```

### wrap


```solidity
function wrap(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
    internal
    returns (address _token, uint256 _fromFlags, uint256 _toFlags);
```

### unwrap


```solidity
function unwrap(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
    internal
    returns (address _token, uint256 _fromFlags, uint256 _toFlags);
```

## Structs
### Store

```solidity
struct Store {
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => address) root;
    mapping(address => address) wrapper;
    mapping(address parent => address[]) subs;
    mapping(address sub => uint32) subIndex;
    mapping(address => uint256) flags;
    mapping(address => uint256) debits;
    mapping(address => uint256) credits;
}
```

### AccountCache

```solidity
struct AccountCache {
    uint256 balance;
    address current;
    uint256 flags;
}
```

