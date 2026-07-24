# LedgerLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/LedgerLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff))
```


### SOURCE_NAME

```solidity
string internal constant SOURCE_NAME = "Source"
```


### SOURCE_ADDRESS

```solidity
address internal constant SOURCE_ADDRESS = 0x245f14e61ecde591FD8B445DC8e2bF76da4505E6
```


### NATIVE_ADDRESS

```solidity
address internal constant NATIVE_ADDRESS = 0xE0092BfAe8c1A1d8CB953ed67bd42A4861E423F9
```


### ACCOUNT_KIND_SHIFT

```solidity
uint256 constant ACCOUNT_KIND_SHIFT = 0
```


### ACCOUNT_KIND_MASK

```solidity
uint256 constant ACCOUNT_KIND_MASK = uint256(0x07) << ACCOUNT_KIND_SHIFT
```


### TOKEN_KIND_SHIFT

```solidity
uint256 constant TOKEN_KIND_SHIFT = 3
```


### TOKEN_KIND_MASK

```solidity
uint256 constant TOKEN_KIND_MASK = uint256(0x07) << TOKEN_KIND_SHIFT
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

### enforceNativeValue


```solidity
function enforceNativeValue(uint256 expected_) internal view;
```

### checkRoots


```solidity
function checkRoots(address a_, address b_) internal view returns (address);
```

### flags


```solidity
function flags(address packedAddress_, AccountKind accountKind_, TokenKind tokenKind_, uint8 depth_)
    internal
    pure
    returns (uint256 _flags);
```

### flags


```solidity
function flags(address absolute_) internal view returns (uint256);
```

### rootCount


```solidity
function rootCount() internal view returns (uint256);
```

### rootAt


```solidity
function rootAt(uint256 index_) internal view returns (address);
```

### roots


```solidity
function roots(uint256 start_, uint256 limit_) internal view returns (address[] memory _roots);
```

### accountKind


```solidity
function accountKind(uint256 flags_) internal pure returns (AccountKind);
```

### tokenKind


```solidity
function tokenKind(uint256 flags_) internal pure returns (TokenKind);
```

### packedAddress


```solidity
function packedAddress(uint256 flags_) internal pure returns (address);
```

### holderParent


```solidity
function holderParent(uint256 flags_) internal pure returns (address);
```

### isUnregisteredAccount


```solidity
function isUnregisteredAccount(uint256 flags_) internal pure returns (bool);
```

### isDebitGroup


```solidity
function isDebitGroup(uint256 flags_) internal pure returns (bool);
```

### isCreditGroup


```solidity
function isCreditGroup(uint256 flags_) internal pure returns (bool);
```

### isDebitLedger


```solidity
function isDebitLedger(uint256 flags_) internal pure returns (bool);
```

### isCreditLedger


```solidity
function isCreditLedger(uint256 flags_) internal pure returns (bool);
```

### isGroup


```solidity
function isGroup(uint256 flags_) internal pure returns (bool);
```

### isLedger


```solidity
function isLedger(uint256 flags_) internal pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags_) internal pure returns (bool);
```

### effectiveFlags


```solidity
function effectiveFlags(address root_, address holderParent_, address relative_)
    internal
    view
    returns (uint256 _effectiveFlags, uint256 _originalFlags, address _absolute);
```

### isUnregisteredToken


```solidity
function isUnregisteredToken(uint256 flags_) internal pure returns (bool);
```

### isInternal


```solidity
function isInternal(uint256 flags_) internal pure returns (bool);
```

### isNative


```solidity
function isNative(uint256 flags_) internal pure returns (bool);
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

### isClaim


```solidity
function isClaim(uint256 flags_) internal pure returns (bool);
```

### claimAccount


```solidity
function claimAccount(uint256 flags_) internal pure returns (address);
```

### checkClaimAccount


```solidity
function checkClaimAccount(address claimTokenAddress_, address absoluteClaimAccount_) internal view;
```

### toAddress

Derives a relative address from a human-readable name.

Relative addresses are reusable across token trees and become holder addresses under a holder parent.


```solidity
function toAddress(string memory name_) internal pure returns (address);
```

### toAddress

Derives the next address in an address tree.

Use `toAddress(holderParent, relative)` for holders, and `toAddress(root, holder)` for absolute keys.


```solidity
function toAddress(address base_, address relative_) internal pure returns (address);
```

### toAddress

Derives an absolute Ledger storage address in root scope.

First derives the holder from `holderParent_ + relative_`, then projects it through `root_`.


```solidity
function toAddress(address root_, address holderParent_, address relative_) internal pure returns (address);
```

### toAddress

Derives a named relative address in a holder-parent context.

This is a contextual relative value, not an absolute Ledger storage key.


```solidity
function toAddress(address holderParent_, string memory name_) internal pure returns (address);
```

### name


```solidity
function name(address absolute_, string memory name_) internal;
```

### symbol


```solidity
function symbol(address absolute_, string memory symbol_) internal;
```

### decimals


```solidity
function decimals(address absolute_, uint8 decimals_) internal;
```

### name


```solidity
function name(address absolute_) internal view returns (string memory);
```

### symbol


```solidity
function symbol(address absolute_) internal view returns (string memory);
```

### decimals


```solidity
function decimals(address absolute_) internal view returns (uint8);
```

### root


```solidity
function root(address absolute_) internal view returns (address);
```

### wrapper


```solidity
function wrapper(address absolute_) internal view returns (address);
```

### subAccounts


```solidity
function subAccounts(address absolute_) internal view returns (address[] memory);
```

### subAccount


```solidity
function subAccount(address absolute_, uint256 index_) internal view returns (address);
```

### hasSubAccount


```solidity
function hasSubAccount(address absolute_) internal view returns (bool);
```

### subAccountIndex


```solidity
function subAccountIndex(address absolute_) internal view returns (uint32);
```

### toSubIndex


```solidity
function toSubIndex(uint256 index_) private pure returns (uint32);
```

### debitBalanceOf


```solidity
function debitBalanceOf(address absolute_) internal view returns (uint256);
```

### creditBalanceOf


```solidity
function creditBalanceOf(address absolute_) internal view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address absolute_, bool isCredit_) internal view returns (uint256 _balance);
```

### totalSupply


```solidity
function totalSupply(address root_) internal view returns (uint256 _supply);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address root_, address holderParent_, string memory name_, bool isCredit_)
    internal
    returns (address _holder, uint256 _flags);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(
    address root_,
    address holderParent_,
    address relative_,
    string memory name_,
    bool isCredit_
) internal returns (address _holder, uint256 _flags);
```

### addSubAccount


```solidity
function addSubAccount(address root_, address holderParent_, string memory name_, bool isCredit_)
    internal
    returns (address _holder, uint256 _flags);
```

### addSubAccount


```solidity
function addSubAccount(address root_, address holderParent_, address relative_, string memory name_, bool isCredit_)
    internal
    returns (address _holder, uint256 _flags);
```

### addLedger


```solidity
function addLedger(
    address root_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    TokenKind tokenKind_,
    address packedAddress_
) internal returns (uint256 _flags);
```

### setNativeMetadata


```solidity
function setNativeMetadata(string memory name_, string memory symbol_, uint8 decimals_) internal;
```

### nativeName


```solidity
function nativeName() internal view returns (string memory);
```

### nativeSymbol


```solidity
function nativeSymbol() internal view returns (string memory);
```

### nativeDecimals


```solidity
function nativeDecimals() internal view returns (uint8);
```

### addNativeToken


```solidity
function addNativeToken() internal returns (uint256 _flags);
```

### addExternalToken


```solidity
function addExternalToken(address token_) internal returns (uint256 _flags);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address root_, address holderParent_, string memory name_)
    internal
    returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address root_, address holderParent_, address relative_)
    internal
    returns (address _holder);
```

### removeSubAccount


```solidity
function removeSubAccount(address root_, address holderParent_, string memory name_) internal returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address root_, address holderParent_, address relative_)
    internal
    returns (address _holder);
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

### setAccountCache


```solidity
function setAccountCache(address root_, address holderParent_, address relative_)
    private
    view
    returns (AccountCache memory _acct);
```

### emitWrapperTransfer


```solidity
function emitWrapperTransfer(
    address root_,
    AccountCache memory from_,
    bool fromIsCredit_,
    AccountCache memory to_,
    bool toIsCredit_,
    uint256 amount_
) private;
```

### enforceTransfer


```solidity
function enforceTransfer(
    address root_,
    address fromHolderParent_,
    address from_,
    address toHolderParent_,
    address to_
) internal view returns (address _root, bool _fromIsCredit, bool _toIsCredit);
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
) internal returns (address _root, bool _fromIsCredit, bool _toIsCredit);
```

### wrap


```solidity
function wrap(
    address payer_,
    address root_,
    address fromHolderParent_,
    address from_,
    address toHolderParent_,
    address to_,
    uint256 amount_
) internal returns (address, bool _fromIsCredit, bool _toIsCredit);
```

### unwrap


```solidity
function unwrap(
    address recipient_,
    address root_,
    address fromHolderParent_,
    address from_,
    address toHolderParent_,
    address to_,
    uint256 amount_
) internal returns (address, bool _fromIsCredit, bool _toIsCredit);
```

## Structs
### Store

```solidity
struct Store {
    mapping(address => string) name;
    mapping(address => string) symbol;
    mapping(address => uint8) decimals;
    mapping(address => address) root;
    address[] roots;
    mapping(address => uint256) rootIndex;
    mapping(address => address) wrapper;
    mapping(address parent => address[]) subs;
    mapping(address sub => uint32) subIndex;
    mapping(address => uint256) flags;
    mapping(address => uint256) debits;
    mapping(address => uint256) credits;
    string nativeName;
    string nativeSymbol;
    uint8 nativeDecimals;
}
```

### AccountCache

```solidity
struct AccountCache {
    uint256 balance;
    address holder;
    address relative;
    address absolute;
    uint256 flags;
    uint8 depth;
    bool isUnregistered;
}
```

### WrapCache

```solidity
struct WrapCache {
    uint256 rootFlags;
    uint256 balanceBefore;
    uint256 balanceAfter;
    uint256 received;
}
```

### UnwrapCache

```solidity
struct UnwrapCache {
    uint256 rootFlags;
    uint256 liabilities;
    uint256 collateral;
    uint256 balanceBefore;
    uint256 balanceAfter;
    uint256 received;
}
```

## Enums
### AccountKind

```solidity
enum AccountKind {
    Unregistered,
    DebitGroup,
    CreditGroup,
    DebitLedger,
    CreditLedger
}
```

### TokenKind

```solidity
enum TokenKind {
    Unregistered,
    Native,
    External,
    Internal,
    Claim
}
```

