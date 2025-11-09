# Ledger

[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/modules/Ledger/Ledger.sol)

**Inherits:**
[Module](/src/modules/Module.sol/abstract.Module.md), [Initializable](/src/utilities/Initializable.sol/abstract.Initializable.md)

## State Variables

### \_decimals

```solidity
uint8 internal immutable _decimals;
```

### INITIALIZABLE_STORAGE

```solidity
bytes32 private constant INITIALIZABLE_STORAGE =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger.Initializable")) - 1)) & ~bytes32(uint256(0xff));
```

## Functions

### constructor

```solidity
constructor(uint8 decimals_);
```

### \_initializableStorageSlot

```solidity
function _initializableStorageSlot() internal pure override returns (bytes32);
```

### commands

```solidity
function selectors() public pure virtual override returns (bytes4[] memory _selectors);
```

### initializeLedger_unchained

```solidity
function initializeLedger_unchained() public onlyInitializing;
```

### initializeLedger

```solidity
function initializeLedger() public initializer;
```

### name

```solidity
function name(address addr_) public view returns (string memory);
```

### symbol

```solidity
function symbol(address addr_) public view returns (string memory);
```

### decimals

```solidity
function decimals(address addr_) public view returns (uint8);
```

### root

```solidity
function root(address addr_) public view returns (address);
```

### parent

```solidity
function parent(address addr_) public view returns (address);
```

### isGroup

```solidity
function isGroup(address addr_) public view returns (bool);
```

### subAccounts

```solidity
function subAccounts(address parent_) public view returns (address[] memory);
```

### hasSubAccount

```solidity
function hasSubAccount(address parent_) public view returns (bool);
```

### subAccountIndex

```solidity
function subAccountIndex(address addr_) public view returns (uint32);
```

### name

```solidity
function name() public view returns (string memory);
```

### symbol

```solidity
function symbol() public view returns (string memory);
```

### decimals

```solidity
function decimals() public view returns (uint8);
```

### balanceOf

```solidity
function balanceOf(address parent_, string memory subName_) public view returns (uint256);
```

### balanceOf

```solidity
function balanceOf(address parent_, address owner_) public view returns (uint256);
```

### balanceOf

```solidity
function balanceOf(address owner_) public view returns (uint256);
```

### totalSupply

```solidity
function totalSupply(address token_) public view returns (uint256);
```

### totalSupply

```solidity
function totalSupply() public view returns (uint256);
```

### transfer

```solidity
function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) public returns (bool);
```

### transfer

```solidity
function transfer(address to_, uint256 amount_) public returns (bool);
```

### approve

```solidity
function approve(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
    public
    returns (bool);
```

### approve

```solidity
function approve(address spender_, uint256 amount_) public returns (bool);
```

### allowance

```solidity
function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
    public
    view
    returns (uint256);
```

### allowance

```solidity
function allowance(address owner_, address spender_) public view returns (uint256);
```

### transferFrom

```solidity
function transferFrom(
    address fromParent_,
    address from_,
    address spenderParent_,
    address toParent_,
    address to_,
    uint256 amount_
) public returns (bool);
```

### transferFrom

```solidity
function transferFrom(address from_, address to_, uint256 amount_) public returns (bool);
```
