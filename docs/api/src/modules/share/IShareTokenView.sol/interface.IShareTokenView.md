# IShareTokenView
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/share/IShareTokenView.sol)


## Functions
### isShareToken

Whether token has a registered share backing account.


```solidity
function isShareToken(address token) external view returns (bool);
```

### backingAccount

Registered absolute backing account, or zero for an unregistered share token.


```solidity
function backingAccount(address token) external view returns (address);
```

### shareTokenState

Current Ledger accounting; reverts if token is not a valid share.


```solidity
function shareTokenState(address token) external view returns (State memory);
```

### convertToShares

Raw share quote, rounded down; existing supply/backing determines the ratio.

Both-zero initialization is decimal-adjusted 1:1; positive input rejects mismatched zero states.


```solidity
function convertToShares(address token, uint256 backing) external view returns (uint256);
```

### convertToBacking

Raw backing quote, rounded down; a full-supply quote includes all remaining backing.

This does not check holder balance or authorize release. Existing supply with zero backing quotes zero.


```solidity
function convertToBacking(address token, uint256 shares) external view returns (uint256);
```

## Structs
### State
A live Ledger snapshot; quantities are raw integers, not a common-decimal valuation.


```solidity
struct State {
    address backingAccount; // Absolute registered leaf; may be nested or credit-sided.
    address backingLedger; // Derived from backingAccount; need not expose an ERC20.
    uint256 supply; // Raw share units, using share-token decimals.
    uint256 backing; // Net balance in backingLedger decimals, using the leaf's polarity.
}
```

