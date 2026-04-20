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
                c.isRoot ? "Supply: " : (LedgerLib.isCredit(c.flags) ? "C: " : "D: "),
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
