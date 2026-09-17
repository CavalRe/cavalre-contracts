# IStakingRewardToken
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/5316bd1d9e8e7ab1df82167844d0b85518ce76e4/modules/staking/IStakingRewardToken.sol)


## Functions
### createStakingRewardToken

Create an SR token with immutable S, R, absolute staking account T, and half-life configuration.

T must be an empty debit leaf on S. Identical creation requests return the existing token.


```solidity
function createStakingRewardToken(
    address stakingLedger,
    address rewardLedger,
    address stakingAccount,
    uint256 halfLife,
    ILedgerTokenFactory.TokenMetadata memory metadata
) external returns (address token, uint256 flags);
```

### stake

Deposit S from the caller's Ledger balance and mint principal shares.


```solidity
function stake(address token, uint256 amount, uint256 minimumShares) external returns (uint256 shares);
```

### unstake

Burn principal shares, retaining available rewards and forfeiting proportional pending rewards.

On a full exit by the last reward-unit holder, all remaining rewards become available to them.


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

### stakingRewardToken

SR configuration and balances, expressed in each token's raw decimals.


```solidity
function stakingRewardToken(address token) external view returns (Configuration memory);
```

### rewardsOf

Current rewards for a token-local holder key, including holders who have exited.

Token amounts use R's raw decimals; units are internal accounting quantities.


```solidity
function rewardsOf(address token, address holder) external view returns (Rewards memory);
```

## Events
### StakingRewardTokenCreated

```solidity
event StakingRewardTokenCreated(
    address indexed token,
    address indexed stakingLedger,
    address indexed rewardLedger,
    address stakingAccount,
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
event Forfeited(address indexed token, address indexed account, uint256 pendingUnits, uint256 cancelledUnits);
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
    address stakingAccount;
    uint256 stakedBalance;
    address rewardLedger;
    address rewardAccount;
    uint256 halfLife;
    Rewards rewards;
}
```

