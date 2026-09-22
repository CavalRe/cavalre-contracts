# LedgerTokenFactory
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/main/modules/ledger/LedgerTokenFactory.sol)

**Inherits:**
[Dispatchable](/modules/dispatcher/Dispatchable.sol/abstract.Dispatchable.md)


## Functions
### signatures


```solidity
function signatures() external pure virtual override returns (string[] memory _signatures);
```

### selectors


```solidity
function selectors() external pure virtual override returns (bytes4[] memory _selectors);
```

### createInternalTokens


```solidity
function createInternalTokens(ILedgerTokenFactory.TokenMetadata[] memory tokens_)
    external
    returns (address[] memory _tokenAddresses, uint256[] memory _flags);
```

### createShareTokens

Create share tokens in input order; any failed item reverts the entire batch.


```solidity
function createShareTokens(ILedgerTokenFactory.ShareTokenConfig[] memory tokens_)
    external
    returns (address[] memory _tokenAddresses, uint256[] memory _flags);
```

### createStakingRewardToken

Create an SR wrapper and configure its staking and reward accounts.


```solidity
function createStakingRewardToken(
    address stakingGroup_,
    address rewardGroup_,
    uint256 halfLife_,
    ILedgerTokenFactory.TokenMetadata memory metadata_
) external returns (address);
```

