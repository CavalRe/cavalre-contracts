// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Wrapper} from "../ledger/ERC20Wrapper.sol";
import {IReceiptToken} from "./IReceiptToken.sol";
import {IReceiptTokenView} from "./IReceiptTokenView.sol";

/// @notice ERC20 receipt surface. Settlement belongs to the consuming application's module.
/// @dev Adds no storage. Metadata and allowances use shared ERC20Wrapper behavior; balances,
/// supply and backing remain in Ledger. Install ReceiptToken/ReceiptTokenView for the added calls.
contract ReceiptWrapper is ERC20Wrapper {
    constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20Wrapper(dispatcher_, name_, symbol_, decimals_)
    {}

    /// @notice Current backing reference, backing balance and supply in their respective raw units.
    function receiptState() external view returns (IReceiptTokenView.State memory) {
        return IReceiptTokenView(dispatcher()).receiptState(address(this));
    }

    /// @notice Quote raw receipts for raw backing, rounding down; no backing is moved.
    function convertToReceipts(uint256 backing_) external view returns (uint256) {
        return IReceiptTokenView(dispatcher()).convertToReceipts(address(this), backing_);
    }

    /// @notice Quote raw backing for raw receipts, rounding down; no receipts are burned.
    function convertToBacking(uint256 receipts_) external view returns (uint256) {
        return IReceiptTokenView(dispatcher()).convertToBacking(address(this), receipts_);
    }

    /// @notice Burn only the caller's receipts without releasing backing.
    /// @dev ERC20 approvals do not permit cancelling another holder's receipts.
    function cancel(uint256 receipts_) external {
        IReceiptToken(dispatcher()).cancelReceipt(address(this), msg.sender, receipts_);
    }
}
