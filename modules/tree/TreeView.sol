// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedger} from "../ledger/ILedger.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";
import {TreeLib} from "./TreeLib.sol";

contract TreeView is Dispatchable {
    function checkLedgerParent(address ledger_, address parent_) private view {
        if (!LedgerLib.isLedger(LedgerLib.flags(ledger_))) revert ILedger.InvalidLedgerAccount(ledger_);
        address _absoluteParent = parent_ == ledger_ ? ledger_ : LedgerLib.toAddress(ledger_, parent_);
        if (!LedgerLib.isGroup(LedgerLib.flags(_absoluteParent))) revert ILedger.InvalidAccountGroup();
    }

    function signatures() external pure override returns (string[] memory _signatures) {
        _signatures = new string[](30);
        _signatures[0] = "ledger(address)";
        _signatures[1] = "flags(address)";
        _signatures[2] = "wrapper(address)";
        _signatures[3] = "tree(address)";
        _signatures[4] = "treeNode(address)";
        _signatures[5] = "treeNode(address,address,address)";
        _signatures[6] = "accountKind(uint256)";
        _signatures[7] = "tokenKind(uint256)";
        _signatures[8] = "packedAddress(uint256)";
        _signatures[9] = "isUnregisteredAccount(uint256)";
        _signatures[10] = "isDebitGroup(uint256)";
        _signatures[11] = "isCreditGroup(uint256)";
        _signatures[12] = "isDebitLedger(uint256)";
        _signatures[13] = "isCreditLedger(uint256)";
        _signatures[14] = "isGroup(uint256)";
        _signatures[15] = "isLedgerAccount(uint256)";
        _signatures[16] = "isCredit(uint256)";
        _signatures[17] = "effectiveFlags(address,address,address)";
        _signatures[18] = "isUnregisteredToken(uint256)";
        _signatures[19] = "isInternal(uint256)";
        _signatures[20] = "isNative(uint256)";
        _signatures[21] = "isExternal(uint256)";
        _signatures[22] = "isLedger(uint256)";
        _signatures[23] = "isReceipt(uint256)";
        _signatures[24] = "receiptAccount(uint256)";
        _signatures[25] = "subAccounts(address)";
        _signatures[26] = "hasSubAccount(address)";
        _signatures[27] = "subAccountIndex(address)";
        _signatures[28] = "debugTree(address)";
        _signatures[29] = "debugTrees(address[])";
    }

    function selectors() external pure override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](30);
        _selectors[n++] = bytes4(keccak256("ledger(address)"));
        _selectors[n++] = bytes4(keccak256("flags(address)"));
        _selectors[n++] = bytes4(keccak256("wrapper(address)"));
        _selectors[n++] = bytes4(keccak256("tree(address)"));
        _selectors[n++] = bytes4(keccak256("treeNode(address)"));
        _selectors[n++] = bytes4(keccak256("treeNode(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("accountKind(uint256)"));
        _selectors[n++] = bytes4(keccak256("tokenKind(uint256)"));
        _selectors[n++] = bytes4(keccak256("packedAddress(uint256)"));
        _selectors[n++] = bytes4(keccak256("isUnregisteredAccount(uint256)"));
        _selectors[n++] = bytes4(keccak256("isDebitGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCreditGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isDebitLedger(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCreditLedger(uint256)"));
        _selectors[n++] = bytes4(keccak256("isGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isLedgerAccount(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCredit(uint256)"));
        _selectors[n++] = bytes4(keccak256("effectiveFlags(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("isUnregisteredToken(uint256)"));
        _selectors[n++] = bytes4(keccak256("isInternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isNative(uint256)"));
        _selectors[n++] = bytes4(keccak256("isExternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isLedger(uint256)"));
        _selectors[n++] = bytes4(keccak256("isReceipt(uint256)"));
        _selectors[n++] = bytes4(keccak256("receiptAccount(uint256)"));
        _selectors[n++] = bytes4(keccak256("subAccounts(address)"));
        _selectors[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _selectors[n++] = bytes4(keccak256("subAccountIndex(address)"));
        _selectors[n++] = bytes4(keccak256("debugTree(address)"));
        _selectors[n++] = bytes4(keccak256("debugTrees(address[])"));

        if (n != 30) revert InvalidCommandsLength(n);
    }

    function ledger(address absolute_) external view returns (address) {
        return LedgerLib.ledger(absolute_);
    }

    function flags(address absolute_) external view returns (uint256) {
        return LedgerLib.flags(absolute_);
    }

    function wrapper(address ledger_) external view returns (address) {
        return LedgerLib.wrapper(ledger_);
    }

    function tree(address ledger_) external view returns (TreeLib.TreeNode[] memory) {
        return TreeLib.tree(ledger_);
    }

    function treeNode(address ledger_) external view returns (TreeLib.TreeNode memory) {
        return TreeLib.node(ledger_, address(0), ledger_);
    }

    function treeNode(address ledger_, address parent_, address relative_)
        external
        view
        returns (TreeLib.TreeNode memory)
    {
        return TreeLib.node(ledger_, parent_, relative_);
    }

    function accountKind(uint256 flags_) external pure returns (LedgerLib.AccountKind) {
        return LedgerLib.accountKind(flags_);
    }

    function tokenKind(uint256 flags_) external pure returns (LedgerLib.TokenKind) {
        return LedgerLib.tokenKind(flags_);
    }

    function packedAddress(uint256 flags_) external pure returns (address) {
        return LedgerLib.packedAddress(flags_);
    }

    function isUnregisteredAccount(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isUnregisteredAccount(flags_);
    }

    function isDebitGroup(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isDebitGroup(flags_);
    }

    function isCreditGroup(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isCreditGroup(flags_);
    }

    function isDebitLedger(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isDebitLedger(flags_);
    }

    function isCreditLedger(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isCreditLedger(flags_);
    }

    function isGroup(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isGroup(flags_);
    }

    function isLedgerAccount(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isLedgerAccount(flags_);
    }

    function isCredit(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isCredit(flags_);
    }

    function effectiveFlags(address ledger_, address parent_, address relative_)
        external
        view
        returns (uint256, uint256, address)
    {
        checkLedgerParent(ledger_, parent_);
        return LedgerLib.effectiveFlags(ledger_, parent_, relative_);
    }

    function isUnregisteredToken(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isUnregisteredToken(flags_);
    }

    function isInternal(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isInternal(flags_);
    }

    function isNative(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isNative(flags_);
    }

    function isExternal(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isExternal(flags_);
    }

    function isLedger(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isLedger(flags_);
    }

    function isReceipt(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isReceipt(flags_);
    }

    function receiptAccount(uint256 flags_) external pure returns (address) {
        return LedgerLib.receiptAccount(flags_);
    }

    function subAccounts(address absolute_) external view returns (address[] memory) {
        return LedgerLib.subAccounts(absolute_);
    }

    function hasSubAccount(address absolute_) external view returns (bool) {
        return LedgerLib.hasSubAccount(absolute_);
    }

    function subAccountIndex(address absolute_) external view returns (uint32) {
        return LedgerLib.subAccountIndex(absolute_);
    }

    function debugTree(address ledger_) external view {
        TreeLib.debugTree(ledger_);
    }

    function debugTrees(address[] memory ledgers_) external view {
        TreeLib.debugTrees(ledgers_);
    }
}
