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
    function addSubAccountGroup(address root, address holderParent, address relative, string memory name, bool isCredit)
        external
        returns (address subAccount, uint256 flags);

    /// @param isCredit True for credit-side account, false for debit-side in the double-entry tree.
    function addSubAccount(address root, address holderParent, address relative, string memory name, bool isCredit)
        external
        returns (address subAccount, uint256 flags);

    function addNativeToken() external returns (uint256 flags);

    function addExternalToken(address[] memory tokens) external returns (uint256[] memory flags);

    function removeSubAccountGroup(address root, address holderParent, address relative) external returns (address);

    function removeSubAccount(address root, address holderParent, address relative) external returns (address);

    // ─────────────────────────────────────────────────────────────────────────────
    // Transfers (full routed; explicit parents)
    // ─────────────────────────────────────────────────────────────────────────────
    function transfer(
        address root,
        address fromHolderParent,
        address from,
        address toHolderParent,
        address to,
        uint256 amount
    ) external;

    function transfer(address root, address fromHolderParent, address toHolderParent, address to, uint256 amount)
        external;

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
    error InvalidNativePayer(address payer, address sender);
    error LedgerUninitialized();
    error InvalidString(string symbol);
    error InvalidSubAccount(address addr);
    error InvalidSubAccountGroup(string subName, bool isCredit);
    error InvalidSubAccountIndex(uint256 index);
    error InvalidToken(address token, string name, string symbol, uint8 decimals);
    error NativeTransferFailed();
    error SubAccountNotFound(address addr);
    error SubAccountGroupNotFound(address addr);
    error TooManySubAccounts(uint256 count);
    error UndercollateralizedToken(address token, uint256 liabilities, uint256 collateral);
    error Unauthorized(address user);
    error UnsupportedTokenBehavior(address token, uint256 expected, uint256 actual);
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
