# StakingRewardWrapper
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/a40e08a217d6c3655416be8a6de882a5e4963112/modules/staking/StakingRewardWrapper.sol)

**Inherits:**
[ERC20Wrapper](/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol/abstract.ERC20Wrapper.md)

ERC20 surface for SR tokens; transfers settle through the SR module.

Uses inherited metadata and allowance storage. Ledger retains balances and events.


## Functions
### constructor


```solidity
constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
    ERC20Wrapper(dispatcher_, name_, symbol_, decimals_);
```

### transfer


```solidity
function transfer(address to_, uint256 amount_) public override returns (bool);
```

### transferFrom


```solidity
function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool);
```

