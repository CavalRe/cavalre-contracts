// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib, FloatStrings} from "./FloatStrings.sol";
import {LedgerLib} from "./LedgerLib.sol";

import {console} from "forge-std/src/Test.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Tree helpers
// ─────────────────────────────────────────────────────────────────────────────
library TreeLib {
    using FloatLib for uint256;
    using FloatStrings for Float;

    struct TreeCache {
        bool isRoot;
        address addr;
        uint256 flags;
        uint256 balance;
        string label;
        bool isGroup;
        string subPrefix;
        address[] subs;
    }

    struct TreeNode {
        address parent;
        address addr;
        string name;
        bool isCredit;
        uint256 debit;
        uint256 credit;
    }

    function node(address parent_, address addr_) internal view returns (TreeNode memory _node) {
        bool _isRoot = LedgerLib.isZeroAddress(parent_);
        address _absolute = _isRoot ? addr_ : LedgerLib.toAddress(parent_, addr_);
        uint256 _flags;
        _node.parent = parent_;
        _node.addr = addr_;
        _node.name = LedgerLib.name(_absolute);
        if (_isRoot) {
            _flags = LedgerLib.flags(_absolute);
        } else {
            (, _flags) = LedgerLib.effectiveFlags(parent_, addr_);
        }
        _node.isCredit = LedgerLib.isCredit(_flags);
        _node.debit = LedgerLib.debitBalanceOf(_absolute);
        _node.credit = LedgerLib.creditBalanceOf(_absolute);
    }

    function tree(address root_) internal view returns (TreeNode[] memory _nodes) {
        _nodes = new TreeNode[](count(root_));
        fill(address(0), root_, _nodes, 0);
    }

    function count(address addr_) internal view returns (uint256 _count) {
        _count = 1;
        address[] memory _subs = LedgerLib.subAccounts(addr_);
        for (uint256 i = 0; i < _subs.length; i++) {
            _count += count(LedgerLib.toAddress(addr_, _subs[i]));
        }
    }

    function fill(address parent_, address addr_, TreeNode[] memory nodes_, uint256 n_) internal view returns (uint256 _n) {
        TreeNode memory _node = node(parent_, addr_);
        nodes_[n_] = _node;
        _n = n_ + 1;

        address _absolute = LedgerLib.isZeroAddress(parent_) ? addr_ : LedgerLib.toAddress(parent_, addr_);
        address[] memory _subs = LedgerLib.subAccounts(_absolute);
        for (uint256 i = 0; i < _subs.length; i++) {
            _n = fill(_absolute, _subs[i], nodes_, _n);
        }
    }

    function logTree(
        address parent_,
        address addr_,
        string memory prefix_,
        bool isFirst_,
        bool isLast_
    ) internal view {
        TreeCache memory c;

        c.isRoot = LedgerLib.isZeroAddress(parent_);
        c.addr = c.isRoot ? addr_ : LedgerLib.toAddress(parent_, addr_);
        c.flags = LedgerLib.flags(c.addr);
        if (c.isRoot) {
            c.balance = LedgerLib.totalSupply(c.addr);
        } else {
            (, uint256 _flags) = LedgerLib.effectiveFlags(parent_, addr_);
            c.balance = LedgerLib.isCredit(_flags)
                ? LedgerLib.creditBalanceOf(c.addr)
                : LedgerLib.debitBalanceOf(c.addr);
        }
        string memory label = string(
            abi.encodePacked(
                LedgerLib.name(c.addr),
                " (",
                LedgerLib.isCredit(c.flags) ? "C: " : "D: ",
                c.balance.toFloat(LedgerLib.decimals(LedgerLib.root(c.addr))).toString(),
                ")"
            )
        );
        c.isGroup = LedgerLib.isGroup(c.flags);
        console.log(
            "%s%s%s",
            prefix_,
            isFirst_
                ? ""
                : (isLast_
                        ? (c.isGroup ? unicode"└─ " : unicode"└● ")
                        : (c.isGroup ? unicode"├─ " : unicode"├● ")),
            label
        );
        c.subPrefix = string(abi.encodePacked(prefix_, isFirst_ ? "" : (isLast_ ? "   " : unicode"│  ")));

        c.subs = LedgerLib.subAccounts(c.addr);
        for (uint256 i = 0; i < c.subs.length; i++) {
            logTree(c.addr, c.subs[i], c.subPrefix, false, i == c.subs.length - 1);
        }
    }

    function debugTree(address root_) internal view {
        logTree(address(0), root_, "", true, true);
    }

    function debugTrees(address[] memory roots_) internal view {
        for (uint256 i = 0; i < roots_.length; i++) {
            logTree(address(0), roots_[i], "", true, true);
            console.log("---------------------------------");
        }
    }
}
