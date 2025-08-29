// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Module} from "./Module.sol";
import {Initializable} from "../utilities/Initializable.sol";
import {LedgersLib as Lib} from "../libraries/LedgersLib.sol";

import {ILedgers} from "../interfaces/ILedgers.sol";

contract ERC20Wrapper {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    address private immutable _ledgers;
    string private _name; // kept for constructor parity; getters read from Ledgers
    string private _symbol; // kept for constructor parity; getters read from Ledgers
    uint8 public immutable _decimals;

    // -------------------------------------------------------------------------
    // Events (ERC-20 standard)
    // -------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // -------------------------------------------------------------------------
    // Init
    // -------------------------------------------------------------------------

    constructor(address ledgers_, string memory name_, string memory symbol_, uint8 decimals_) {
        _ledgers = ledgers_;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    // -------------------------------------------------------------------------
    // Metadata (delegated to Ledgers)
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
        return ILedgers(_ledgers).totalSupply(address(this));
    }

    function balanceOf(address account_) public view returns (uint256) {
        return ILedgers(_ledgers).balanceOf(address(this), account_);
    }

    // -------------------------------------------------------------------------
    // Allowance (delegated to Ledgers)
    // -------------------------------------------------------------------------

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return ILedgers(_ledgers).allowance(address(this), owner_, address(this), spender_);
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        emit Approval(msg.sender, spender_, amount_);
        return ILedgers(_ledgers).approveWrapper(address(this), msg.sender, spender_, amount_);
    }

    /// @notice Atomically increases `spender` allowance for `msg.sender`.
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool _ok) {
        uint256 _amount;
        (_ok, _amount) = ILedgers(_ledgers).increaseAllowanceWrapper(address(this), msg.sender, spender_, addedValue_);
        emit Approval(msg.sender, spender_, _amount);
    }

    /// @notice Atomically decreases `spender` allowance for `msg.sender`.
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool _ok) {
        uint256 _amount;
        (_ok, _amount) =
            ILedgers(_ledgers).decreaseAllowanceWrapper(address(this), msg.sender, spender_, subtractedValue_);
        emit Approval(msg.sender, spender_, _amount);
    }

    /// @notice Sets allowance safely even if a non-zero allowance already exists.
    /// If both current and desired are non-zero, sets to 0 first, then to `amount_`.
    function forceApprove(address spender_, uint256 amount_) public returns (bool) {
        emit Approval(msg.sender, spender_, amount_);
        return ILedgers(_ledgers).forceApproveWrapper(address(this), msg.sender, spender_, amount_);
    }

    // -------------------------------------------------------------------------
    // Transfers (delegated to Ledgers)
    // -------------------------------------------------------------------------

    function transfer(address to_, uint256 amount_) public returns (bool) {
        emit Transfer(msg.sender, to_, amount_);
        return ILedgers(_ledgers).transferWrapper(address(this), msg.sender, to_, amount_);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        emit Transfer(from_, to_, amount_);
        return ILedgers(_ledgers).transferFromWrapper(address(this), from_, msg.sender, to_, amount_);
    }

    // -------------------------------------------------------------------------
    // Mint / Burn (delegated to Ledgers; emits zero-address Transfer per ERC-20)
    // -------------------------------------------------------------------------

    function mint(address to_, uint256 amount_) public returns (bool) {
        emit Transfer(address(0), to_, amount_);
        return ILedgers(_ledgers).mintWrapper(address(this), to_, amount_);
    }

    function burn(address from_, uint256 amount_) public returns (bool) {
        emit Transfer(from_, address(0), amount_);
        return ILedgers(_ledgers).burnWrapper(address(this), from_, amount_);
    }
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
        _commands = new bytes4[](23);
        _commands[n++] = bytes4(keccak256("initializeLedgers()"));
        _commands[n++] = bytes4(keccak256("name(address)"));
        _commands[n++] = bytes4(keccak256("symbol(address)"));
        _commands[n++] = bytes4(keccak256("decimals(address)"));
        _commands[n++] = bytes4(keccak256("root(address)"));
        _commands[n++] = bytes4(keccak256("parent(address)"));
        _commands[n++] = bytes4(keccak256("isGroup(address)"));
        _commands[n++] = bytes4(keccak256("subAccounts(address)"));
        _commands[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _commands[n++] = bytes4(keccak256("subAccountIndex(address)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _commands[n++] = bytes4(keccak256("totalSupply(address)"));
        _commands[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approve(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("allowance(address,address,address,address)"));
        _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approveWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("increaseAllowanceWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("decreaseAllowanceWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("forceApproveWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("transferWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("transferFromWrapper(address,address,address,address,address,uint256)"));

        if (n != _commands.length) revert InvalidCommandsLength(n);
    }

    function initializeLedgers_unchained() public onlyInitializing {
        enforceIsOwner();

        Lib.addLedger(address(this), "Scale", unicode"𝑆", 18);
    }

    function initializeLedgers() external initializer {
        initializeLedgers_unchained();
    }

    function createToken(string memory name_, string memory symbol_, uint8 decimals_) external returns (address) {
        enforceIsOwner();

        address token = address(new ERC20Wrapper(address(this), name_, symbol_, decimals_));
        Lib.addLedger(token, name_, symbol_, decimals_);
        return token;
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

    function subAccounts(address parent_) external view returns (address[] memory) {
        return Lib.subAccounts(parent_);
    }

    function hasSubAccount(address parent_) external view returns (bool) {
        return Lib.hasSubAccount(parent_);
    }

    function subAccountIndex(address addr_) external view returns (uint32) {
        return Lib.subAccountIndex(addr_);
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

    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external returns (bool) {
        return Lib.transfer(fromParent_, msg.sender, toParent_, to_, amount_, true);
    }

    function approve(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
        external
        returns (bool)
    {
        return Lib.approve(ownerParent_, msg.sender, spenderParent_, spender_, amount_, true);
    }

    function increaseAllowance(address ownerParent_, address spenderParent_, address spender_, uint256 addedValue_)
        external
        returns (bool _ok)
    {
        (_ok,) = Lib.increaseAllowance(ownerParent_, msg.sender, spenderParent_, spender_, addedValue_, true);
    }

    function decreaseAllowance(address ownerParent_, address spenderParent_, address spender_, uint256 subtractedValue_)
        external
        returns (bool _ok)
    {
        (_ok,) = Lib.decreaseAllowance(ownerParent_, msg.sender, spenderParent_, spender_, subtractedValue_, true);
    }

    function forceApprove(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
        external
        returns (bool)
    {
        return Lib.forceApprove(ownerParent_, msg.sender, spenderParent_, spender_, amount_, true);
    }

    function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
        external
        view
        returns (uint256)
    {
        return Lib.allowance(ownerParent_, owner_, spenderParent_, spender_);
    }

    function transferFrom(
        address fromParent_,
        address from_,
        address spenderParent_,
        address toParent_,
        address to_,
        uint256 amount_
    ) external returns (bool) {
        return Lib.transferFrom(fromParent_, from_, spenderParent_, msg.sender, toParent_, to_, amount_, true);
    }

    // //=================
    // // ERC20 for Scale
    // //=================
    // function name() external view returns (string memory) {
    //     return Lib.name(address(this));
    // }

    // function symbol() external view returns (string memory) {
    //     return Lib.symbol(address(this));
    // }

    // function decimals() external view returns (uint8) {
    //     return _decimals;
    // }

    // function balanceOf(address owner_) external view returns (uint256) {
    //     return Lib.balanceOf(Lib.toLedgerAddress(address(this), owner_));
    // }

    // function totalSupply() external view returns (uint256) {
    //     return Lib.balanceOf(Lib.toLedgerAddress(address(this), Lib.SUPPLY_ADDRESS));
    // }

    // function transfer(address to_, uint256 amount_) external returns (bool) {
    //     emit ILedgers.Transfer(msg.sender, to_, amount_);
    //     return Lib.transfer(address(this), msg.sender, address(this), to_, amount_, false);
    // }

    // function approve(address spender_, uint256 amount_) external returns (bool) {
    //     emit ILedgers.Approval(msg.sender, spender_, amount_);
    //     return Lib.approve(address(this), msg.sender, address(this), spender_, amount_, false);
    // }

    // function allowance(address owner_, address spender_) external view returns (uint256) {
    //     return Lib.allowance(address(this), owner_, address(this), spender_);
    // }

    // function transferFrom(address from_, address to_, uint256 amount_) external returns (bool) {
    //     return Lib.transferFrom(address(this), from_, address(this), msg.sender, address(this), to_, amount_, false);
    // }

    //=======================
    // ERC20 Wrapper Helpers
    //=======================
    function approveWrapper(address token_, address owner_, address spender_, uint256 amount_)
        external
        returns (bool)
    {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.approve(token_, owner_, token_, spender_, amount_, false);
    }

    function increaseAllowanceWrapper(address token_, address owner_, address spender_, uint256 addedValue_)
        external
        returns (bool, uint256)
    {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.increaseAllowance(token_, owner_, token_, spender_, addedValue_, false);
    }

    function decreaseAllowanceWrapper(address token_, address owner_, address spender_, uint256 subtractedValue_)
        external
        returns (bool, uint256)
    {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.decreaseAllowance(token_, owner_, token_, spender_, subtractedValue_, false);
    }

    function forceApproveWrapper(address token_, address owner_, address spender_, uint256 amount_)
        external
        returns (bool)
    {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.forceApprove(token_, owner_, token_, spender_, amount_, false);
    }

    function transferWrapper(address token_, address from_, address to_, uint256 amount_) external returns (bool) {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.transfer(token_, from_, token_, to_, amount_, false);
    }

    function mintWrapper(address token_, address to_, uint256 amount_) external returns (bool) {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.transfer(token_, Lib.SUPPLY_ADDRESS, token_, to_, amount_, true);
    }

    function burnWrapper(address token_, address from_, uint256 amount_) external returns (bool) {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.transfer(token_, from_, token_, Lib.SUPPLY_ADDRESS, amount_, true);
    }

    function transferFromWrapper(address token_, address from_, address spender_, address to_, uint256 amount_)
        external
        returns (bool)
    {
        if (msg.sender != token_) revert ILedgers.Unauthorized(msg.sender);
        return Lib.transferFrom(token_, from_, token_, spender_, token_, to_, amount_, false);
    }
}
