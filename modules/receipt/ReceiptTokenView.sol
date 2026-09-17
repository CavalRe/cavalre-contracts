// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {IReceiptTokenView} from "./IReceiptTokenView.sol";
import {ReceiptTokenLib} from "./ReceiptTokenLib.sol";

/// @notice Dispatcher read surface; receipt metadata and accounting are derived from Ledger.
contract ReceiptTokenView is Dispatchable, IReceiptTokenView {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](5);
        signatures_[0] = "receiptState(address)";
        signatures_[1] = "convertToReceipts(address,uint256)";
        signatures_[2] = "convertToBacking(address,uint256)";
        signatures_[3] = "isReceipt(address)";
        signatures_[4] = "receiptAccount(address)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](5);
        selectors_[0] = IReceiptTokenView.receiptState.selector;
        selectors_[1] = IReceiptTokenView.convertToReceipts.selector;
        selectors_[2] = IReceiptTokenView.convertToBacking.selector;
        selectors_[3] = IReceiptTokenView.isReceipt.selector;
        selectors_[4] = IReceiptTokenView.receiptAccount.selector;
    }

    /// @inheritdoc IReceiptTokenView
    function isReceipt(address token_) external view returns (bool) {
        return ReceiptTokenLib.isReceipt(token_);
    }

    /// @inheritdoc IReceiptTokenView
    function receiptAccount(address token_) external view returns (address) {
        return ReceiptTokenLib.receiptAccount(token_);
    }

    /// @inheritdoc IReceiptTokenView
    function receiptState(address token_) external view returns (State memory) {
        return ReceiptTokenLib.receiptState(token_);
    }

    /// @inheritdoc IReceiptTokenView
    function convertToReceipts(address token_, uint256 backing_) external view returns (uint256) {
        return ReceiptTokenLib.convertToReceipts(token_, backing_);
    }

    /// @inheritdoc IReceiptTokenView
    function convertToBacking(address token_, uint256 receipts_) external view returns (uint256) {
        return ReceiptTokenLib.convertToBacking(token_, receipts_);
    }
}
