// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger} from "./ILedger.sol";
import {ILedgerView} from "./ILedgerView.sol";
import {ERC20TokenLib} from "./ERC20TokenLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice External ERC20 surface backed by Dispatcher ledger balances.
/// @dev Derived tokens override balance views and transfers for their own account and settlement rules.
contract ERC20Token is IERC20 {
    // -- Storage --

    address private immutable _dispatcher;
    string private _name;
    string private _symbol;
    uint8 public immutable _decimals;
    mapping(address => mapping(address => uint256)) internal _allowances;

    // -- Init --

    constructor(address dispatcher_, string memory name_, string memory symbol_, uint8 decimals_) {
        _dispatcher = dispatcher_;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    modifier dispatcherOnly() {
        if (msg.sender != _dispatcher) revert ILedger.Unauthorized(msg.sender);
        _;
    }

    // -- Metadata --

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function dispatcher() public view returns (address) {
        return _dispatcher;
    }

    // -- Supply / Balances --

    function totalSupply() public view virtual returns (uint256) {
        return ILedgerView(_dispatcher).totalSupply(address(this));
    }

    /// @notice Normal balance of the direct account at H(this, account_), including its subtree.
    /// @dev Displaying group custody does not grant authority to spend descendants.
    function balanceOf(address account_) public view virtual returns (uint256) {
        return ILedgerView(_dispatcher).balanceOf(address(this), address(this), account_);
    }

    // -- Allowances (stored in this token) --

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        return ERC20TokenLib.approve(_allowances, spender_, amount_);
    }

    /// @notice Atomically increases `spender` allowance for `msg.sender`.
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool _ok) {
        return ERC20TokenLib.increaseAllowance(_allowances, spender_, addedValue_);
    }

    /// @notice Atomically decreases `spender` allowance for `msg.sender`.
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool _ok) {
        return ERC20TokenLib.decreaseAllowance(_allowances, spender_, subtractedValue_);
    }

    /// @notice Sets allowance safely even if a non-zero allowance already exists.
    /// If both current and desired are non-zero, sets to 0 first, then to `amount_`.
    function forceApprove(address spender_, uint256 amount_) public returns (bool) {
        return ERC20TokenLib.forceApprove(_allowances, spender_, amount_);
    }

    // -- Transfers --

    /// @notice Transfer between direct ledger holders; derived tokens override this entry point.
    function transfer(address to_, uint256 amount_) public virtual returns (bool) {
        return ERC20TokenLib.transfer(_dispatcher, msg.sender, to_, amount_);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public virtual returns (bool) {
        ERC20TokenLib.spendAllowance(_allowances, from_, msg.sender, amount_);
        return ERC20TokenLib.transfer(_dispatcher, from_, to_, amount_);
    }

    function emitTransfer(address from_, address to_, uint256 amount_) public dispatcherOnly {
        emit Transfer(from_, to_, amount_);
    }
}
