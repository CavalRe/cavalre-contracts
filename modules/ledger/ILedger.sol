// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedger {
    // ─────────────────────────────────────────────────────────────────────────────
    // Initializers
    // ─────────────────────────────────────────────────────────────────────────────
    function initializeLedger(string memory name, string memory symbol) external;

    // ─────────────────────────────────────────────────────────────────────────────
    // TreeView Manipulation
    // ─────────────────────────────────────────────────────────────────────────────
    function addSubAccountGroup(address parent, string memory name, bool isCredit)
        external
        returns (address addr, uint256 flags);

    function addSubAccountGroup(address parent, address addr, string memory name, bool isCredit)
        external
        returns (address subAccount, uint256 flags);

    /// @param isCredit True for credit-side account, false for debit-side in the double-entry tree.
    function addSubAccount(address parent, string memory name, bool isCredit)
        external
        returns (address addr, uint256 flags);

    /// @param isCredit True for credit-side account, false for debit-side in the double-entry tree.
    function addSubAccount(address parent, address addr, string memory name, bool isCredit)
        external
        returns (address subAccount, uint256 flags);

    function addNativeToken() external returns (uint256 flags);

    function addExternalToken(address token) external returns (uint256 flags);

    function createInternalToken(string memory name, string memory symbol, uint8 decimals)
        external
        returns (address token, uint256 flags);

    function createClaimToken(string memory name, string memory symbol, uint8 decimals, address parent, address addr)
        external
        returns (address token, uint256 flags);

    function removeSubAccountGroup(address parent, string memory name) external returns (address);

    function removeSubAccountGroup(address parent, address addr) external returns (address);

    function removeSubAccount(address parent, string memory name) external returns (address);

    function removeSubAccount(address parent, address child) external returns (address);

    // ─────────────────────────────────────────────────────────────────────────────
    // Transfers (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transfer(address fromParent, address from, address toParent, address to, uint256 amount) external;

    function transfer(address fromParent, address toParent, address to, uint256 amount) external;

    // ─────────────────────────────────────────────────────────────────────────────
    function wrap(address token_, uint256 amount_)
        external
        payable
        returns (address token, bool fromIsCredit, bool toIsCredit);

    function unwrap(address token_, uint256 amount_)
        external
        payable
        returns (address token, bool fromIsCredit, bool toIsCredit);

    function handleNative() external payable;

    // ─────────────────────────────────────────────────────────────────────────────
    // Custom errors
    // ─────────────────────────────────────────────────────────────────────────────
    error DifferentRoots(address a, address b);
    error DuplicateToken(address token);
    error DuplicateWrapper(address token);
    error HasBalance(address addr);
    error HasSubAccount(address addr);
    error IncorrectAmount(uint256 received, uint256 expected);
    error InsufficientAllowance(address ownerParent, address owner, address spender, uint256 current, uint256 amount);
    error InsufficientBalance(address token, address parent, address account, uint256 amount);
    error InvalidAddress(address absoluteAddress);
    error InvalidDecimals(uint8 decimals);
    error InvalidAccountGroup();
    error InvalidLedgerAccount(address ledgerAddress);
    error LedgerUninitialized();
    error InvalidString(string symbol);
    error InvalidSubAccount(address addr);
    error InvalidSubAccountGroup(string subName, bool isCredit);
    error InvalidSubAccountIndex(uint256 index);
    error InvalidToken(address token, string name, string symbol, uint8 decimals);
    error NativeTransferFailed();
    error SubAccountNotFound(address addr);
    error SubAccountGroupNotFound(address addr);
    error Unauthorized(address user);
    error ZeroDepth();
    error ZeroAddress();

    // ─────────────────────────────────────────────────────────────────────────────
    // Events
    event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
    event SubAccountAdded(address indexed root, address indexed parent, address addr, bool isCredit);
    event SubAccountGroupAdded(address indexed root, address indexed parent, string subName, bool isCredit);
    event SubAccountRemoved(address indexed root, address indexed parent, address addr);
    event SubAccountGroupRemoved(address indexed root, address indexed parent, address addr);
    event Credit(address indexed root, address indexed account, uint256 amount, uint256 balance);
    event Debit(address indexed root, address indexed account, uint256 amount, uint256 balance);

    // ─────────────────────────────────────────────────────────────────────────────
    // Standard ERC-20 events (emitted through library/wrapper)
    // ─────────────────────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
