# MockERC20
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/e9b2f507f0b2f5b63f28b4ef324f0d8c853d1aa9/tests/modules/Ledger.t.sol)

**Inherits:**
[ERC20](/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol/abstract.ERC20.md)


## State Variables
### _mockDecimals

```solidity
uint8 private immutable _mockDecimals
```


## Functions
### constructor


```solidity
constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_);
```

### mint


```solidity
function mint(address to_, uint256 amount_) external;
```

### decimals


```solidity
function decimals() public view override returns (uint8);
```

