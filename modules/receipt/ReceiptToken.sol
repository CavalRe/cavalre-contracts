// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {IReceiptToken} from "./IReceiptToken.sol";
import {ReceiptTokenLib} from "./ReceiptTokenLib.sol";

/// @notice Wrapper-authorized cancellation. Applications expose authorized issue/redeem settlement.
contract ReceiptToken is Dispatchable, IReceiptToken {
    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](1);
        signatures_[0] = "cancelReceipt(address,address,uint256)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](1);
        selectors_[0] = IReceiptToken.cancelReceipt.selector;
    }

    /// @inheritdoc IReceiptToken
    function cancelReceipt(address token_, address holder_, uint256 receipts_) external {
        // The wrapper supplies its caller as holder; an arbitrary caller cannot burn another holder.
        if (msg.sender != token_ || LedgerLib.wrapper(token_) != token_) revert ILedger.Unauthorized(msg.sender);
        ReceiptTokenLib.cancel(token_, holder_, receipts_);
    }
}
