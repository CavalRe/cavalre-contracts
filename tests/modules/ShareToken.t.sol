// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {Dispatchable} from "../../modules/dispatcher/Dispatchable.sol";
import {IDispatcher} from "../../modules/dispatcher/IDispatcher.sol";
import {Ledger} from "../../modules/ledger/Ledger.sol";
import {TreeLib} from "../../modules/tree/TreeLib.sol";
import {ERC20Wrapper} from "../../modules/ledger/ERC20Wrapper.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {TreeView} from "../../modules/tree/TreeView.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {LedgerTokenFactory} from "../../modules/ledger/LedgerTokenFactory.sol";
import {LedgerTokenFactoryView} from "../../modules/ledger/LedgerTokenFactoryView.sol";
import {ILedgerTokenFactory} from "../../modules/ledger/ILedgerTokenFactory.sol";
import {ShareTokenView} from "../../modules/share/ShareTokenView.sol";
import {ShareTokenLib} from "../../modules/share/ShareTokenLib.sol";
import {ShareToken} from "../../modules/share/ShareToken.sol";
import {IShareToken} from "../../modules/share/IShareToken.sol";
import {IShareTokenView} from "../../modules/share/IShareTokenView.sol";

/// @dev Authorized non-token backing settlement composed directly with share issuance/redemption.
contract ShareApplication is Dispatchable {
    address internal constant SCALE = address(0x500);
    address internal constant GROUP = address(0x501);
    address internal constant BACKING = address(0x502);
    address internal constant OFFSET = address(0x503);

    function signatures() external pure override returns (string[] memory signatures_) {
        signatures_ = new string[](8);
        signatures_[0] = "configure(bool,uint8,bool)";
        signatures_[1] = "issue(address,address,uint256,bool)";
        signatures_[2] = "redeem(address,uint256,bool)";
        signatures_[3] = "changeBacking(address,uint256,bool)";
        signatures_[4] = "holderFlags(address,address)";
        signatures_[5] = "issueAt(address,address,address,uint256)";
        signatures_[6] = "redeemAt(address,address,address,uint256)";
        signatures_[7] = "cancelAt(address,address,address,uint256)";
    }

    function selectors() external pure override returns (bytes4[] memory selectors_) {
        selectors_ = new bytes4[](8);
        selectors_[0] = this.configure.selector;
        selectors_[1] = this.issue.selector;
        selectors_[2] = this.redeem.selector;
        selectors_[3] = this.changeBacking.selector;
        selectors_[4] = this.holderFlags.selector;
        selectors_[5] = this.issueAt.selector;
        selectors_[6] = this.redeemAt.selector;
        selectors_[7] = this.cancelAt.selector;
    }

    function moveBacking(address token_, uint256 amount_, bool add_) internal {
        IShareTokenView.State memory state_ = ShareTokenLib.shareTokenState(token_);
        bool source_ = state_.backingAccount == LedgerLib.toAddress(SCALE, LedgerLib.SOURCE_ADDRESS);
        address relative_ = source_ ? LedgerLib.SOURCE_ADDRESS : BACKING;
        uint256 backingFlags_ = LedgerLib.flags(state_.backingAccount);
        bool credit_ = LedgerLib.isCredit(backingFlags_);
        address other_ = credit_ ? OFFSET : LedgerLib.SOURCE_ADDRESS;
        (uint256 otherFlags_,,) = LedgerLib.effectiveFlags(SCALE, SCALE, other_);
        if (add_ == credit_) LedgerLib.transfer(SCALE, backingFlags_, relative_, otherFlags_, other_, amount_);
        else LedgerLib.transfer(SCALE, otherFlags_, other_, backingFlags_, relative_, amount_);
    }

    function addBacking(address token_, uint256 amount_, bool bad_) internal {
        if (!bad_) moveBacking(token_, amount_, true);
    }

    function releaseBacking(address token_, uint256 amount_, bool bad_) internal {
        if (!bad_) moveBacking(token_, amount_, false);
    }

    function configure(bool credit_, uint8 decimals_, bool source_) external returns (address) {
        enforceIsOwner();
        LedgerLib.addLedger(SCALE, "Scale", "SCALE", decimals_, LedgerLib.TokenKind.Unregistered);
        if (source_) return LedgerLib.toAddress(SCALE, LedgerLib.SOURCE_ADDRESS);
        LedgerLib.addSubAccountGroup(SCALE, SCALE, GROUP, "Nested", credit_);
        LedgerLib.addSubAccount(SCALE, LedgerLib.toAddress(SCALE, GROUP), BACKING, "Backing", credit_);
        return LedgerLib.toAddress(LedgerLib.toAddress(SCALE, GROUP), BACKING);
    }

    function issue(address token_, address holder_, uint256 amount_, bool bad_) external returns (uint256) {
        enforceIsOwner();
        IShareTokenView.State memory before_ = ShareTokenLib.shareTokenState(token_);
        addBacking(token_, amount_, bad_);
        IShareTokenView.State memory after_ = ShareTokenLib.shareTokenState(token_);
        if (after_.supply != before_.supply || after_.backing != before_.backing + amount_) {
            revert IShareToken.InvalidSettlement();
        }
        return ShareTokenLib.issue(token_, token_, holder_, amount_);
    }

    function redeem(address token_, uint256 amount_, bool bad_) external returns (uint256 backing_) {
        IShareTokenView.State memory before_ = ShareTokenLib.shareTokenState(token_);
        backing_ = ShareTokenLib.redeem(token_, token_, msg.sender, amount_);
        releaseBacking(token_, backing_, bad_);
        IShareTokenView.State memory after_ = ShareTokenLib.shareTokenState(token_);
        if (after_.supply != before_.supply - amount_ || after_.backing != before_.backing - backing_) {
            revert IShareToken.InvalidSettlement();
        }
    }

    function changeBacking(address token_, uint256 amount_, bool add_) external {
        enforceIsOwner();
        moveBacking(token_, amount_, add_);
    }

    function issueAt(address token_, address parent_, address relative_, uint256 amount_) external returns (uint256) {
        enforceIsOwner();
        IShareTokenView.State memory before_ = ShareTokenLib.shareTokenState(token_);
        addBacking(token_, amount_, false);
        IShareTokenView.State memory after_ = ShareTokenLib.shareTokenState(token_);
        if (after_.supply != before_.supply || after_.backing != before_.backing + amount_) {
            revert IShareToken.InvalidSettlement();
        }
        return ShareTokenLib.issue(token_, parent_, relative_, amount_);
    }

    function redeemAt(address token_, address parent_, address relative_, uint256 amount_)
        external
        returns (uint256 backing_)
    {
        enforceIsOwner();
        IShareTokenView.State memory before_ = ShareTokenLib.shareTokenState(token_);
        backing_ = ShareTokenLib.redeem(token_, parent_, relative_, amount_);
        releaseBacking(token_, backing_, false);
        IShareTokenView.State memory after_ = ShareTokenLib.shareTokenState(token_);
        if (after_.supply != before_.supply - amount_ || after_.backing != before_.backing - backing_) {
            revert IShareToken.InvalidSettlement();
        }
    }

    function cancelAt(address token_, address parent_, address relative_, uint256 amount_) external {
        enforceIsOwner();
        ShareTokenLib.cancel(token_, parent_, relative_, amount_);
    }

    function holderFlags(address token_, address holder_) external view returns (uint256) {
        return LedgerLib.flags(LedgerLib.toAddress(token_, holder_));
    }
}

contract ShareTokenTest is Test {
    Dispatcher internal dispatcher_;
    ShareApplication internal app_;
    LedgerTokenFactory internal factory_;
    LedgerTokenFactoryView internal prediction_;
    ShareToken internal token_;
    address internal alice_ = address(0xa11ce);
    address internal bob_ = address(0xb0b);

    function setUp() public {
        dispatcher_ = new Dispatcher(address(this));
        address[] memory modules_ = new address[](6);
        modules_[0] = address(new Ledger(18, "Ether", "ETH", 18));
        modules_[1] = address(new LedgerView());
        modules_[2] = address(new LedgerTokenFactory());
        modules_[3] = address(new LedgerTokenFactoryView());
        modules_[4] = address(new ShareTokenView());
        modules_[5] = address(new ShareApplication());
        dispatcher_.addModule(modules_);
        Ledger(payable(address(dispatcher_))).initializeLedger("Ledger", "L");
        app_ = ShareApplication(address(dispatcher_));
        factory_ = LedgerTokenFactory(address(dispatcher_));
        prediction_ = LedgerTokenFactoryView(address(dispatcher_));
    }

    function create(bool credit_, uint8 backingDecimals_, uint8 shareDecimals_, bool source_) internal {
        address backing_ = app_.configure(credit_, backingDecimals_, source_);
        ILedgerTokenFactory.ShareTokenConfig[] memory tokens_ = new ILedgerTokenFactory.ShareTokenConfig[](1);
        tokens_[0] = ILedgerTokenFactory.ShareTokenConfig(backing_, metadata(shareDecimals_));
        (address[] memory tokenAddresses_,) = factory_.createShareTokens(tokens_);
        token_ = ShareToken(tokenAddresses_[0]);
    }

    function metadata(uint8 decimals_) internal pure returns (ILedgerTokenFactory.TokenMetadata memory) {
        return ILedgerTokenFactory.TokenMetadata("Share", "R", decimals_, "1");
    }

    function testShareTokenRegistrationStoresBackingAndPacksParent() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new TreeView());
        dispatcher_.addModule(modules_);
        create(false, 18, 18, false);
        TreeView tree_ = TreeView(address(dispatcher_));
        IShareTokenView view_ = IShareTokenView(address(dispatcher_));
        uint256 flags_ = tree_.flags(address(token_));
        address backing_ = token_.shareTokenState().backingAccount;
        // Ledger flags describe the parent; share registration occupies its own namespace.
        assertEq(flags_, (uint256(uint160(LedgerLib.ROOT_ADDRESS)) << 96) | (2 << 8) | (3 << 3) | 1);
        bytes32 namespace_ =
            keccak256(abi.encode(uint256(keccak256("cavalre.storage.ShareToken")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(
            vm.load(address(dispatcher_), keccak256(abi.encode(address(token_), namespace_))),
            bytes32(uint256(uint160(backing_)))
        );
        LedgerLib.TokenKind kind_ = tree_.tokenKind(flags_);
        assertEq(uint8(kind_), uint8(LedgerLib.TokenKind.Internal));
        assertTrue(view_.isShareToken(address(token_)));
        assertEq(view_.backingAccount(address(token_)), backing_);
        assertEq(LedgerLib.packedAddress(flags_), LedgerLib.ROOT_ADDRESS);
        assertEq(LedgerLib.parent(flags_), LedgerLib.ROOT_ADDRESS);
        assertEq(LedgerLib.parent(tree_.flags(address(0x500))), LedgerLib.ROOT_ADDRESS, "non-token ledger parent");
        assertFalse(tree_.isNative(flags_));
        assertFalse(tree_.isExternal(flags_));
        assertTrue(tree_.isInternal(flags_));
        uint256 sourceFlags_ = tree_.flags(LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS));
        assertTrue(tree_.isCreditLedger(sourceFlags_));
        assertEq(LedgerLib.parent(sourceFlags_), address(token_));
        assertFalse(view_.isShareToken(LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)));
        assertEq(view_.backingAccount(LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)), address(0));
        assertEq(
            dispatcher_.module(IShareTokenView.isShareToken.selector),
            dispatcher_.module(IShareTokenView.shareTokenState.selector)
        );
        assertEq(
            dispatcher_.module(IShareTokenView.backingAccount.selector),
            dispatcher_.module(IShareTokenView.shareTokenState.selector)
        );
        assertTrue(
            dispatcher_.module(TreeView.tokenKind.selector) != dispatcher_.module(IShareTokenView.isShareToken.selector)
        );

        // Share identity survives removal of empty backing, but accounting must reject the missing leaf.
        Ledger(payable(address(dispatcher_)))
            .removeSubAccount(address(0x500), LedgerLib.parent(tree_.flags(backing_)), address(0x502));
        assertTrue(view_.isShareToken(address(token_)));
        assertEq(view_.backingAccount(address(token_)), backing_);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, address(token_)));
        view_.shareTokenState(address(token_));
    }

    function testBackingPersistsAcrossViewReplacement() public {
        create(false, 6, 18, false);
        app_.issue(address(token_), alice_, 100e6, false);
        address backing_ = token_.shareTokenState().backingAccount;
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new TreeView());
        dispatcher_.addModule(modules_);
        TreeView tree_ = TreeView(address(dispatcher_));
        uint256 flags_ = tree_.flags(address(token_));
        assertEq(LedgerLib.packedAddress(flags_), LedgerLib.ROOT_ADDRESS);
        assertEq(LedgerLib.parent(flags_), LedgerLib.ROOT_ADDRESS);

        modules_[0] = dispatcher_.module(IShareTokenView.shareTokenState.selector);
        dispatcher_.removeModule(modules_);
        ShareTokenView replacement_ = new ShareTokenView();
        assertFalse(replacement_.isShareToken(address(token_)), "configuration belongs to Dispatcher storage");
        assertEq(replacement_.backingAccount(address(token_)), address(0));
        modules_[0] = address(replacement_);
        dispatcher_.addModule(modules_);

        IShareTokenView view_ = IShareTokenView(address(dispatcher_));
        assertTrue(view_.isShareToken(address(token_)));
        assertEq(view_.backingAccount(address(token_)), backing_);
        assertEq(token_.shareTokenState().backing, 100e6);
        assertEq(token_.totalSupply(), 100e18);
        assertEq(token_.balanceOf(alice_), 100e18);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 100e18, false), 100e6);
        assertTrue(view_.isShareToken(address(token_)), "full redemption retains registration");
        assertEq(tree_.flags(address(token_)), flags_, "parent flags survive complete redemption");
        assertEq(view_.backingAccount(address(token_)), backing_, "backing binding survives complete redemption");
    }

    function testShareTokenBackingImmutableAndReplayPreservesAccounting() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        app_.changeBacking(address(token_), 50, true);
        address backing_ = token_.shareTokenState().backingAccount;
        ILedgerTokenFactory.ShareTokenConfig[] memory tokens_ = new ILedgerTokenFactory.ShareTokenConfig[](1);
        tokens_[0] = ILedgerTokenFactory.ShareTokenConfig(backing_, metadata(18));
        (address[] memory again_,) = factory_.createShareTokens(tokens_);
        assertEq(again_[0], address(token_));
        tokens_[0].backingAccount = LedgerLib.toAddress(address(0x500), LedgerLib.SOURCE_ADDRESS);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidToken.selector, address(token_), "Share", "R", 18));
        factory_.createShareTokens(tokens_);

        // A conflicting later item rolls back an earlier wrapper deployment and both registrations.
        ILedgerTokenFactory.ShareTokenConfig[] memory batch_ = new ILedgerTokenFactory.ShareTokenConfig[](2);
        batch_[0] = ILedgerTokenFactory.ShareTokenConfig(
            backing_, ILedgerTokenFactory.TokenMetadata("Fresh Share", "FRESH", 18, "1")
        );
        batch_[1] = tokens_[0];
        address fresh_ = prediction_.predictShareTokenAddress("Fresh Share", "FRESH", 18, "1");
        uint256 ledgerCount_ = LedgerView(address(dispatcher_)).ledgerCount();
        assertEq(fresh_.code.length, 0);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidToken.selector, address(token_), "Share", "R", 18));
        factory_.createShareTokens(batch_);
        assertEq(fresh_.code.length, 0, "earlier wrapper deployment rolled back");
        assertEq(
            LedgerView(address(dispatcher_)).ledgerCount(), ledgerCount_, "earlier Ledger registration rolled back"
        );
        assertFalse(IShareTokenView(address(dispatcher_)).isShareToken(fresh_));
        assertEq(IShareTokenView(address(dispatcher_)).backingAccount(fresh_), address(0));
        assertEq(IShareTokenView(address(dispatcher_)).backingAccount(address(token_)), backing_);
        assertEq(token_.shareTokenState().backing, 150);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
    }

    function testShareTokenViewReturnsNestedBackingSnapshot() public {
        create(false, 6, 18, false);
        app_.issue(address(token_), alice_, 400e6, false);
        app_.changeBacking(address(token_), 600e6, true);
        IShareTokenView.State memory state_ = IShareTokenView(address(dispatcher_)).shareTokenState(address(token_));
        assertEq(state_.backingLedger, address(0x500));
        assertEq(
            state_.backingAccount,
            LedgerLib.toAddress(LedgerLib.toAddress(address(0x500), address(0x501)), address(0x502))
        );
        assertEq(state_.supply, 400e18);
        assertEq(state_.backing, 1000e6);
        assertTrue(dispatcher_.module(IShareTokenView.shareTokenState.selector) != address(0));
    }

    function testShareTokenViewRejectsNonShareTokenAndOldLedgerViewSelectorIsAbsent() public {
        create(false, 18, 18, false);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, address(0x500)));
        IShareTokenView(address(dispatcher_)).shareTokenState(address(0x500));
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
        assertEq(token_.convertToShares(2e6), 2e18);
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
        assertEq(token_.shareTokenState().backing, 0);
        assertEq(app_.issue(address(token_), alice_, 1e6, false), 1e18);
    }

    function testCreditNestedBacking() public {
        create(true, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        assertEq(token_.shareTokenState().backingLedger, address(0x500));
        assertEq(token_.shareTokenState().backing, 100);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 100, false), 100);
        assertEq(token_.shareTokenState().backing, 0);
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
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InsufficientAllowance.selector, address(token_), alice_, bob_, 0, 40)
        );
        vm.prank(bob_);
        token_.transferFrom(alice_, LedgerLib.SOURCE_ADDRESS, 40);
        vm.prank(alice_);
        token_.approve(bob_, 40);
        bytes memory error_ = abi.encodeWithSelector(
            ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)
        );
        vm.expectRevert(error_);
        vm.prank(bob_);
        token_.transferFrom(alice_, LedgerLib.SOURCE_ADDRESS, 40);
        assertEq(token_.allowance(alice_, bob_), 40);
        vm.expectRevert(error_);
        vm.prank(alice_);
        token_.transfer(LedgerLib.SOURCE_ADDRESS, 100);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.shareTokenState().backing, 100);

        // Only an authorized consuming module can cancel shares without settlement.
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, bob_));
        vm.prank(bob_);
        app_.cancelAt(address(token_), address(token_), alice_, 40);
        vm.expectEmit(true, true, false, true, address(token_));
        emit ERC20Wrapper.Transfer(alice_, address(0), 40);
        app_.cancelAt(address(token_), address(token_), alice_, 40);
        assertEq(token_.balanceOf(alice_), 60);
        assertEq(token_.totalSupply(), 60);
        assertEq(token_.shareTokenState().backing, 100);
        vm.expectEmit(true, true, false, true, address(token_));
        emit ERC20Wrapper.Transfer(alice_, address(0), 60);
        app_.cancelAt(address(token_), address(token_), alice_, 60);
        assertEq(token_.balanceOf(alice_), 0);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.shareTokenState().backing, 100);
        vm.expectRevert(abi.encodeWithSelector(IShareToken.InvalidShareState.selector, 0, 100));
        app_.issue(address(token_), bob_, 1, false);
    }

    function testRemovedCancellationSelectorCannotBurnShareTokens() public {
        create(false, 18, 18, false);
        app_.issue(address(token_), alice_, 100, false);
        bytes4 selector_ = bytes4(keccak256("cancelReceipt(address,uint256)"));
        assertEq(dispatcher_.module(selector_), address(0));
        vm.prank(alice_);
        (bool success_, bytes memory result_) =
            address(dispatcher_).call(abi.encodeWithSelector(selector_, address(token_), 100));
        assertFalse(success_);
        assertEq(result_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, selector_));
        selector_ = bytes4(keccak256("cancelShareToken(address,address,uint256)"));
        assertEq(dispatcher_.module(selector_), address(0));
        vm.prank(alice_);
        (success_, result_) = address(dispatcher_).call(abi.encodeWithSelector(selector_, address(token_), alice_, 100));
        assertFalse(success_);
        assertEq(result_, abi.encodeWithSelector(IDispatcher.CommandNotFound.selector, selector_));
        vm.prank(alice_);
        (success_,) = address(token_).call(abi.encodeWithSignature("cancel(uint256)", 100));
        assertFalse(success_);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.shareTokenState().backing, 100);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)
            )
        );
        vm.prank(alice_);
        token_.transfer(LedgerLib.SOURCE_ADDRESS, 100);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.shareTokenState().backing, 100);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 100, false), 100);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.shareTokenState().backing, 0);
    }

    function testRegisteredDebitCustodyShareTokenOperations() public {
        create(false, 18, 18, false);
        Ledger(payable(address(dispatcher_))).addSubAccount(address(token_), address(token_), bob_, "Custody", false);
        assertEq(app_.issue(address(token_), bob_, 100, false), 100);
        vm.prank(bob_);
        assertEq(app_.redeem(address(token_), 25, false), 25);
        assertEq(token_.shareTokenState().backing, 75);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(address(token_), LedgerLib.SOURCE_ADDRESS)
            )
        );
        vm.prank(bob_);
        token_.transfer(LedgerLib.SOURCE_ADDRESS, 25);
        assertEq(token_.balanceOf(bob_), 75);
        assertEq(token_.totalSupply(), 75);
        assertEq(token_.shareTokenState().backing, 75);
        vm.prank(bob_);
        assertEq(app_.redeem(address(token_), 75, false), 75);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.shareTokenState().backing, 0);
    }

    function testNestedDebitCustodyShareTokenOperations() public {
        create(false, 18, 18, false);
        Ledger ledger_ = Ledger(payable(address(dispatcher_)));
        (address group_,) =
            ledger_.addSubAccountGroup(address(token_), address(token_), address(0xcafe), "Custody Group", true);
        (address absolute_,) = ledger_.addSubAccount(address(token_), group_, bob_, "Custody", false);
        assertEq(absolute_, LedgerLib.toAddress(group_, bob_));
        assertEq(app_.issueAt(address(token_), group_, bob_, 100), 100);
        // ERC20 holder keys cannot alias a nested accounting address.
        assertEq(token_.balanceOf(absolute_), 0);
        vm.expectRevert();
        vm.prank(absolute_);
        token_.transfer(alice_, 1);
        assertEq(app_.redeemAt(address(token_), group_, bob_, 20), 20);
        app_.cancelAt(address(token_), group_, bob_, 30);
        assertEq(LedgerView(address(dispatcher_)).balanceOf(address(token_), group_, bob_), 50);
        assertEq(token_.totalSupply(), 50);
        assertEq(token_.shareTokenState().backing, 80);
        assertEq(app_.redeemAt(address(token_), group_, bob_, 50), 80);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.shareTokenState().backing, 0);
    }

    function testUnauthorizedIssueAndRedemption() public {
        create(false, 18, 18, false);
        ILedgerTokenFactory.ShareTokenConfig[] memory tokens_ = new ILedgerTokenFactory.ShareTokenConfig[](1);
        tokens_[0] = ILedgerTokenFactory.ShareTokenConfig(token_.shareTokenState().backingAccount, metadata(18));
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, bob_));
        vm.prank(bob_);
        factory_.createShareTokens(tokens_);
        vm.expectRevert(abi.encodeWithSelector(IDispatcher.OwnableUnauthorizedAccount.selector, bob_));
        vm.prank(bob_);
        app_.issue(address(token_), bob_, 10, false);
        app_.issue(address(token_), alice_, 100, false);
        vm.expectRevert();
        vm.prank(bob_);
        app_.redeem(address(token_), 10, false);
        assertEq(token_.shareTokenState().backing, 100);
        vm.expectRevert();
        vm.prank(bob_);
        token_.transfer(alice_, 1);
    }

    function testBadSettlementRollsBack() public {
        create(false, 18, 18, false);
        vm.expectRevert(IShareToken.InvalidSettlement.selector);
        app_.issue(address(token_), alice_, 100, true);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.shareTokenState().backing, 0);
        app_.issue(address(token_), alice_, 100, false);
        // Existing backing cannot be reused as if a new contribution had been settled.
        vm.expectRevert(IShareToken.InvalidSettlement.selector);
        app_.issue(address(token_), bob_, 50, true);
        assertEq(token_.balanceOf(bob_), 0);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.shareTokenState().backing, 100);
        vm.expectRevert(IShareToken.InvalidSettlement.selector);
        vm.prank(alice_);
        app_.redeem(address(token_), 100, true);
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.shareTokenState().backing, 100);
    }

    function testRoundingAndZeroAmounts() public {
        create(false, 18, 6, false);
        vm.expectRevert(IShareToken.InvalidShareAmount.selector);
        app_.issue(address(token_), alice_, 1, false);
        // A share-side failure also rolls back the backing posting made before issue.
        assertEq(token_.shareTokenState().backing, 0);
        assertEq(LedgerView(address(dispatcher_)).totalSupply(address(0x500)), 0);
        app_.issue(address(token_), alice_, 3e12, false);
        app_.changeBacking(address(token_), 1, true);
        assertEq(token_.convertToBacking(1), 1e12);
        assertEq(token_.convertToShares(1e12), 0);
        vm.prank(alice_);
        app_.redeem(address(token_), 1, false);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 2, false), 2e12 + 1);
        assertEq(token_.convertToShares(0), 0);
        vm.expectRevert(IShareToken.InvalidShareAmount.selector);
        app_.issue(address(token_), alice_, 0, false);
    }

    function testZeroBackingLossAndDustRedemption() public {
        create(false, 6, 18, false);
        app_.issue(address(token_), alice_, 1, false);
        vm.expectRevert(IShareToken.InvalidShareAmount.selector);
        vm.prank(alice_);
        app_.redeem(address(token_), 1, false);
        app_.changeBacking(address(token_), 1, false);
        vm.expectRevert(abi.encodeWithSelector(IShareToken.InvalidShareState.selector, 1e12, 0));
        app_.issue(address(token_), alice_, 1, false);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), 1e12, false), 0);
        assertEq(token_.totalSupply(), 0);
    }

    function testDecimalDifferenceGuardAndZeroDecimals() public {
        create(false, 0, 78, false);
        vm.expectRevert(IShareToken.UnsupportedDecimalDifference.selector);
        token_.convertToShares(1);
        vm.expectRevert(IShareToken.UnsupportedDecimalDifference.selector);
        token_.convertToBacking(1);
    }

    function testFactoryPredictionIdempotenceAndInternalSeparation() public {
        create(false, 18, 18, false);
        assertEq(prediction_.predictShareTokenAddress("Share", "R", 18, "1"), address(token_));
        ILedgerTokenFactory.ShareTokenConfig[] memory shares_ = new ILedgerTokenFactory.ShareTokenConfig[](1);
        shares_[0] = ILedgerTokenFactory.ShareTokenConfig(token_.shareTokenState().backingAccount, metadata(18));
        (address[] memory again_, uint256[] memory shareFlags_) = factory_.createShareTokens(shares_);
        assertEq(again_[0], address(token_));
        shares_[0].backingAccount = LedgerLib.toAddress(address(0x500), LedgerLib.SOURCE_ADDRESS);
        vm.expectRevert();
        factory_.createShareTokens(shares_);
        ILedgerTokenFactory.TokenMetadata[] memory tokens_ = new ILedgerTokenFactory.TokenMetadata[](1);
        tokens_[0] = metadata(18);
        (address[] memory internal_, uint256[] memory internalFlags_) = factory_.createInternalTokens(tokens_);
        assertEq(internalFlags_[0], shareFlags_[0], "share identity is independent of Ledger flags");
        assertEq(internal_[0], prediction_.predictERC20TokenAddress("Share", "R", 18, "1"));
        assertTrue(internal_[0] != address(token_));
        (address[] memory againInternal_,) = factory_.createInternalTokens(tokens_);
        assertEq(internal_[0], againInternal_[0]);
        IShareTokenView view_ = IShareTokenView(address(dispatcher_));
        assertTrue(view_.isShareToken(address(token_)));
        assertFalse(view_.isShareToken(internal_[0]));
        assertEq(view_.backingAccount(internal_[0]), address(0));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, internal_[0]));
        view_.shareTokenState(internal_[0]);

        (again_, shareFlags_) = factory_.createShareTokens(new ILedgerTokenFactory.ShareTokenConfig[](0));
        assertEq(again_.length, 0);
        assertEq(shareFlags_.length, 0);
        assertEq(
            dispatcher_.module(bytes4(keccak256("createReceiptToken(address,(string,string,uint8,string))"))),
            address(0)
        );
        assertEq(
            dispatcher_.module(bytes4(keccak256("createInternalToken((string,string,uint8,string)[])"))), address(0)
        );
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

    function testInvalidShareTokenAccountsCannotIssueRedeemOrCancel() public {
        create(false, 18, 18, false);
        Ledger ledger_ = Ledger(payable(address(dispatcher_)));
        address[5] memory holders_ = [address(0), LedgerLib.SOURCE_ADDRESS, address(0xc), address(0xd), address(0xcc)];
        ledger_.addSubAccount(address(token_), address(token_), holders_[2], "Credit Leaf", true);
        ledger_.addSubAccountGroup(address(token_), address(token_), holders_[3], "Debit Group", false);
        ledger_.addSubAccountGroup(address(token_), address(token_), holders_[4], "Credit Group", true);
        app_.issue(address(token_), alice_, 100, false);
        for (uint256 i_; i_ < holders_.length; ++i_) {
            bytes memory error_ = abi.encodeWithSelector(
                ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(address(token_), holders_[i_])
            );
            vm.expectRevert(error_);
            app_.issue(address(token_), holders_[i_], 1, false);
            vm.expectRevert(error_);
            vm.prank(holders_[i_]);
            app_.redeem(address(token_), 1, false);
            vm.expectRevert();
            vm.prank(holders_[i_]);
            token_.transfer(alice_, 1);
        }
        assertEq(token_.balanceOf(alice_), 100);
        assertEq(token_.totalSupply(), 100);
        assertEq(token_.shareTokenState().backing, 100);
    }

    function testInitialZeroDecimalsAndFloorIssuance() public {
        create(false, 0, 0, false);
        app_.issue(address(token_), alice_, 3, false);
        app_.changeBacking(address(token_), 4, true);
        assertEq(app_.issue(address(token_), bob_, 5, false), 2);
        assertEq(token_.totalSupply(), 5);
        assertEq(token_.shareTokenState().backing, 12);
        assertEq(token_.convertToBacking(5), 12);
    }

    function testFullPrecisionRatio() public {
        create(false, 18, 18, false);
        uint256 large_ = uint256(1) << 200;
        app_.issue(address(token_), alice_, large_, false);
        app_.changeBacking(address(token_), large_, true);
        // Intermediate products exceed 256 bits, but their quotients fit.
        assertEq(token_.convertToShares(large_), large_ / 2);
        assertEq(token_.convertToBacking(large_), large_ * 2);
        vm.prank(alice_);
        assertEq(app_.redeem(address(token_), large_, false), large_ * 2);
    }

    function testInitializationScaleOverflow() public {
        create(false, 0, 77, false);
        assertEq(token_.convertToShares(1), 10 ** 77);
        vm.expectRevert();
        app_.issue(address(token_), alice_, 2, false);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.shareTokenState().backing, 0);
    }

    function testOccupiedShareTokenPredictionRejected() public {
        address backing_ = app_.configure(false, 18, false);
        address predicted_ = prediction_.predictShareTokenAddress("Share", "R", 18, "1");
        ILedgerTokenFactory.ShareTokenConfig[] memory tokens_ = new ILedgerTokenFactory.ShareTokenConfig[](1);
        tokens_[0] = ILedgerTokenFactory.ShareTokenConfig(backing_, metadata(18));
        vm.etch(predicted_, hex"00");
        vm.expectRevert();
        factory_.createShareTokens(tokens_);

        vm.etch(predicted_, hex"");
        factory_.createShareTokens(tokens_);
        // Leave a matching Internal ledger and wrapper at the predicted address, without share registration.
        bytes32 namespace_ =
            keccak256(abi.encode(uint256(keccak256("cavalre.storage.ShareToken")) - 1)) & ~bytes32(uint256(0xff));
        vm.store(address(dispatcher_), keccak256(abi.encode(predicted_, namespace_)), bytes32(0));
        IShareTokenView view_ = IShareTokenView(address(dispatcher_));
        assertFalse(view_.isShareToken(predicted_));
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidToken.selector, predicted_, "Share", "R", 18));
        factory_.createShareTokens(tokens_);
        assertEq(view_.backingAccount(predicted_), address(0));
        assertFalse(view_.isShareToken(predicted_));
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
            .transfer(
                address(0x500),
                LedgerLib.toAddress(address(0x500), address(0x501)),
                address(0x502),
                address(0x500),
                bob_,
                100
            );
        assertEq(token_.shareTokenState().backing, 100);
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

        // Leave one raw share unit after partial redemptions. All rounding
        // remainder must stay in backing until that final unit is redeemed.
        uint256 remainingShares_ = uint256(initial_) - partBounded_;
        uint256 released_ = quote_;
        if (remainingShares_ > 1) {
            vm.prank(alice_);
            released_ += app_.redeem(address(token_), remainingShares_ - 1, false);
        }
        IShareTokenView.State memory last_ = token_.shareTokenState();
        assertEq(last_.supply, 1);
        assertEq(last_.backing, backing_ - released_);
        assertEq(token_.convertToBacking(1), last_.backing);
        vm.prank(alice_);
        uint256 finalBacking_ = app_.redeem(address(token_), 1, false);
        assertEq(finalBacking_, last_.backing);
        assertEq(released_ + finalBacking_, backing_);
        assertEq(token_.totalSupply(), 0);
        assertEq(token_.balanceOf(alice_), 0);
        assertEq(token_.shareTokenState().backing, 0);
    }

    function assertShareTokenRoot() internal view {
        TreeLib.TreeNode memory root_ = TreeView(address(dispatcher_)).treeNode(address(token_));
        assertEq(root_.debit, root_.credit);
        assertEq(root_.debit, token_.totalSupply());
        root_ = TreeView(address(dispatcher_)).treeNode(token_.shareTokenState().backingLedger);
        assertEq(root_.debit, root_.credit);
    }

    function testShareTokenCustodyProjectionAndPublicRestrictions() public {
        address[] memory modules_ = new address[](1);
        modules_[0] = address(new TreeView());
        dispatcher_.addModule(modules_);
        create(false, 18, 18, false);
        Ledger ledger_ = Ledger(payable(address(dispatcher_)));
        address custodian_ = address(0xcafe);
        (address group_,) = ledger_.addSubAccountGroup(address(token_), address(token_), custodian_, "Custody", false);
        vm.expectEmit(true, true, false, true, address(token_));
        emit ERC20Wrapper.Transfer(address(0), custodian_, 100);
        app_.issueAt(address(token_), group_, bob_, 100);
        assertEq(token_.balanceOf(custodian_), 100);
        assertShareTokenRoot();
        vm.prank(custodian_);
        vm.expectRevert();
        token_.transfer(alice_, 1);
        vm.prank(custodian_);
        token_.approve(alice_, 1);
        vm.prank(alice_);
        vm.expectRevert();
        token_.transferFrom(custodian_, alice_, 1);
        assertEq(token_.allowance(custodian_, alice_), 1);
        vm.prank(custodian_);
        vm.expectRevert();
        token_.transfer(bob_, 1);
        assertEq(token_.balanceOf(custodian_), 100);
        vm.expectEmit(true, true, false, true, address(token_));
        emit ERC20Wrapper.Transfer(custodian_, address(0), 20);
        app_.cancelAt(address(token_), group_, bob_, 20);
        assertEq(token_.balanceOf(custodian_), 80);
        assertShareTokenRoot();
        app_.redeemAt(address(token_), group_, bob_, 40);
        assertEq(token_.balanceOf(custodian_), 40);
        assertEq(token_.shareTokenState().backing, 50);
        assertShareTokenRoot();
        app_.issue(address(token_), alice_, 50, false);
        assertShareTokenRoot();
        vm.prank(alice_);
        vm.expectRevert();
        token_.transfer(alice_, 41);
        vm.prank(alice_);
        token_.approve(bob_, 40);
        vm.prank(bob_);
        vm.expectEmit(true, true, false, true, address(token_));
        emit ERC20Wrapper.Transfer(alice_, alice_, 40);
        token_.transferFrom(alice_, alice_, 40);
        assertEq(token_.allowance(alice_, bob_), 0);
        assertShareTokenRoot();
    }
}
