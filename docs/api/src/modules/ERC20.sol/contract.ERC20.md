# ERC20
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/ERC20.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md), [Initializable](/utilities/Initializable.sol/abstract.Initializable.md)

## Description

Canonical-root ERC20 module.

Exposes ERC20 API at router address. Metadata, balances, total supply, and transfer posting route through `LedgerLib` for canonical root `address(this)`. Allowances live in `ERC20Lib`.

## Functions
### initializeERC20

```solidity
function initializeERC20() external initializer;
```

### name

```solidity
function name() external view returns (string memory);
```

### symbol

```solidity
function symbol() external view returns (string memory);
```

### decimals

```solidity
function decimals() external view returns (uint8);
```

### totalSupply

```solidity
function totalSupply() external view returns (uint256);
```

### balanceOf

```solidity
function balanceOf(address owner_) external view returns (uint256);
```

### allowance

```solidity
function allowance(address owner_, address spender_) external view returns (uint256);
```

### approve

```solidity
function approve(address spender_, uint256 amount_) external returns (bool);
```

### transfer

```solidity
function transfer(address to_, uint256 amount_) external returns (bool);
```

### transferFrom

```solidity
function transferFrom(address from_, address to_, uint256 amount_) external returns (bool);
```

### increaseAllowance

```solidity
function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool);
```

### decreaseAllowance

```solidity
function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool);
```

### forceApprove

```solidity
function forceApprove(address spender_, uint256 amount_) external returns (bool);
```
