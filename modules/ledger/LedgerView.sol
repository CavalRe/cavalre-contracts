// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedger} from "./ILedger.sol";
import {ILedgerView} from "./ILedgerView.sol";
import {LedgerLib} from "./LedgerLib.sol";

contract LedgerView is Dispatchable, ILedgerView {
    function checkLedgerParent(address ledger_, address parent_) private view {
        if (!LedgerLib.isLedger(LedgerLib.flags(ledger_))) revert ILedger.InvalidLedgerAccount(ledger_);
        address _absoluteParent = parent_ == ledger_ ? ledger_ : LedgerLib.toAddress(ledger_, parent_);
        if (!LedgerLib.isGroup(LedgerLib.flags(_absoluteParent))) revert ILedger.InvalidAccountGroup();
    }

    function signatures() external pure override returns (string[] memory s) {
        s = new string[](15);
        s[0] = "name(address)";
        s[1] = "symbol(address)";
        s[2] = "decimals(address)";
        s[3] = "nativeName()";
        s[4] = "nativeSymbol()";
        s[5] = "nativeDecimals()";
        s[6] = "ledgerCount()";
        s[7] = "ledgerAt(uint256)";
        s[8] = "ledgers(uint256,uint256)";
        s[9] = "debitBalanceOf(address,address,address)";
        s[10] = "creditBalanceOf(address,address,address)";
        s[11] = "balanceOf(address,address,address)";
        s[12] = "totalSupply(address)";
        s[13] = "isClaim(address)";
        s[14] = "claimAccountOf(address)";
    }

    function selectors() external pure override returns (bytes4[] memory s) {
        s = new bytes4[](15);
        s[0] = bytes4(keccak256("name(address)"));
        s[1] = bytes4(keccak256("symbol(address)"));
        s[2] = bytes4(keccak256("decimals(address)"));
        s[3] = bytes4(keccak256("nativeName()"));
        s[4] = bytes4(keccak256("nativeSymbol()"));
        s[5] = bytes4(keccak256("nativeDecimals()"));
        s[6] = bytes4(keccak256("ledgerCount()"));
        s[7] = bytes4(keccak256("ledgerAt(uint256)"));
        s[8] = bytes4(keccak256("ledgers(uint256,uint256)"));
        s[9] = bytes4(keccak256("debitBalanceOf(address,address,address)"));
        s[10] = bytes4(keccak256("creditBalanceOf(address,address,address)"));
        s[11] = bytes4(keccak256("balanceOf(address,address,address)"));
        s[12] = bytes4(keccak256("totalSupply(address)"));
        s[13] = bytes4(keccak256("isClaim(address)"));
        s[14] = bytes4(keccak256("claimAccountOf(address)"));
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

    function ledgerCount() external view returns (uint256) {
        return LedgerLib.ledgerCount();
    }

    function ledgerAt(uint256 index_) external view returns (address) {
        return LedgerLib.ledgerAt(index_);
    }

    function ledgers(uint256 start_, uint256 limit_) external view returns (address[] memory) {
        return LedgerLib.ledgers(start_, limit_);
    }

    function debitBalanceOf(address ledger_, address parent_, address relative_) external view returns (uint256) {
        checkLedgerParent(ledger_, parent_);
        return LedgerLib.debitBalanceOf(LedgerLib.toAddress(ledger_, parent_, relative_));
    }

    function creditBalanceOf(address ledger_, address parent_, address relative_) external view returns (uint256) {
        checkLedgerParent(ledger_, parent_);
        return LedgerLib.creditBalanceOf(LedgerLib.toAddress(ledger_, parent_, relative_));
    }

    function balanceOf(address ledger_, address parent_, address relative_) external view returns (uint256) {
        checkLedgerParent(ledger_, parent_);
        (uint256 _flags,, address _absolute) = LedgerLib.effectiveFlags(ledger_, parent_, relative_);
        return LedgerLib.balanceOf(_absolute, LedgerLib.isCredit(_flags));
    }

    function totalSupply(address ledger_) external view returns (uint256) {
        return LedgerLib.totalSupply(ledger_);
    }

    function isClaim(address ledger_) external view returns (bool) {
        return LedgerLib.isClaim(LedgerLib.flags(ledger_));
    }

    function claimAccountOf(address ledger_) external view returns (address) {
        return LedgerLib.claimAccount(LedgerLib.flags(ledger_));
    }
}
