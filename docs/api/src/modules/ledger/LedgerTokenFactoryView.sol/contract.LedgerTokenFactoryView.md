# LedgerTokenFactoryView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/ledger/LedgerTokenFactoryView.sol)

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

### predictERC20TokenAddress


```solidity
function predictERC20TokenAddress(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    string memory version_
) external view returns (address);
```

### predictShareTokenAddress


```solidity
function predictShareTokenAddress(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    string memory version_
) external view returns (address);
```

### _tokenMetadata


```solidity
function _tokenMetadata(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
    private
    pure
    returns (ILedgerTokenFactory.TokenMetadata memory _token);
```

