# ERC20Lib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4104c9a5fb1b403d7a1bc8bdf3c0f7c85335ff70/libraries/ERC20Lib.sol)


## State Variables
### INITIALIZE_ERC20

```solidity
bytes4 internal constant INITIALIZE_ERC20 = bytes4(keccak256("initializeERC20()"))
```


### NAME

```solidity
bytes4 internal constant NAME = bytes4(keccak256("name()"))
```


### SYMBOL

```solidity
bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"))
```


### DECIMALS

```solidity
bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"))
```


### TOTAL_SUPPLY

```solidity
bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"))
```


### BALANCE_OF

```solidity
bytes4 internal constant BALANCE_OF = bytes4(keccak256("balanceOf(address)"))
```


### ALLOWANCE

```solidity
bytes4 internal constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"))
```


### APPROVE

```solidity
bytes4 internal constant APPROVE = bytes4(keccak256("approve(address,uint256)"))
```


### TRANSFER

```solidity
bytes4 internal constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"))
```


### TRANSFER_FROM

```solidity
bytes4 internal constant TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"))
```


### INCREASE_ALLOWANCE

```solidity
bytes4 internal constant INCREASE_ALLOWANCE = bytes4(keccak256("increaseAllowance(address,uint256)"))
```


### DECREASE_ALLOWANCE

```solidity
bytes4 internal constant DECREASE_ALLOWANCE = bytes4(keccak256("decreaseAllowance(address,uint256)"))
```


### FORCE_APPROVE

```solidity
bytes4 internal constant FORCE_APPROVE = bytes4(keccak256("forceApprove(address,uint256)"))
```


### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff))
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

## Structs
### Store

```solidity
struct Store {
    mapping(address => mapping(address => uint256)) allowances;
}
```

