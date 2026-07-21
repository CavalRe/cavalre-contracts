// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerTokenFactoryView {
    function tokenSalt(string memory name, string memory symbol, uint8 decimals, string memory version)
        external
        pure
        returns (bytes32);

    function predictToken(string memory name, string memory symbol, uint8 decimals, string memory version)
        external
        view
        returns (address token);
}
