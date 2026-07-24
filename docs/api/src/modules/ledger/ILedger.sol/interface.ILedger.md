# ILedger
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/ILedger.sol)


## Functions
### initializeLedger


```solidity
function initializeLedger(string memory name, string memory symbol) external;
```

### addSubAccountGroup


```solidity
function addSubAccountGroup(address root, address holderParent, address relative, string memory name, bool isCredit)
    external
    returns (address subAccount, uint256 flags);
```

### addSubAccount


```solidity
function addSubAccount(address root, address holderParent, address relative, string memory name, bool isCredit)
    external
    returns (address subAccount, uint256 flags);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`root`|`address`||
|`holderParent`|`address`||
|`relative`|`address`||
|`name`|`string`||
|`isCredit`|`bool`|True for credit-side account, false for debit-side in the double-entry tree.|


### addNativeToken


```solidity
function addNativeToken() external returns (uint256 flags);
```

### addExternalToken


```solidity
function addExternalToken(address[] memory tokens) external returns (uint256[] memory flags);
```

### removeSubAccountGroup


```solidity
function removeSubAccountGroup(address root, address holderParent, address relative) external returns (address);
```

### removeSubAccount


```solidity
function removeSubAccount(address root, address holderParent, address relative) external returns (address);
```

### transfer


```solidity
function transfer(
    address root,
    address fromHolderParent,
    address from,
    address toHolderParent,
    address to,
    uint256 amount
) external;
```

### transfer


```solidity
function transfer(address root, address fromHolderParent, address toHolderParent, address to, uint256 amount)
    external;
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

### handleNative


```solidity
function handleNative() external payable;
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

### InvalidNativePayer

```solidity
error InvalidNativePayer(address payer, address sender);
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

### TooManySubAccounts

```solidity
error TooManySubAccounts(uint256 count);
```

### UndercollateralizedToken

```solidity
error UndercollateralizedToken(address token, uint256 liabilities, uint256 collateral);
```

### Unauthorized

```solidity
error Unauthorized(address user);
```

### UnsupportedTokenBehavior

```solidity
error UnsupportedTokenBehavior(address token, uint256 expected, uint256 actual);
```

### ZeroDepth

```solidity
error ZeroDepth();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

