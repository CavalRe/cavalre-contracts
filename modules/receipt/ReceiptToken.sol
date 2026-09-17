// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {IReceiptToken} from "./IReceiptToken.sol";
import {ReceiptTokenLib} from "./ReceiptTokenLib.sol";

/// @notice Permissionless self-cancellation only. Applications expose authorized issue/redeem settlement.
contract ReceiptToken is Dispatchable, IReceiptToken {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](2);
        signatures_[0] = "cancelReceipt(address,uint256)";
        signatures_[1] = "cancelReceipt(address,address,uint256)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](2);
        selectors_[0] = bytes4(keccak256("cancelReceipt(address,uint256)"));
        selectors_[1] = bytes4(keccak256("cancelReceipt(address,address,uint256)"));
    }

    /// @inheritdoc IReceiptToken
    function cancelReceipt(address token_, uint256 receipts_) external {
        ReceiptTokenLib.cancel(token_, msg.sender, receipts_);
    }

    /// @inheritdoc IReceiptToken
    function cancelReceipt(address token_, address holder_, uint256 receipts_) external {
        // The wrapper supplies its caller as holder; an arbitrary caller cannot burn another holder.
        if (msg.sender != token_ || LedgerLib.wrapper(token_) != token_) revert ILedger.Unauthorized(msg.sender);
        ReceiptTokenLib.cancel(token_, holder_, receipts_);
    }
}
