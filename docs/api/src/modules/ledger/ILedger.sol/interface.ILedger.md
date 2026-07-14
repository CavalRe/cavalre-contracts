# ILedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/modules/ledger/ILedger.sol)


## Functions
### initializeLedger


```solidity
function initializeLedger(string memory name, string memory symbol) external;
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent, string memory name, bool isCredit)
    external
    returns (address addr, uint256 flags);
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address parent, address addr, string memory name, bool isCredit)
    external
    returns (address subAccount, uint256 flags);
```

### addSubAccount


```solidity
function addSubAccount(address parent, string memory name, bool isCredit)
    external
    returns (address addr, uint256 flags);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`parent`|`address`||
|`name`|`string`||
|`isCredit`|`bool`|True for credit-side account, false for debit-side in the double-entry tree.|


### addSubAccount


```solidity
function addSubAccount(address parent, address addr, string memory name, bool isCredit)
    external
    returns (address subAccount, uint256 flags);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`parent`|`address`||
|`addr`|`address`||
|`name`|`string`||
|`isCredit`|`bool`|True for credit-side account, false for debit-side in the double-entry tree.|


### addNativeToken


```solidity
function addNativeToken() external returns (uint256 flags);
```

### addExternalToken


```solidity
function addExternalToken(address token) external returns (uint256 flags);
```

### createInternalToken


```solidity
function createInternalToken(string memory name, string memory symbol, uint8 decimals)
    external
    returns (address token, uint256 flags);
```

### createClaimToken


```solidity
function createClaimToken(string memory name, string memory symbol, uint8 decimals, address parent, address addr)
    external
    returns (address token, uint256 flags);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent, string memory name) external returns (address);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address parent, address addr) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent, string memory name) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address parent, address child) external returns (address);
```

### transfer


```solidity
function transfer(address fromParent, address from, address toParent, address to, uint256 amount) external;
```

### transfer


```solidity
function transfer(address fromParent, address toParent, address to, uint256 amount) external;
```

### wrap


```solidity
function wrap(address token_, uint256 amount_)
    external
    payable
    returns (address token, bool fromIsCredit, bool toIsCredit);
```

### unwrap


```solidity
function unwrap(address token_, uint256 amount_)
    external
    payable
    returns (address token, bool fromIsCredit, bool toIsCredit);
```

## Events
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
event SubAccountGroupRemoved(address indexed root, address indexed parent, address addr);
```

### Credit

```solidity
event Credit(address indexed root, address indexed account, uint256 amount, uint256 balance);
```

### Debit

```solidity
event Debit(address indexed root, address indexed account, uint256 amount, uint256 balance);
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

### DuplicateToken

```solidity
error DuplicateToken(address token);
```

### DuplicateWrapper

```solidity
error DuplicateWrapper(address token);
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

### LedgerUninitialized

```solidity
error LedgerUninitialized();
```

### InvalidString

```solidity
error InvalidString(string symbol);
```

### InvalidSubAccount

```solidity
error InvalidSubAccount(address addr);
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

### NativeTransferFailed

```solidity
error NativeTransferFailed();
```

### SubAccountNotFound

```solidity
error SubAccountNotFound(address addr);
```

### SubAccountGroupNotFound

```solidity
error SubAccountGroupNotFound(address addr);
```

### Unauthorized

```solidity
error Unauthorized(address user);
```

### ZeroDepth

```solidity
error ZeroDepth();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

