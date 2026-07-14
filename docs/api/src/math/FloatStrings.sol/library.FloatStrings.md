# FloatStrings
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5bbebe0228964dbc72fdf4ed69e4da2d6b47fa98/math/FloatStrings.sol)

Testing/debug formatting helper. Do not use this library in production
deployable contracts unless an external linked-library deployment is
intentional. Public library functions here can force Foundry/Solidity to
deploy and link `FloatStrings`.


## Functions
### msb


```solidity
function msb(int256 value_) internal pure returns (uint256);
```

### shiftStringBytesLeft


```solidity
function shiftStringBytesLeft(bytes memory strBytes_, uint256 numChars_) public pure returns (bytes memory);
```

### shiftStringLeft


```solidity
function shiftStringLeft(string memory str_, uint256 numChars_) public pure returns (string memory);
```

### shiftStringBytesRight


```solidity
function shiftStringBytesRight(bytes memory strBytes_, uint256 numChars_)
    public
    pure
    returns (bytes memory _result, bytes memory _remainder);
```

### shiftStringRight


```solidity
function shiftStringRight(string memory str_, uint256 numChars_)
    public
    pure
    returns (string memory _result, string memory _remainder);
```

### toStringBytes


```solidity
function toStringBytes(uint256 value_) public pure returns (bytes memory);
```

### toStringBytes


```solidity
function toStringBytes(Float value_) internal pure returns (bytes memory, bytes memory);
```

### toString


```solidity
function toString(uint256 value_) public pure returns (string memory);
```

### toString


```solidity
function toString(int256 value_) public pure returns (string memory);
```

### trimStringBytesRight


```solidity
function trimStringBytesRight(bytes memory strBytes_) public pure returns (bytes memory);
```

### trimStringRight


```solidity
function trimStringRight(string memory str_) public pure returns (string memory);
```

### toString


```solidity
function toString(Float number_) internal pure returns (string memory);
```

### digits


```solidity
function digits(uint256 number_) public pure returns (uint8);
```

