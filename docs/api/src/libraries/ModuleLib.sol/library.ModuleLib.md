# ModuleLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4beb1bb5ec51300e77fe11434272324aa08bfb7c/libraries/ModuleLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Module")) - 1)) & ~bytes32(uint256(0xff))
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
    mapping(address => address) owners;
}
```

