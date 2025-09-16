// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILedgers {
    // ─────────────────────────────────────────────────────────────────────────────
    // Initializers
    // ─────────────────────────────────────────────────────────────────────────────
    function initializeLedgers() external;
    function createToken(string memory name, string memory symbol, uint8 decimals) external returns (address);

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
    function isGroup(address addr) external view returns (bool);
    function isCredit(address addr) external view returns (bool);
    function isInternal(address addr) external view returns (bool);
    function subAccounts(address parent) external view returns (address[] memory);
    function hasSubAccount(address parent) external view returns (bool);
    function subAccountIndex(address parent, address addr) external view returns (uint32);

    // ─────────────────────────────────────────────────────────────────────────────
    // Balances
    // ─────────────────────────────────────────────────────────────────────────────
    // Subaccount balance by group name
    function balanceOf(address parent, string memory subName) external view returns (uint256);
    // Ledger account balance by parent/owner
    function balanceOf(address parent, address owner) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // Supply
    // ─────────────────────────────────────────────────────────────────────────────
    function totalSupply(address token) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // Transfers (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transfer(address fromParent, address from, address toParent, address to, uint256 amount, bool emitEvent)
        external
        returns (bool);
    function transfer(address fromParent, address toParent, address to, uint256 amount) external returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // Approvals (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function approve(address ownerParent, address owner, address spender, uint256 amount) external returns (bool);
    function approve(address ownerParent, address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address ownerParent, address owner, address spender, uint256 addedValue)
        external
        returns (bool, uint256);
    function increaseAllowance(address ownerParent, address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address ownerParent, address owner, address spender, uint256 subtractedValue)
        external
        returns (bool, uint256);
    function decreaseAllowance(address ownerParent, address spender, uint256 subtractedValue) external returns (bool);
    function forceApprove(address ownerParent, address owner, address spender, uint256 amount)
        external
        returns (bool);
    function forceApprove(address ownerParent, address spender, uint256 amount) external returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // Allowance (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function allowance(address ownerParent, address owner, address spender) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // transferFrom (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transferFrom(
        address spender,
        address fromParent,
        address from,
        address toParent,
        address to,
        uint256 amount,
        bool emitEvent
    ) external returns (bool);

    function transferFrom(address fromParent, address from, address toParent, address to, uint256 amount)
        external
        returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // Custom errors
    // ─────────────────────────────────────────────────────────────────────────────
    error DifferentRoots(address a, address b);
    error DuplicateSubAccount(address sub);
    error HasBalance(address addr);
    error HasSubAccount(address addr);
    error InsufficientAllowance(address ownerParent, address owner, address spender, uint256 current, uint256 amount);
    error InsufficientBalance(address token, address parent, address account, uint256 amount);
    error InvalidAddress(address absoluteAddress);
    error InvalidDecimals(uint8 decimals);
    error InvalidAccountGroup(address groupAddress);
    error InvalidLedgerAccount(address ledgerAddress);
    error InvalidSubAccount(address addr, bool isCredit);
    error InvalidSubAccountGroup(string subName, bool isCredit);
    error InvalidSubAccountIndex(uint256 index);
    error InvalidString(string symbol);
    error InvalidToken(string name, string symbol, uint8 decimals);
    error MaxDepthExceeded();
    error NotCredit(string name);
    error SubAccountNotFound(address addr);
    error SubAccountGroupNotFound(string subName);
    error Unauthorized(address user);
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
