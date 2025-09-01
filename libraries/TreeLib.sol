// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// // ─────────────────────────────────────────────────────────────────────────────
// // Import split layout (interfaces + lib + module + infra)
// // Adjust paths if your repo layout differs.
// // ─────────────────────────────────────────────────────────────────────────────
// import {ILedgers} from "../../interfaces/ILedgers.sol";
import {Ledgers, Lib} from "../modules/Ledgers.sol";
// import {Module} from "../../modules/Module.sol";
// import {Router} from "../../modules/Router.sol";

import {console} from "forge-std/src/Test.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Tree helpers
// ─────────────────────────────────────────────────────────────────────────────
library TreeLib {
    function logTree(Ledgers ledgers, address root, string memory prefix, bool isFirst, bool isLast) internal view {
        string memory label = ledgers.name(root);
        bool isGroup = ledgers.isGroup(root);
        console.log(
            "%s%s%s",
            prefix,
            isFirst ? "" : (isLast ? (isGroup ? unicode"└─ " : unicode"└● ") : (isGroup ? unicode"├─ " : unicode"├● ")),
            label
        );
        string memory subPrefix = string(abi.encodePacked(prefix, isFirst ? "" : (isLast ? "   " : unicode"│  ")));

        address[] memory subs = ledgers.subAccounts(root);
        for (uint256 i = 0; i < subs.length; i++) {
            string memory _name = ledgers.name(subs[i]);
            logTree(ledgers, Lib.toGroupAddress(root, _name), subPrefix, false, i == subs.length - 1);
        }
    }

    function debugTree(Ledgers ledgers, address root) internal view {
        logTree(ledgers, root, "", true, true);
    }
}
