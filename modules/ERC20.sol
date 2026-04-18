// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Module} from "./Module.sol";
import {Initializable} from "../utilities/Initializable.sol";
import {LedgerLib} from "../libraries/LedgerLib.sol";
import {ERC20Lib} from "../libraries/ERC20Lib.sol";
import {ILedger} from "../interfaces/ILedger.sol";

contract ERC20 is Module, Initializable {
    // -- Storage --

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.ERC20.Initializable")) - 1)) & ~bytes32(uint256(0xff));

    // -- Init --

    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](13);
        _selectors[0] = ERC20Lib.INITIALIZE_ERC20;
        _selectors[1] = ERC20Lib.NAME;
        _selectors[2] = ERC20Lib.SYMBOL;
        _selectors[3] = ERC20Lib.DECIMALS;
        _selectors[4] = ERC20Lib.TOTAL_SUPPLY;
        _selectors[5] = ERC20Lib.BALANCE_OF;
        _selectors[6] = ERC20Lib.ALLOWANCE;
        _selectors[7] = ERC20Lib.APPROVE;
        _selectors[8] = ERC20Lib.TRANSFER;
        _selectors[9] = ERC20Lib.TRANSFER_FROM;
        _selectors[10] = ERC20Lib.INCREASE_ALLOWANCE;
        _selectors[11] = ERC20Lib.DECREASE_ALLOWANCE;
        _selectors[12] = ERC20Lib.FORCE_APPROVE;
    }

    function initializeERC20() external initializer {
        enforceIsOwner();
        // ERC-20 surface is only valid once the canonical root has been registered in Ledger state.
        if (LedgerLib.root(address(this)) != address(this)) {
            revert ILedger.LedgerUninitialized();
        }
    }

    // -- Metadata --

    function name() external view returns (string memory) {
        return LedgerLib.name(address(this));
    }

    function symbol() external view returns (string memory) {
        return LedgerLib.symbol(address(this));
    }

    function decimals() external view returns (uint8) {
        return LedgerLib.decimals(address(this));
    }

    // -- Supply / Balances --

    function totalSupply() external view returns (uint256) {
        return LedgerLib.totalSupply(address(this));
    }

    function balanceOf(address owner_) external view returns (uint256) {
        return LedgerLib.debitBalanceOf(LedgerLib.toAddress(address(this), owner_));
    }

    // -- Allowance --

    function allowance(address owner_, address spender_) external view returns (uint256) {
        return ERC20Lib.store().allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_) external returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool) {
        uint256 amount_ = ERC20Lib.store().allowances[msg.sender][spender_] + addedValue_;
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool) {
        uint256 current_ = ERC20Lib.store().allowances[msg.sender][spender_];
        if (subtractedValue_ > current_) {
            revert ILedger.InsufficientAllowance(address(this), msg.sender, spender_, current_, subtractedValue_);
        }
        _approve(msg.sender, spender_, current_ - subtractedValue_);
        return true;
    }

    function forceApprove(address spender_, uint256 amount_) external returns (bool) {
        uint256 current_ = ERC20Lib.store().allowances[msg.sender][spender_];
        if (current_ != 0 && amount_ != 0) {
            _approve(msg.sender, spender_, 0);
        }
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    // -- Transfers --

    function transfer(address to_, uint256 amount_) external returns (bool) {
        emit ILedger.Transfer(msg.sender, to_, amount_);
        ILedger(address(this)).transfer(address(this), msg.sender, address(this), to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) external returns (bool) {
        uint256 current_ = ERC20Lib.store().allowances[from_][msg.sender];
        if (current_ < amount_) {
            revert ILedger.InsufficientAllowance(address(this), from_, msg.sender, current_, amount_);
        }
        if (current_ != type(uint256).max) {
            ERC20Lib.store().allowances[from_][msg.sender] = current_ - amount_;
        }
        emit ILedger.Transfer(from_, to_, amount_);
        ILedger(address(this)).transfer(address(this), from_, address(this), to_, amount_);
        return true;
    }

    function _approve(address owner_, address spender_, uint256 amount_) private {
        ERC20Lib.store().allowances[owner_][spender_] = amount_;
        emit ILedger.Approval(owner_, spender_, amount_);
    }
}
