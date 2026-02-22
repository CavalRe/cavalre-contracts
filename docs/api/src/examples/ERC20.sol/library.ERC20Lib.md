# ERC20Lib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4beb1bb5ec51300e77fe11434272324aa08bfb7c/examples/ERC20.sol)


## State Variables
### INITIALIZE_ERC20

```solidity
bytes4 internal constant INITIALIZE_ERC20 = bytes4(keccak256("initializeERC20(string,string)"))
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


### TRANSFER

```solidity
bytes4 internal constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"))
```


### ALLOWANCE

```solidity
bytes4 internal constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"))
```


### APPROVE

```solidity
bytes4 internal constant APPROVE = bytes4(keccak256("approve(address,uint256)"))
```


### TRANSFER_FROM

```solidity
bytes4 internal constant TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"))
```


### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00
```


## Functions
### store


```solidity
function store() internal pure returns (ERC20Upgradeable.ERC20Storage storage s);
```

