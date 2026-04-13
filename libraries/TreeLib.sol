// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib, FloatStrings} from "./FloatStrings.sol";
// // ─────────────────────────────────────────────────────────────────────────────
// // Import split layout (interfaces + lib + module + infra)
// // Adjust paths if your repo layout differs.
// // ─────────────────────────────────────────────────────────────────────────────
// import {ILedger} from "../../interfaces/ILedger.sol";
import {Ledger, LedgerLib} from "../modules/Ledger.sol";
// import {Module} from "../../modules/Module.sol";
// import {Router} from "../../modules/Router.sol";

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
        Ledger ledgers_,
        address parent_,
        address addr_,
        string memory prefix_,
        bool isFirst_,
        bool isLast_
    ) internal view {
        TreeCache memory c;

        c.isRoot = LedgerLib.isZeroAddress(parent_);
        c.addr = c.isRoot ? addr_ : LedgerLib.toAddress(parent_, addr_);
        c.flags = ledgers_.flags(c.addr);
        if (c.isRoot) {
            c.balance = 0;
        } else {
            (, uint256 _flags) = ledgers_.effectiveFlags(parent_, addr_);
            c.balance = ledgers_.isCredit(_flags)
                ? ledgers_.creditBalanceOf(parent_, addr_)
                : ledgers_.debitBalanceOf(parent_, addr_);
        }
        string memory label = string(
            abi.encodePacked(
                ledgers_.name(c.addr),
                " (",
                LedgerLib.isCredit(c.flags) ? "C: " : "D: ",
                c.balance.toFloat(ledgers_.decimals(ledgers_.root(c.addr))).toString(),
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

        c.subs = ledgers_.subAccounts(c.addr);
        for (uint256 i = 0; i < c.subs.length; i++) {
            logTree(ledgers_, c.addr, c.subs[i], c.subPrefix, false, i == c.subs.length - 1);
        }
    }

    function debugTree(Ledger ledgers, address root) internal view {
        logTree(ledgers, address(0), root, "", true, true);
    }

    function debugTrees(Ledger ledgers, address[] memory roots) internal view {
        for (uint256 i = 0; i < roots.length; i++) {
            logTree(ledgers, address(0), roots[i], "", true, true);
            console.log("---------------------------------");
        }
    }
}
