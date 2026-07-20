// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib, FloatStrings} from "../../math/FloatStrings.sol";
import {LedgerLib} from "../ledger/LedgerLib.sol";

import {console} from "forge-std/src/Test.sol";

// ─────────────────────────────────────────────────────────────────────────────
// TreeView helpers
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
        address holderParent;
        address relative;
        string name;
        bool isCredit;
        uint256 debit;
        uint256 credit;
    }

    function node(address root_, address holderParent_, address relative_)
        internal
        view
        returns (TreeNode memory _node)
    {
        bool _isRoot = LedgerLib.isZeroAddress(holderParent_);
        address _absolute = _isRoot ? root_ : LedgerLib.toAddress(root_, holderParent_, relative_);
        uint256 _flags;
        _node.holderParent = holderParent_;
        _node.relative = relative_;
        _node.name = LedgerLib.name(_absolute);
        if (_isRoot) {
            _flags = LedgerLib.flags(_absolute);
        } else {
            (_flags,,) = LedgerLib.effectiveFlags(root_, holderParent_, relative_);
        }
        _node.isCredit = LedgerLib.isCredit(_flags);
        _node.debit = LedgerLib.debitBalanceOf(_absolute);
        _node.credit = LedgerLib.creditBalanceOf(_absolute);
    }

    function tree(address root_) internal view returns (TreeNode[] memory _nodes) {
        _nodes = new TreeNode[](count(root_, address(0), root_));
        fill(root_, address(0), root_, _nodes, 0);
    }

    function count(address root_, address holderParent_, address relative_) internal view returns (uint256 _count) {
        bool _isRoot = LedgerLib.isZeroAddress(holderParent_);
        address _absolute = _isRoot ? root_ : LedgerLib.toAddress(root_, holderParent_, relative_);
        address _holder = _isRoot ? root_ : LedgerLib.toAddress(holderParent_, relative_);
        _count = 1;
        address[] memory _subs = LedgerLib.subAccounts(_absolute);
        for (uint256 i = 0; i < _subs.length; i++) {
            _count += count(root_, _holder, _subs[i]);
        }
    }

    function fill(address root_, address holderParent_, address relative_, TreeNode[] memory nodes_, uint256 n_)
        internal
        view
        returns (uint256 _n)
    {
        TreeNode memory _node = node(root_, holderParent_, relative_);
        nodes_[n_] = _node;
        _n = n_ + 1;

        bool _isRoot = LedgerLib.isZeroAddress(holderParent_);
        address _absolute = _isRoot ? root_ : LedgerLib.toAddress(root_, holderParent_, relative_);
        address _holder = _isRoot ? root_ : LedgerLib.toAddress(holderParent_, relative_);
        address[] memory _subs = LedgerLib.subAccounts(_absolute);
        for (uint256 i = 0; i < _subs.length; i++) {
            _n = fill(root_, _holder, _subs[i], nodes_, _n);
        }
    }

    function logTree(
        address root_,
        address holderParent_,
        address relative_,
        string memory prefix_,
        bool isFirst_,
        bool isLast_
    ) internal view {
        TreeCache memory c;

        c.isRoot = LedgerLib.isZeroAddress(holderParent_);
        c.addr = c.isRoot ? root_ : LedgerLib.toAddress(root_, holderParent_, relative_);
        c.flags = LedgerLib.flags(c.addr);
        if (c.isRoot) {
            c.balance = LedgerLib.totalSupply(c.addr);
        } else {
            (uint256 _flags,,) = LedgerLib.effectiveFlags(root_, holderParent_, relative_);
            c.balance =
                LedgerLib.isCredit(_flags) ? LedgerLib.creditBalanceOf(c.addr) : LedgerLib.debitBalanceOf(c.addr);
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
        address _holder = c.isRoot ? root_ : LedgerLib.toAddress(holderParent_, relative_);
        for (uint256 i = 0; i < c.subs.length; i++) {
            logTree(root_, _holder, c.subs[i], c.subPrefix, false, i == c.subs.length - 1);
        }
    }

    function debugTree(address root_) internal view {
        logTree(root_, address(0), root_, "", true, true);
    }

    function debugTrees(address[] memory roots_) internal view {
        for (uint256 i = 0; i < roots_.length; i++) {
            logTree(roots_[i], address(0), roots_[i], "", true, true);
            console.log("---------------------------------");
        }
    }
}
