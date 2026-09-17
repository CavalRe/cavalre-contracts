# StakingRewardToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5316bd1d9e8e7ab1df82167844d0b85518ce76e4/modules/staking/StakingRewardToken.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md), [ReentrancyGuard](/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md), [IStakingRewardToken](/modules/staking/IStakingRewardToken.sol/interface.IStakingRewardToken.md), [ILedgerTransferHook](/modules/ledger/ILedgerTransferHook.sol/interface.ILedgerTransferHook.md)


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

### createStakingRewardToken


```solidity
function createStakingRewardToken(
    address stakingLedger_,
    address rewardLedger_,
    address stakingAccount_,
    uint256 halfLife_,
    ILedgerTokenFactory.TokenMetadata memory metadata_
) external nonReentrant returns (address, uint256);
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

### stakingRewardToken


```solidity
function stakingRewardToken(address token_) external view returns (Configuration memory);
```

### rewardsOf


```solidity
function rewardsOf(address token_, address holder_) external view returns (Rewards memory);
```

### beforeLedgerTransfer


```solidity
function beforeLedgerTransfer(
    address ledger_,
    address from_,
    address to_,
    bool fromIsCredit_,
    bool toIsCredit_,
    uint256 amount_
) external;
```

