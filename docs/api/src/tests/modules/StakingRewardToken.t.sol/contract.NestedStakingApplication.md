# NestedStakingApplication
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/tests/modules/StakingRewardToken.t.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### claimAt


```solidity
function claimAt(address token_, address parent_, address relative_, address recipient_)
    external
    returns (uint256);
```

### unstakeAt


```solidity
function unstakeAt(address token_, address parent_, address relative_, address recipient_, uint256 shares_)
    external
    returns (uint256);
```

