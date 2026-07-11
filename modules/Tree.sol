// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "./Dispatchable.sol";
import {LedgerLib} from "../libraries/LedgerLib.sol";
import {TreeLib} from "../libraries/TreeLib.sol";

contract Tree is Dispatchable {
    function signatures() external pure override returns (string[] memory _signatures) {
        _signatures = new string[](31);
        _signatures[0] = "root(address)";
        _signatures[1] = "parent(address)";
        _signatures[2] = "flags(address)";
        _signatures[3] = "wrapper(address)";
        _signatures[4] = "tree(address)";
        _signatures[5] = "treeNode(address)";
        _signatures[6] = "treeNode(address,address)";
        _signatures[7] = "accountKind(uint256)";
        _signatures[8] = "tokenKind(uint256)";
        _signatures[9] = "packedAddress(uint256)";
        _signatures[10] = "isUnregisteredAccount(uint256)";
        _signatures[11] = "isDebitGroup(uint256)";
        _signatures[12] = "isCreditGroup(uint256)";
        _signatures[13] = "isDebitLedger(uint256)";
        _signatures[14] = "isCreditLedger(uint256)";
        _signatures[15] = "isGroup(uint256)";
        _signatures[16] = "isLedger(uint256)";
        _signatures[17] = "isCredit(uint256)";
        _signatures[18] = "effectiveFlags(address,address)";
        _signatures[19] = "isUnregisteredToken(uint256)";
        _signatures[20] = "isInternal(uint256)";
        _signatures[21] = "isNative(uint256)";
        _signatures[22] = "isExternal(uint256)";
        _signatures[23] = "isRoot(uint256)";
        _signatures[24] = "isClaim(uint256)";
        _signatures[25] = "claimAccount(uint256)";
        _signatures[26] = "subAccounts(address)";
        _signatures[27] = "hasSubAccount(address)";
        _signatures[28] = "subAccountIndex(address,address)";
        _signatures[29] = "debugTree(address)";
        _signatures[30] = "debugTrees(address[])";
    }

    function selectors() external pure override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](31);
        _selectors[n++] = bytes4(keccak256("root(address)"));
        _selectors[n++] = bytes4(keccak256("parent(address)"));
        _selectors[n++] = bytes4(keccak256("flags(address)"));
        _selectors[n++] = bytes4(keccak256("wrapper(address)"));
        _selectors[n++] = bytes4(keccak256("tree(address)"));
        _selectors[n++] = bytes4(keccak256("treeNode(address)"));
        _selectors[n++] = bytes4(keccak256("treeNode(address,address)"));
        _selectors[n++] = bytes4(keccak256("accountKind(uint256)"));
        _selectors[n++] = bytes4(keccak256("tokenKind(uint256)"));
        _selectors[n++] = bytes4(keccak256("packedAddress(uint256)"));
        _selectors[n++] = bytes4(keccak256("isUnregisteredAccount(uint256)"));
        _selectors[n++] = bytes4(keccak256("isDebitGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCreditGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isDebitLedger(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCreditLedger(uint256)"));
        _selectors[n++] = bytes4(keccak256("isGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isLedger(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCredit(uint256)"));
        _selectors[n++] = bytes4(keccak256("effectiveFlags(address,address)"));
        _selectors[n++] = bytes4(keccak256("isUnregisteredToken(uint256)"));
        _selectors[n++] = bytes4(keccak256("isInternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isNative(uint256)"));
        _selectors[n++] = bytes4(keccak256("isExternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isRoot(uint256)"));
        _selectors[n++] = bytes4(keccak256("isClaim(uint256)"));
        _selectors[n++] = bytes4(keccak256("claimAccount(uint256)"));
        _selectors[n++] = bytes4(keccak256("subAccounts(address)"));
        _selectors[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _selectors[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _selectors[n++] = bytes4(keccak256("debugTree(address)"));
        _selectors[n++] = bytes4(keccak256("debugTrees(address[])"));

        if (n != 31) revert InvalidCommandsLength(n);
    }

    function root(address addr_) external view returns (address) {
        return LedgerLib.root(addr_);
    }

    function parent(address addr_) external view returns (address) {
        return LedgerLib.parent(addr_);
    }

    function flags(address addr_) external view returns (uint256) {
        return LedgerLib.flags(addr_);
    }

    function wrapper(address token_) external view returns (address) {
        return LedgerLib.wrapper(token_);
    }

    function tree(address root_) external view returns (TreeLib.TreeNode[] memory) {
        return TreeLib.tree(root_);
    }

    function treeNode(address root_) external view returns (TreeLib.TreeNode memory) {
        return TreeLib.node(address(0), root_);
    }

    function treeNode(address parent_, address addr_) external view returns (TreeLib.TreeNode memory) {
        return TreeLib.node(parent_, addr_);
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

    function isLedger(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isLedger(flags_);
    }

    function isCredit(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isCredit(flags_);
    }

    function effectiveFlags(address parent_, address addr_) external view returns (address, uint256) {
        return LedgerLib.effectiveFlags(parent_, addr_);
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

    function isRoot(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isRoot(flags_);
    }

    function isClaim(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isClaim(flags_);
    }

    function claimAccount(uint256 flags_) external pure returns (address) {
        return LedgerLib.claimAccount(flags_);
    }

    function subAccounts(address parent_) external view returns (address[] memory) {
        return LedgerLib.subAccounts(parent_);
    }

    function hasSubAccount(address parent_) external view returns (bool) {
        return LedgerLib.hasSubAccount(parent_);
    }

    function subAccountIndex(address parent_, address addr_) external view returns (uint32) {
        return LedgerLib.subAccountIndex(parent_, addr_);
    }

    function debugTree(address root_) external view {
        TreeLib.debugTree(root_);
    }

    function debugTrees(address[] memory roots_) external view {
        TreeLib.debugTrees(roots_);
    }
}
