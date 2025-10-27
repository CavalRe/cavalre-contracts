# Lib

[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/modules/Ledger/Ledger.sol)

## State Variables

### MAX_DEPTH

```solidity
uint8 internal constant MAX_DEPTH = 10;
```

### SUPPLY_ADDRESS

```solidity
address internal constant SUPPLY_ADDRESS = 0x486d9E1EFfBE2991Ba97401Be079767f9879e1Dd;
```

### INITIALIZE_LEDGERS

```solidity
bytes4 internal constant INITIALIZE_LEDGERS = bytes4(keccak256("initializeLedger()"));
```

### NAME

```solidity
bytes4 internal constant NAME = bytes4(keccak256("name(address)"));
```

### SYMBOL

```solidity
bytes4 internal constant SYMBOL = bytes4(keccak256("symbol(address)"));
```

### DECIMALS

```solidity
bytes4 internal constant DECIMALS = bytes4(keccak256("decimals(address)"));
```

### ROOT

```solidity
bytes4 internal constant ROOT = bytes4(keccak256("root(address)"));
```

### PARENT

```solidity
bytes4 internal constant PARENT = bytes4(keccak256("parent(address)"));
```

### IS_GROUP

```solidity
bytes4 internal constant IS_GROUP = bytes4(keccak256("isGroup(address)"));
```

### SUBACCOUNTS

```solidity
bytes4 internal constant SUBACCOUNTS = bytes4(keccak256("subAccounts(address)"));
```

### HAS_SUBACCOUNT

```solidity
bytes4 internal constant HAS_SUBACCOUNT = bytes4(keccak256("hasSubAccount(address)"));
```

### SUBACCOUNT_INDEX

```solidity
bytes4 internal constant SUBACCOUNT_INDEX = bytes4(keccak256("subAccountIndex(address)"));
```

### BASE_NAME

```solidity
bytes4 internal constant BASE_NAME = bytes4(keccak256("name()"));
```

### BASE_SYMBOL

```solidity
bytes4 internal constant BASE_SYMBOL = bytes4(keccak256("symbol()"));
```

### BASE_DECIMALS

```solidity
bytes4 internal constant BASE_DECIMALS = bytes4(keccak256("decimals()"));
```

### GROUP_BALANCE_OF

```solidity
bytes4 internal constant GROUP_BALANCE_OF = bytes4(keccak256("balanceOf(address,string)"));
```

### BALANCE_OF

```solidity
bytes4 internal constant BALANCE_OF = bytes4(keccak256("balanceOf(address,address)"));
```

### BASE_BALANCE_OF

```solidity
bytes4 internal constant BASE_BALANCE_OF = bytes4(keccak256("balanceOf(address)"));
```

### TOTAL_SUPPLY

```solidity
bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply(address)"));
```

### BASE_TOTAL_SUPPLY

```solidity
bytes4 internal constant BASE_TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
```

### TRANSFER

```solidity
bytes4 internal constant TRANSFER = bytes4(keccak256("transfer(address,address,address,uint256)"));
```

### BASE_TRANSFER

```solidity
bytes4 internal constant BASE_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
```

### APPROVE

```solidity
bytes4 internal constant APPROVE = bytes4(keccak256("approve(address,address,address,uint256)"));
```

### BASE_APPROVE

```solidity
bytes4 internal constant BASE_APPROVE = bytes4(keccak256("approve(address,uint256)"));
```

### ALLOWANCE

```solidity
bytes4 internal constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"));
```

### BASE_ALLOWANCE

```solidity
bytes4 internal constant BASE_ALLOWANCE = bytes4(keccak256("allowance(address)"));
```

### TRANSFER_FROM

```solidity
bytes4 internal constant TRANSFER_FROM =
    bytes4(keccak256("transferFrom(address,address,address,address,address,uint256)"));
```

### BASE_TRANSFER_FROM

```solidity
bytes4 internal constant BASE_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
```

### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger")) - 1)) & ~bytes32(uint256(0xff));
```

## Functions

### store

```solidity
function store() internal pure returns (Store storage s);
```

### checkZeroAddress

```solidity
function checkZeroAddress(address addr_) internal pure;
```

### isGroup

```solidity
function isGroup(address addr_) internal view returns (bool);
```

### isCredit

```solidity
function isCredit(address addr_) internal view returns (bool);
```

### isValidString

```solidity
function isValidString(string memory str_) internal pure returns (bool);
```

### checkString

```solidity
function checkString(string memory str_) internal pure;
```

### checkAccountGroup

```solidity
function checkAccountGroup(address addr_) internal view;
```

### toNamedAddress

```solidity
function toNamedAddress(string memory name_) internal pure returns (address);
```

### toLedgerAddress

```solidity
function toLedgerAddress(address parent_, address ledger_) internal pure returns (address);
```

### toGroupAddress

```solidity
function toGroupAddress(address parent_, string memory name_) internal pure returns (address);
```

### checkRoots

```solidity
function checkRoots(address a_, address b_) internal view;
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

### subAccounts

```solidity
function subAccounts(address parent_) internal view returns (address[] memory);
```

### hasSubAccount

```solidity
function hasSubAccount(address parent_) internal view returns (bool);
```

### subAccountIndex

```solidity
function subAccountIndex(address addr_) internal view returns (uint32);
```

### balanceOf

```solidity
function balanceOf(address addr_) internal view returns (uint256);
```

### hasBalance

```solidity
function hasBalance(address addr_) internal view returns (bool);
```

### addSubAccount

```solidity
function addSubAccount(address parent_, string memory name_, bool isGroup_, bool isCredit_)
    internal
    returns (address _sub);
```

### removeSubAccount

```solidity
function removeSubAccount(address parent_, string memory name_) internal returns (address);
```

### addLedger

```solidity
function addLedger(address token_, string memory name_, string memory symbol_, uint8 decimals_) internal;
```

### debit

```solidity
function debit(address parent_, address ledger_, uint256 amount_, bool emitEvent_)
    internal
    returns (address _currentAccount);
```

### credit

```solidity
function credit(address parent_, address ledger_, uint256 amount_, bool emitEvent_)
    internal
    returns (address _currentAccount);
```

### transfer

```solidity
function transfer(address fromParent_, address from_, address toParent_, address to_, uint256 amount_, bool emitEvent_)
    internal
    returns (bool);
```

### mint

```solidity
function mint(address toParent_, address to_, uint256 amount_) internal returns (bool);
```

### burn

```solidity
function burn(address fromParent_, address from_, uint256 amount_) internal returns (bool);
```

### approve

```solidity
function approve(
    address ownerParent_,
    address owner_,
    address spenderParent_,
    address spender_,
    uint256 amount_,
    bool emitEvent_
) internal returns (bool);
```

### allowance

```solidity
function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
    internal
    view
    returns (uint256);
```

### transferFrom

```solidity
function transferFrom(
    address fromParent_,
    address from_,
    address spenderParent_,
    address spender_,
    address toParent_,
    address to_,
    uint256 amount_,
    bool emitEvent_
) internal returns (bool);
```

## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value);
```

### Credit

```solidity
event Credit(address indexed parent, address indexed ledger, uint256 value);
```

### Debit

```solidity
event Debit(address indexed parent, address indexed ledger, uint256 value);
```

### InternalApproval

```solidity
event InternalApproval(address indexed owner, address indexed spender, uint256 value);
```

### LedgerAdded

```solidity
event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
```

### SubAccountAdded

```solidity
event SubAccountAdded(address indexed root, address indexed parent, string subName, bool isGroup, bool isCredit);
```

### SubAccountRemoved

```solidity
event SubAccountRemoved(address indexed root, address indexed parent, string subName);
```

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
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

### HasBalance

```solidity
error HasBalance(string subName);
```

### HasSubAccount

```solidity
error HasSubAccount(string subName);
```

### InsufficientBalance

```solidity
error InsufficientBalance();
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
error InvalidAccountGroup(address groupAddress);
```

### InvalidLedgerAccount

```solidity
error InvalidLedgerAccount(address ledgerAddress);
```

### InvalidSubAccount

```solidity
error InvalidSubAccount(string subName, bool isGroup, bool isCredit);
```

### InvalidString

```solidity
error InvalidString(string symbol);
```

### InvalidToken

```solidity
error InvalidToken(string name, string symbol, uint8 decimals);
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
error SubAccountNotFound(string subName);
```

### ZeroAddress

```solidity
error ZeroAddress();
```
