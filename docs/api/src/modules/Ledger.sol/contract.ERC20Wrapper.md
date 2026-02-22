# ERC20Wrapper
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/27a8b6bea99c34fd7ef12952ab488aa1d4998a37/modules/Ledger.sol)


## State Variables
### _router

```solidity
address private immutable _router
```


### _token

```solidity
address private immutable _token
```


### _name

```solidity
string private _name
```


### _symbol

```solidity
string private _symbol
```


### _decimals

```solidity
uint8 public immutable _decimals
```


### _allowances

```solidity
mapping(address => mapping(address => uint256)) private _allowances
```


## Functions
### constructor


```solidity
constructor(address router_, address token_, string memory name_, string memory symbol_, uint8 decimals_) ;
```

### routerOnly


```solidity
modifier routerOnly() ;
```

### name


```solidity
function name() public view returns (string memory);
```

### symbol


```solidity
function symbol() public view returns (string memory);
```

### decimals


```solidity
function decimals() public view returns (uint8);
```

### router


```solidity
function router() public view returns (address);
```

### token


```solidity
function token() public view returns (address);
```

### totalSupply


```solidity
function totalSupply() public view returns (uint256);
```

### balanceOf


```solidity
function balanceOf(address account_) public view returns (uint256);
```

### allowance


```solidity
function allowance(address owner_, address spender_) public view returns (uint256);
```

### approve


```solidity
function approve(address spender_, uint256 amount_) public returns (bool);
```

### increaseAllowance

Atomically increases `spender` allowance for `msg.sender`.


```solidity
function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool _ok);
```

### decreaseAllowance

Atomically decreases `spender` allowance for `msg.sender`.


```solidity
function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool _ok);
```

### forceApprove

Sets allowance safely even if a non-zero allowance already exists.
If both current and desired are non-zero, sets to 0 first, then to `amount_`.


```solidity
function forceApprove(address spender_, uint256 amount_) public returns (bool);
```

### transfer


```solidity
function transfer(address to_, uint256 amount_) public returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from_, address to_, uint256 amount_) public returns (bool);
```

### mint


```solidity
function mint(address to_, uint256 amount_) public routerOnly;
```

### burn


```solidity
function burn(address from_, uint256 amount_) public routerOnly;
```

## Events
### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value);
```

