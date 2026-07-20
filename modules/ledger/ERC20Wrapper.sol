// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger} from "./ILedger.sol";
import {ILedgerView} from "./ILedgerView.sol";

contract ERC20Wrapper {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    address private immutable _dispatcher;
    string private _name;
    string private _symbol;
    uint8 public immutable _decimals;
    mapping(address => mapping(address => uint256)) private _allowances;

    // -------------------------------------------------------------------------
    // Events (ERC-20 standard)
    // -------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // -------------------------------------------------------------------------
    // Init
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // Metadata
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // Supply / Balances (delegated to Ledger)
    // -------------------------------------------------------------------------

    function totalSupply() public view returns (uint256) {
        return ILedgerView(_dispatcher).totalSupply(address(this));
    }

    function balanceOf(address account_) public view returns (uint256) {
        return ILedgerView(_dispatcher).balanceOf(address(this), address(this), account_);
    }

    // -------------------------------------------------------------------------
    // Allowance (delegated to Ledger)
    // -------------------------------------------------------------------------

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        _allowances[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }

    /// @notice Atomically increases `spender` allowance for `msg.sender`.
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool _ok) {
        uint256 _amount = _allowances[msg.sender][spender_] + addedValue_;
        _allowances[msg.sender][spender_] = _amount;
        emit Approval(msg.sender, spender_, _amount);
        return true;
    }

    /// @notice Atomically decreases `spender` allowance for `msg.sender`.
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool _ok) {
        uint256 current = _allowances[msg.sender][spender_];
        if (subtractedValue_ > current) {
            revert ILedger.InsufficientAllowance(address(this), msg.sender, spender_, current, subtractedValue_);
        }
        uint256 _amount = current - subtractedValue_;
        _allowances[msg.sender][spender_] = _amount;
        emit Approval(msg.sender, spender_, _amount);
        return true;
    }

    /// @notice Sets allowance safely even if a non-zero allowance already exists.
    /// If both current and desired are non-zero, sets to 0 first, then to `amount_`.
    function forceApprove(address spender_, uint256 amount_) public returns (bool) {
        uint256 current = _allowances[msg.sender][spender_];
        if (current != 0 && amount_ != 0) {
            _allowances[msg.sender][spender_] = 0;
            emit Approval(msg.sender, spender_, 0);
        }
        _allowances[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
        return true;
    }

    // -------------------------------------------------------------------------
    // Transfers (call back into Ledger)
    // -------------------------------------------------------------------------

    function transfer(address to_, uint256 amount_) public returns (bool) {
        ILedger(_dispatcher).transfer(address(this), address(this), msg.sender, address(this), to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        uint256 current = _allowances[from_][msg.sender];
        if (current < amount_) {
            revert ILedger.InsufficientAllowance(address(this), from_, msg.sender, current, amount_);
        }
        if (current != type(uint256).max) {
            _allowances[from_][msg.sender] = current - amount_;
        }
        ILedger(_dispatcher).transfer(address(this), address(this), from_, address(this), to_, amount_);
        return true;
    }

    function emitTransfer(address from_, address to_, uint256 amount_) public dispatcherOnly {
        emit Transfer(from_, to_, amount_);
    }
}
