# RandomLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/libraries/RandomLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Random")) - 1)) & ~bytes32(uint256(0xff))
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

### nextSeed


```solidity
function nextSeed(uint256 seed_) internal pure returns (uint256);
```

### random


```solidity
function random(uint256 seed_) internal pure returns (Float);
```

### randomPositive


```solidity
function randomPositive(uint256 seed_) internal pure returns (Float);
```

### randomUnit


```solidity
function randomUnit(uint256 seed_) internal pure returns (Float);
```

### randomInterval


```solidity
function randomInterval(uint256 seed_, Float low_, Float high_) internal pure returns (Float);
```

### randomUnitNormal


```solidity
function randomUnitNormal(uint256 seed_) internal pure returns (Float, uint256);
```

### randomNormal


```solidity
function randomNormal(uint256 seed_, Float mean_, Float stddev_) internal pure returns (Float, uint256);
```

### randomLogNormal


```solidity
function randomLogNormal(uint256 seed_, Float mean_, Float stddev_) internal pure returns (Float, uint256);
```

### random


```solidity
function random() internal returns (Float);
```

### randomPositive


```solidity
function randomPositive() internal returns (Float);
```

### randomUnit


```solidity
function randomUnit() internal returns (Float);
```

### randomInterval


```solidity
function randomInterval(Float low, Float high) internal returns (Float);
```

### randomUnitNormal


```solidity
function randomUnitNormal() internal returns (Float _float);
```

### randomNormal


```solidity
function randomNormal(Float mean, Float stddev) internal returns (Float _float);
```

### randomLogNormal


```solidity
function randomLogNormal(Float mean, Float stddev) internal returns (Float _float);
```

## Structs
### Store

```solidity
struct Store {
    uint256 seed;
}
```

