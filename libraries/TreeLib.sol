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
        address addr;
        address parent;
        address root;
        string name;
        string symbol;
        uint8 decimals;
        uint256 flags;
        uint256 balance;
        address[] subs;
    }

    function node(address parent_, address addr_) internal view returns (TreeNode memory _node) {
        bool _isRoot = LedgerLib.isZeroAddress(parent_);
        _node.addr = _isRoot ? addr_ : LedgerLib.toAddress(parent_, addr_);
        _node.parent = parent_;
        _node.root = LedgerLib.root(_node.addr);
        _node.name = LedgerLib.name(_node.addr);
        _node.symbol = LedgerLib.symbol(_node.addr);
        _node.decimals = LedgerLib.decimals(_node.root);
        _node.flags = LedgerLib.flags(_node.addr);
        if (_isRoot) {
            _node.balance = LedgerLib.totalSupply(_node.addr);
        } else {
            (, uint256 _flags) = LedgerLib.effectiveFlags(parent_, addr_);
            _node.balance = LedgerLib.isCredit(_flags)
                ? LedgerLib.creditBalanceOf(_node.addr)
                : LedgerLib.debitBalanceOf(_node.addr);
        }
        _node.subs = LedgerLib.subAccounts(_node.addr);
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
