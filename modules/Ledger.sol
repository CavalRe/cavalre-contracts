// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Module} from "./Module.sol";
import {Initializable} from "../utilities/Initializable.sol";
import {LedgerLib} from "../libraries/LedgerLib.sol";

import {Float, ILedger} from "../interfaces/ILedger.sol";

import {console} from "forge-std/src/console.sol";

contract ERC20Wrapper {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    address private immutable _router;
    address private immutable _token;
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

    constructor(address router_, address token_, string memory name_, string memory symbol_, uint8 decimals_) {
        _router = router_;
        _token = token_ == address(0) ? address(this) : token_;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    modifier routerOnly() {
        if (msg.sender != _router) revert ILedger.Unauthorized(msg.sender);
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
    // Supply / Balances (delegated to Ledger)
    // -------------------------------------------------------------------------

    function totalSupply() public view returns (uint256) {
        return ILedger(_router).totalSupply(_token);
    }

    function balanceOf(address account_) public view returns (uint256) {
        return ILedger(_router).balanceOf(_token, account_);
    }

    // -------------------------------------------------------------------------
    // Allowance (delegated to Ledger)
    // -------------------------------------------------------------------------

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return ILedger(_router).allowance(_token, owner_, spender_);
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        emit Approval(msg.sender, spender_, amount_);
        return ILedger(_router).approve(_token, msg.sender, spender_, amount_);
    }

    /// @notice Atomically increases `spender` allowance for `msg.sender`.
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool _ok) {
        uint256 _amount;
        (_ok, _amount) = ILedger(_router).increaseAllowance(_token, msg.sender, spender_, addedValue_);
        emit Approval(msg.sender, spender_, _amount);
    }

    /// @notice Atomically decreases `spender` allowance for `msg.sender`.
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool _ok) {
        uint256 _amount;
        (_ok, _amount) = ILedger(_router).decreaseAllowance(_token, msg.sender, spender_, subtractedValue_);
        emit Approval(msg.sender, spender_, _amount);
    }

    /// @notice Sets allowance safely even if a non-zero allowance already exists.
    /// If both current and desired are non-zero, sets to 0 first, then to `amount_`.
    function forceApprove(address spender_, uint256 amount_) public returns (bool) {
        emit Approval(msg.sender, spender_, amount_);
        return ILedger(_router).forceApprove(_token, msg.sender, spender_, amount_);
    }

    // -------------------------------------------------------------------------
    // Transfers (call back into Ledger)
    // -------------------------------------------------------------------------

    function transfer(address to_, uint256 amount_) public returns (bool) {
        emit Transfer(msg.sender, to_, amount_);
        console.log("ERC20Wrapper transfer called: ", msg.sender, to_, amount_);
        return ILedger(_router).transfer(_token, msg.sender, _token, to_, amount_, false);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        emit Transfer(from_, to_, amount_);
        return ILedger(_router).transferFrom(msg.sender, _token, from_, _token, to_, amount_, false);
    }

    // // -------------------------------------------------------------------------
    // // Mint / Burn (delegated to Ledger; emits zero-address Transfer per ERC-20)
    // // -------------------------------------------------------------------------

    function mint(address to_, uint256 amount_) public routerOnly {
        emit Transfer(address(0), to_, amount_);
    }

    function burn(address from_, uint256 amount_) public routerOnly {
        emit Transfer(from_, address(0), amount_);
    }

    // function emitTransfer(address from_, address to_, uint256 amount_) public {
    //     if (msg.sender != _router) revert ILedger.Unauthorized(msg.sender);

    //     emit Transfer(from_, to_, amount_);
    // }

    // function emitApproval(address owner_, address spender_, uint256 amount_) public {
    //     if (msg.sender != _router) revert ILedger.Unauthorized(msg.sender);

    //     emit Approval(owner_, spender_, amount_);
    // }
}

contract Ledger is Module, Initializable, ILedger {
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    uint8 internal immutable _decimals;

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Ledger.Initializable")) - 1)) & ~bytes32(uint256(0xff));

    function _initializableStorageSlot() internal pure override returns (bytes32) {
        return INITIALIZABLE_STORAGE;
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](38);
        _selectors[n++] = bytes4(keccak256("initializeLedger(string)"));
        _selectors[n++] = bytes4(keccak256("createWrappedToken(address)"));
        _selectors[n++] = bytes4(keccak256("createInternalToken(string,string,uint8,bool)"));
        _selectors[n++] = bytes4(keccak256("name(address)"));
        _selectors[n++] = bytes4(keccak256("symbol(address)"));
        _selectors[n++] = bytes4(keccak256("decimals(address)"));
        _selectors[n++] = bytes4(keccak256("root(address)"));
        _selectors[n++] = bytes4(keccak256("parent(address)"));
        _selectors[n++] = bytes4(keccak256("flags(address)"));
        _selectors[n++] = bytes4(keccak256("wrapper(address)"));
        _selectors[n++] = bytes4(keccak256("isGroup(address)"));
        _selectors[n++] = bytes4(keccak256("isCredit(address)"));
        _selectors[n++] = bytes4(keccak256("isInternal(address)"));
        _selectors[n++] = bytes4(keccak256("subAccounts(address)"));
        _selectors[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _selectors[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _selectors[n++] = bytes4(keccak256("totalSupply(address)"));
        _selectors[n++] = bytes4(keccak256("reserveAddress(address)"));
        _selectors[n++] = bytes4(keccak256("scaleAddress(address)"));
        _selectors[n++] = bytes4(keccak256("reserve(address)"));
        _selectors[n++] = bytes4(keccak256("scale(address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256,bool)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("approve(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("approve(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("increaseAllowance(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("increaseAllowance(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("decreaseAllowance(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("decreaseAllowance(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("forceApprove(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("forceApprove(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("allowance(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("transferFrom(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("transferFrom(address,address,address,address,address,uint256,bool)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,uint256)"));

        if (n != _selectors.length) revert InvalidCommandsLength(n);
    }

    function initializeLedger_unchained(string memory nativeTokenSymbol_) public onlyInitializing {
        enforceIsOwner();

        LedgerLib.addLedger(address(this), address(0), "Scale", "S", 18, false, true);

        // Add native token wrapper
        address token_ = LedgerLib.NATIVE_ADDRESS;
        if (!LedgerLib.isZeroAddress(token_) && token_ == LedgerLib.root(token_)) revert ILedger.DuplicateToken(token_);
        if (!LedgerLib.isValidString(nativeTokenSymbol_)) revert ILedger.InvalidString(nativeTokenSymbol_);
        address _wrapper = address(
            new ERC20Wrapper(
                address(this),
                token_,
                string(abi.encodePacked(nativeTokenSymbol_, " | CavalRe")),
                string(abi.encodePacked(nativeTokenSymbol_, ".cav")),
                18
            )
        );
        LedgerLib.addLedger(token_, _wrapper, nativeTokenSymbol_, nativeTokenSymbol_, 18, false, false);
    }

    function initializeLedger(string memory nativeTokenSymbol_) external initializer {
        initializeLedger_unchained(nativeTokenSymbol_);
    }

    function createWrappedToken(address token_) external {
        enforceIsOwner();

        LedgerLib.createWrappedToken(token_);
    }

    function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, bool isCredit_)
        external
        returns (address)
    {
        enforceIsOwner();

        return LedgerLib.createInternalToken(name_, symbol_, decimals_, isCredit_);
    }

    //==========
    // Metadata
    //==========
    function name(address addr_) external view returns (string memory) {
        return LedgerLib.name(addr_);
    }

    function symbol(address addr_) external view returns (string memory) {
        return LedgerLib.symbol(addr_);
    }

    function decimals(address addr_) external view returns (uint8) {
        return LedgerLib.decimals(addr_);
    }

    function root(address addr_) external view returns (address) {
        return LedgerLib.root(addr_);
    }

    function parent(address addr_) external view returns (address) {
        return LedgerLib.parent(addr_);
    }

    function flags(address addr_) external view returns (uint256) {
        return LedgerLib.flags(addr_);
    }

    function wrapper(address token_) external view returns (address) {
        return LedgerLib.wrapper(token_);
    }

    function isGroup(address addr_) external view returns (bool) {
        return LedgerLib.isGroup(addr_);
    }

    function isCredit(address addr_) external view returns (bool) {
        return LedgerLib.isCredit(addr_);
    }

    function isInternal(address addr_) external view returns (bool) {
        return LedgerLib.isInternal(addr_);
    }

    function subAccounts(address parent_) external view returns (address[] memory) {
        return LedgerLib.subAccounts(parent_);
    }

    function hasSubAccount(address parent_) external view returns (bool) {
        return LedgerLib.hasSubAccount(parent_);
    }

    function subAccountIndex(address parent_, address addr_) external view returns (uint32) {
        return LedgerLib.subAccountIndex(parent_, addr_);
    }

    //=========================
    // Balances & Valuations
    //=========================
    // Subaccount balances
    function balanceOf(address parent_, string memory subName_) external view returns (uint256) {
        return LedgerLib.balanceOf(LedgerLib.toGroupAddress(parent_, subName_));
    }

    // Ledger account balances
    function balanceOf(address parent_, address owner_) external view returns (uint256) {
        return LedgerLib.balanceOf(LedgerLib.toLedgerAddress(parent_, owner_));
    }

    function totalSupply(address token_) external view returns (uint256) {
        return LedgerLib.balanceOf(LedgerLib.toLedgerAddress(token_, LedgerLib.TOTAL_ADDRESS));
    }

    function reserveAddress(address token_) external view returns (address) {
        return LedgerLib.reserveAddress(token_);
    }

    function scaleAddress(address token_) external view returns (address) {
        return LedgerLib.scaleAddress(token_);
    }

    function reserve(address token_) external view returns (uint256) {
        return LedgerLib.reserve(token_);
    }

    function scale(address token_) external view returns (uint256) {
        return LedgerLib.scale(token_);
    }

    function price(address token_) external view returns (Float memory) {
        return LedgerLib.price(token_);
    }

    function totalValue(address token_) external view returns (Float memory) {
        return LedgerLib.totalValue(token_);
    }

    //===========
    // Transfers
    //===========

    function transfer(
        address fromParent_,
        address from_,
        address toParent_,
        address to_,
        uint256 amount_,
        bool emitEvent_
    ) external returns (bool) {
        if (msg.sender != LedgerLib.wrapper(LedgerLib.root(fromParent_))) revert ILedger.Unauthorized(msg.sender);
        return LedgerLib.transfer(fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }

    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external returns (bool) {
        return LedgerLib.transfer(fromParent_, msg.sender, toParent_, to_, amount_, true);
    }

    function approve(address ownerParent_, address owner_, address spender_, uint256 amount_) external returns (bool) {
        if (msg.sender != LedgerLib.root(ownerParent_)) revert ILedger.Unauthorized(msg.sender);
        return LedgerLib.approve(ownerParent_, owner_, spender_, amount_, true);
    }

    function approve(address ownerParent_, address spender_, uint256 amount_) external returns (bool) {
        return LedgerLib.approve(ownerParent_, msg.sender, spender_, amount_, true);
    }

    function increaseAllowance(address ownerParent_, address owner_, address spender_, uint256 addedValue_)
        external
        returns (bool _ok, uint256 _newAllowance)
    {
        if (msg.sender != LedgerLib.root(ownerParent_)) revert ILedger.Unauthorized(msg.sender);
        (_ok, _newAllowance) = LedgerLib.increaseAllowance(ownerParent_, owner_, spender_, addedValue_, true);
    }

    function increaseAllowance(address ownerParent_, address spender_, uint256 addedValue_)
        external
        returns (bool _ok)
    {
        (_ok,) = LedgerLib.increaseAllowance(ownerParent_, msg.sender, spender_, addedValue_, true);
    }

    function decreaseAllowance(address ownerParent_, address owner_, address spender_, uint256 subtractedValue_)
        external
        returns (bool _ok, uint256 _newAllowance)
    {
        if (msg.sender != LedgerLib.root(ownerParent_)) revert ILedger.Unauthorized(msg.sender);
        (_ok, _newAllowance) = LedgerLib.decreaseAllowance(ownerParent_, owner_, spender_, subtractedValue_, true);
    }

    function decreaseAllowance(address ownerParent_, address spender_, uint256 subtractedValue_)
        external
        returns (bool _ok)
    {
        (_ok,) = LedgerLib.decreaseAllowance(ownerParent_, msg.sender, spender_, subtractedValue_, true);
    }

    function forceApprove(address ownerParent_, address owner_, address spender_, uint256 amount_)
        external
        returns (bool)
    {
        if (msg.sender != LedgerLib.root(ownerParent_)) revert ILedger.Unauthorized(msg.sender);
        return LedgerLib.forceApprove(ownerParent_, owner_, spender_, amount_, true);
    }

    function forceApprove(address ownerParent_, address spender_, uint256 amount_) external returns (bool) {
        return LedgerLib.forceApprove(ownerParent_, msg.sender, spender_, amount_, true);
    }

    function allowance(address ownerParent_, address owner_, address spender_) external view returns (uint256) {
        return LedgerLib.allowance(ownerParent_, owner_, spender_);
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
        if (msg.sender != LedgerLib.root(fromParent_)) revert ILedger.Unauthorized(msg.sender);
        return LedgerLib.transferFrom(spender_, fromParent_, from_, toParent_, to_, amount_, emitEvent_);
    }

    function transferFrom(address fromParent_, address from_, address toParent_, address to_, uint256 amount_)
        external
        returns (bool)
    {
        return LedgerLib.transferFrom(msg.sender, fromParent_, from_, toParent_, to_, amount_, true);
    }

    function wrap(address token_, uint256 amount_) external payable {
        LedgerLib.wrap(token_, amount_);
    }

    function unwrap(address token_, uint256 amount_) external payable {
        LedgerLib.unwrap(token_, amount_);
    }
}
