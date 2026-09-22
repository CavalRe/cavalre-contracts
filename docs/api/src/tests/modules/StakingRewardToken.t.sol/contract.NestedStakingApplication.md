# NestedStakingApplication
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/tests/modules/StakingRewardToken.t.sol)

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

