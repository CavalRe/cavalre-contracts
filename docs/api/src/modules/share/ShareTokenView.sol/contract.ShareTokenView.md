# ShareTokenView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/share/ShareTokenView.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [IShareTokenView](/modules/share/IShareTokenView.sol/interface.IShareTokenView.md)

Dispatcher read surface for share registration and Ledger accounting.


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### isShareToken

Whether token has a registered share backing account.


```solidity
function isShareToken(address token_) external view returns (bool);
```

### backingAccount

Registered absolute backing account, or zero for an unregistered share token.


```solidity
function backingAccount(address token_) external view returns (address);
```

### shareTokenState

Current Ledger accounting; reverts if token is not a valid share.


```solidity
function shareTokenState(address token_) external view returns (State memory);
```

### convertToShares

Raw share quote, rounded down; existing supply/backing determines the ratio.

Both-zero initialization is decimal-adjusted 1:1; positive input rejects mismatched zero states.


```solidity
function convertToShares(address token_, uint256 backing_) external view returns (uint256);
```

### convertToBacking

Raw backing quote, rounded down; a full-supply quote includes all remaining backing.

This does not check holder balance or authorize release. Existing supply with zero backing quotes zero.


```solidity
function convertToBacking(address token_, uint256 shares_) external view returns (uint256);
```

