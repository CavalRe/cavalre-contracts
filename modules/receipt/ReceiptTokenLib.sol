// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {ILedgerTokenFactory} from "../ledger/ILedgerTokenFactory.sol";
import {IReceiptToken} from "./IReceiptToken.sol";
import {IReceiptTokenView} from "./IReceiptTokenView.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice Receipt arithmetic and Ledger accounting for trusted consuming modules.
/// @dev Receipts are Internal ledgers whose packed address identifies a registered backing leaf.
/// Ledger owns the reference, supply and balances; this library adds no storage or receipt flag.
/// Callers authorize issuance, holder burns, and settlement independently, enforce slippage,
/// and guard reentrancy across their entire operation. A backing reference grants no spending rights.
library ReceiptTokenLib {
    // -- Registration --

    /// @notice Whether token_ currently resolves to a valid receipt ledger and backing leaf.
    function isReceipt(address token_) internal view returns (bool) {
        return receiptAccount(token_) != address(0);
    }

    /// @notice Return the absolute backing account, or zero if token_ does not identify a valid receipt.
    /// @dev Ledger stores the packed address opaquely; only receipt code interprets it as backing.
    /// Ordinary internal ledgers pack Root, which is not an eligible backing leaf. For either kind
    /// of Internal ledger, LedgerLib.parent still returns Root: the backing reference is not a parent.
    function receiptAccount(address token_) internal view returns (address backingAccount_) {
        uint256 flags_ = LedgerLib.flags(token_);
        if (!LedgerLib.isLedger(flags_) || !LedgerLib.isInternal(flags_)) return address(0);
        backingAccount_ = LedgerLib.packedAddress(flags_);
        if (!LedgerLib.isLedgerAccount(LedgerLib.flags(backingAccount_)) || LedgerLib.ledger(backingAccount_) == token_)
        {
            return address(0);
        }
    }

    /// @notice Register a deployed receipt wrapper as an Internal ledger backed by backingAccount_.
    /// @dev Trusted factory registration only. The caller must authorize creation and deploy token_.
    /// Ledger creates the debit root and its credit Source. No holder registration is required.
    /// Ledger rejects conflicting flags/metadata on replay,
    /// preserving the backing reference and preventing adoption of an ordinary internal token.
    function register(address token_, address backingAccount_, ILedgerTokenFactory.TokenMetadata memory metadata_)
        internal
        returns (uint256 flags_)
    {
        checkReceiptAccount(token_, backingAccount_);
        flags_ = LedgerLib.addLedger(
            token_, metadata_.name, metadata_.symbol, metadata_.decimals, LedgerLib.TokenKind.Internal, backingAccount_
        );
        LedgerLib.store().wrapper[token_] = token_;
    }

    /// @dev Backing must be a registered leaf outside the receipt's own ledger. Nested debit/credit
    /// leaves and Source accounts are valid; their ledger need not be a token (for example, Scale).
    function checkReceiptAccount(address token_, address backingAccount_) internal view {
        if (!LedgerLib.isLedgerAccount(LedgerLib.flags(backingAccount_)) || LedgerLib.ledger(backingAccount_) == token_)
        {
            revert ILedger.InvalidLedgerAccount(backingAccount_);
        }
    }

    /// @notice Read current raw supply and the backing account's net balance from Ledger.
    /// @dev Backing uses its own ledger's decimals and its registered debit/credit polarity.
    function receiptState(address token_) internal view returns (IReceiptTokenView.State memory state_) {
        state_.backingAccount = receiptAccount(token_);
        if (state_.backingAccount == address(0)) revert ILedger.InvalidLedgerAccount(token_);
        state_.backingLedger = LedgerLib.ledger(state_.backingAccount);
        state_.supply = LedgerLib.totalSupply(token_);
        state_.backing =
            LedgerLib.balanceOf(state_.backingAccount, LedgerLib.isCredit(LedgerLib.flags(state_.backingAccount)));
    }

    // -- Conversion --

    /// @notice Quote raw receipts for a raw backing quantity, rounding down.
    /// @dev Positive supply and backing use backing_ * supply / backing; decimals are already in
    /// that ratio. Only a completely empty receipt initializes at one whole receipt per whole
    /// backing unit. A mismatched zero state rejects positive input rather than assigning orphan
    /// backing to a new holder or issuing against a fully depleted account. Zero input quotes zero.
    function convertToReceipts(address token_, uint256 backing_) internal view returns (uint256) {
        IReceiptTokenView.State memory state_ = receiptState(token_);
        if (backing_ == 0) return 0;
        if (state_.supply != 0 && state_.backing != 0) {
            return Math.mulDiv(backing_, state_.supply, state_.backing);
        }
        if (state_.supply != 0 || state_.backing != 0) {
            revert IReceiptToken.InvalidReceiptState(state_.supply, state_.backing);
        }
        return scale(backing_, LedgerLib.decimals(state_.backingLedger), LedgerLib.decimals(token_));
    }

    /// @notice Quote raw backing for raw receipts, rounding down.
    /// @dev A full-supply quote returns all backing exactly; partial rounding stays with remaining
    /// holders. Live supply with zero backing quotes zero. Both-zero state uses decimal-adjusted
    /// 1:1 units; zero supply with positive backing rejects positive input. This is a quantity quote,
    /// not a balance check: redeem separately enforces available supply and holder balance.
    function convertToBacking(address token_, uint256 receipts_) internal view returns (uint256) {
        IReceiptTokenView.State memory state_ = receiptState(token_);
        if (receipts_ == 0) return 0;
        if (state_.supply != 0) return Math.mulDiv(receipts_, state_.backing, state_.supply);
        if (state_.backing != 0) revert IReceiptToken.InvalidReceiptState(0, state_.backing);
        return scale(receipts_, LedgerLib.decimals(token_), LedgerLib.decimals(state_.backingLedger));
    }

    /// @dev Initialization only: scale down floors and scale up uses checked multiplication.
    /// 10**difference must fit uint256; the scaled result must fit as well.
    function scale(uint256 amount_, uint8 fromDecimals_, uint8 toDecimals_) private pure returns (uint256) {
        uint256 difference_ = fromDecimals_ > toDecimals_ ? fromDecimals_ - toDecimals_ : toDecimals_ - fromDecimals_;
        if (difference_ > 77) revert IReceiptToken.UnsupportedDecimalDifference();
        uint256 factor_ = 10 ** difference_;
        return toDecimals_ >= fromDecimals_ ? amount_ * factor_ : amount_ / factor_;
    }

    // -- Receipt Operations --

    /// @notice Issue receipts at the pre-settlement ratio after adding exactly backing_ to backing.
    /// @dev settle_(token_, backing_, data_) is trusted internal application code; data_ is opaque
    /// to this library. It performs authorized token custody or non-token accounting as appropriate.
    /// The callback must leave receipt supply unchanged. Zero/dust issuance reverts, and any failed
    /// delta check rolls back settlement. Callers enforce slippage and reentrancy protection.
    function issue(
        address token_,
        address holder_,
        uint256 backing_,
        bytes memory data_,
        function(address, uint256, bytes memory) internal settle_
    ) internal returns (uint256 receipts_) {
        IReceiptTokenView.State memory state_ = receiptState(token_);
        receipts_ = convertToReceipts(token_, backing_);
        if (receipts_ == 0) revert IReceiptToken.InvalidReceiptAmount();
        checkHolder(token_, holder_);
        settle_(token_, backing_, data_);
        IReceiptTokenView.State memory after_ = receiptState(token_);
        if (after_.supply != state_.supply || after_.backing != state_.backing + backing_) {
            revert IReceiptToken.InvalidSettlement();
        }
        // Use the default Ledger path so mint accounting, ERC20 events and installed SR hooks all run.
        LedgerLib.transfer(token_, token_, LedgerLib.SOURCE_ADDRESS, token_, holder_, receipts_);
        emit IReceiptToken.ReceiptIssued(token_, holder_, receipts_, backing_);
    }

    /// @notice Burn authorized holder receipts and settle the pre-burn proportional backing quote.
    /// @dev The caller authorizes the holder burn and backing release, checks slippage, and guards
    /// reentrancy. Burn precedes settlement; settle_(token_, backing_, data_) must release exactly
    /// the quoted backing without changing receipt supply further. Failure rolls back both steps.
    /// Complete redemption releases the remainder; fully depleted receipts can redeem for zero.
    function redeem(
        address token_,
        address holder_,
        uint256 receipts_,
        bytes memory data_,
        function(address, uint256, bytes memory) internal settle_
    ) internal returns (uint256 backing_) {
        IReceiptTokenView.State memory state_ = receiptState(token_);
        if (receipts_ == 0 || receipts_ > state_.supply) revert IReceiptToken.InvalidReceiptAmount();
        backing_ = convertToBacking(token_, receipts_);
        // Positive backing must not be silently donated by a rounded-to-zero redemption; use cancel.
        if (backing_ == 0 && state_.backing != 0) revert IReceiptToken.InvalidReceiptAmount();
        checkHolder(token_, holder_);
        LedgerLib.transfer(token_, token_, holder_, token_, LedgerLib.SOURCE_ADDRESS, receipts_);
        settle_(token_, backing_, data_);
        IReceiptTokenView.State memory after_ = receiptState(token_);
        if (after_.supply != state_.supply - receipts_ || after_.backing != state_.backing - backing_) {
            revert IReceiptToken.InvalidSettlement();
        }
        emit IReceiptToken.ReceiptRedeemed(token_, holder_, receipts_, backing_);
    }

    /// @notice Burn receipts without settling or releasing backing.
    /// @dev The caller must authorize the holder burn. Cancelling the last receipt leaves orphan
    /// backing, so positive issuance remains blocked until an authorized application resolves it.
    function cancel(address token_, address holder_, uint256 receipts_) internal {
        receiptState(token_);
        if (receipts_ == 0) revert IReceiptToken.InvalidReceiptAmount();
        checkHolder(token_, holder_);
        LedgerLib.transfer(token_, token_, holder_, token_, LedgerLib.SOURCE_ADDRESS, receipts_);
        emit IReceiptToken.ReceiptCancelled(token_, holder_, receipts_);
    }

    /// @dev Direct, unregistered holders inherit debit polarity from the receipt root. Reject
    /// registered leaves/groups (including Source) so issue/cancel/redeem cannot target them.
    function checkHolder(address token_, address holder_) private view {
        if (
            holder_ == address(0)
                || !LedgerLib.isUnregisteredAccount(LedgerLib.flags(LedgerLib.toAddress(token_, holder_)))
        ) {
            revert IReceiptToken.InvalidReceiptHolder(holder_);
        }
    }
}
