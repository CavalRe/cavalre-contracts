// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedger {
    // ─────────────────────────────────────────────────────────────────────────────
    // Initializers
    // ─────────────────────────────────────────────────────────────────────────────
    function initializeLedger(string memory name, string memory symbol) external;

    // ─────────────────────────────────────────────────────────────────────────────
    // Metadata (by arbitrary address)
    // ─────────────────────────────────────────────────────────────────────────────
    function name(address addr) external view returns (string memory);

    function symbol(address addr) external view returns (string memory);

    function decimals(address addr) external view returns (uint8);

    function nativeName() external view returns (string memory);

    function nativeSymbol() external view returns (string memory);

    // ─────────────────────────────────────────────────────────────────────────────
    // Tree Manipulation
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

    function createToken(string memory name, string memory symbol, uint8 decimals, bool isCredit)
        external
        returns (address token, uint256 flags);

    function createWrapper(address token) external returns (address wrapper, uint256 flags);

    function removeSubAccountGroup(address parent, string memory name) external returns (address);

    function removeSubAccountGroup(address parent, address addr) external returns (address);

    function removeSubAccount(address parent, string memory name) external returns (address);

    function removeSubAccount(address parent, address child) external returns (address);

    // ─────────────────────────────────────────────────────────────────────────────
    // Balances & Valuations
    // ─────────────────────────────────────────────────────────────────────────────
    function debitBalanceOf(address parent, address owner) external view returns (uint256);

    function creditBalanceOf(address parent, address owner) external view returns (uint256);

    function balanceOf(address parent, address owner) external view returns (uint256);

    function totalSupply(address token) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // Transfers (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transfer(address fromParent, address from, address toParent, address to, uint256 amount)
        external
        returns (address root, uint256 fromFlags, uint256 toFlags);

    function transfer(address fromParent, address toParent, address to, uint256 amount)
        external
        returns (address root, uint256 fromFlags, uint256 toFlags);

    // ─────────────────────────────────────────────────────────────────────────────
    function wrap(address token_, uint256 amount_)
        external
        payable
        returns (address token, uint256 fromFlags, uint256 toFlags);

    function unwrap(address token_, uint256 amount_)
        external
        payable
        returns (address token, uint256 fromFlags, uint256 toFlags);

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
    error InvalidSubAccount(address addr, bool isCredit);
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
    event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
    event SubAccountAdded(address indexed root, address indexed parent, address addr, bool isCredit);
    event SubAccountGroupAdded(address indexed root, address indexed parent, string subName, bool isCredit);
    event SubAccountRemoved(address indexed root, address indexed parent, address addr);
    event SubAccountGroupRemoved(address indexed root, address indexed parent, address addr);

    // ─────────────────────────────────────────────────────────────────────────────
    // Standard ERC-20 events (emitted through library/wrapper)
    // ─────────────────────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
