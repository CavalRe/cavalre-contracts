# ILedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/27a8b6bea99c34fd7ef12952ab488aa1d4998a37/interfaces/ILedger.sol)


## Functions
### initializeLedger


```solidity
function initializeLedger() external;
```

### name


```solidity
function name(address addr) external view returns (string memory);
```

### symbol


```solidity
function symbol(address addr) external view returns (string memory);
```

### decimals


```solidity
function decimals(address addr) external view returns (uint8);
```

### nativeName


```solidity
function nativeName() external view returns (string memory);
```

### nativeSymbol


```solidity
function nativeSymbol() external view returns (string memory);
```

### root


```solidity
function root(address addr) external view returns (address);
```

### parent


```solidity
function parent(address addr) external view returns (address);
```

### flags


```solidity
function flags(address addr) external view returns (uint256);
```

### wrapper


```solidity
function wrapper(address token) external view returns (address);
```

### isGroup


```solidity
function isGroup(uint256 flags) external pure returns (bool);
```

### isCredit


```solidity
function isCredit(uint256 flags) external pure returns (bool);
```

### isInternal


```solidity
function isInternal(uint256 flags) external pure returns (bool);
```

### isNative


```solidity
function isNative(uint256 flags) external pure returns (bool);
```

### isWrapper


```solidity
function isWrapper(uint256 flags) external pure returns (bool);
```

### isRegistered


```solidity
function isRegistered(uint256 flags) external pure returns (bool);
```

### isExternal


```solidity
function isExternal(uint256 flags) external pure returns (bool);
```

### subAccounts


```solidity
function subAccounts(address parent) external view returns (address[] memory);
```

### hasSubAccount


```solidity
function hasSubAccount(address parent) external view returns (bool);
```

### subAccountIndex


```solidity
function subAccountIndex(address parent, address addr) external view returns (uint32);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent, string memory name, bool isCredit) external returns (address);
```

### addSubAccount


```solidity
function addSubAccount(address parent, address addr, string memory name, bool isInternal) external returns (address);
```

### createNativeWrapper


```solidity
function createNativeWrapper(string memory nativeTokenName, string memory nativeTokenSymbol)
    external
    returns (address);
```

### createWrappedToken


```solidity
function createWrappedToken(address token) external;
```

### createInternalToken


```solidity
function createInternalToken(string memory name, string memory symbol, uint8 decimals, bool isCredit)
    external
    returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent, string memory name) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent, address child) external returns (address);
```

### balanceOf


```solidity
function balanceOf(address parent, string memory subName) external view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address parent, address owner) external view returns (uint256);
```

### totalSupply


```solidity
function totalSupply(address token) external view returns (uint256);
```

### scaleAddress


```solidity
function scaleAddress(address token) external view returns (address);
```

### scale


```solidity
function scale(address token) external view returns (uint256);
```

### transfer


```solidity
function transfer(address fromParent, address from, address toParent, address to, uint256 amount)
    external
    returns (bool);
```

### transfer


```solidity
function transfer(address fromParent, address toParent, address to, uint256 amount) external returns (bool);
```

### wrap


```solidity
function wrap(address token_, uint256 amount_, address sourceParent_, address source_) external payable;
```

### unwrap


```solidity
function unwrap(address token_, uint256 amount_, address sourceParent_, address source_) external payable;
```

## Events
### BalanceUpdate

```solidity
event BalanceUpdate(address indexed token, address indexed parent, address indexed account, uint256 newBalance);
```

### Credit

```solidity
event Credit(address indexed token, address indexed parent, address indexed account, uint256 value);
```

### Debit

```solidity
event Debit(address indexed token, address indexed parent, address indexed account, uint256 value);
```

### InternalApproval

```solidity
event InternalApproval(address indexed ownerParent, address indexed owner, address indexed spender, uint256 value);
```

### LedgerAdded

```solidity
event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
```

### SubAccountAdded

```solidity
event SubAccountAdded(address indexed root, address indexed parent, address addr, bool isCredit);
```

### SubAccountGroupAdded

```solidity
event SubAccountGroupAdded(address indexed root, address indexed parent, string subName, bool isCredit);
```

### SubAccountRemoved

```solidity
event SubAccountRemoved(address indexed root, address indexed parent, address addr);
```

### SubAccountGroupRemoved

```solidity
event SubAccountGroupRemoved(address indexed root, address indexed parent, string subName);
```

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value);
```

## Errors
### DifferentRoots

```solidity
error DifferentRoots(address a, address b);
```

### DuplicateSubAccount

```solidity
error DuplicateSubAccount(address sub);
```

### DuplicateToken

```solidity
error DuplicateToken(address token);
```

### HasBalance

```solidity
error HasBalance(address addr);
```

### HasSubAccount

```solidity
error HasSubAccount(address addr);
```

### IncorrectAmount

```solidity
error IncorrectAmount(uint256 received, uint256 expected);
```

### InsufficientAllowance

```solidity
error InsufficientAllowance(address ownerParent, address owner, address spender, uint256 current, uint256 amount);
```

### InsufficientBalance

```solidity
error InsufficientBalance(address token, address parent, address account, uint256 amount);
```

### InvalidAddress

```solidity
error InvalidAddress(address absoluteAddress);
```

### InvalidDecimals

```solidity
error InvalidDecimals(uint8 decimals);
```

### InvalidAccountGroup

```solidity
error InvalidAccountGroup();
```

### InvalidLedgerAccount

```solidity
error InvalidLedgerAccount(address ledgerAddress);
```

### InvalidReallocation

```solidity
error InvalidReallocation(address token, int256 reallocation);
```

### InvalidString

```solidity
error InvalidString(string symbol);
```

### InvalidSubAccount

```solidity
error InvalidSubAccount(address addr, bool isCredit);
```

### InvalidSubAccountGroup

```solidity
error InvalidSubAccountGroup(string subName, bool isCredit);
```

### InvalidSubAccountIndex

```solidity
error InvalidSubAccountIndex(uint256 index);
```

### InvalidToken

```solidity
error InvalidToken(address token, string name, string symbol, uint8 decimals);
```

### MaxDepthExceeded

```solidity
error MaxDepthExceeded();
```

### NotCredit

```solidity
error NotCredit(string name);
```

### SubAccountNotFound

```solidity
error SubAccountNotFound(address addr);
```

### SubAccountGroupNotFound

```solidity
error SubAccountGroupNotFound(string subName);
```

### Unauthorized

```solidity
error Unauthorized(address user);
```

### ZeroAddress

```solidity
error ZeroAddress();
```

### ZeroScale

```solidity
error ZeroScale(address addr);
```

