// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Token} from "../ledger/ERC20Token.sol";
import {ERC20TokenLib} from "../ledger/ERC20TokenLib.sol";
import {IStakingRewards} from "./IStakingRewards.sol";

/// @notice ERC20 surface for SR tokens; transfers settle through the SR module.
/// @dev Uses inherited metadata and allowances. Balances and total supply come from this token's ledger root.
contract StakingRewardsToken is ERC20Token {
    constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20Token(dispatcher_, name_, symbol_, decimals_)
    {}

    /// @dev The SR callback settles rewards and moves stake atomically before Ledger requests the token's Transfer event.
    function transfer(address to_, uint256 amount_) public override returns (bool) {
        IStakingRewards(dispatcher()).transfer(address(this), msg.sender, to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        ERC20TokenLib.spendAllowance(_allowances, from_, msg.sender, amount_);
        IStakingRewards(dispatcher()).transfer(address(this), from_, to_, amount_);
        return true;
    }
}
