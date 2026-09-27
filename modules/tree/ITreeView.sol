// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Account metadata needed by external tokens before authorized ledger postings.
interface ITreeView {
    function effectiveFlags(address ledger, address parent, address relative)
        external
        view
        returns (uint256 effectiveFlags_, uint256 originalFlags, address absolute);
}
