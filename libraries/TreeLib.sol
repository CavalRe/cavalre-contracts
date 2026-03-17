// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FloatStrings} from "./FloatStrings.sol";
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
    function logTree(
        Ledger ledgers_,
        address parent_,
        address root_,
        string memory prefix_,
        bool isFirst_,
        bool isLast_
    ) internal view {
        address _root = LedgerLib.isZeroAddress(parent_) ? root_ : LedgerLib.toAddress(parent_, root_);
        uint256 _flags = ledgers_.flags(_root);
        uint256 _balance = LedgerLib.isZeroAddress(parent_) ? 0 : ledgers_.balanceOf(parent_, root_);
        string memory label = string(
            abi.encodePacked(
                ledgers_.name(_root),
                " (",
                LedgerLib.isCredit(_flags) ? "C: " : "D: ",
                FloatStrings.toString(_balance),
                ")"
            )
        );
        bool isGroup = LedgerLib.isGroup(_flags);
        console.log(
            "%s%s%s",
            prefix_,
            isFirst_
                ? ""
                : (isLast_
                        ? (isGroup ? unicode"└─ " : unicode"└● ")
                        : (isGroup ? unicode"├─ " : unicode"├● ")),
            label
        );
        string memory subPrefix = string(abi.encodePacked(prefix_, isFirst_ ? "" : (isLast_ ? "   " : unicode"│  ")));

        address[] memory subs = ledgers_.subAccounts(_root);
        for (uint256 i = 0; i < subs.length; i++) {
            logTree(ledgers_, _root, LedgerLib.toAddress(_root, subs[i]), subPrefix, false, i == subs.length - 1);
        }
    }

    function debugTree(Ledger ledgers, address root) internal view {
        logTree(ledgers, address(0), root, "", true, true);
    }
}
