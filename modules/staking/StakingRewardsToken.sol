// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Token} from "../ledger/ERC20Token.sol";
import {ERC20TokenLib} from "../ledger/ERC20TokenLib.sol";
import {ILedgerView} from "../ledger/ILedgerView.sol";
import {IStakingRewards} from "./IStakingRewards.sol";

/// @notice ERC20 surface for SR tokens; transfers settle through the SR module.
/// @dev Uses inherited metadata and allowances. Balances are actual tokens in the configured staking group.
contract StakingRewardsToken is ERC20Token {
    constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20Token(dispatcher_, name_, symbol_, decimals_)
    {}

    function totalSupply() public view override returns (uint256) {
        return IStakingRewards(dispatcher()).stakingRewardToken(address(this)).totalSupply;
    }

    function balanceOf(address account_) public view override returns (uint256) {
        IStakingRewards.Configuration memory config_ = IStakingRewards(dispatcher()).stakingRewardToken(address(this));
        return ILedgerView(dispatcher()).balanceOf(config_.stakingLedger, config_.stakingGroup, account_);
    }

    /// @dev The SR callback settles rewards and moves stake atomically before the token emits Transfer.
    function transfer(address to_, uint256 amount_) public override returns (bool) {
        IStakingRewards(dispatcher()).transfer(address(this), msg.sender, to_, amount_);
        emit Transfer(msg.sender, to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        ERC20TokenLib.spendAllowance(_allowances, from_, msg.sender, amount_);
        IStakingRewards(dispatcher()).transfer(address(this), from_, to_, amount_);
        emit Transfer(from_, to_, amount_);
        return true;
    }
}
