# StakingRewardFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/staking/StakingRewardFactory.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)

Owner-only program creation, separated from runtime accounting for EIP-170.


## Functions
### signatures


```solidity
function signatures() external pure override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure override returns (bytes4[] memory selectors_);
```

### createStakingRewardToken


```solidity
function createStakingRewardToken(
    address stakingGroup_,
    address rewardGroup_,
    uint256 halfLife_,
    ILedgerTokenFactory.TokenMetadata memory metadata_
) external returns (address);
```
