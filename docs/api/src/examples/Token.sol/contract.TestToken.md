# TestToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4104c9a5fb1b403d7a1bc8bdf3c0f7c85335ff70/examples/Token.sol)

**Inherits:**
[ERC20](/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol/abstract.ERC20.md)


## Functions
### constructor


```solidity
constructor(uint8 _decimals) ERC20(_decimals);
```

### selectors


```solidity
function selectors() public pure virtual override returns (bytes4[] memory _selectors);
```

### initializeTestToken


```solidity
function initializeTestToken(string memory _name, string memory _symbol) public initializer;
```

### mint


```solidity
function mint(uint256 _amount) public;
```

### burn


```solidity
function burn(uint256 _amount) public;
```

### receive


```solidity
receive() external payable;
```

### deposit


```solidity
function deposit() public payable;
```

### withdraw


```solidity
function withdraw(uint256 wad) public;
```

## Events
### Deposit

```solidity
event Deposit(address indexed dst, uint256 wad);
```

### Withdrawal

```solidity
event Withdrawal(address indexed src, uint256 wad);
```

