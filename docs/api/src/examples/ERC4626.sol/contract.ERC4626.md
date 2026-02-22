# ERC4626
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4beb1bb5ec51300e77fe11434272324aa08bfb7c/examples/ERC4626.sol)

**Inherits:**
[Module](/modules/Module.sol/abstract.Module.md), [ERC4626Upgradeable](/node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol/abstract.ERC4626Upgradeable.md)


## State Variables
### _decimals

```solidity
uint8 private immutable _decimals
```


### INITIALIZABLE_STORAGE

```solidity
bytes32 private constant INITIALIZABLE_STORAGE = keccak256(
    abi.encode(uint256(keccak256("cavalre.storage.ERC4626.Initializable")) - 1)
) & ~bytes32(uint256(0xff))
```


## Functions
### constructor


```solidity
constructor(uint8 decimals_) ;
```

### _initializableStorageSlot


```solidity
function _initializableStorageSlot() internal pure override returns (bytes32);
```

### selectors


```solidity
function selectors() public pure virtual override returns (bytes4[] memory _selectors);
```

### decimals


```solidity
function decimals() public view override returns (uint8);
```

### initialize4626


```solidity
function initialize4626(IERC20 _token, string memory _name, string memory _symbol) public initializer;
```

