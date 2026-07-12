// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedgerView} from "./ILedgerView.sol";
import {LedgerLib} from "./LedgerLib.sol";

contract LedgerView is Dispatchable, ILedgerView {
    function signatures() external pure override returns (string[] memory s) {
        s = new string[](12);
        s[0] = "name(address)";
        s[1] = "symbol(address)";
        s[2] = "decimals(address)";
        s[3] = "nativeName()";
        s[4] = "nativeSymbol()";
        s[5] = "nativeDecimals()";
        s[6] = "debitBalanceOf(address,address)";
        s[7] = "creditBalanceOf(address,address)";
        s[8] = "balanceOf(address,address)";
        s[9] = "totalSupply(address)";
        s[10] = "isClaim(address)";
        s[11] = "claimAccountOf(address)";
    }

    function selectors() external pure override returns (bytes4[] memory s) {
        s = new bytes4[](12);
        s[0] = bytes4(keccak256("name(address)"));
        s[1] = bytes4(keccak256("symbol(address)"));
        s[2] = bytes4(keccak256("decimals(address)"));
        s[3] = bytes4(keccak256("nativeName()"));
        s[4] = bytes4(keccak256("nativeSymbol()"));
        s[5] = bytes4(keccak256("nativeDecimals()"));
        s[6] = bytes4(keccak256("debitBalanceOf(address,address)"));
        s[7] = bytes4(keccak256("creditBalanceOf(address,address)"));
        s[8] = bytes4(keccak256("balanceOf(address,address)"));
        s[9] = bytes4(keccak256("totalSupply(address)"));
        s[10] = bytes4(keccak256("isClaim(address)"));
        s[11] = bytes4(keccak256("claimAccountOf(address)"));
    }

    function name(address a) external view returns (string memory) {
        return LedgerLib.name(a);
    }

    function symbol(address a) external view returns (string memory) {
        return LedgerLib.symbol(a);
    }

    function decimals(address a) external view returns (uint8) {
        return LedgerLib.decimals(a);
    }

    function nativeName() external view returns (string memory) {
        return LedgerLib.nativeName();
    }

    function nativeSymbol() external view returns (string memory) {
        return LedgerLib.nativeSymbol();
    }

    function nativeDecimals() external view returns (uint8) {
        return LedgerLib.nativeDecimals();
    }

    function debitBalanceOf(address p, address a) external view returns (uint256) {
        return LedgerLib.debitBalanceOf(LedgerLib.toAddress(p, a));
    }

    function creditBalanceOf(address p, address a) external view returns (uint256) {
        return LedgerLib.creditBalanceOf(LedgerLib.toAddress(p, a));
    }

    function balanceOf(address p, address a) external view returns (uint256) {
        (address x, uint256 f) = LedgerLib.effectiveFlags(p, a);
        return LedgerLib.balanceOf(x, LedgerLib.isCredit(f));
    }

    function totalSupply(address t) external view returns (uint256) {
        return LedgerLib.totalSupply(t);
    }

    function isClaim(address t) external view returns (bool) {
        return LedgerLib.isClaim(LedgerLib.flags(t));
    }

    function claimAccountOf(address t) external view returns (address) {
        return LedgerLib.claimAccount(t);
    }
}
