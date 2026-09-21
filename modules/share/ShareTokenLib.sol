// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LedgerLib} from "../ledger/LedgerLib.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {IShareToken} from "./IShareToken.sol";
import {IShareTokenView} from "./IShareTokenView.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice Share arithmetic and share issuance/burns for trusted consuming modules.
/// @dev Shares are Internal ledgers with a backing reference in this library's namespaced storage.
/// Ledger owns parent topology, supply and balances; its packed address always identifies the parent.
/// Callers perform and verify backing movements, authorize issuance and holder burns, enforce
/// slippage, and guard reentrancy across the entire operation. A backing reference grants no spending rights.
library ShareTokenLib {
    struct Store {
        mapping(address token => address backingAccount) backingAccounts;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.ShareToken")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position_ = STORE_POSITION;
        assembly {
            s.slot := position_
        }
    }

    // -- Registration --

    /// @notice Registered absolute backing account, or zero for an unregistered share token.
    function backingAccount(address token_) internal view returns (address) {
        return store().backingAccounts[token_];
    }

    /// @notice Whether token_ has a registered backing account.
    function isShareToken(address token_) internal view returns (bool) {
        return backingAccount(token_) != address(0);
    }

    /// @dev Backing must be a registered leaf outside the share's own ledger. Nested debit/credit
    /// leaves and Source accounts are valid; their ledger need not be a token (for example, Scale).
    function enforceShareTokenBackingAccount(address token_, address backingAccount_) internal view {
        if (!LedgerLib.isLedgerAccount(LedgerLib.flags(backingAccount_)) || LedgerLib.ledger(backingAccount_) == token_)
        {
            revert ILedger.InvalidLedgerAccount(backingAccount_);
        }
    }

    /// @notice Read current raw supply and the backing account's net balance from Ledger.
    /// @dev Backing uses its own ledger's decimals and its registered debit/credit polarity.
    function shareTokenState(address token_) internal view returns (IShareTokenView.State memory state_) {
        state_.backingAccount = backingAccount(token_);
        uint256 backingFlags_ = LedgerLib.flags(state_.backingAccount);
        // Unknown shares resolve to zero; removed backing leaves also have unregistered flags.
        if (!LedgerLib.isLedgerAccount(backingFlags_)) revert ILedger.InvalidLedgerAccount(token_);
        state_.backingLedger = LedgerLib.ledger(state_.backingAccount);
        state_.supply = LedgerLib.totalSupply(token_);
        state_.backing = LedgerLib.balanceOf(state_.backingAccount, LedgerLib.isCredit(backingFlags_));
    }

    // -- Conversion --

    /// @dev Initialization only: scale down floors and scale up uses checked multiplication.
    /// 10**difference must fit uint256; the scaled result must fit as well.
    function convertDecimals(uint256 amount_, uint8 fromDecimals_, uint8 toDecimals_) private pure returns (uint256) {
        uint256 difference_ = fromDecimals_ > toDecimals_ ? fromDecimals_ - toDecimals_ : toDecimals_ - fromDecimals_;
        if (difference_ > 77) revert IShareToken.UnsupportedDecimalDifference();
        uint256 factor_ = 10 ** difference_;
        return toDecimals_ >= fromDecimals_ ? amount_ * factor_ : amount_ / factor_;
    }

    /// @notice Quote raw shares for a raw backing quantity, rounding down.
    /// @dev Positive supply and backing use backing_ * supply / backing; decimals are already in
    /// that ratio. Only a completely empty share initializes at one whole share per whole
    /// backing unit. A mismatched zero state rejects positive input rather than assigning orphan
    /// backing to a new holder or issuing against a fully depleted account. Zero input quotes zero.
    function convertToShares(address token_, uint256 backing_) internal view returns (uint256) {
        IShareTokenView.State memory state_ = shareTokenState(token_);
        if (backing_ == 0) return 0;
        if (state_.supply != 0 && state_.backing != 0) {
            return Math.mulDiv(backing_, state_.supply, state_.backing);
        }
        if (state_.supply != 0 || state_.backing != 0) {
            revert IShareToken.InvalidShareState(state_.supply, state_.backing);
        }
        return convertDecimals(backing_, LedgerLib.decimals(state_.backingLedger), LedgerLib.decimals(token_));
    }

    /// @notice Quote raw backing for raw shares, rounding down.
    /// @dev A full-supply quote returns all backing exactly; partial rounding stays with remaining
    /// holders. Live supply with zero backing quotes zero. Both-zero state uses decimal-adjusted
    /// 1:1 units; zero supply with positive backing rejects positive input. This is a quantity quote,
    /// not a balance check: redeem separately enforces available supply and holder balance.
    function convertToBacking(address token_, uint256 shares_) internal view returns (uint256) {
        IShareTokenView.State memory state_ = shareTokenState(token_);
        if (shares_ == 0) return 0;
        if (state_.supply != 0) return Math.mulDiv(shares_, state_.backing, state_.supply);
        if (state_.backing != 0) revert IShareToken.InvalidShareState(0, state_.backing);
        return convertDecimals(shares_, LedgerLib.decimals(token_), LedgerLib.decimals(state_.backingLedger));
    }

    // -- Share Operations --

    /// @dev Accept effective debit leaves and registered debit leaves with explicit absolute parent context.
    /// Reject zero, credit accounts (including Source), and groups.
    function enforceShareTokenAccount(address token_, address parent_, address relative_)
        private
        view
        returns (uint256 flags_)
    {
        address absolute_;
        (flags_,, absolute_) = LedgerLib.effectiveFlags(token_, parent_, relative_);
        if (relative_ == address(0) || !LedgerLib.isDebitLedger(flags_)) {
            revert ILedger.InvalidLedgerAccount(absolute_);
        }
    }

    /// @notice Issue shares for backing_ already added by the caller, using the ratio before that addition.
    /// @dev The caller must add and verify exactly backing_ with unchanged share supply immediately
    /// before calling, in the same transaction. This function only mints shares from their Source.
    /// Zero/dust issuance reverts, rolling back the caller's preceding backing movement as well.
    function issue(address token_, address parent_, address relative_, uint256 backing_)
        internal
        returns (uint256 shares_)
    {
        IShareTokenView.State memory state_ = shareTokenState(token_);
        if (backing_ == 0) revert IShareToken.InvalidShareAmount();
        if (state_.backing < backing_) revert IShareToken.InvalidSettlement();
        // Recover the pre-addition backing balance; pricing against the funded balance would dilute issuance.
        state_.backing -= backing_;
        if ((state_.supply == 0) != (state_.backing == 0)) {
            revert IShareToken.InvalidShareState(state_.supply, state_.backing);
        }
        shares_ = state_.supply == 0
            ? convertDecimals(backing_, LedgerLib.decimals(state_.backingLedger), LedgerLib.decimals(token_))
            : Math.mulDiv(backing_, state_.supply, state_.backing);
        if (shares_ == 0) revert IShareToken.InvalidShareAmount();
        uint256 accountFlags_ = enforceShareTokenAccount(token_, parent_, relative_);
        (uint256 sourceFlags_,,) = LedgerLib.effectiveFlags(token_, token_, LedgerLib.SOURCE_ADDRESS);
        LedgerLib.transfer(token_, sourceFlags_, LedgerLib.SOURCE_ADDRESS, accountFlags_, relative_, shares_);
        emit IShareToken.ShareIssued(
            token_, parent_ == token_ ? relative_ : LedgerLib.toAddress(parent_, relative_), shares_, backing_
        );
    }

    /// @notice Burn authorized holder shares into Source and return their pre-burn backing quote.
    /// @dev The caller must release and verify exactly the returned backing immediately afterward,
    /// in the same transaction, and verify the expected supply decrease. This function does not move backing.
    /// Complete redemption quotes the remainder; fully depleted shares can redeem for zero.
    function redeem(address token_, address parent_, address relative_, uint256 shares_)
        internal
        returns (uint256 backing_)
    {
        IShareTokenView.State memory state_ = shareTokenState(token_);
        if (shares_ == 0 || shares_ > state_.supply) revert IShareToken.InvalidShareAmount();
        // The amount check above guarantees positive supply; reuse its validated snapshot.
        backing_ = Math.mulDiv(shares_, state_.backing, state_.supply);
        // Positive backing must not be silently donated by a rounded-to-zero redemption; use cancel.
        if (backing_ == 0 && state_.backing != 0) revert IShareToken.InvalidShareAmount();
        uint256 accountFlags_ = enforceShareTokenAccount(token_, parent_, relative_);
        (uint256 sourceFlags_,,) = LedgerLib.effectiveFlags(token_, token_, LedgerLib.SOURCE_ADDRESS);
        LedgerLib.transfer(token_, accountFlags_, relative_, sourceFlags_, LedgerLib.SOURCE_ADDRESS, shares_);
        emit IShareToken.ShareRedeemed(
            token_, parent_ == token_ ? relative_ : LedgerLib.toAddress(parent_, relative_), shares_, backing_
        );
    }

    /// @notice Burn shares without settling or releasing backing.
    /// @dev The caller must authorize the holder burn. Cancelling the last share leaves orphan
    /// backing, so positive issuance remains blocked until an authorized application resolves it.
    function cancel(address token_, address parent_, address relative_, uint256 shares_) internal {
        shareTokenState(token_);
        if (shares_ == 0) revert IShareToken.InvalidShareAmount();
        uint256 accountFlags_ = enforceShareTokenAccount(token_, parent_, relative_);
        (uint256 sourceFlags_,,) = LedgerLib.effectiveFlags(token_, token_, LedgerLib.SOURCE_ADDRESS);
        LedgerLib.transfer(token_, accountFlags_, relative_, sourceFlags_, LedgerLib.SOURCE_ADDRESS, shares_);
        emit IShareToken.ShareCancelled(
            token_, parent_ == token_ ? relative_ : LedgerLib.toAddress(parent_, relative_), shares_
        );
    }
}
