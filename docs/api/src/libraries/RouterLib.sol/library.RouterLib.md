# RouterLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/716535f21df26e2431fe11fe8288f267361b03c3/libraries/RouterLib.sol)


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

