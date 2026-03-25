# MockERC20
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/3a4fcfc9619f01f0afd3feb42acd82ec72eed095/tests/modules/Ledger.t.sol)

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

