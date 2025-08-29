// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILedgers {
    // ─────────────────────────────────────────────────────────────────────────────
    // Initializers
    // ─────────────────────────────────────────────────────────────────────────────
    function initializeLedgers() external;

    // ─────────────────────────────────────────────────────────────────────────────
    // Metadata (by arbitrary address)
    // ─────────────────────────────────────────────────────────────────────────────
    function name(address addr_) external view returns (string memory);
    function symbol(address addr_) external view returns (string memory);
    function decimals(address addr_) external view returns (uint8);

    // ─────────────────────────────────────────────────────────────────────────────
    // Tree navigation
    // ─────────────────────────────────────────────────────────────────────────────
    function root(address addr_) external view returns (address);
    function parent(address addr_) external view returns (address);
    function isGroup(address addr_) external view returns (bool);
    function subAccounts(address parent_) external view returns (address[] memory);
    function hasSubAccount(address parent_) external view returns (bool);
    function subAccountIndex(address addr_) external view returns (uint32);

    // ─────────────────────────────────────────────────────────────────────────────
    // Balances
    // ─────────────────────────────────────────────────────────────────────────────
    // Subaccount balance by group name
    function balanceOf(address parent_, string memory subName_) external view returns (uint256);
    // Ledger account balance by parent/owner
    function balanceOf(address parent_, address owner_) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // Supply
    // ─────────────────────────────────────────────────────────────────────────────
    function totalSupply(address token_) external view returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // Transfers (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // Approvals (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function approve(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
        external
        returns (bool);
    function increaseAllowance(address ownerParent_, address spenderParent_, address spender_, uint256 addedValue_)
        external
        returns (bool);
    function decreaseAllowance(address ownerParent_, address spenderParent_, address spender_, uint256 subtractedValue_)
        external
        returns (bool);
    function forceApprove(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
        external
        returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // Allowance (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
        external
        view
        returns (uint256);

    // ─────────────────────────────────────────────────────────────────────────────
    // transferFrom (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transferFrom(
        address fromParent_,
        address from_,
        address spenderParent_,
        address toParent_,
        address to_,
        uint256 amount_
    ) external returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // ERC20 wrapper entrypoints
    // (token_ is the ERC20Wrapper’s address)
    // ─────────────────────────────────────────────────────────────────────────────
    function approveWrapper(address token_, address owner_, address spender_, uint256 amount_)
        external
        returns (bool);

    function increaseAllowanceWrapper(address token_, address owner_, address spender_, uint256 addedValue_)
        external
        returns (bool, uint256);

    function decreaseAllowanceWrapper(address token_, address owner_, address spender_, uint256 subtractedValue_)
        external
        returns (bool, uint256);

    function forceApproveWrapper(address token_, address owner_, address spender_, uint256 amount_)
        external
        returns (bool);

    function transferWrapper(address token_, address from_, address to_, uint256 amount_) external returns (bool);

    function mintWrapper(address token_, address to_, uint256 amount_) external returns (bool);

    function burnWrapper(address token_, address from_, uint256 amount_) external returns (bool);

    function transferFromWrapper(address token_, address from_, address spender_, address to_, uint256 amount_)
        external
        returns (bool);

    // ─────────────────────────────────────────────────────────────────────────────
    // Custom errors
    // ─────────────────────────────────────────────────────────────────────────────
    error DifferentRoots(address a, address b);
    error DuplicateSubAccount(address sub);
    error HasBalance(string subName);
    error HasSubAccount(string subName);
    error InsufficientAllowance(
        address ownerParent, address owner, address spenderParent, address spender, uint256 current, uint256 amount
    );
    error InsufficientBalance(address token, address parent, address account, uint256 amount);
    error InvalidAddress(address absoluteAddress);
    error InvalidDecimals(uint8 decimals);
    error InvalidAccountGroup(address groupAddress);
    error InvalidLedgerAccount(address ledgerAddress);
    error InvalidSubAccount(string subName, bool isGroup, bool isCredit);
    error InvalidString(string symbol);
    error InvalidToken(string name, string symbol, uint8 decimals);
    error MaxDepthExceeded();
    error NotCredit(string name);
    error SubAccountNotFound(string subName);
    error Unauthorized(address user);
    error ZeroAddress();

    // ─────────────────────────────────────────────────────────────────────────────
    // Events (Double-entry journal)
    // Walks up from (parent_, addr_) to the root without updating the root.
    // Emits once on success with (token=root, parent_, addr_, amount_).
    //  - token  : actual token root (for fast indexing/filtering)
    //  - parent : fixed parent group of ledger account
    //  - account: exact ledger account (no children by design)
    // ─────────────────────────────────────────────────────────────────────────────
    event Credit(address indexed token, address indexed parent, address indexed account, uint256 value);
    event Debit(address indexed token, address indexed parent, address indexed account, uint256 value);
    event InternalApproval(address indexed owner, address indexed spender, uint256 value);
    event LedgerAdded(address indexed tokenAddress, string name, string symbol, uint8 decimals);
    event SubAccountAdded(address indexed root, address indexed parent, string subName, bool isGroup, bool isCredit);
    event SubAccountRemoved(address indexed root, address indexed parent, string subName);

    // ─────────────────────────────────────────────────────────────────────────────
    // Standard ERC-20 events (emitted through library/wrapper)
    // ─────────────────────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
