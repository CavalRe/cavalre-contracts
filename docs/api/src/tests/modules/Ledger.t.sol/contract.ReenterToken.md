# ReenterToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/0c0c9e5af38811191bb039b59135f9126c750415/tests/modules/Ledger.t.sol)

**Inherits:**
[ERC20](/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol/abstract.ERC20.md)


## State Variables
### target

```solidity
address public target
```


### reenter

```solidity
bool public reenter
```


### _decimals

```solidity
uint8 private immutable _decimals
```


## Functions
### constructor


```solidity
constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_);
```

### decimals


```solidity
function decimals() public view override returns (uint8);
```

### mint


```solidity
function mint(address to_, uint256 amount_) external;
```

### setTarget


```solidity
function setTarget(address target_) external;
```

### setReenter


```solidity
function setReenter(bool reenter_) external;
```

### transferFrom


```solidity
function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool);
```

