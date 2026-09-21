# LedgerLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/LedgerLib.sol)


## Constants
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


### ROOT_NAME

```solidity
string internal constant ROOT_NAME = "Root"
```


### ROOT_ADDRESS

```solidity
address internal constant ROOT_ADDRESS = 0xFE99DF08Ff3B677df31fFB23cD04828AA70d2de5
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

### enforceNonZeroAddress


```solidity
function enforceNonZeroAddress(address addr_) internal pure;
```

### isValidString


```solidity
function isValidString(string memory str_) internal pure returns (bool);
```

### enforceValidString


```solidity
function enforceValidString(string memory str_) internal pure;
```

### enforceNativeValue


```solidity
function enforceNativeValue(uint256 expected_) internal view;
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

### ledgerCount


```solidity
function ledgerCount() internal view returns (uint256);
```

### ledgerAt


```solidity
function ledgerAt(uint256 index_) internal view returns (address);
```

### ledgers


```solidity
function ledgers(uint256 start_, uint256 limit_) internal view returns (address[] memory _ledgers);
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

### parent


```solidity
function parent(uint256 flags_) internal pure returns (address);
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

### isLedgerAccount


```solidity
function isLedgerAccount(uint256 flags_) internal pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags_) internal pure returns (bool);
```

### effectiveFlags


```solidity
function effectiveFlags(address ledger_, address parent_, address relative_)
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

### isLedger


```solidity
function isLedger(uint256 flags_) internal pure returns (bool);
```

### toAddress

Derives a relative address from a human-readable name.

Relative addresses are reusable child keys; direct children supply ERC20 custody holder addresses.


```solidity
function toAddress(string memory name_) internal pure returns (address);
```

### toAddress

Derives an absolute accounting address from its absolute parent and relative child.

H(g,r): hash the 40 packed bytes of the absolute parent and relative child; retain the low 160 bits.


```solidity
function toAddress(address parent_, address relative_) internal pure returns (address);
```

### toAddress

Derives an absolute accounting address from its absolute parent and a child name.

Equivalent to toAddress(parent_, toAddress(name_)).


```solidity
function toAddress(address parent_, string memory name_) internal pure returns (address);
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

### ledger

Custody flags pack the ledger as their parent. Roots identify themselves by their flags;
unregistered leaves require explicit parent context and retain no address-only ledger lookup.


```solidity
function ledger(address absolute_) internal view returns (address);
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
function totalSupply(address ledger_) internal view returns (uint256 _supply);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address ledger_, address parent_, string memory name_, bool isCredit_)
    internal
    returns (address _absolute, uint256 _flags);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(
    address ledger_,
    address parent_,
    address relative_,
    string memory name_,
    bool isCredit_
) internal returns (address _absolute, uint256 _flags);
```

### addSubAccount


```solidity
function addSubAccount(address ledger_, address parent_, string memory name_, bool isCredit_)
    internal
    returns (address _absolute, uint256 _flags);
```

### addSubAccount


```solidity
function addSubAccount(address ledger_, address parent_, address relative_, string memory name_, bool isCredit_)
    internal
    returns (address _absolute, uint256 _flags);
```

### addLedger


```solidity
function addLedger(
    address ledger_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    TokenKind tokenKind_
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
function removeSubAccountGroup(address ledger_, address parent_, string memory name_) internal returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address ledger_, address parent_, address relative_)
    internal
    returns (address _absolute);
```

### removeSubAccount


```solidity
function removeSubAccount(address ledger_, address parent_, string memory name_) internal returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address ledger_, address parent_, address relative_)
    internal
    returns (address _absolute);
```

### _update


```solidity
function _update(
    AccountCache memory acct_,
    address ledger_,
    mapping(address => uint256) storage balances_,
    uint256 amount_,
    bool isIncreased_
) internal returns (uint256 _balance);
```

### setAccountCache


```solidity
function setAccountCache(uint256 flags_, address relative_) private pure returns (AccountCache memory _acct);
```

### custody

Token roots have stored depth 2 because of the enclosing global Root.
Custodians are their direct children (article depth 2, stored depth 3).


```solidity
function custody(address ledger_, uint256 flags_, address relative_)
    internal
    view
    returns (address holder_, bool isCredit_);
```

### emitWrapperTransfer


```solidity
function emitWrapperTransfer(address ledger_, AccountCache memory from_, AccountCache memory to_, uint256 amount_)
    private;
```

### transfer

Callers resolve effective flags for both endpoints on ledger_ before calling.
Flags carry each absolute parent, depth and polarity, including unregistered leaves.
This internal posting reuses that validated metadata; callers own authorization.


```solidity
function transfer(
    address ledger_,
    uint256 fromFlags_,
    address from_,
    uint256 toFlags_,
    address to_,
    uint256 amount_
) internal returns (address _ledger, bool _fromIsCredit, bool _toIsCredit);
```

### wrap


```solidity
function wrap(
    address payer_,
    address ledger_,
    address fromParent_,
    address from_,
    address toParent_,
    address to_,
    uint256 amount_
) internal returns (address, bool _fromIsCredit, bool _toIsCredit);
```

### unwrap


```solidity
function unwrap(
    address recipient_,
    address ledger_,
    address fromParent_,
    address from_,
    address toParent_,
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
    // Registered accounts point to their absolute depth-3 custodian; ledger roots have no entry.
    mapping(address absolute => address custodyAccount) custody;
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
    address relative;
    address absolute;
    uint256 flags;
    uint8 depth;
}
```

### WrapCache

```solidity
struct WrapCache {
    uint256 ledgerFlags;
    uint256 balanceBefore;
    uint256 balanceAfter;
    uint256 received;
}
```

### UnwrapCache

```solidity
struct UnwrapCache {
    uint256 ledgerFlags;
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
    Internal
}
```

