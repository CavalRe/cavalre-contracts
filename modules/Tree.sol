// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Module} from "./Module.sol";
import {LedgerLib} from "../libraries/LedgerLib.sol";
import {TreeLib} from "../libraries/TreeLib.sol";

contract Tree is Module {
    function selectors() external pure override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](19);
        _selectors[n++] = bytes4(keccak256("root(address)"));
        _selectors[n++] = bytes4(keccak256("parent(address)"));
        _selectors[n++] = bytes4(keccak256("flags(address)"));
        _selectors[n++] = bytes4(keccak256("wrapper(address)"));
        _selectors[n++] = bytes4(keccak256("treeNode(address)"));
        _selectors[n++] = bytes4(keccak256("treeNode(address,address)"));
        _selectors[n++] = bytes4(keccak256("isGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCredit(uint256)"));
        _selectors[n++] = bytes4(keccak256("effectiveFlags(address,address)"));
        _selectors[n++] = bytes4(keccak256("isInternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isNative(uint256)"));
        _selectors[n++] = bytes4(keccak256("isRegistered(uint256)"));
        _selectors[n++] = bytes4(keccak256("isExternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isRoot(uint256)"));
        _selectors[n++] = bytes4(keccak256("subAccounts(address)"));
        _selectors[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _selectors[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _selectors[n++] = bytes4(keccak256("debugTree(address)"));
        _selectors[n++] = bytes4(keccak256("debugTrees(address[])"));

        if (n != 19) revert InvalidCommandsLength(n);
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

    function treeNode(address root_) external view returns (TreeLib.TreeNode memory) {
        return TreeLib.node(address(0), root_);
    }

    function treeNode(address parent_, address addr_) external view returns (TreeLib.TreeNode memory) {
        return TreeLib.node(parent_, addr_);
    }

    function isGroup(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isGroup(flags_);
    }

    function isCredit(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isCredit(flags_);
    }

    function effectiveFlags(address parent_, address addr_) external view returns (address, uint256) {
        return LedgerLib.effectiveFlags(parent_, addr_);
    }

    function isInternal(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isInternal(flags_);
    }

    function isNative(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isNative(flags_);
    }

    function isRegistered(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isRegistered(flags_);
    }

    function isExternal(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isExternal(flags_);
    }

    function isRoot(uint256 flags_) external pure returns (bool) {
        return LedgerLib.isRoot(flags_);
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
