// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Wrapper} from "../ledger/ERC20Wrapper.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {ILedgerView} from "../ledger/ILedgerView.sol";
import {IStakingRewardToken} from "./IStakingRewardToken.sol";

/// @notice ERC20 surface for SR tokens; transfers settle through the SR module.
/// @dev Uses inherited metadata and allowances. Balances are actual tokens in the configured staking group.
contract StakingRewardWrapper is ERC20Wrapper {
    constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20Wrapper(dispatcher_, name_, symbol_, decimals_)
    {}

    function totalSupply() public view override returns (uint256) {
        return IStakingRewardToken(dispatcher()).stakingRewardToken(address(this)).totalSupply;
    }

    function balanceOf(address account_) public view override returns (uint256) {
        IStakingRewardToken.Configuration memory config_ =
            IStakingRewardToken(dispatcher()).stakingRewardToken(address(this));
        return ILedgerView(dispatcher()).balanceOf(config_.stakingLedger, config_.stakingGroup, account_);
    }

    function transfer(address to_, uint256 amount_) public override returns (bool) {
        IStakingRewardToken(dispatcher()).transfer(address(this), msg.sender, to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        uint256 current_ = _allowances[from_][msg.sender];
        if (current_ < amount_) {
            revert ILedger.InsufficientAllowance(address(this), from_, msg.sender, current_, amount_);
        }
        if (current_ != type(uint256).max) {
            _allowances[from_][msg.sender] = current_ - amount_;
        }
        IStakingRewardToken(dispatcher()).transfer(address(this), from_, to_, amount_);
        return true;
    }
}
