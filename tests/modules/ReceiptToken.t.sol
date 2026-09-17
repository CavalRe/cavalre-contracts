// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {Dispatchable} from "../../modules/dispatcher/Dispatchable.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {Ledger} from "../../modules/ledger/Ledger.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {TreeView} from "../../modules/tree/TreeView.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {LedgerTokenFactory} from "../../modules/ledger/LedgerTokenFactory.sol";
import {LedgerTokenFactoryView} from "../../modules/ledger/LedgerTokenFactoryView.sol";
import {ILedgerTokenFactory} from "../../modules/ledger/ILedgerTokenFactory.sol";
import {ReceiptToken} from "../../modules/receipt/ReceiptToken.sol";
import {ReceiptTokenView} from "../../modules/receipt/ReceiptTokenView.sol";
import {ReceiptTokenLib} from "../../modules/receipt/ReceiptTokenLib.sol";
import {ReceiptWrapper} from "../../modules/receipt/ReceiptWrapper.sol";
import {IReceiptToken} from "../../modules/receipt/IReceiptToken.sol";
import {IReceiptTokenView} from "../../modules/receipt/IReceiptTokenView.sol";

/// @dev Example authorized application settlement against a non-token ledger; no ERC20 calls.
contract ReceiptApplication is Dispatchable {
    address internal constant SCALE = address(0x500);
    address internal constant GROUP = address(0x501);
    address internal constant BACKING = address(0x502);
    address internal constant OFFSET = address(0x503);

    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](5);
        signatures_[0] = "configure(bool,uint8,bool)";
        signatures_[1] = "issue(address,address,uint256,bool)";
        signatures_[2] = "redeem(address,uint256,bool)";
        signatures_[3] = "changeBacking(address,uint256,bool)";
        signatures_[4] = "holderFlags(address,address)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](5);
        selectors_[0] = this.configure.selector;
        selectors_[1] = this.issue.selector;
        selectors_[2] = this.redeem.selector;
        selectors_[3] = this.changeBacking.selector;
        selectors_[4] = this.holderFlags.selector;
    }

    function configure(bool credit_, uint8 decimals_, bool source_) external returns (address) {
        enforceIsOwner();
        LedgerLib.addLedger(SCALE, "Scale", "SCALE", decimals_, LedgerLib.TokenKind.Unregistered, address(0));
        if (source_) return LedgerLib.toAddress(SCALE, LedgerLib.SOURCE_ADDRESS);
        LedgerLib.addSubAccountGroup(SCALE, SCALE, GROUP, "Nested", credit_);
        LedgerLib.addSubAccount(SCALE, GROUP, BACKING, "Backing", credit_);
        return LedgerLib.toAddress(SCALE, GROUP, BACKING);
    }

    function issue(address token_, address holder_, uint256 amount_, bool bad_) external returns (uint256) {
        enforceIsOwner();
        return ReceiptTokenLib.issue(token_, holder_, amount_, abi.encode(bad_), addBacking);
    }

    function redeem(address token_, uint256 amount_, bool bad_) external returns (uint256) {
        return ReceiptTokenLib.redeem(token_, msg.sender, amount_, abi.encode(bad_), releaseBacking);
    }

    function changeBacking(address token_, uint256 amount_, bool add_) external {
        enforceIsOwner();
        moveBacking(token_, amount_, add_);
    }

    function holderFlags(address token_, address holder_) external view returns (uint256) {
        return LedgerLib.flags(LedgerLib.toAddress(token_, holder_));
    }

    function addBacking(address token_, uint256 amount_, bytes memory data_) internal {
        if (!abi.decode(data_, (bool))) moveBacking(token_, amount_, true);
    }

    function releaseBacking(address token_, uint256 amount_, bytes memory data_) internal {
        if (!abi.decode(data_, (bool))) moveBacking(token_, amount_, false);
    }

    function moveBacking(address token_, uint256 amount_, bool add_) internal {
        IReceiptTokenView.State memory state_ = ReceiptTokenLib.receiptState(token_);
        bool source_ = state_.backingAccount == LedgerLib.toAddress(SCALE, LedgerLib.SOURCE_ADDRESS);
        address parent_ = source_ ? SCALE : GROUP;
        address relative_ = source_ ? LedgerLib.SOURCE_ADDRESS : BACKING;
        bool credit_ = LedgerLib.isCredit(LedgerLib.flags(state_.backingAccount));
        address other_ = credit_ ? OFFSET : LedgerLib.SOURCE_ADDRESS;
        if (add_ == credit_) LedgerLib.transfer(SCALE, parent_, relative_, SCALE, other_, amount_);
        else LedgerLib.transfer(SCALE, SCALE, other_, parent_, relative_, amount_);
    }
}

contract ReceiptTokenTest is Test {
    Dispatcher internal dispatcher_;
    ReceiptApplication internal app_;
    LedgerTokenFactory internal factory_;
    LedgerTokenFactoryView internal prediction_;
    ReceiptToken internal receipt_;
    ReceiptWrapper internal token_;
    address internal alice_ = address(0xa11ce);
    address internal bob_ = address(0xb0b);

    function setUp() public {
        dispatcher_ = new Dispatcher(address(this));
        address[] memory modules_ = new address[](7);
        modules_[0] = address(new Ledger(18, "Ether", "ETH", 18));
        modules_[1] = address(new LedgerView());
        modules_[2] = address(new LedgerTokenFactory());
        modules_[3] = address(new LedgerTokenFactoryView());
        modules_[4] = address(new ReceiptToken());
        modules_[5] = address(new ReceiptTokenView());
        modules_[6] = address(new ReceiptApplication());
        dispatcher_.addModule(modules_);
        Ledger(payable(address(dispatcher_))).initializeLedger("Ledger", "L");
        app_ = ReceiptApplication(address(dispatcher_));
        factory_ = LedgerTokenFactory(address(dispatcher_));
        prediction_ = LedgerTokenFactoryView(address(dispatcher_));
        receipt_ = ReceiptToken(address(dispatcher_));
    }

    function create(bool credit_, uint8 backingDecimals_, uint8 receiptDecimals_, bool source_) internal {
        address backing_ = app_.configure(credit_, backingDecimals_, source_);
        (address tokenAddress_,) = factory_.createReceiptToken(backing_, metadata(receiptDecimals_));
        token_ = ReceiptWrapper(tokenAddress_);
    }

    function metadata(uint8 decimals_) internal pure returns (ILedgerTokenFactory.TokenMetadata memory) {
        return ILedgerTokenFactory.TokenMetadata("Receipt", "R", decimals_, "1");
    }

    function testReceiptRegistrationPacksBackingAndKeepsRootParent() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new TreeView());
        dispatcher_.addModule(modules_);
        create(false, 18, 18, false);
        TreeView tree_ = TreeView(address(dispatcher_));
        IReceiptTokenView view_ = IReceiptTokenView(address(dispatcher_));
        uint256 flags_ = tree_.flags(address(token_));
        address backing_ = token_.receiptState().backingAccount;
        // The packed lane stores backing, while kind remains Internal and the parent remains Root.
        assertEq(flags_, (uint256(uint160(backing_)) << 96) | (2 << 8) | (3 << 3) | 1);
        LedgerLib.TokenKind kind_ = tree_.tokenKind(flags_);
        assertEq(uint8(kind_), uint8(LedgerLib.TokenKind.Internal));
        assertTrue(view_.isReceipt(address(token_)));
        assertEq(view_.receiptAccount(address(token_)), backing_);
        assertEq(LedgerLib.parent(flags_), LedgerLib.ROOT_ADDRESS);
        assertFalse(tree_.isNative(flags_));
        assertFalse(tree_.isExternal(flags_));
        assertTrue(tree_.isInternal(flags_));
        uint256 sourceFlags_ = tree_.flags(LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS));
        assertTrue(tree_.isCreditLedger(sourceFlags_));
        assertFalse(view_.isReceipt(LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)));
        assertEq(view_.receiptAccount(LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)), address(0));
        assertEq(
            dispatcher_.module(IReceiptTokenView.isReceipt.selector),
            dispatcher_.module(IReceiptTokenView.receiptState.selector)
        );
        assertEq(
            dispatcher_.module(IReceiptTokenView.receiptAccount.selector),
            dispatcher_.module(IReceiptTokenView.receiptState.selector)
        );
        assertTrue(
            dispatcher_.module(TreeView.tokenKind.selector) != dispatcher_.module(IReceiptTokenView.isReceipt.selector)
        );
    }

    function testPackedBackingPersistsAcrossViewReplacement() public {
        create(false, 6, 18, false);
        app_.issue(address(token_), alice_, 100e6, false);
        address backing_ = token_.receiptState().backingAccount;
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new TreeView());
        dispatcher_.addModule(modules_);
        TreeView tree_ = TreeView(address(dispatcher_));
        uint256 flags_ = tree_.flags(address(token_));
        assertEq(LedgerLib.packedAddress(flags_), backing_);
        assertEq(LedgerLib.parent(flags_), LedgerLib.ROOT_ADDRESS);

        modules_[0] = dispatcher_.module(IReceiptTokenView.receiptState.selector);
        dispatcher_.removeModule(modules_);
        ReceiptTokenView replacement_ = new ReceiptTokenView();
        assertFalse(replacement_.isReceipt(address(token_)), "configuration belongs to Dispatcher storage");
        modules_[0] = address(replacement_);
        dispatcher_.addModule(modules_);

        IReceiptTokenView view_ = IReceiptTokenView(address(dispatcher_));
        assertTrue(view_.isReceipt(address(token_)));
        assertEq(view_.receiptAccount(address(token_)), backing_);
        assertEq(token_.receiptState().backing, 100e6);
        assertEq(token_.totalSupply(), 100e18);
        assertEq(token_.balanceOf(alice_), 100e18);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 100e18, false), 100e6);
        assertTrue(view_.isReceipt(address(token_)), "full redemption retains registration");
        assertEq(tree_.flags(address(token_)), flags_, "backing survives complete redemption");
    }

    function testReceiptBackingImmutableAndReplayPreservesAccounting() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        app_.changeBacking(address(token_), 50, true);
        address backing_ = token_.receiptState().backingAccount;
        (address again_,) = factory_.createReceiptToken(backing_, metadata(18));
        assertEq(again_, address(token_));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidToken.selector, address(token_), "Receipt", "R", 18));
        factory_.createReceiptToken(LedgerLib.toAddress(address(0x500), LedgerLib.SOURCE_ADDRESS), metadata(18));
        assertEq(IReceiptTokenView(address(dispatcher_)).receiptAccount(address(token_)), backing_);
        assertEq(token_.receiptState().backing, 150);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
    }

    function testReceiptViewReturnsNestedBackingSnapshot() public {
        create(false, 6, 18, false);
        app_.issue(address(token_), alice_, 400e6, false);
        app_.changeBacking(address(token_), 600e6, true);
        IReceiptTokenView.State memory state_ = IReceiptTokenView(address(dispatcher_)).receiptState(address(token_));
        assertEq(state_.backingLedger, address(0x500));
        assertEq(state_.backingAccount, LedgerLib.toAddress(address(0x500), address(0x501), address(0x502)));
        assertEq(state_.supply, 400e18);
        assertEq(state_.backing, 1000e6);
        assertTrue(dispatcher_.module(IReceiptTokenView.receiptState.selector) != address(0));
    }

    function testReceiptViewRejectsNonReceiptAndOldLedgerViewSelectorIsAbsent() public {
        create(false, 18, 18, false);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, address(0x500)));
        IReceiptTokenView(address(dispatcher_)).receiptState(address(0x500));
        bytes4 oldSelector_ = bytes4(keccak256("receiptToken(address)"));
        assertEq(dispatcher_.module(oldSelector_), address(0));
        (bool success_, bytes memory reason_) =
            address(dispatcher_).call(abi.encodeWithSelector(oldSelector_, address(token_)));
        assertFalse(success_);
        assertEq(reason_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, oldSelector_));
    }

    function testDebitNonTokenBackingAndCompleteRedemption() public {
        create(false, 6, 18, false);
        assertEq(address(0x500).code.length, 0);
        assertEq(token_.convertToReceipts(2e6), 2e18);
        assertEq(token_.convertToBacking(2e18), 2e6);
        assertEq(app_.issue(address(token_), alice_, 2e6, false), 2e18);
        app_.changeBacking(address(token_), 1e6, true);
        assertEq(app_.issue(address(token_), bob_, 3e6, false), 2e18);
        assertEq(app_.holderFlags(address(token_), alice_), 0);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 1e18, false), 15e5);
        vm.prank(bob_);
        token_.transfer(alice_, 2e18);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 3e18, false), 45e5);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.receiptState().backing, 0);
        assertEq(app_.issue(address(token_), alice_, 1e6, false), 1e18);
    }

    function testCreditNestedBacking() public {
        create(true, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        assertEq(token_.receiptState().backingLedger, address(0x500));
        assertEq(token_.receiptState().backing, 100);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 100, false), 100);
        assertEq(token_.receiptState().backing, 0);
    }

    function testSourceBacking() public {
        create(true, 18, 18, true);
        app_.issue(address(token_), alice_, 100, false);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 100, false), 100);
    }

    function testCancellationAuthorizationAndOrphanBacking() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        vm.prank(alice_);
        token_.approve(bob_, 100);
        vm.expectRevert(abi.encodeWithSelector(ILedger.Unauthorized.selector, bob_));
        vm.prank(bob_);
        receipt_.cancelReceipt(address(token_), alice_, 10);
        vm.expectRevert(abi.encodeWithSelector(ILedger.Unauthorized.selector, alice_));
        vm.prank(alice_);
        receipt_.cancelReceipt(address(token_), alice_, 10);
        vm.prank(alice_);
        token_.cancel(40);
        assertEq(token_.totalSupply(), 60);
        assertEq(token_.receiptState().backing, 100);
        vm.prank(alice_);
        token_.cancel(60);
        vm.expectRevert(abi.encodeWithSelector(IReceiptToken.InvalidReceiptState.selector, 0, 100));
        app_.issue(address(token_), bob_, 1, false);
    }

    function testRemovedCancellationSelectorCannotBurnReceipts() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        bytes4 selector_ = bytes4(keccak256("cancelReceipt(address,uint256)"));
        assertEq(dispatcher_.module(selector_), address(0));
        vm.prank(alice_);
        (bool success_, bytes memory result_) =
            address(dispatcher_).call(abi.encodeWithSelector(selector_, address(token_), 100));
        assertFalse(success_);
        assertEq(result_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, selector_));
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.receiptState().backing, 100);
        vm.prank(alice_);
        token_.cancel(100);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.receiptState().backing, 100);
    }

    function testRegisteredDebitCustodyReceiptOperations() public {
        create(false, 18, 18, false);
        Ledger(payable(address(dispatcher_))).addSubAccount(address(token_), address(token_), bob_, "Custody", false);
        assertEq(app_.issue(address(token_), bob_, 100, false), 100);
        vm.prank(bob_);
        assertEq(app_.redeem(address(token_), 25, false), 25);
        assertEq(token_.receiptState().backing, 75);
        vm.prank(bob_);
        token_.cancel(25);
        assertEq(token_.balanceOf(bob_), 50);
        assertEq(token_.totalSupply(), 50);
        assertEq(token_.receiptState().backing, 75);
        vm.prank(bob_);
        assertEq(app_.redeem(address(token_), 50, false), 75);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.receiptState().backing, 0);
    }

    function testNestedDebitCustodyReceiptOperations() public {
        create(false, 18, 18, false);
        Ledger ledger_ = Ledger(payable(address(dispatcher_)));
        address group_ = address(0xcafe);
        // Holder polarity comes from the leaf even beneath a credit group.
        ledger_.addSubAccountGroup(address(token_), address(token_), group_, "Custody Group", true);
        (address holder_,) = ledger_.addSubAccount(address(token_), group_, bob_, "Custody", false);
        assertEq(holder_, LedgerLib.toAddress(group_, bob_));
        assertEq(app_.issue(address(token_), holder_, 100, false), 100);
        app_.issue(address(token_), alice_, 20, false);
        vm.prank(alice_);
        token_.transfer(holder_, 20);
        assertEq(token_.balanceOf(holder_), 120);
        vm.prank(holder_);
        assertEq(app_.redeem(address(token_), 20, false), 20);
        vm.prank(holder_);
        token_.cancel(50);
        assertEq(token_.balanceOf(holder_), 50);
        assertEq(token_.totalSupply(), 50);
        assertEq(token_.receiptState().backing, 100);
        vm.prank(holder_);
        assertEq(app_.redeem(address(token_), 50, false), 100);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.receiptState().backing, 0);
    }

    function testUnauthorizedIssueAndRedemption() public {
        create(false, 18, 18, false);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, bob_));
        vm.prank(bob_);
        app_.issue(address(token_), bob_, 10, false);
        app_.issue(address(token_), alice_, 100, false);
        vm.expectRevert();
        vm.prank(bob_);
        app_.redeem(address(token_), 10, false);
        assertEq(token_.receiptState().backing, 100);
        vm.expectRevert();
        vm.prank(bob_);
        token_.cancel(1);
    }

    function testBadSettlementRollsBack() public {
        create(false, 18, 18, false);
        vm.expectRevert(IReceiptToken.InvalidSettlement.selector);
        app_.issue(address(token_), alice_, 100, true);
        assertEq(token_.totalSupply(), 0);
        app_.issue(address(token_), alice_, 100, false);
        vm.expectRevert(IReceiptToken.InvalidSettlement.selector);
        vm.prank(alice_);
        app_.redeem(address(token_), 100, true);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.receiptState().backing, 100);
    }

    function testRoundingAndZeroAmounts() public {
        create(false, 18, 6, false);
        vm.expectRevert(IReceiptToken.InvalidReceiptAmount.selector);
        app_.issue(address(token_), alice_, 1, false);
        app_.issue(address(token_), alice_, 3e12, false);
        app_.changeBacking(address(token_), 1, true);
        assertEq(token_.convertToBacking(1), 1e12);
        assertEq(token_.convertToReceipts(1e12), 0);
        vm.prank(alice_);
        app_.redeem(address(token_), 1, false);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 2, false), 2e12 + 1);
        assertEq(token_.convertToReceipts(0), 0);
        vm.expectRevert(IReceiptToken.InvalidReceiptAmount.selector);
        app_.issue(address(token_), alice_, 0, false);
    }

    function testZeroBackingLossAndDustRedemption() public {
        create(false, 6, 18, false);
        app_.issue(address(token_), alice_, 1, false);
        vm.expectRevert(IReceiptToken.InvalidReceiptAmount.selector);
        vm.prank(alice_);
        app_.redeem(address(token_), 1, false);
        app_.changeBacking(address(token_), 1, false);
        vm.expectRevert(abi.encodeWithSelector(IReceiptToken.InvalidReceiptState.selector, 1e12, 0));
        app_.issue(address(token_), alice_, 1, false);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 1e12, false), 0);
        assertEq(token_.totalSupply(), 0);
    }

    function testDecimalDifferenceGuardAndZeroDecimals() public {
        create(false, 0, 78, false);
        vm.expectRevert(IReceiptToken.UnsupportedDecimalDifference.selector);
        token_.convertToReceipts(1);
        vm.expectRevert(IReceiptToken.UnsupportedDecimalDifference.selector);
        token_.convertToBacking(1);
    }

    function testFactoryPredictionIdempotenceAndInternalSeparation() public {
        create(false, 18, 18, false);
        assertEq(prediction_.predictReceiptToken("Receipt", "R", 18, "1"), address(token_));
        (address again_,) = factory_.createReceiptToken(token_.receiptState().backingAccount, metadata(18));
        assertEq(again_, address(token_));
        vm.expectRevert();
        factory_.createReceiptToken(LedgerLib.toAddress(address(0x500), LedgerLib.SOURCE_ADDRESS), metadata(18));
        ILedgerTokenFactory.TokenMetadata[] memory tokens_ = new ILedgerTokenFactory.TokenMetadata[](1);
        tokens_[0] = metadata(18);
        (address[] memory internal_,) = factory_.createInternalToken(tokens_);
        assertEq(internal_[0], prediction_.predictToken("Receipt", "R", 18, "1"));
        assertTrue(internal_[0] != address(token_));
        (address[] memory againInternal_,) = factory_.createInternalToken(tokens_);
        assertEq(internal_[0], againInternal_[0]);
        IReceiptTokenView view_ = IReceiptTokenView(address(dispatcher_));
        assertTrue(view_.isReceipt(address(token_)));
        assertFalse(view_.isReceipt(internal_[0]));
        assertEq(view_.receiptAccount(internal_[0]), address(0));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, internal_[0]));
        view_.receiptState(internal_[0]);
    }

    function testSharedAllowanceAndRemovedTransferSelector() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        vm.prank(alice_);
        token_.approve(bob_, 30);
        vm.prank(bob_);
        token_.transferFrom(alice_, bob_, 20);
        assertEq(token_.allowance(alice_, bob_), 10);
        assertEq(token_.balanceOf(bob_), 20);
        (bool success_,) = address(dispatcher_)
            .call(
                abi.encodeWithSignature(
                    "transfer(address,address,address,address,uint256)",
                    address(token_),
                    address(token_),
                    address(token_),
                    bob_,
                    1
                )
            );
        assertFalse(success_);
        assertEq(token_.totalSupply(), 100);
    }

    function testInvalidHoldersCannotIssueRedeemOrCancel() public {
        create(false, 18, 18, false);
        Ledger ledger_ = Ledger(payable(address(dispatcher_)));
        address[5] memory holders_ = [address(0), LedgerLib.SOURCE_ADDRESS, address(0xc), address(0xd), address(0xcc)];
        ledger_.addSubAccount(address(token_), address(token_), holders_[2], "Credit Leaf", true);
        ledger_.addSubAccountGroup(address(token_), address(token_), holders_[3], "Debit Group", false);
        ledger_.addSubAccountGroup(address(token_), address(token_), holders_[4], "Credit Group", true);
        app_.issue(address(token_), alice_, 100, false);
        for (uint256 i_; i_ < holders_.length; ++i_) {
            bytes memory error_ = abi.encodeWithSelector(IReceiptToken.InvalidReceiptHolder.selector, holders_[i_]);
            vm.expectRevert(error_);
            app_.issue(address(token_), holders_[i_], 1, false);
            vm.expectRevert(error_);
            vm.prank(holders_[i_]);
            app_.redeem(address(token_), 1, false);
            vm.expectRevert(error_);
            vm.prank(holders_[i_]);
            token_.cancel(1);
        }
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.receiptState().backing, 100);
    }

    function testInitialZeroDecimalsAndFloorIssuance() public {
        create(false, 0, 0, false);
        app_.issue(address(token_), alice_, 3, false);
        app_.changeBacking(address(token_), 4, true);
        assertEq(app_.issue(address(token_), bob_, 5, false), 2);
        assertEq(token_.totalSupply(), 5);
        assertEq(token_.receiptState().backing, 12);
        assertEq(token_.convertToBacking(5), 12);
    }

    function testFullPrecisionRatio() public {
        create(false, 18, 18, false);
        uint256 large_ = uint256(1) << 200;
        app_.issue(address(token_), alice_, large_, false);
        app_.changeBacking(address(token_), large_, true);
        // Intermediate products exceed 256 bits, but their quotients fit.
        assertEq(token_.convertToReceipts(large_), large_ / 2);
        assertEq(token_.convertToBacking(large_), large_ * 2);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), large_, false), large_ * 2);
    }

    function testInitializationScaleOverflow() public {
        create(false, 0, 77, false);
        assertEq(token_.convertToReceipts(1), 10 ** 77);
        vm.expectRevert();
        app_.issue(address(token_), alice_, 2, false);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.receiptState().backing, 0);
    }

    function testOccupiedReceiptPredictionRejected() public {
        address backing_ = app_.configure(false, 18, false);
        address predicted_ = prediction_.predictReceiptToken("Receipt", "R", 18, "1");
        vm.etch(predicted_, hex"00");
        vm.expectRevert();
        factory_.createReceiptToken(backing_, metadata(18));
    }

    function testBackingReferenceDoesNotExposePublicIssuanceOrRelease() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        vm.prank(bob_);
        (bool success_,) = address(dispatcher_)
            .call(abi.encodeWithSignature("issueReceipt(address,address,uint256)", address(token_), bob_, 100));
        assertFalse(success_);
        vm.expectRevert();
        vm.prank(bob_);
        Ledger(payable(address(dispatcher_)))
            .transfer(address(0x500), address(0x501), address(0x502), address(0x500), bob_, 100);
        assertEq(token_.receiptState().backing, 100);
        assertEq(token_.totalSupply(), 100);
    }

    function testFuzzProportionalRedemption(uint96 initial_, uint96 gain_, uint96 part_) public {
        vm.assume(initial_ > 1);
        uint256 partBounded_ = bound(uint256(part_), 1, uint256(initial_) - 1);
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, initial_, false);
        app_.changeBacking(address(token_), gain_, true);
        uint256 backing_ = uint256(initial_) + gain_;
        uint256 quote_ = partBounded_ * backing_ / initial_;
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), partBounded_, false), quote_);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), uint256(initial_) - partBounded_, false), backing_ - quote_);
        assertEq(token_.receiptState().backing, 0);
    }
}
