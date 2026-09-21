# ShareToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/share/ShareToken.sol)

**Inherits:**
[ERC20Wrapper](/modules/ledger/ERC20Wrapper.sol/contract.ERC20Wrapper.md)

ERC20 share surface. Settlement belongs to the consuming application's module.

Adds no storage. Metadata and allowances use shared ERC20Wrapper behavior. Ledger owns
supply and balances; ShareTokenLib stores the backing reference in Dispatcher storage.
Install ShareTokenView for the added read calls.


## Functions
### constructor


```solidity
constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
    ERC20Wrapper(dispatcher_, name_, symbol_, decimals_);
```

### shareTokenState

Current backing reference, backing balance and supply in their respective raw units.


```solidity
function shareTokenState() external view returns (IShareTokenView.State memory);
```

### convertToShares

Quote raw shares for raw backing, rounding down; no backing is moved.


```solidity
function convertToShares(uint256 backing_) external view returns (uint256);
```

### convertToBacking

Quote raw backing for raw shares, rounding down; no shares are burned.


```solidity
function convertToBacking(uint256 shares_) external view returns (uint256);
```

