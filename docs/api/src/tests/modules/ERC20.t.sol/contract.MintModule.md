# MintModule
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/864c40b9986bd124ebb2cf2fd60ea0a56f3c0024/tests/modules/ERC20.t.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md)


## State Variables
### DEFAULT_SOURCE_NAME

```solidity
string internal constant DEFAULT_SOURCE_NAME = "Source"
```


## Functions
### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory _selectors);
```

### mintCanonical


```solidity
function mintCanonical(address to_, uint256 amount_) external;
```

