// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";
import {IStakingRewardToken} from "./IStakingRewardToken.sol";
import {StakingRewardLib} from "./StakingRewardLib.sol";

/// @notice Owner-only program creation, separated from runtime accounting for EIP-170.
contract StakingRewardFactory is Dispatchable {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](1);
        signatures_[0] = "createStakingRewardToken(address,address,uint256,(string,string,uint8,string))";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](1);
        selectors_[0] = IStakingRewardToken.createStakingRewardToken.selector;
    }

    function createStakingRewardToken(
        address stakingGroup_,
        address rewardGroup_,
        uint256 halfLife_,
        ILedgerTokenFactory.TokenMetadata memory metadata_
    ) external returns (address) {
        enforceIsOwner();
        return StakingRewardLib.createStakingRewardToken(stakingGroup_, rewardGroup_, halfLife_, metadata_);
    }
}
