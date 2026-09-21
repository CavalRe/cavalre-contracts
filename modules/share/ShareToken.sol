// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Wrapper} from "../ledger/ERC20Wrapper.sol";
import {IShareTokenView} from "./IShareTokenView.sol";

/// @notice ERC20 share surface. Settlement belongs to the consuming application's module.
/// @dev Adds no storage. Metadata and allowances use shared ERC20Wrapper behavior. Ledger owns
/// supply and balances; ShareTokenLib stores the backing reference in Dispatcher storage.
/// Install ShareTokenView for the added read calls.
contract ShareToken is ERC20Wrapper {
    constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20Wrapper(dispatcher_, name_, symbol_, decimals_)
    {}

    /// @notice Current backing reference, backing balance and supply in their respective raw units.
    function shareTokenState() external view returns (IShareTokenView.State memory) {
        return IShareTokenView(dispatcher()).shareTokenState(address(this));
    }

    /// @notice Quote raw shares for raw backing, rounding down; no backing is moved.
    function convertToShares(uint256 backing_) external view returns (uint256) {
        return IShareTokenView(dispatcher()).convertToShares(address(this), backing_);
    }

    /// @notice Quote raw backing for raw shares, rounding down; no shares are burned.
    function convertToBacking(uint256 shares_) external view returns (uint256) {
        return IShareTokenView(dispatcher()).convertToBacking(address(this), shares_);
    }
}
