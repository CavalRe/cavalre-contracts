# StakingRewardLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/staking/StakingRewardLib.sol)


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


### REWARDS

```solidity
address internal constant REWARDS = address(uint160(uint256(keccak256("Staking Rewards"))))
```


## Functions
### store


```solidity
function store() internal pure returns (Store storage s);
```

### createStakingRewardToken


```solidity
function createStakingRewardToken(
    address stakingLedger_,
    address rewardLedger_,
    address stakingAccount_,
    uint256 halfLife_,
    ILedgerTokenFactory.TokenMetadata memory metadata_
) internal returns (address token_, uint256 flags_);
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
    private
    view
    returns (uint256 flags_, address absolute_);
```

### stake


```solidity
function stake(address token_, address holder_, uint256 amount_, uint256 minimum_)
    internal
    returns (uint256 shares_);
```

### unstake


```solidity
function unstake(address token_, address holder_, uint256 shares_, uint256 minimum_)
    internal
    returns (uint256 amount_);
```

### unstake

The consuming module authorizes the explicit share leaf and payout recipient.


```solidity
function unstake(
    address token_,
    address parent_,
    address relative_,
    address recipient_,
    uint256 shares_,
    uint256 minimum_
) internal returns (uint256 amount_);
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

The consuming module authorizes the explicit share leaf and payout recipient.


```solidity
function claim(address token_, address parent_, address relative_, address recipient_)
    internal
    returns (uint256 claimed_);
```

### settleTransferRewards

SR operations settle rewards explicitly before changing share balances.
Transfers behave as sender exits and receiver entries; accrued rewards stay with the sender.


```solidity
function settleTransferRewards(
    address ledger_,
    address from_,
    address to_,
    bool fromIsCredit_,
    bool toIsCredit_,
    uint256 amount_
) private;
```

### settleHolderRewards

Checkpoint one holder and apply any outgoing shares using the same pre-transfer balance.


```solidity
function settleHolderRewards(Program storage p, address token_, address absolute_, uint256 shares_)
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
    // phi^(hat U): cumulative issued units per share.
    uint256 unclaimedAccumulator;
    // exp(-r * updatedAt) * phi^(hat P): the decaying pending accumulator.
    uint256 pendingAccumulator;
    uint256 updatedAt;
}
```

### Program

```solidity
struct Program {
    address rewardLedger;
    uint256 halfLife;
    Checkpoint checkpoint;
    address stakingAccount;
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
    address rewardAccount;
    uint256 flags;
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
    address relative;
    uint256 flags;
    uint256 balance;
    uint256 supply;
}
```

### StakeCache

```solidity
struct StakeCache {
    StakingBackingCache backing;
    uint256 decimals;
    uint256 shareDecimals;
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
    uint256 balance;
    uint256 availableUnits;
}
```

### SettleHolderRewardsCache

```solidity
struct SettleHolderRewardsCache {
    uint256 balance;
    uint256 pendingUnits;
    uint256 availableUnits;
    uint256 cancelledUnits;
}
```

