# DispatcherLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/dispatcher/DispatcherLib.sol)


## State Variables
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.Dispatcher")) - 1)) & ~bytes32(uint256(0xff))
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

### addModule


```solidity
function addModule(address module_) internal;
```

### removeModule


```solidity
function removeModule(address module_) internal;
```

### owner


```solidity
function owner(address module_) internal view returns (address);
```

### module


```solidity
function module(bytes4 selector_) internal view returns (address);
```

### modules


```solidity
function modules() internal view returns (address[] memory);
```

### verifyModule


```solidity
function verifyModule(address module_)
    internal
    pure
    returns (bytes4[] memory _selectors, string[] memory _signatures);
```

### signatures


```solidity
function signatures(address module_) internal pure returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors(address module_) internal pure returns (bytes4[] memory _selectors);
```

### commands


```solidity
function commands() internal view returns (Command[] memory _commands);
```

### commands


```solidity
function commands(address[] memory modules_) internal pure returns (Command[] memory _commands);
```

### enforceModuleUpdate


```solidity
function enforceModuleUpdate(address module_)
    private
    view
    returns (Store storage s, string[] memory _signatures, bytes4[] memory _selectors);
```

## Structs
### Command

```solidity
struct Command {
    address module;
    string signature;
    bytes4 selector;
}
```

### Store

```solidity
struct Store {
    mapping(address => address) owners;
    mapping(bytes4 => address) modules;
    address[] moduleList;
    mapping(address => uint256) moduleListIndexes;
}
```

