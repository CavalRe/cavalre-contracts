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
        s[6] = "debitBalanceOf(address,address,address)";
        s[7] = "creditBalanceOf(address,address,address)";
        s[8] = "balanceOf(address,address,address)";
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
        s[6] = bytes4(keccak256("debitBalanceOf(address,address,address)"));
        s[7] = bytes4(keccak256("creditBalanceOf(address,address,address)"));
        s[8] = bytes4(keccak256("balanceOf(address,address,address)"));
        s[9] = bytes4(keccak256("totalSupply(address)"));
        s[10] = bytes4(keccak256("isClaim(address)"));
        s[11] = bytes4(keccak256("claimAccountOf(address)"));
    }

    function name(address absolute_) external view returns (string memory) {
        return LedgerLib.name(absolute_);
    }

    function symbol(address absolute_) external view returns (string memory) {
        return LedgerLib.symbol(absolute_);
    }

    function decimals(address absolute_) external view returns (uint8) {
        return LedgerLib.decimals(absolute_);
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

    function debitBalanceOf(address root_, address holderParent_, address relative_) external view returns (uint256) {
        return LedgerLib.debitBalanceOf(LedgerLib.toAddress(root_, holderParent_, relative_));
    }

    function creditBalanceOf(address root_, address holderParent_, address relative_) external view returns (uint256) {
        return LedgerLib.creditBalanceOf(LedgerLib.toAddress(root_, holderParent_, relative_));
    }

    function balanceOf(address root_, address holderParent_, address relative_) external view returns (uint256) {
        (uint256 _flags,, address _absolute) = LedgerLib.effectiveFlags(root_, holderParent_, relative_);
        return LedgerLib.balanceOf(_absolute, LedgerLib.isCredit(_flags));
    }

    function totalSupply(address root_) external view returns (uint256) {
        return LedgerLib.totalSupply(root_);
    }

    function isClaim(address root_) external view returns (bool) {
        return LedgerLib.isClaim(LedgerLib.flags(root_));
    }

    function claimAccountOf(address root_) external view returns (address) {
        return LedgerLib.claimAccount(LedgerLib.flags(root_));
    }
}
