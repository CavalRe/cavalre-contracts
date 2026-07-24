# MemoryLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/utilities/MemoryLib.sol)


## Functions
### addressSet


```solidity
function addressSet(uint256 n_) internal pure returns (AddressSet memory set_);
```

### addressDict


```solidity
function addressDict(uint256 n_) internal pure returns (AddressDict memory dict_);
```

### insert


```solidity
function insert(AddressSet memory set_, address addr_) internal pure;
```

### contains


```solidity
function contains(AddressSet memory set_, address addr_) internal pure returns (bool);
```

### set


```solidity
function set(AddressDict memory dict_, address key_, uint256 value_) internal pure;
```

### get


```solidity
function get(AddressDict memory dict_, address key_) internal pure returns (bool found_, uint256 value_);
```

## Errors
### DuplicateAddress

```solidity
error DuplicateAddress(address addr_);
```

### ZeroAddress

```solidity
error ZeroAddress();
```

## Structs
### AddressSet

```solidity
struct AddressSet {
    address[] slots;
    uint256 mask;
}
```

### AddressDict

```solidity
struct AddressDict {
    address[] keys;
    uint256[] values;
    uint256 mask;
}
```

