// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IShareTokenView {
    /// @notice A live Ledger snapshot; quantities are raw integers, not a common-decimal valuation.
    struct State {
        address backingAccount; // Absolute registered leaf; may be nested or credit-sided.
        address backingLedger; // Derived from backingAccount; need not expose an ERC20.
        uint256 supply; // Raw share units, using share-token decimals.
        uint256 backing; // Net balance in backingLedger decimals, using the leaf's polarity.
    }

    /// @notice Whether token has a registered share backing account.
    function isShareToken(address token) external view returns (bool);
    /// @notice Registered absolute backing account, or zero for an unregistered share token.
    function backingAccount(address token) external view returns (address);
    /// @notice Current Ledger accounting; reverts if token is not a valid share.
    function shareTokenState(address token) external view returns (State memory);
    /// @notice Raw share quote, rounded down; existing supply/backing determines the ratio.
    /// @dev Both-zero initialization is decimal-adjusted 1:1; positive input rejects mismatched zero states.
    function convertToShares(address token, uint256 backing) external view returns (uint256);
    /// @notice Raw backing quote, rounded down; a full-supply quote includes all remaining backing.
    /// @dev This does not check holder balance or authorize release. Existing supply with zero backing quotes zero.
    function convertToBacking(address token, uint256 shares) external view returns (uint256);
}
