// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Module} from "./Module.sol";
import {Initializable} from "../utilities/Initializable.sol";
import {LedgersLib as Lib} from "../libraries/LedgersLib.sol";

import {ILedgers} from "../interfaces/ILedgers.sol";

import {console} from "forge-std/src/console.sol";

contract ERC20Wrapper {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    address private immutable _router;
    string private _name;
    string private _symbol;
    uint8 public immutable _decimals;

    // -------------------------------------------------------------------------
    // Events (ERC-20 standard)
    // -------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // -------------------------------------------------------------------------
    // Init
    // -------------------------------------------------------------------------

    constructor(address router_, string memory name_, string memory symbol_, uint8 decimals_) {
        _router = router_;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    modifier routerOnly() {
        if (msg.sender != _router) revert ILedgers.Unauthorized(msg.sender);
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

    // -------------------------------------------------------------------------
    // Supply / Balances (delegated to Ledgers)
    // -------------------------------------------------------------------------

    function totalSupply() public view returns (uint256) {
        return ILedgers(_router).totalSupply(address(this));
    }

    function balanceOf(address account_) public view returns (uint256) {
        return ILedgers(_router).balanceOf(address(this), account_);
    }

    // -------------------------------------------------------------------------
    // Allowance (delegated to Ledgers)
    // -------------------------------------------------------------------------

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return ILedgers(_router).allowance(address(this), owner_, spender_);
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        emit Approval(msg.sender, spender_, amount_);
        return ILedgers(_router).approve(address(this), msg.sender, spender_, amount_);
    }

    /// @notice Atomically increases `spender` allowance for `msg.sender`.
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool _ok) {
        uint256 _amount;
        (_ok, _amount) = ILedgers(_router).increaseAllowance(address(this), msg.sender, spender_, addedValue_);
        emit Approval(msg.sender, spender_, _amount);
    }

    /// @notice Atomically decreases `spender` allowance for `msg.sender`.
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool _ok) {
        uint256 _amount;
        (_ok, _amount) = ILedgers(_router).decreaseAllowance(address(this), msg.sender, spender_, subtractedValue_);
        emit Approval(msg.sender, spender_, _amount);
    }

    /// @notice Sets allowance safely even if a non-zero allowance already exists.
    /// If both current and desired are non-zero, sets to 0 first, then to `amount_`.
    function forceApprove(address spender_, uint256 amount_) public returns (bool) {
        emit Approval(msg.sender, spender_, amount_);
        return ILedgers(_router).forceApprove(address(this), msg.sender, spender_, amount_);
    }

    // -------------------------------------------------------------------------
    // Transfers (call back into Ledgers)
    // -------------------------------------------------------------------------

    function transfer(address to_, uint256 amount_) public returns (bool) {
        emit Transfer(msg.sender, to_, amount_);
        return ILedgers(_router).transfer(address(this), msg.sender, address(this), to_, amount_, false);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        emit Transfer(from_, to_, amount_);
        return ILedgers(_router).transferFrom(msg.sender, address(this), from_, address(this), to_, amount_, false);
    }

    // // -------------------------------------------------------------------------
    // // Mint / Burn (delegated to Ledgers; emits zero-address Transfer per ERC-20)
    // // -------------------------------------------------------------------------

    function mint(address to_, uint256 amount_) public routerOnly {
        emit Transfer(address(0), to_, amount_);
    }

    function burn(address from_, uint256 amount_) public routerOnly {
        emit Transfer(from_, address(0), amount_);
    }

    // function emitTransfer(address from_, address to_, uint256 amount_) public {
    //     if (msg.sender != _router) revert ILedgers.Unauthorized(msg.sender);

    //     emit Transfer(from_, to_, amount_);
    // }

    // function emitApproval(address owner_, address spender_, uint256 amount_) public {
    //     if (msg.sender != _router) revert ILedgers.Unauthorized(msg.sender);

    //     emit Approval(owner_, spender_, amount_);
    // }
}

contract Ledgers is Module, Initializable, ILedgers {
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    uint8 internal immutable _decimals;

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledgers.Initializable")) - 1)) & ~bytes32(uint256(0xff));

    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    function commands() external pure virtual override returns (bytes4[] memory _commands) {
        uint256 n;
        _commands = new bytes4[](29);
        _commands[n++] = bytes4(keccak256("initializeLedgers()"));
        _commands[n++] = bytes4(keccak256("createToken(string,string,uint8)"));
        _commands[n++] = bytes4(keccak256("name(address)"));
        _commands[n++] = bytes4(keccak256("symbol(address)"));
        _commands[n++] = bytes4(keccak256("decimals(address)"));
        _commands[n++] = bytes4(keccak256("root(address)"));
        _commands[n++] = bytes4(keccak256("parent(address)"));
        _commands[n++] = bytes4(keccak256("isGroup(address)"));
        _commands[n++] = bytes4(keccak256("isCredit(address)"));
        _commands[n++] = bytes4(keccak256("isInternal(address)"));
        _commands[n++] = bytes4(keccak256("subAccounts(address)"));
        _commands[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _commands[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _commands[n++] = bytes4(keccak256("totalSupply(address)"));
        _commands[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256,bool)"));
        _commands[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approve(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approve(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("increaseAllowance(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("increaseAllowance(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("decreaseAllowance(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("decreaseAllowance(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("forceApprove(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("forceApprove(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("allowance(address,address,address)"));
        _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,address,uint256,bool)"));

        if (n != _commands.length) revert InvalidCommandsLength(n);
    }

    function initializeLedgers_unchained() public onlyInitializing {
        enforceIsOwner();

        Lib.addLedger(address(this), "Scale", "S", 18, true);
    }

    function initializeLedgers() external initializer {
        initializeLedgers_unchained();
    }

    function createToken(string memory name_, string memory symbol_, uint8 decimals_) external returns (address) {
        enforceIsOwner();

        return Lib.createToken(name_, symbol_, decimals_);
    }

    //==========
    // Metadata
    //==========
    function name(address addr_) external view returns (string memory) {
        return Lib.name(addr_);
    }

    function symbol(address addr_) external view returns (string memory) {
        return Lib.symbol(addr_);
    }

    function decimals(address addr_) external view returns (uint8) {
        return Lib.decimals(addr_);
    }

    function root(address addr_) external view returns (address) {
        return Lib.root(addr_);
    }

    function parent(address addr_) external view returns (address) {
        return Lib.parent(addr_);
    }

    function isGroup(address addr_) external view returns (bool) {
        return Lib.isGroup(addr_);
    }

    function isCredit(address addr_) external view returns (bool) {
        return Lib.isCredit(addr_);
    }

    function isInternal(address addr_) external view returns (bool) {
        return Lib.isInternal(addr_);
    }

    function subAccounts(address parent_) external view returns (address[] memory) {
        return Lib.subAccounts(parent_);
    }

    function hasSubAccount(address parent_) external view returns (bool) {
        return Lib.hasSubAccount(parent_);
    }

    function subAccountIndex(address parent_, address addr_) external view returns (uint32) {
        return Lib.subAccountIndex(parent_, addr_);
    }

    //======================
    // Balances & Transfers
    //======================

    // Subaccount balances
    function balanceOf(address parent_, string memory subName_) external view returns (uint256) {
        return Lib.balanceOf(Lib.toGroupAddress(parent_, subName_));
    }

    // Ledger account balances
    function balanceOf(address parent_, address owner_) external view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(parent_, owner_));
    }

    function totalSupply(address token_) external view returns (uint256) {
        return Lib.balanceOf(Lib.toLedgerAddress(token_, Lib.SUPPLY_ADDRESS));
    }

    function transfer(
        address fromParent_,
        address from_,
        address toParent_,
        address to_,
        uint256 amount_,
        bool emitEvent_
    ) external returns (bool) {
        if (msg.sender != Lib.root(fromParent_)) revert ILedgers.Unauthorized(msg.sender);
        return Lib.transfer(fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }

    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external returns (bool) {
        return Lib.transfer(fromParent_, msg.sender, toParent_, to_, amount_, true);
    }

    function approve(address ownerParent_, address owner_, address spender_, uint256 amount_) external returns (bool) {
        if (msg.sender != Lib.root(ownerParent_)) revert ILedgers.Unauthorized(msg.sender);
        return Lib.approve(ownerParent_, owner_, spender_, amount_, true);
    }

    function approve(address ownerParent_, address spender_, uint256 amount_) external returns (bool) {
        return Lib.approve(ownerParent_, msg.sender, spender_, amount_, true);
    }

    function increaseAllowance(address ownerParent_, address owner_, address spender_, uint256 addedValue_)
        external
        returns (bool _ok, uint256 _newAllowance)
    {
        if (msg.sender != Lib.root(ownerParent_)) revert ILedgers.Unauthorized(msg.sender);
        (_ok, _newAllowance) = Lib.increaseAllowance(ownerParent_, owner_, spender_, addedValue_, true);
    }

    function increaseAllowance(address ownerParent_, address spender_, uint256 addedValue_)
        external
        returns (bool _ok)
    {
        (_ok,) = Lib.increaseAllowance(ownerParent_, msg.sender, spender_, addedValue_, true);
    }

    function decreaseAllowance(address ownerParent_, address owner_, address spender_, uint256 subtractedValue_)
        external
        returns (bool _ok, uint256 _newAllowance)
    {
        if (msg.sender != Lib.root(ownerParent_)) revert ILedgers.Unauthorized(msg.sender);
        (_ok, _newAllowance) = Lib.decreaseAllowance(ownerParent_, owner_, spender_, subtractedValue_, true);
    }

    function decreaseAllowance(address ownerParent_, address spender_, uint256 subtractedValue_)
        external
        returns (bool _ok)
    {
        (_ok,) = Lib.decreaseAllowance(ownerParent_, msg.sender, spender_, subtractedValue_, true);
    }

    function forceApprove(address ownerParent_, address owner_, address spender_, uint256 amount_)
        external
        returns (bool)
    {
        if (msg.sender != Lib.root(ownerParent_)) revert ILedgers.Unauthorized(msg.sender);
        return Lib.forceApprove(ownerParent_, owner_, spender_, amount_, true);
    }

    function forceApprove(address ownerParent_, address spender_, uint256 amount_) external returns (bool) {
        return Lib.forceApprove(ownerParent_, msg.sender, spender_, amount_, true);
    }

    function allowance(address ownerParent_, address owner_, address spender_) external view returns (uint256) {
        return Lib.allowance(ownerParent_, owner_, spender_);
    }

    function transferFrom(
        address spender_,
        address fromParent_,
        address from_,
        address toParent_,
        address to_,
        uint256 amount_,
        bool emitEvent_
    ) external returns (bool) {
        if (msg.sender != Lib.root(fromParent_)) revert ILedgers.Unauthorized(msg.sender);
        return Lib.transferFrom(spender_, fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }

    function transferFrom(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
        external
        returns (bool)
    {
        return Lib.transferFrom(msg.sender, fromParent_, from_, toParent_, to_, amount_, true);
    }
}
