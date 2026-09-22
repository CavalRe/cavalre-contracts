# ILedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/ledger/ILedgerTokenFactory.sol)


## Functions
### createInternalTokens


```solidity
function createInternalTokens(TokenMetadata[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);
```

### createShareTokens

Create share tokens in input order; any failed item reverts the entire batch.


```solidity
function createShareTokens(ShareTokenConfig[] memory tokens)
    external
    returns (address[] memory tokenAddresses, uint256[] memory flags);
```

### createStakingRewardToken

Create an SR wrapper with immutable staking group, reward group and half-life.


```solidity
function createStakingRewardToken(
    address stakingGroup,
    address rewardGroup,
    uint256 halfLife,
    TokenMetadata memory metadata
) external returns (address token);
```

## Structs
### TokenMetadata

```solidity
struct TokenMetadata {
    string name;
    string symbol;
    uint8 decimals;
    string version;
}
```

### ShareTokenConfig

```solidity
struct ShareTokenConfig {
    address backingAccount;
    TokenMetadata metadata;
}
```

