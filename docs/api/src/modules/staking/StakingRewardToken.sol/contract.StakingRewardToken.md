# StakingRewardToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/staking/StakingRewardToken.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [ReentrancyGuard](/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)


## Constants
### REENTRANCY_GUARD_STORAGE

```solidity
bytes32 private constant REENTRANCY_GUARD_STORAGE = keccak256(
    abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken.ReentrancyGuard")) - 1)
) & ~bytes32(uint256(0xff))
```


## Functions
### _reentrancyGuardStorageSlot


```solidity
function _reentrancyGuardStorageSlot() internal pure override returns (bytes32);
```

### signatures


```solidity
function signatures() external pure virtual override returns (string[] memory signatures_);
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory selectors_);
```

### stake


```solidity
function stake(address token_, uint256 amount_, uint256 minimumShares_) external nonReentrant returns (uint256);
```

### unstake


```solidity
function unstake(address token_, uint256 shares_, uint256 minimumStake_) external nonReentrant returns (uint256);
```

### reward


```solidity
function reward(address token_, uint256 amount_) external nonReentrant;
```

### claim


```solidity
function claim(address token_) external nonReentrant returns (uint256);
```

### transfer


```solidity
function transfer(address token_, address from_, address to_, uint256 amount_) external nonReentrant;
```

### settleStakeTransfer

LedgerLib invokes this through the Dispatcher before its internal posting.


```solidity
function settleStakeTransfer(
    address token_,
    address from_,
    address to_,
    bool fromOutside_,
    bool toOutside_,
    uint256 amount_
) external;
```

### stakingRewardToken


```solidity
function stakingRewardToken(address token_) external view returns (IStakingRewardToken.Configuration memory);
```

### rewardsOf


```solidity
function rewardsOf(address token_, address holder_) external view returns (IStakingRewardToken.Rewards memory);
```

### rewardsOfAccount


```solidity
function rewardsOfAccount(address token_, address parent_, address relative_)
    external
    view
    returns (IStakingRewardToken.Rewards memory);
```

