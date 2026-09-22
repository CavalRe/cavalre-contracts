# IStakingRewardToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/staking/IStakingRewardToken.sol)


## Functions
### createStakingRewardToken

Create an ERC20 wrapper over actual stakes beneath an absolute staking group.

Configure two registered debit groups and a positive half-life. The staking group starts empty.


```solidity
function createStakingRewardToken(
    address stakingGroup,
    address rewardGroup,
    uint256 halfLife,
    ILedgerTokenFactory.TokenMetadata memory metadata
) external returns (address token);
```

### stake

Transfer actual staking tokens from the caller's wallet account into their staking account.


```solidity
function stake(address token, uint256 amount, uint256 minimumShares) external returns (uint256 shares);
```

### unstake

Withdraw actual staking tokens, retaining available rewards and forfeiting proportional pending rewards.

On the final eligible-stake exit, pending rewards become available; exited holders retain their rewards.


```solidity
function unstake(address token, uint256 shares, uint256 minimumStake) external returns (uint256 amount);
```

### reward

Fund pending rewards from the caller's R Ledger balance, allocated to current share holders.


```solidity
function reward(address token, uint256 amount) external;
```

### claim

Redeem all available reward units into the caller's R Ledger balance.

Pays the floored token value and leaves pending units unchanged, even if the payout rounds to zero.


```solidity
function claim(address token) external returns (uint256 claimed);
```

### transfer

Transfer direct SR balances after settling sender and recipient rewards.

Only the token's registered wrapper may call. The wrapper owns allowance checks.


```solidity
function transfer(address token, address from, address to, uint256 amount) external;
```

### settleStakeTransfer

Internal posting settlement; only the Dispatcher itself may invoke this selector.


```solidity
function settleStakeTransfer(
    address token,
    address from,
    address to,
    bool fromOutside,
    bool toOutside,
    uint256 amount
) external;
```

### stakingRewardToken

SR configuration and balances, expressed in each token's raw decimals.


```solidity
function stakingRewardToken(address token) external view returns (Configuration memory);
```

### rewardsOf

Current rewards for a direct holder, including holders who have exited.

Token amounts use R's raw decimals; units are internal accounting quantities.


```solidity
function rewardsOf(address token, address holder) external view returns (Rewards memory);
```

### rewardsOfAccount

Rewards for an internal leaf with explicit absolute parent context.


```solidity
function rewardsOfAccount(address token, address parent, address relative) external view returns (Rewards memory);
```

## Events
### StakingRewardTokenCreated

```solidity
event StakingRewardTokenCreated(
    address indexed token,
    address indexed stakingGroup,
    address indexed rewardGroup,
    address rewardShareToken,
    uint256 halfLife
);
```

### Staked

```solidity
event Staked(address indexed token, address indexed holder, uint256 stake, uint256 shares);
```

### Unstaked

```solidity
event Unstaked(address indexed token, address indexed holder, uint256 shares, uint256 stake);
```

### Rewarded

```solidity
event Rewarded(address indexed token, address indexed funder, uint256 amount, uint256 units);
```

### Claimed

```solidity
event Claimed(address indexed token, address indexed holder, uint256 amount, uint256 units);
```

### Forfeited

```solidity
event Forfeited(
    address indexed token, address indexed account, uint256 pendingUnits, uint256 allocationRemainderUnits
);
```

## Errors
### NotStakingRewardToken

```solidity
error NotStakingRewardToken(address token);
```

### AlreadyConfigured

```solidity
error AlreadyConfigured(address token);
```

### InvalidConfiguration

```solidity
error InvalidConfiguration();
```

### AccountReserved

```solidity
error AccountReserved(address account);
```

### UnauthorizedTransfer

```solidity
error UnauthorizedTransfer();
```

### ZeroAmount

```solidity
error ZeroAmount();
```

### NoStake

```solidity
error NoStake();
```

### InsufficientRewards

```solidity
error InsufficientRewards();
```

### InsufficientStake

```solidity
error InsufficientStake();
```

### Slippage

```solidity
error Slippage(uint256 amount, uint256 minimum);
```

## Structs
### Rewards

```solidity
struct Rewards {
    uint256 unclaimedUnits;
    uint256 pendingUnits;
    uint256 unclaimed;
    uint256 pending;
    uint256 available;
}
```

### Configuration

```solidity
struct Configuration {
    address tokenAddress;
    uint256 totalSupply;
    address stakingLedger;
    address stakingGroup;
    uint256 stakedBalance;
    address rewardLedger;
    address rewardGroup;
    address rewardAccount;
    address rewardShareToken;
    uint256 halfLife;
    Rewards rewards;
    uint256 allocationRemainderUnits;
}
```

