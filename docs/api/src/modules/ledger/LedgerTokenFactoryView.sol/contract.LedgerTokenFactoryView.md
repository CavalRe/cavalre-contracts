# LedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/d0ede1b69895a3bda07d109941a341b13cd3d245/modules/ledger/LedgerTokenFactoryView.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory _selectors);
```

### tokenSalt


```solidity
function tokenSalt(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    external
    pure
    returns (bytes32);
```

### predictToken


```solidity
function predictToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    external
    view
    returns (address);
```

### _tokenMetadata


```solidity
function _tokenMetadata(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    private
    pure
    returns (ILedgerTokenFactory.TokenMetadata memory _token);
```

