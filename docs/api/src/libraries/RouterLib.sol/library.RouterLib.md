# RouterLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/60feb3a156b5466ba1b6f8ec3f8f965b7f89c2de/libraries/RouterLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Router")) - 1)) & ~bytes32(uint256(0xff))
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
    mapping(bytes4 => address) modules;
}
```

