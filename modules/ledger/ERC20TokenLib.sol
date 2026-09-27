// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger} from "./ILedger.sol";
import {ILedgerView} from "./ILedgerView.sol";
import {LedgerLib} from "./LedgerLib.sol";
import {ITreeView} from "../tree/ITreeView.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Shared allowances and transfer policy for external ERC20 token contracts.
/// @dev Internal functions use the calling token's storage and emit events from that token.
library ERC20TokenLib {
    /// @dev Public ERC20 operations only spend direct debit leaves; custody groups and credits are excluded.
    function enforceDebitLeaves(uint256 fromFlags_, address from_, uint256 toFlags_, address to_) internal pure {
        if (from_ == address(0) || !LedgerLib.isDebitLedger(fromFlags_)) {
            revert ILedger.InvalidLedgerAccount(LedgerLib.toAddress(LedgerLib.parent(fromFlags_), from_));
        }
        if (to_ == address(0) || !LedgerLib.isDebitLedger(toFlags_)) {
            revert ILedger.InvalidLedgerAccount(LedgerLib.toAddress(LedgerLib.parent(toFlags_), to_));
        }
    }

    /// @dev Resolve and validate in token context before calling the permissioned Ledger module.
    function transfer(address dispatcher_, address from_, address to_, uint256 amount_) internal returns (bool) {
        (uint256 fromFlags_,, address fromAbsolute_) =
            ITreeView(dispatcher_).effectiveFlags(address(this), address(this), from_);
        (uint256 toFlags_,,) = ITreeView(dispatcher_).effectiveFlags(address(this), address(this), to_);
        enforceDebitLeaves(fromFlags_, from_, toFlags_, to_);
        // Ledger self-postings are no-ops; ERC20 still requires enough spendable balance.
        if (from_ == to_ && ILedgerView(dispatcher_).balanceOf(address(this), address(this), from_) < amount_) {
            revert ILedger.InsufficientBalance(address(this), address(this), fromAbsolute_, amount_);
        }
        ILedger(dispatcher_).transfer(address(this), fromFlags_, from_, toFlags_, to_, amount_);
        return true;
    }

    function approve(
        mapping(address => mapping(address => uint256)) storage allowances_,
        address spender_,
        uint256 amount_
    ) internal returns (bool) {
        allowances_[msg.sender][spender_] = amount_;
        emit IERC20.Approval(msg.sender, spender_, amount_);
        return true;
    }

    function increaseAllowance(
        mapping(address => mapping(address => uint256)) storage allowances_,
        address spender_,
        uint256 addedValue_
    ) internal returns (bool) {
        return approve(allowances_, spender_, allowances_[msg.sender][spender_] + addedValue_);
    }

    function decreaseAllowance(
        mapping(address => mapping(address => uint256)) storage allowances_,
        address spender_,
        uint256 subtractedValue_
    ) internal returns (bool) {
        uint256 current_ = allowances_[msg.sender][spender_];
        if (subtractedValue_ > current_) {
            revert ILedger.InsufficientAllowance(address(this), msg.sender, spender_, current_, subtractedValue_);
        }
        return approve(allowances_, spender_, current_ - subtractedValue_);
    }

    /// @dev Preserve the zero-reset Approval event when replacing a nonzero allowance with another.
    function forceApprove(
        mapping(address => mapping(address => uint256)) storage allowances_,
        address spender_,
        uint256 amount_
    ) internal returns (bool) {
        if (allowances_[msg.sender][spender_] != 0 && amount_ != 0) approve(allowances_, spender_, 0);
        return approve(allowances_, spender_, amount_);
    }

    /// @dev Infinite allowances are not consumed. Spending an allowance does not emit Approval.
    function spendAllowance(
        mapping(address => mapping(address => uint256)) storage allowances_,
        address owner_,
        address spender_,
        uint256 amount_
    ) internal {
        uint256 current_ = allowances_[owner_][spender_];
        if (current_ < amount_) {
            revert ILedger.InsufficientAllowance(address(this), owner_, spender_, current_, amount_);
        }
        if (current_ != type(uint256).max) allowances_[owner_][spender_] = current_ - amount_;
    }
}
