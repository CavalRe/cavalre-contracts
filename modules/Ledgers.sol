// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Module} from "@cavalre/contracts/modules/Module.sol";
import {Initializable} from "@cavalre/contracts/utilities/Initializable.sol";
import {LedgersLib as Lib} from "@cavalre/contracts/libraries/LedgersLib.sol";

contract Ledgers is Module, Initializable {
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    uint8 internal immutable _decimals;

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledgers.Initializable")) - 1)) & ~bytes32(uint256(0xff));

    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    function commands() public pure virtual override returns (bytes4[] memory _commands) {
        uint256 n;
        _commands = new bytes4[](26);
        _commands[n++] = Lib.INITIALIZE_LEDGERS;
        _commands[n++] = Lib.NAME;
        _commands[n++] = Lib.SYMBOL;
        _commands[n++] = Lib.DECIMALS;
        _commands[n++] = Lib.ROOT;
        _commands[n++] = Lib.PARENT;
        _commands[n++] = Lib.IS_GROUP;
        _commands[n++] = Lib.SUBACCOUNTS;
        _commands[n++] = Lib.HAS_SUBACCOUNT;
        _commands[n++] = Lib.SUBACCOUNT_INDEX;
        _commands[n++] = Lib.BASE_NAME;
        _commands[n++] = Lib.BASE_SYMBOL;
        _commands[n++] = Lib.BASE_DECIMALS;
        _commands[n++] = Lib.GROUP_BALANCE_OF;
        _commands[n++] = Lib.BALANCE_OF;
        _commands[n++] = Lib.BASE_BALANCE_OF;
        _commands[n++] = Lib.TOTAL_SUPPLY;
        _commands[n++] = Lib.BASE_TOTAL_SUPPLY;
        _commands[n++] = Lib.TRANSFER;
        _commands[n++] = Lib.BASE_TRANSFER;
        _commands[n++] = Lib.APPROVE;
        _commands[n++] = Lib.BASE_APPROVE;
        _commands[n++] = Lib.ALLOWANCE;
        _commands[n++] = Lib.BASE_ALLOWANCE;
        _commands[n++] = Lib.TRANSFER_FROM;
        _commands[n++] = Lib.BASE_TRANSFER_FROM;
    }

    function initializeLedgers_unchained() public onlyInitializing {
        enforceIsOwner();

        Lib.addLedger(address(this), "Scale", unicode"𝑆", 18);
    }

    function initializeLedgers() public initializer {
        initializeLedgers_unchained();
    }

    //==========
    // Metadata
    //==========
    function name(address addr_) public view returns (string memory) {
        return Lib.name(addr_);
    }

    function symbol(address addr_) public view returns (string memory) {
        return Lib.symbol(addr_);
    }

    function decimals(address addr_) public view returns (uint8) {
        return Lib.decimals(addr_);
    }

    function root(address addr_) public view returns (address) {
        return Lib.root(addr_);
    }

    function parent(address addr_) public view returns (address) {
        return Lib.parent(addr_);
    }

    function isGroup(address addr_) public view returns (bool) {
        return Lib.isGroup(addr_);
    }

    function subAccounts(address parent_) public view returns (address[] memory) {
        return Lib.subAccounts(parent_);
    }

    function hasSubAccount(address parent_) public view returns (bool) {
        return Lib.hasSubAccount(parent_);
    }

    function subAccountIndex(address addr_) public view returns (uint32) {
        return Lib.subAccountIndex(addr_);
    }

    //================
    // ERC20 Metadata
    //================
    function name() public view returns (string memory) {
        return Lib.name(address(this));
    }

    function symbol() public view returns (string memory) {
        return Lib.symbol(address(this));
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    //======================
    // Balances & Transfers
    //======================

    // Subaccount balances
    function balanceOf(address parent_, string memory subName_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toGroupAddress(parent_, subName_));
    }

    // Ledger account balances
    function balanceOf(address parent_, address owner_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(parent_, owner_));
    }

    // ERC20 compatibility
    function balanceOf(address owner_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(address(this), owner_));
    }

    function totalSupply(address token_) public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(token_, Lib.SUPPLY_ADDRESS));
    }

    // ERC20 compatibility
    function totalSupply() public view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(address(this), Lib.SUPPLY_ADDRESS));
    }

    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) public returns (bool) {
        return Lib.transfer(fromParent_, msg.sender, toParent_, to_, amount_, true);
    }

    // ERC20 compatibility
    function transfer(address to_, uint256 amount_) public returns (bool) {
        emit Lib.Transfer(msg.sender, to_, amount_);
        return Lib.transfer(address(this), msg.sender, address(this), to_, amount_, false);
    }

    function approve(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
        public
        returns (bool)
    {
        return Lib.approve(ownerParent_, msg.sender, spenderParent_, spender_, amount_, true);
    }

    // ERC20 compatibility
    function approve(address spender_, uint256 amount_) public returns (bool) {
        emit Lib.Approval(msg.sender, spender_, amount_);
        return Lib.approve(address(this), msg.sender, address(this), spender_, amount_, false);
    }

    function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
        public
        view
        returns (uint256)
    {
        return Lib.allowance(ownerParent_, owner_, spenderParent_, spender_);
    }

    // ERC20 compatibility
    function allowance(address owner_, address spender_) public view returns (uint256) {
        return Lib.allowance(address(this), owner_, address(this), spender_);
    }

    function transferFrom(
        address fromParent_,
        address from_,
        address spenderParent_,
        address toParent_,
        address to_,
        uint256 amount_
    ) public returns (bool) {
        return Lib.transferFrom(fromParent_, from_, spenderParent_, msg.sender, toParent_, to_, amount_, true);
    }

    // ERC20 compatibility
    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        return Lib.transferFrom(address(this), from_, address(this), msg.sender, address(this), to_, amount_, false);
    }
}
