// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float} from "../libraries/FloatLib.sol";

interface ILedger {
    // ─────────────────────────────────────────────────────────────────────────────
    // Initializers
    // ─────────────────────────────────────────────────────────────────────────────
    function initializeLedger(string memory nativeTokenSymbol) external;
    // ─────────────────────────────────────────────────────────────────────────────
    // Metadata (by arbitrary address)
    // ─────────────────────────────────────────────────────────────────────────────
    function name(address addr) external view returns (string memory);
    function symbol(address addr) external view returns (string memory);
    function decimals(address addr) external view returns (uint8);

    // ─────────────────────────────────────────────────────────────────────────────
    // Tree navigation
    // ─────────────────────────────────────────────────────────────────────────────
    function root(address addr) external view returns (address);
    function parent(address addr) external view returns (address);
    function flags(address addr) external view returns (uint256);
    function wrapper(address token) external view returns (address);
    function isGroup(address addr) external view returns (bool);
    function isCredit(address addr) external view returns (bool);
    function isInternal(address addr) external view returns (bool);
    function subAccounts(address parent) external view returns (address[] memory);
    function hasSubAccount(address parent) external view returns (bool);
    function subAccountIndex(address parent, address addr) external view returns (uint32);

    // ─────────────────────────────────────────────────────────────────────────────
    // Tree Manipulation
    // ─────────────────────────────────────────────────────────────────────────────
    function addSubAccountGroup(address parent, string memory name, bool isCredit) external returns (address);
    function addSubAccount(address parent, address addr, string memory name, bool isInternal)
        external
        returns (address);
    function addLedger(
        address root,
        address wrapper,
        string memory name,
        string memory symbol,
        uint8 decimals,
        bool isCredit,
        bool isInternal
    ) external;
    function createWrappedToken(address token) external;
    function createInternalToken(string memory name, string memory symbol, uint8 decimals, bool isCredit)
        external
        returns (address);
    function removeSubAccountGroup(address parent, string memory name) external returns (address);
    function removeSubAccount(address parent, address child) external returns (address);

    // ─────────────────────────────────────────────────────────────────────────────
    // Balances & Valuations
    // ─────────────────────────────────────────────────────────────────────────────
    function balanceOf(address parent, string memory subName) external view returns (uint256);
    function balanceOf(address parent, address owner) external view returns (uint256);
    function totalSupply(address token) external view returns (uint256);
    function reserveAddress(address token) external view returns (address);
    function scaleAddress(address token) external view returns (address);
    function reserve(address token) external view returns (uint256);
    function scale(address token) external view returns (uint256);
    function price(address token) external view returns (Float);
    function totalValue(address token) external view returns (Float);

    // ─────────────────────────────────────────────────────────────────────────────
    // Transfers (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transfer(address fromParent, address from, address toParent, address to, uint256 amount, bool emitEvent)
        external
        returns (bool);
    function transfer(address fromParent, address toParent, address to, uint256 amount) external returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    function wrap(address token_, uint256 amount_) external payable;
    function unwrap(address token_, uint256 amount_) external payable;

    // ─────────────────────────────────────────────────────────────────────────────
    // Custom errors
    // ─────────────────────────────────────────────────────────────────────────────
    error DifferentRoots(address a, address b);
    error DuplicateSubAccount(address sub);
    error DuplicateToken(address token);
    error HasBalance(address addr);
    error HasSubAccount(address addr);
    error IncorrectAmount(uint256 received, uint256 expected);
    error InsufficientAllowance(address ownerParent, address owner, address spender, uint256 current, uint256 amount);
    error InsufficientBalance(address token, address parent, address account, uint256 amount);
    error InvalidAddress(address absoluteAddress);
    error InvalidDecimals(uint8 decimals);
    error InvalidAccountGroup(address groupAddress);
    error InvalidLedgerAccount(address ledgerAddress);
    error InvalidReallocation(address token, int256 reallocation);
    error InvalidString(string symbol);
    error InvalidSubAccount(address addr, bool isCredit);
    error InvalidSubAccountGroup(string subName, bool isCredit);
    error InvalidSubAccountIndex(uint256 index);
    error InvalidToken(address token, string name, string symbol, uint8 decimals);
    error MaxDepthExceeded();
    error NotCredit(string name);
    error SubAccountNotFound(address addr);
    error SubAccountGroupNotFound(string subName);
    error Unauthorized(address user);
    error ZeroAddress();
    error ZeroReserve(address addr);
    error ZeroScale(address addr);

    // ─────────────────────────────────────────────────────────────────────────────
    // Events (Double-entry journal)
    // Walks up from (parent, addr) to the root without updating the root.
    // Emits once on success with (token=root, parent, addr, amount).
    //  - token  : actual token root (for fast indexing/filtering)
    //  - parent : fixed parent group of ledger account
    //  - account: exact ledger account (no children by design)
    // ─────────────────────────────────────────────────────────────────────────────
    event BalanceUpdate(address indexed token, address indexed parent, address indexed account, uint256 newBalance);
    event Credit(address indexed token, address indexed parent, address indexed account, uint256 value);
    event Debit(address indexed token, address indexed parent, address indexed account, uint256 value);
    event InternalApproval(address indexed ownerParent, address indexed owner, address indexed spender, uint256 value);
    event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
    event SubAccountAdded(address indexed root, address indexed parent, address addr, bool isCredit);
    event SubAccountGroupAdded(address indexed root, address indexed parent, string subName, bool isCredit);
    event SubAccountRemoved(address indexed root, address indexed parent, address addr);
    event SubAccountGroupRemoved(address indexed root, address indexed parent, string subName);

    // ─────────────────────────────────────────────────────────────────────────────
    // Standard ERC-20 events (emitted through library/wrapper)
    // ─────────────────────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
