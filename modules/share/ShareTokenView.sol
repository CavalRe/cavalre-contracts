// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {IShareTokenView} from "./IShareTokenView.sol";
import {ShareTokenLib} from "./ShareTokenLib.sol";

/// @notice Dispatcher read surface for share registration and Ledger accounting.
contract ShareTokenView is Dispatchable, IShareTokenView {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](5);
        signatures_[0] = "shareTokenState(address)";
        signatures_[1] = "convertToShares(address,uint256)";
        signatures_[2] = "convertToBacking(address,uint256)";
        signatures_[3] = "isShareToken(address)";
        signatures_[4] = "backingAccount(address)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](5);
        selectors_[0] = IShareTokenView.shareTokenState.selector;
        selectors_[1] = IShareTokenView.convertToShares.selector;
        selectors_[2] = IShareTokenView.convertToBacking.selector;
        selectors_[3] = IShareTokenView.isShareToken.selector;
        selectors_[4] = IShareTokenView.backingAccount.selector;
    }

    /// @inheritdoc IShareTokenView
    function isShareToken(address token_) external view returns (bool) {
        return ShareTokenLib.isShareToken(token_);
    }

    /// @inheritdoc IShareTokenView
    function backingAccount(address token_) external view returns (address) {
        return ShareTokenLib.backingAccount(token_);
    }

    /// @inheritdoc IShareTokenView
    function shareTokenState(address token_) external view returns (State memory) {
        return ShareTokenLib.shareTokenState(token_);
    }

    /// @inheritdoc IShareTokenView
    function convertToShares(address token_, uint256 backing_) external view returns (uint256) {
        return ShareTokenLib.convertToShares(token_, backing_);
    }

    /// @inheritdoc IShareTokenView
    function convertToBacking(address token_, uint256 shares_) external view returns (uint256) {
        return ShareTokenLib.convertToBacking(token_, shares_);
    }
}
