# Lib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/examples/ERC4626.sol)


## State Variables
### INITIALIZE_ERC4626

```solidity
bytes4 internal constant INITIALIZE_ERC4626 = bytes4(keccak256("initializeERC4626(IERC20,string,string)"))
```


### ASSET

```solidity
bytes4 internal constant ASSET = bytes4(keccak256("asset()"))
```


### TOTAL_ASSETS

```solidity
bytes4 internal constant TOTAL_ASSETS = bytes4(keccak256("totalAssets()"))
```


### CONVERT_TO_SHARES

```solidity
bytes4 internal constant CONVERT_TO_SHARES = bytes4(keccak256("convertToShares(uint256)"))
```


### CONVERT_TO_ASSETS

```solidity
bytes4 internal constant CONVERT_TO_ASSETS = bytes4(keccak256("convertToAssets(uint256)"))
```


### MAX_DEPOSIT

```solidity
bytes4 internal constant MAX_DEPOSIT = bytes4(keccak256("maxDeposit()"))
```


### PREVIEW_DEPOSIT

```solidity
bytes4 internal constant PREVIEW_DEPOSIT = bytes4(keccak256("previewDeposit(uint256)"))
```


### DEPOSIT

```solidity
bytes4 internal constant DEPOSIT = bytes4(keccak256("deposit(uint256)"))
```


### MAX_MINT

```solidity
bytes4 internal constant MAX_MINT = bytes4(keccak256("maxMint()"))
```


### PREVIEW_MINT

```solidity
bytes4 internal constant PREVIEW_MINT = bytes4(keccak256("previewMint(uint256)"))
```


### MINT

```solidity
bytes4 internal constant MINT = bytes4(keccak256("mint(uint256)"))
```


### MAX_WITHDRAW

```solidity
bytes4 internal constant MAX_WITHDRAW = bytes4(keccak256("maxWithdraw()"))
```


### PREVIEW_WITHDRAW

```solidity
bytes4 internal constant PREVIEW_WITHDRAW = bytes4(keccak256("previewWithdraw(uint256)"))
```


### WITHDRAW

```solidity
bytes4 internal constant WITHDRAW = bytes4(keccak256("withdraw(uint256)"))
```


### MAX_REDEEM

```solidity
bytes4 internal constant MAX_REDEEM = bytes4(keccak256("maxRedeem()"))
```


### PREVIEW_REDEEM

```solidity
bytes4 internal constant PREVIEW_REDEEM = bytes4(keccak256("previewRedeem(uint256)"))
```


### REDEEM

```solidity
bytes4 internal constant REDEEM = bytes4(keccak256("redeem(uint256)"))
```


### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION = 0x0773e532dfede91f04b12a73d3d2acd361424f41f76b4fb79f090161e36b4e00
```


## Functions
### store


```solidity
function store() internal pure returns (ERC4626Upgradeable.ERC4626Storage storage s);
```

