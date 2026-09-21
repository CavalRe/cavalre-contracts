// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";

/// @dev Preserve internal mixed-polarity postings without adding a group solvency constraint.
contract LedgerInternalBalancesTest is Test {
    address private constant L = address(0x100);
    address private constant G = address(0x200);
    address private constant D = address(0x300);
    address private constant C = address(0x400);
    address private constant WALLET = address(0x500);

    function custodyBalance() external view returns (uint256) {
        return LedgerLib.balanceOf(LedgerLib.toAddress(L, G), false);
    }

    function testValidPostingMakesDebitCustodyNormalBalanceNegative() public {
        LedgerLib.addLedger(L, "Token", "T", 18, LedgerLib.TokenKind.Internal);
        LedgerLib.addSubAccountGroup(L, L, G, "Custodian", false);
        LedgerLib.addSubAccount(L, LedgerLib.toAddress(L, G), D, "Debit", false);
        LedgerLib.addSubAccount(L, LedgerLib.toAddress(L, G), C, "Credit", true);

        address custodian_ = LedgerLib.toAddress(L, G);
        // The single ancestry cache stores custody, including for mixed-polarity descendants.
        assertEq(LedgerLib.store().custody[L], address(0));
        assertEq(LedgerLib.ledger(L), L);
        assertEq(LedgerLib.store().custody[custodian_], custodian_);
        assertEq(LedgerLib.store().custody[LedgerLib.toAddress(custodian_, D)], custodian_);
        assertEq(LedgerLib.store().custody[LedgerLib.toAddress(custodian_, C)], custodian_);
        assertEq(
            LedgerLib.store().custody[LedgerLib.toAddress(L, LedgerLib.SOURCE_ADDRESS)],
            LedgerLib.toAddress(L, LedgerLib.SOURCE_ADDRESS)
        );

        // Start with a positive custody balance and balanced root.
        (uint256 sourceFlags_,,) = LedgerLib.effectiveFlags(L, L, LedgerLib.SOURCE_ADDRESS);
        (uint256 debitFlags_,,) = LedgerLib.effectiveFlags(L, LedgerLib.toAddress(L, G), D);
        LedgerLib.transfer(L, sourceFlags_, LedgerLib.SOURCE_ADDRESS, debitFlags_, D, 1);
        assertEq(this.custodyBalance(), 1);

        // Credit the credit leaf by 2; debit an ordinary wallet by 2.
        // Neither leaf is overdrawn. Existing Ledger accepts this posting.
        (uint256 creditFlags_,,) = LedgerLib.effectiveFlags(L, LedgerLib.toAddress(L, G), C);
        (uint256 walletFlags_,,) = LedgerLib.effectiveFlags(L, L, WALLET);
        LedgerLib.transfer(L, creditFlags_, C, walletFlags_, WALLET, 2);

        assertEq(LedgerLib.debitBalanceOf(custodian_), 1);
        assertEq(LedgerLib.creditBalanceOf(custodian_), 2);
        assertEq(LedgerLib.balanceOf(LedgerLib.toAddress(L, WALLET), false), 2);
        assertEq(LedgerLib.debitBalanceOf(L), 3);
        assertEq(LedgerLib.creditBalanceOf(L), 3);
        assertEq(LedgerLib.totalSupply(L), 3);

        // Effective leaves resolve custody without adding either flags or ancestry storage.
        assertEq(LedgerLib.flags(LedgerLib.toAddress(L, WALLET)), 0);
        assertEq(LedgerLib.store().custody[LedgerLib.toAddress(L, WALLET)], address(0));
        assertEq(LedgerLib.ledger(LedgerLib.toAddress(L, WALLET)), address(0));
        (address holder_, bool credit_) = LedgerLib.custody(L, walletFlags_, WALLET);
        assertEq(holder_, WALLET);
        assertFalse(credit_);
        (uint256 nestedFlags_,,) = LedgerLib.effectiveFlags(L, custodian_, WALLET);
        (holder_, credit_) = LedgerLib.custody(L, nestedFlags_, WALLET);
        assertEq(holder_, G);
        assertFalse(credit_);
        assertEq(LedgerLib.store().custody[LedgerLib.toAddress(custodian_, WALLET)], address(0));

        // Required debit-custodian view is 1 - 2 = -1: uint256 underflow.
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        this.custodyBalance();
    }
}
