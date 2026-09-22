# StakingRewardLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/staking/StakingRewardLib.sol)


## Constants
### STORE_POSITION

```solidity
bytes32 private constant STORE_POSITION =
    keccak256(abi.encode(uint256(keccak256("cavalre.storage.StakingRewardToken")) - 1)) & ~bytes32(uint256(0xff))
```


### UNIT_SCALE

```solidity
uint256 internal constant UNIT_SCALE = 1e36
```


### WAD

```solidity
uint256 private constant WAD = 1e18
```


### LN2

```solidity
uint256 private constant LN2 = 693147180559945309
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

### createStakingRewardToken


```solidity
function createStakingRewardToken(
    address stakingGroup_,
    address rewardGroup_,
    uint256 halfLife_,
    ILedgerTokenFactory.TokenMetadata memory metadata_
) internal returns (address token_);
```

### protectCustodyAccount


```solidity
function protectCustodyAccount(address token_, address absolute_) private;
```

### stakingRewardProgram


```solidity
function stakingRewardProgram(address token_) internal view returns (Program storage p);
```

### applyHalfLife

Whole half-lives use exact binary shifts; only the fractional half-life uses expWad.
No scheduled periods, keeper, or iteration over holders is required.


```solidity
function applyHalfLife(uint256 value_, uint256 elapsed_, uint256 halfLife_) internal pure returns (uint256);
```

### currentRewardCheckpoint


```solidity
function currentRewardCheckpoint(Program storage p) internal view returns (Checkpoint memory checkpoint_);
```

### currentHolderRewardCheckpoint


```solidity
function currentHolderRewardCheckpoint(
    Checkpoint memory position_,
    Checkpoint memory checkpoint_,
    uint256 balance_,
    uint256 halfLife_
) private view returns (Checkpoint memory);
```

### stakingBacking


```solidity
function stakingBacking(address token_) private view returns (StakingBackingCache memory c);
```

### enforceDebitAccount

Rewards and stake ownership belong to debit leaves. A custody group's
aggregate balance does not create a second reward position or authorize a claim.


```solidity
function enforceDebitAccount(address token_, address parent_, address relative_)
    internal
    view
    returns (uint256 flags_, address absolute_);
```

### walletParent

An SR asset is its existing staking subtree. Nested programs move the same
principal between leaves of that subtree, so the enclosing program settles too.


```solidity
function walletParent(address group_) internal view returns (address parent_);
```

### stake


```solidity
function stake(address token_, address holder_, uint256 amount_, uint256 minimum_) internal returns (uint256);
```

### unstake


```solidity
function unstake(address token_, address holder_, uint256 amount_, uint256 minimum_) internal returns (uint256);
```

### unstake

The consuming module authorizes the explicit staking leaf and payout recipient.


```solidity
function unstake(
    address token_,
    address parent_,
    address relative_,
    address recipient_,
    uint256 amount_,
    uint256 minimum_
) internal returns (uint256);
```

### reward


```solidity
function reward(address token_, address funder_, uint256 amount_) internal;
```

### claim


```solidity
function claim(address token_, address holder_) internal returns (uint256 claimed_);
```

### claim

The consuming module authorizes the explicit staking leaf and payout recipient.


```solidity
function claim(address token_, address parent_, address relative_, address recipient_)
    internal
    returns (uint256 claimed_);
```

### settleTransferRewards

Internal Ledger postings settle rewards before changing actual stake balances.
Transfers carry pending entitlement; available entitlement stays with its owner.


```solidity
function settleTransferRewards(
    address token_,
    address from_,
    address to_,
    bool fromOutside_,
    bool toOutside_,
    uint256 amount_
) internal;
```

### settleHolderRewards

Checkpoint one holder and apply outgoing stake using its pre-transfer balance.


```solidity
function settleHolderRewards(Program storage p, address token_, address absolute_, uint256 amount_)
    internal
    returns (Checkpoint storage position_);
```

### stakingRewardToken


```solidity
function stakingRewardToken(address token_)
    internal
    view
    returns (IStakingRewardToken.Configuration memory config_);
```

### rewardsOf


```solidity
function rewardsOf(address token_, address holder_) internal view returns (IStakingRewardToken.Rewards memory);
```

### rewardsOfAccount


```solidity
function rewardsOfAccount(address token_, address parent_, address relative_)
    internal
    view
    returns (IStakingRewardToken.Rewards memory);
```

### rewardBalances


```solidity
function rewardBalances(Checkpoint memory checkpoint_, uint256 unclaimedUnits_, uint256 balance_)
    private
    pure
    returns (IStakingRewardToken.Rewards memory rewards_);
```

## Structs
### Checkpoint

```solidity
struct Checkpoint {
    // Outstanding unclaimed units (hat U) and pending units (hat P), not token amounts.
    uint256 unclaimedUnits;
    uint256 pendingUnits;
    // phi^(hat U): cumulative issued reward units per raw staked token.
    uint256 unclaimedAccumulator;
    // exp(-r * updatedAt) * phi^(hat P): the decaying pending accumulator.
    uint256 pendingAccumulator;
    uint256 updatedAt;
}
```

### Program

```solidity
struct Program {
    address stakingGroup;
    address rewardGroup;
    address rewardShareToken;
    uint256 halfLife;
    // Outstanding reward units are the reward ShareToken's supply, not a second stored balance.
    uint256 pendingUnits;
    uint256 unclaimedAccumulator;
    uint256 pendingAccumulator;
    uint256 updatedAt;
}
```

### Store

```solidity
struct Store {
    mapping(address token => Program) programs;
    mapping(address token => mapping(address absolute => Checkpoint)) positions;
    mapping(address absolute => address token) reservedAccounts;
}
```

### CreateStakingRewardTokenCache

```solidity
struct CreateStakingRewardTokenCache {
    address stakingLedger;
    address rewardLedger;
    address rewardAccount;
    uint256 flags;
    uint256 rewardDecimals;
}
```

### CurrentHolderRewardCheckpointCache

```solidity
struct CurrentHolderRewardCheckpointCache {
    uint256 elapsed;
    uint256 pendingAccumulator;
}
```

### StakingBackingCache

```solidity
struct StakingBackingCache {
    address ledger;
    address parent;
    uint256 flags;
    uint256 balance;
}
```

### RewardCache

```solidity
struct RewardCache {
    uint256 supply;
    uint256 balance;
    uint256 units;
    uint256 increment;
}
```

### ClaimCache

```solidity
struct ClaimCache {
    address absolute;
    address rewardLedger;
    address rewardAbsolute;
    uint256 rewardFlags;
    uint256 balance;
    uint256 supply;
    uint256 availableUnits;
}
```

### SettleHolderRewardsCache

```solidity
struct SettleHolderRewardsCache {
    uint256 balance;
    uint256 pendingUnits;
}
```

