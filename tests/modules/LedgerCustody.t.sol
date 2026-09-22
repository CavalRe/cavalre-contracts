// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20WrapperTest} from "./ERC20Wrapper.t.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {ERC20Wrapper} from "../../modules/ledger/ERC20Wrapper.sol";
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {TreeLib} from "../../modules/tree/TreeLib.sol";
import {Vm} from "forge-std/src/Vm.sol";

contract LedgerCustodyTest is ERC20WrapperTest {
    struct Custodian {
        address holder;
        address absolute;
        bool credit;
    }

    function makeCustodian(address holder_, bool credit_) internal returns (Custodian memory c) {
        c.holder = holder_;
        c.credit = credit_;
        vm.startPrank(owner);
        (c.absolute,) = ledgers.addSubAccountGroup(address(token), address(token), holder_, "Custody", credit_);
        ledgers.addSubAccount(address(token), c.absolute, alice, "Debit", false);
        ledgers.addSubAccount(address(token), c.absolute, bob, "Credit", true);
        vm.stopPrank();
        ledgers.mint(address(token), c.absolute, alice, credit_ ? 40 : 100);
        ledgers.rawTransfer(address(token), c.absolute, bob, address(token), carol, credit_ ? 100 : 40);
        assertEq(token.balanceOf(holder_), 60);
        assertEq(ledgerView.debitBalanceOf(address(token), address(token), holder_), credit_ ? 40 : 100);
        assertEq(ledgerView.creditBalanceOf(address(token), address(token), holder_), credit_ ? 100 : 40);
    }

    function assertSupply() internal view {
        TreeLib.TreeNode memory root_ = tree.treeNode(address(token));
        assertEq(root_.debit, root_.credit);
        assertEq(root_.debit, token.totalSupply());
        assertEq(root_.debit - root_.credit, 0);
    }

    // Covers all 16 combinations of custodian and endpoint polarities with live net balances.
    function testFuzzCustodianProjection(bool fromCredit_, bool toCredit_, bool fromLeafCredit_, bool toLeafCredit_)
        public
    {
        Custodian memory from_ = makeCustodian(address(0x101), fromCredit_);
        Custodian memory to_ = makeCustodian(address(0x102), toCredit_);
        uint256 supply_ = token.totalSupply();
        {
            address fromLeaf_ = fromLeafCredit_ ? bob : alice;
            address toLeaf_ = toLeafCredit_ ? bob : alice;
            address eventFrom_ = fromCredit_ ? address(0) : from_.holder;
            address eventTo_ = toCredit_ ? address(0) : to_.holder;
            if (fromCredit_ && toCredit_) {
                eventFrom_ = to_.holder;
                eventTo_ = from_.holder;
            }
            vm.recordLogs();
            ledgers.rawTransfer(address(token), from_.absolute, fromLeaf_, to_.absolute, toLeaf_, 7);
            Vm.Log[] memory logs_ = vm.getRecordedLogs();
            uint256 transfers_;
            bool creditFound_;
            bool debitFound_;
            for (uint256 i_; i_ < logs_.length; ++i_) {
                if (logs_[i_].topics[0] == TRANSFER_TOPIC) {
                    ++transfers_;
                    assertEq(logs_[i_].emitter, address(token));
                    assertEq(address(uint160(uint256(logs_[i_].topics[1]))), eventFrom_);
                    assertEq(address(uint160(uint256(logs_[i_].topics[2]))), eventTo_);
                    assertEq(abi.decode(logs_[i_].data, (uint256)), 7);
                } else {
                    assertEq(logs_[i_].emitter, address(dispatcher));
                    if (
                        logs_[i_].topics[0] == keccak256("Credit(address,address,uint256,uint256)")
                            && address(uint160(uint256(logs_[i_].topics[2])))
                                == LedgerLib.toAddress(from_.absolute, fromLeaf_)
                    ) creditFound_ = true;
                    if (
                        logs_[i_].topics[0] == keccak256("Debit(address,address,uint256,uint256)")
                            && address(uint160(uint256(logs_[i_].topics[2])))
                                == LedgerLib.toAddress(to_.absolute, toLeaf_)
                    ) debitFound_ = true;
                }
            }
            assertEq(transfers_, 1);
            assertTrue(creditFound_);
            assertTrue(debitFound_);
        }
        assertEq(token.balanceOf(from_.holder), fromCredit_ ? 67 : 53);
        assertEq(token.balanceOf(to_.holder), toCredit_ ? 53 : 67);
        assertEq(
            token.totalSupply(),
            fromLeafCredit_ == toLeafCredit_ ? supply_ : (fromLeafCredit_ ? supply_ + 7 : supply_ - 7)
        );
        assertSupply();
    }

    function testRecursiveDeepEffectiveLeavesAndNoAccountingAlias() public {
        address ledger_ = address(token);
        vm.startPrank(owner);
        (address other_,) = createInternalToken("Other", "O", 18, "1");
        address parent_ = ledger_;
        address otherParent_ = other_;
        address[] memory ancestors_ = new address[](12);
        for (uint256 i_; i_ < ancestors_.length; ++i_) {
            address expected_ = address(uint160(uint256(keccak256(abi.encodePacked(parent_, carol)))));
            (address next_,) = ledgers.addSubAccountGroup(ledger_, parent_, carol, "Deep", false);
            (otherParent_,) = ledgers.addSubAccountGroup(other_, otherParent_, carol, "Deep", false);
            assertEq(next_, expected_);
            assertNotEq(next_, otherParent_);
            assertNotEq(next_, parent_);
            assertEq(tree.ledger(next_), ledger_);
            assertEq(tree.ledger(otherParent_), other_);
            parent_ = next_;
            ancestors_[i_] = next_;
        }
        vm.stopPrank();
        address absolute_ = LedgerLib.toAddress(parent_, alice);
        assertEq(tree.flags(absolute_), 0);
        assertEq(tree.ledger(absolute_), address(0));
        ledgers.mint(ledger_, parent_, alice, 100);
        assertEq(tree.flags(absolute_), 0);
        assertEq(tree.ledger(absolute_), address(0));
        for (uint256 i_; i_ < ancestors_.length; ++i_) {
            TreeLib.TreeNode memory node_ = tree.treeNode(ledger_, i_ == 0 ? ledger_ : ancestors_[i_ - 1], carol);
            assertEq(node_.debit, 100);
            assertEq(node_.credit, 0);
        }
        assertEq(token.balanceOf(carol), 100);
        assertEq(token.balanceOf(absolute_), 0);
        vm.prank(absolute_);
        vm.expectRevert();
        token.transfer(bob, 1);
        vm.prank(absolute_);
        token.approve(bob, 1);
        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(absolute_, bob, 1);
        // Funding the numerically equal ERC20 holder creates a distinct direct account.
        ledgers.mint(ledger_, ledger_, absolute_, 9);
        vm.prank(absolute_);
        token.transfer(bob, 9);
        assertEq(ledgerView.balanceOf(ledger_, parent_, alice), 100);
        assertEq(token.balanceOf(carol), 100);
        assertSupply();
    }

    function testRecursiveAddressRejectsFormerHolderFlattening() public {
        address ledger_ = address(token);
        vm.startPrank(owner);
        (address parent_,) = ledgers.addSubAccountGroup(ledger_, ledger_, carol, "Custody", false);
        (address child_,) = ledgers.addSubAccount(ledger_, parent_, alice, "Position", false);
        vm.stopPrank();

        address expected_ = address(uint160(uint256(keccak256(abi.encodePacked(parent_, alice)))));
        address formerHolder_ = LedgerLib.toAddress(carol, alice);
        address formerAccount_ = LedgerLib.toAddress(ledger_, formerHolder_);
        assertEq(parent_, LedgerLib.toAddress(ledger_, carol));
        assertEq(child_, expected_);
        assertNotEq(child_, formerAccount_);
        assertEq(LedgerLib.parent(tree.flags(child_)), parent_);
        assertEq(tree.ledger(parent_), ledger_);
        assertEq(tree.ledger(child_), ledger_);
        ledgers.mint(ledger_, parent_, alice, 100);
        assertEq(ledgerView.balanceOf(ledger_, parent_, alice), 100);
        assertEq(token.balanceOf(carol), 100);
        assertEq(token.balanceOf(formerHolder_), 0);
        assertEq(tree.flags(formerAccount_), 0);
        assertSupply();
    }

    function testSelfInternalAndZeroEventsKeepCustodyBalances() public {
        for (uint256 i_; i_ < 2; ++i_) {
            Custodian memory c = makeCustodian(address(uint160(0x201 + i_)), i_ == 1);
            vm.expectEmit(true, true, false, true, address(token));
            emit ERC20Wrapper.Transfer(c.holder, c.holder, 5);
            ledgers.rawTransfer(address(token), c.absolute, alice, c.absolute, alice, 5);
            vm.expectEmit(true, true, false, true, address(token));
            emit ERC20Wrapper.Transfer(c.holder, c.holder, 5);
            ledgers.rawTransfer(address(token), c.absolute, bob, c.absolute, alice, 5);
            vm.expectEmit(true, true, false, true, address(token));
            emit ERC20Wrapper.Transfer(c.holder, c.holder, 0);
            ledgers.rawTransfer(address(token), c.absolute, alice, c.absolute, bob, 0);
            assertEq(token.balanceOf(c.holder), 60);
            assertSupply();
        }
    }

    function testPublicCustodyRestrictionsAndSelfTransferAllowance() public {
        Custodian memory c = makeCustodian(address(0x301), false);
        bytes memory groupError_ = abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, c.absolute);
        vm.prank(c.holder);
        vm.expectRevert(groupError_);
        token.transfer(alice, 1);
        vm.prank(c.holder);
        token.approve(bob, 1);
        vm.prank(bob);
        vm.expectRevert(groupError_);
        token.transferFrom(c.holder, alice, 1);
        assertEq(token.allowance(c.holder, bob), 1);
        vm.prank(carol);
        vm.expectRevert(groupError_);
        token.transfer(c.holder, 1);
        vm.prank(address(token));
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledgers.transfer(address(token), c.absolute, alice, address(token), bob, 1);
        vm.prank(address(token));
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledgers.transfer(address(token), address(token), carol, c.absolute, alice, 1);
        vm.prank(address(token));
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledgers.transfer(address(token), c.absolute, alice, c.absolute, alice, 0);
        assertEq(token.balanceOf(c.holder), 60);
        assertEq(token.balanceOf(carol), 40);
        assertEq(ledgerView.balanceOf(address(token), c.absolute, alice), 100);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InsufficientBalance.selector,
                address(token),
                address(token),
                LedgerLib.toAddress(address(token), alice),
                1
            )
        );
        token.transfer(alice, 1);
        ledgers.mint(address(token), address(token), alice, 10);
        vm.prank(alice);
        token.approve(bob, 11);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InsufficientBalance.selector,
                address(token),
                address(token),
                LedgerLib.toAddress(address(token), alice),
                11
            )
        );
        token.transferFrom(alice, alice, 11);
        assertEq(token.allowance(alice, bob), 11);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true, address(token));
        emit ERC20Wrapper.Transfer(alice, alice, 10);
        token.transferFrom(alice, alice, 10);
        assertEq(token.allowance(alice, bob), 1);
        assertEq(token.balanceOf(alice), 10);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.Unauthorized.selector, alice));
        token.emitTransfer(alice, bob, 100);
        assertSupply();
    }

    function testFuzzCustodyConservationAcrossPostings(uint256 seed_) public {
        Custodian memory c = makeCustodian(address(0x401), false);
        for (uint256 i_; i_ < 32; ++i_) {
            seed_ = uint256(keccak256(abi.encode(seed_, i_)));
            uint256 amount_ = seed_ % 21;
            // Internal issuance and cancellation change gross supply while net custody stays 60.
            ledgers.rawTransfer(address(token), c.absolute, bob, c.absolute, alice, amount_);
            assertEq(token.balanceOf(c.holder), 60);
            assertSupply();
            ledgers.rawTransfer(address(token), c.absolute, alice, c.absolute, bob, amount_);
            assertEq(token.balanceOf(c.holder), 60);
            ledgers.rawTransfer(address(token), c.absolute, alice, address(token), alice, amount_);
            assertEq(token.balanceOf(c.holder), 60 - amount_);
            vm.prank(alice);
            token.transfer(bob, amount_);
            ledgers.rawTransfer(address(token), address(token), bob, c.absolute, alice, amount_);
            assertEq(token.balanceOf(c.holder), 60);
            assertSupply();
        }
    }

    function testFuzzExternalAndNativeWrappingPreserveRootSupply(uint96 amount_) public {
        vm.assume(amount_ > 0);
        externalToken.mint(alice, amount_);
        vm.startPrank(alice);
        externalToken.approve(address(dispatcher), amount_);
        ledgers.wrap(address(externalToken), amount_);
        TreeLib.TreeNode memory root_ = tree.treeNode(address(externalToken));
        assertEq(root_.debit, amount_);
        assertEq(root_.credit, amount_);
        assertEq(ledgerView.totalSupply(address(externalToken)), amount_);
        ledgers.unwrap(address(externalToken), amount_);
        root_ = tree.treeNode(address(externalToken));
        assertEq(root_.debit, 0);
        assertEq(root_.credit, 0);
        vm.stopPrank();
        vm.prank(owner);
        ledgers.addNativeToken();
        vm.deal(alice, amount_);
        vm.prank(alice);
        (bool success_,) = address(dispatcher).call{value: amount_}("");
        assertTrue(success_);
        root_ = tree.treeNode(LedgerLib.NATIVE_ADDRESS);
        assertEq(root_.debit, amount_);
        assertEq(root_.credit, amount_);
        assertEq(ledgerView.totalSupply(LedgerLib.NATIVE_ADDRESS), amount_);
        vm.prank(alice);
        ledgers.unwrap(LedgerLib.NATIVE_ADDRESS, amount_);
        root_ = tree.treeNode(LedgerLib.NATIVE_ADDRESS);
        assertEq(root_.debit, 0);
        assertEq(root_.credit, 0);
    }
}
