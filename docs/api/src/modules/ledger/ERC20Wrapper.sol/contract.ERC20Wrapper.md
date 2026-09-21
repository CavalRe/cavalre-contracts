# ERC20Wrapper
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/ERC20Wrapper.sol)


## Constants
### _dispatcher

```solidity
address private immutable _dispatcher
```


### _decimals

```solidity
uint8 public immutable _decimals
```


## State Variables
### _name

```solidity
string private _name
```


### _symbol

```solidity
string private _symbol
```


### _allowances

```solidity
mapping(address => mapping(address => uint256)) internal _allowances
```


## Functions
### constructor


```solidity
constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_) ;
```

### dispatcherOnly


```solidity
modifier dispatcherOnly() ;
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

### dispatcher


```solidity
function dispatcher() public view returns (address);
```

### totalSupply


```solidity
function totalSupply() public view returns (uint256);
```

### balanceOf

Normal balance of the direct account at H(this, account_), including its subtree.

Displaying group custody does not grant authority to spend descendants.


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
function transfer(address to_, uint256 amount_) public virtual returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from_, address to_, uint256 amount_) public virtual returns (bool);
```

### emitTransfer


```solidity
function emitTransfer(address from_, address to_, uint256 amount_) public dispatcherOnly;
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

