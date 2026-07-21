// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/src/Test.sol";
import {Vm} from "forge-std/src/Vm.sol";

import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {Ledger} from "../../modules/ledger/Ledger.sol";
import {ERC20Wrapper} from "../../modules/ledger/ERC20Wrapper.sol";
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {LedgerTokenFactory} from "../../modules/ledger/LedgerTokenFactory.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {TreeView} from "../../modules/tree/TreeView.sol";

import {TestLedger, MockERC20} from "./Ledger.t.sol";

contract ERC20WrapperTest is Test {
    bytes32 internal constant TRANSFER_TOPIC = keccak256("Transfer(address,address,uint256)");

    Dispatcher internal dispatcher;
    TestLedger internal ledgers; // will point to Dispatcher after module add
    LedgerTokenFactory internal ledgerTokenFactory;
    LedgerView internal ledgerView;
    TreeView internal tree;
    ERC20Wrapper internal token;
    MockERC20 internal externalToken;

    address internal owner = address(0xA11CE);
    address internal alice = address(0xB0B);
    address internal bob = address(0xCA11);
    address internal carol = address(0xD00D);
    address internal source_;

    struct MatrixLeg {
        address parent;
        address relative;
        uint8 depth;
        bool isCredit;
        bool isUnregistered;
    }

    struct ExpectedWrapperTransfer {
        bool emitted;
        address from;
        address to;
    }

    address[] internal indexedHolders;
    mapping(address => uint256) internal indexedBalances;

    function setUp() public {
        bool isVerbose = false;

        if (isVerbose) console.log("setUp");
        vm.startPrank(owner);

        // Deploy Ledger impl, register in Dispatcher, then speak to it at Dispatcher address
        if (isVerbose) console.log("Deploying Ledger impl");
        TestLedger impl = new TestLedger(18, 18);
        LedgerTokenFactory ledgerTokenFactoryImpl = new LedgerTokenFactory();
        LedgerView ledgerViewImpl = new LedgerView();
        TreeView treeImpl = new TreeView();
        if (isVerbose) console.log("Deploying Dispatcher");
        dispatcher = new Dispatcher(owner);
        if (isVerbose) console.log("Registering Ledger impl");
        dispatcher.addModule(address(impl));
        dispatcher.addModule(address(ledgerTokenFactoryImpl));
        dispatcher.addModule(address(ledgerViewImpl));
        dispatcher.addModule(address(treeImpl));
        if (isVerbose) console.log("Instantiating Test Ledger");
        ledgers = TestLedger(payable(address(dispatcher)));
        ledgerTokenFactory = LedgerTokenFactory(payable(address(dispatcher)));
        ledgerView = LedgerView(payable(address(dispatcher)));
        tree = TreeView(payable(address(dispatcher)));

        if (isVerbose) console.log("Initializing Test Ledger");
        ledgers.initializeTestLedger();
        source_ = LedgerLib.SOURCE_ADDRESS;

        if (isVerbose) console.log("Adding new token to ledger");
        (address token_,) = ledgerTokenFactory.createInternalToken("Internal Test Token", "ITT", 18, "");
        token = ERC20Wrapper(token_);
        ledgers.addSubAccount(address(token), address(token), source_, LedgerLib.SOURCE_NAME, true);

        if (isVerbose) console.log("Creating external token");
        externalToken = new MockERC20("External Token", "EXT", 18);
        ledgers.addExternalToken(address(externalToken));
        ledgers.addSubAccount(address(externalToken), address(externalToken), source_, LedgerLib.SOURCE_NAME, true);

        if (isVerbose) console.log("Token added");

        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Metadata
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperInit() public view {
        bool isVerbose = true;

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(dispatcher));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(token));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(externalToken));
        if (isVerbose) console.log("--------------------");

        assertEq(token.totalSupply(), 0);
    }

    function testERC20WrapperMetadata() public view {
        assertEq(token.name(), "Internal Test Token");
        assertEq(token.symbol(), "ITT");
        assertEq(token.decimals(), 18);
        assertEq(token.dispatcher(), address(dispatcher));
        assertEq(token.totalSupply(), 0);

        assertEq(ledgerView.name(address(token)), "Internal Test Token");
        assertEq(ledgerView.symbol(address(token)), "ITT");
        assertEq(ledgerView.decimals(address(token)), 18);
        assertEq(ledgerView.totalSupply(address(token)), 0);
    }

    function testERC20WrapperCreateInternalToken() public {
        vm.startPrank(owner);

        (address _newRoot,) = ledgerTokenFactory.createInternalToken("New Test Token", "NTT", 18, "");
        address _newToken = _newRoot;
        assertEq(ERC20Wrapper(_newToken).name(), "New Test Token");
        assertEq(ERC20Wrapper(_newToken).symbol(), "NTT");
        assertEq(ERC20Wrapper(_newToken).decimals(), 18);
        assertEq(ERC20Wrapper(_newToken).totalSupply(), 0);

        assertEq(ledgerView.name(_newRoot), "New Test Token");
        assertEq(ledgerView.symbol(_newRoot), "NTT");
        assertEq(ledgerView.decimals(_newRoot), 18);
    }

    function testERC20WrapperClaimRootMintTransferBurn() public {
        vm.startPrank(owner);
        (address claimToken_,) =
            ledgerTokenFactory.createClaimToken("Claim Token", "CLM", 18, address(token), address(token), source_, "");
        vm.stopPrank();

        ERC20Wrapper claim = ERC20Wrapper(claimToken_);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(claim));
        emit ERC20Wrapper.Transfer(address(0), alice, 1_000);
        ledgers.mint(claimToken_, claimToken_, alice, 1_000);

        assertEq(claim.totalSupply(), 1_000);
        assertEq(claim.balanceOf(alice), 1_000);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(claim));
        emit ERC20Wrapper.Transfer(alice, bob, 400);
        assertTrue(claim.transfer(bob, 400));

        assertEq(claim.balanceOf(alice), 600);
        assertEq(claim.balanceOf(bob), 400);
        assertEq(claim.totalSupply(), 1_000);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(claim));
        emit ERC20Wrapper.Transfer(bob, address(0), 150);
        ledgers.burn(claimToken_, claimToken_, bob, 150);

        assertEq(claim.balanceOf(bob), 250);
        assertEq(claim.totalSupply(), 850);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mint / Transfer / Burn
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMintTransferBurn() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Mint 1000 to alice");
        ledgers.mint(address(token), address(token), alice, 1_000);

        if (isVerbose) console.log("totalSupply()");
        assertEq(token.totalSupply(), 1_000);
        assertEq(token.balanceOf(address(0)), 0);

        if (isVerbose) console.log("balanceOf(alice)");
        assertEq(token.balanceOf(alice), 1_000);

        if (isVerbose) {
            console.log("Transfer -> ERC20 Transfer(alice, bob, 700)");
        }
        assertTrue(token.transfer(bob, 700));

        assertEq(token.balanceOf(alice), 300);
        assertEq(token.balanceOf(bob), 700);
        assertEq(token.totalSupply(), 1_000);
        assertEq(token.balanceOf(address(0)), 0);

        if (isVerbose) console.log("Burn -> ERC20 Transfer(bob, 0x0, 200)");
        vm.stopPrank();
        vm.startPrank(bob);

        ledgers.burn(address(token), address(token), bob, 200);

        assertEq(token.balanceOf(bob), 500);
        assertEq(token.totalSupply(), 800);
        assertEq(token.balanceOf(address(0)), 0);
    }

    function testERC20WrapperTransferToSelfEmitsTransfer() public {
        vm.prank(owner);
        ledgers.mint(address(token), address(token), alice, 1_000);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(alice, alice, 250);
        assertTrue(token.transfer(alice, 250));

        assertEq(token.balanceOf(alice), 1_000);
        assertEq(token.totalSupply(), 1_000);
    }

    function testERC20WrapperZeroTransferEmitsTransfer() public {
        vm.prank(owner);
        ledgers.mint(address(token), address(token), alice, 1_000);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(alice, bob, 0);
        assertTrue(token.transfer(bob, 0));

        assertEq(token.balanceOf(alice), 1_000);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), 1_000);
    }

    function testERC20WrapperTransferMatrix() public {
        vm.startPrank(owner);
        MatrixLeg[] memory froms = _buildMatrixLegs(address(token), 0x1000, "from");
        MatrixLeg[] memory tos = _buildMatrixLegs(address(token), 0x2000, "to");
        vm.stopPrank();

        _assertTransferMatrix(address(token), froms, tos);
    }

    function testERC20WrapperClaimRootTransferMatrix() public {
        address claimToken_;

        vm.startPrank(owner);
        (claimToken_,) = ledgerTokenFactory.createClaimToken(
            "Matrix Claim Token", "MCT", 18, address(token), address(token), source_, ""
        );
        MatrixLeg[] memory froms = _buildMatrixLegs(claimToken_, 0x3000, "claim-from");
        MatrixLeg[] memory tos = _buildMatrixLegs(claimToken_, 0x4000, "claim-to");
        vm.stopPrank();

        _assertTransferMatrix(claimToken_, froms, tos);
    }

    function _assertTransferMatrix(address root_, MatrixLeg[] memory froms, MatrixLeg[] memory tos) private {
        for (uint256 i = 0; i < froms.length; i++) {
            for (uint256 j = 0; j < tos.length; j++) {
                ExpectedWrapperTransfer memory expected = _expectedWrapperTransfer(froms[i], tos[j]);

                vm.recordLogs();
                ledgers.rawTransfer(root_, froms[i].parent, froms[i].relative, tos[j].parent, tos[j].relative, 0);
                _assertWrapperTransferLogs(root_, expected, i, j);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Approvals: approve / transferFrom / increase / decrease / forceApprove
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperApproveTransferFromandAllowanceMutators() public {
        bool isVerbose = false;

        vm.prank(owner);

        // Mint to alice
        if (isVerbose) console.log("Mint 1000 to alice");
        ledgers.mint(address(token), address(token), alice, 1_000);

        // approve (alice → bob: 150)
        if (isVerbose) console.log("Approve (alice -> bob: 150)");
        vm.startPrank(alice);
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 150);
        assertTrue(token.approve(bob, 150));
        assertEq(token.allowance(alice, bob), 150);

        // transferFrom by bob: 120
        vm.stopPrank();
        vm.startPrank(bob);

        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Transfer(alice, bob, 120);
        if (isVerbose) console.log("Transfer (alice -> bob: 120)");
        assertTrue(token.transferFrom(alice, bob, 120));

        assertEq(token.balanceOf(alice), 880);
        assertEq(token.balanceOf(bob), 120);
        assertEq(token.allowance(alice, bob), 30);

        // increaseAllowance by alice (+70 ⇒ 100)
        vm.stopPrank();
        vm.startPrank(alice);

        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 100);
        if (isVerbose) console.log("Increase Allowance (alice -> bob: 70)");
        bool okInc = token.increaseAllowance(bob, 70);
        assertTrue(okInc);
        assertEq(token.allowance(alice, bob), 100);

        // decreaseAllowance by alice (-40 ⇒ 60)
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 60);
        if (isVerbose) console.log("Decrease Allowance (alice -> bob: 40)");
        bool okDec = token.decreaseAllowance(bob, 40);
        assertTrue(okDec);
        assertEq(token.allowance(alice, bob), 60);

        // decreaseAllowance underflow should revert with ILedger.InsufficientAllowance
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InsufficientAllowance.selector, address(token), alice, bob, 60, 61)
        );
        token.decreaseAllowance(bob, 61);

        // forceApprove non-zero→non-zero (safety pattern inside LedgerLib)
        // current=60, set to 200
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 200);
        if (isVerbose) console.log("Force Approve (alice -> bob: 200)");
        assertTrue(token.forceApprove(bob, 200));
        assertEq(token.allowance(alice, bob), 200);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // transferFrom allowance depletion exact match
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperTransferFromExactAllowance() public {
        vm.startPrank(owner);
        ledgers.mint(address(token), address(token), alice, 250);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(bob, 250);
        vm.stopPrank();

        vm.startPrank(bob);
        token.transferFrom(alice, bob, 250);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 250);
        assertEq(token.allowance(alice, bob), 0);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mint/Burn emit ERC20 Transfer events
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMintBurnEmitsTransfer() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(address(0), alice, 50);
        ledgers.mint(address(token), address(token), alice, 50);

        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(alice, address(0), 20);
        ledgers.burn(address(token), address(token), alice, 20);

        vm.stopPrank();
    }

    function testERC20WrapperEtherscanStyleTransferIndexReconcilesHolders() public {
        address testTokenAddress;
        address surplus = LedgerLib.toAddress("Surplus");

        vm.startPrank(owner);
        (testTokenAddress,) = ledgerTokenFactory.createInternalToken("Test Token", "TEST", 18, "");
        ledgers.addSubAccount(testTokenAddress, testTokenAddress, surplus, "Surplus", false);
        vm.stopPrank();

        ERC20Wrapper testToken = ERC20Wrapper(testTokenAddress);

        vm.recordLogs();

        vm.prank(owner);
        ledgers.mint(testTokenAddress, testTokenAddress, surplus, 1_000);

        ledgers.rawTransfer(testTokenAddress, testTokenAddress, surplus, testTokenAddress, alice, 300);
        ledgers.rawTransfer(testTokenAddress, testTokenAddress, surplus, testTokenAddress, bob, 400);
        ledgers.rawTransfer(testTokenAddress, testTokenAddress, surplus, testTokenAddress, carol, 300);

        vm.prank(alice);
        assertTrue(testToken.transfer(bob, 50));

        vm.prank(bob);
        testToken.approve(carol, 75);

        vm.prank(carol);
        assertTrue(testToken.transferFrom(bob, alice, 75));

        vm.prank(bob);
        assertTrue(testToken.transfer(bob, 0));

        vm.prank(carol);
        assertTrue(testToken.transfer(carol, 10));

        vm.prank(owner);
        ledgers.burn(testTokenAddress, testTokenAddress, carol, 25);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        _assertExplorerEventAddressProjection(testTokenAddress, logs, surplus);
        _indexTokenTransferLogs(testTokenAddress, logs);

        _assertIndexedHolder(testTokenAddress, alice);
        _assertIndexedHolder(testTokenAddress, bob);
        _assertIndexedHolder(testTokenAddress, carol);
        _assertIndexedHolder(testTokenAddress, surplus);
        _assertIndexedHolder(testTokenAddress, address(0));

        assertEq(_indexedHolderCount(), 3, "indexed holder count");
        assertEq(_indexedSupply(), testToken.totalSupply(), "indexed supply");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Reverts: direct calls into wrapper transfer path MUST fail
    // We intentionally call LedgerLib.transfer first in Ledger.transfer(...) so
    // root/flags/root-mismatch validation stays centralized there.
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperLedgerWrapperFunctionsUnauthorized() public {
        bool isVerbose = false;

        // Any external calling Ledger.*Wrapper (not the token itself) should revert
        if (isVerbose) {
            console.log("Expect revert: Ledger.*Wrapper transfer called externally");
        }
        vm.expectRevert();
        ledgers.transfer(address(token), alice, address(token), bob, 1);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Sanity: multiple holders and totals
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMultiHolderAccounting() public {
        vm.startPrank(owner);
        ledgers.mint(address(token), address(token), alice, 400);
        ledgers.mint(address(token), address(token), bob, 600);
        vm.stopPrank();

        assertEq(token.totalSupply(), 1_000);
        assertEq(token.balanceOf(alice), 400);
        assertEq(token.balanceOf(bob), 600);

        vm.prank(bob);
        token.transfer(alice, 50);

        assertEq(token.balanceOf(alice), 450);
        assertEq(token.balanceOf(bob), 550);
        assertEq(token.totalSupply(), 1_000);
    }

    struct MatrixBuildCache {
        address debitGroupRelative;
        address creditGroupRelative;
        address debitGroup;
        address creditGroup;
        address r2d;
        address r2c;
        address rd;
        address rc;
        string debitGroupName;
        string creditGroupName;
        string r2dName;
        string r2cName;
        string rdName;
        string rcName;
    }

    function _buildMatrixLegs(address root_, uint160 base_, string memory prefix_)
        private
        returns (MatrixLeg[] memory legs_)
    {
        legs_ = new MatrixLeg[](7);
        MatrixBuildCache memory c;

        c.debitGroupRelative = address(base_ + 0x10);
        c.creditGroupRelative = address(base_ + 0x20);
        c.debitGroupName = string.concat(prefix_, "-debit-group");
        c.creditGroupName = string.concat(prefix_, "-credit-group");
        (c.debitGroup,) = ledgers.addSubAccountGroup(root_, root_, c.debitGroupRelative, c.debitGroupName, false);
        (c.creditGroup,) = ledgers.addSubAccountGroup(root_, root_, c.creditGroupRelative, c.creditGroupName, true);

        c.r2d = address(base_ + 0x04);
        c.r2c = address(base_ + 0x05);
        c.rd = address(base_ + 0x06);
        c.rc = address(base_ + 0x07);
        c.r2dName = string.concat(prefix_, "-r2d");
        c.r2cName = string.concat(prefix_, "-r2c");
        c.rdName = string.concat(prefix_, "-rd");
        c.rcName = string.concat(prefix_, "-rc");
        ledgers.addSubAccount(root_, root_, c.r2d, c.r2dName, false);
        ledgers.addSubAccount(root_, root_, c.r2c, c.r2cName, true);
        ledgers.addSubAccount(root_, c.debitGroup, c.rd, c.rdName, false);
        ledgers.addSubAccount(root_, c.creditGroup, c.rc, c.rcName, true);

        legs_[0] = MatrixLeg(root_, address(base_ + 0x01), 2, false, true); // U2D
        legs_[1] = MatrixLeg(c.debitGroup, address(base_ + 0x02), 3, false, true); // U>D
        legs_[2] = MatrixLeg(c.creditGroup, address(base_ + 0x03), 3, true, true); // U>C
        legs_[3] = MatrixLeg(root_, c.r2d, 2, false, false); // R2D
        legs_[4] = MatrixLeg(root_, c.r2c, 2, true, false); // R2C
        legs_[5] = MatrixLeg(c.debitGroup, c.rd, 3, false, false); // R>D
        legs_[6] = MatrixLeg(c.creditGroup, c.rc, 3, true, false); // R>C
    }

    function _expectedWrapperTransfer(MatrixLeg memory from_, MatrixLeg memory to_)
        private
        pure
        returns (ExpectedWrapperTransfer memory expected_)
    {
        expected_.from = from_.isCredit ? address(0) : _holder(from_);
        expected_.to = to_.isCredit ? address(0) : _holder(to_);
        expected_.emitted = true;
    }

    function _holder(MatrixLeg memory leg_) private pure returns (address) {
        return leg_.depth == 2 ? leg_.relative : LedgerLib.toAddress(leg_.parent, leg_.relative);
    }

    function _assertWrapperTransferLogs(
        address root_,
        ExpectedWrapperTransfer memory expected_,
        uint256 fromIndex_,
        uint256 toIndex_
    ) private {
        Vm.Log[] memory logs_ = vm.getRecordedLogs();
        uint256 count_;
        address actualFrom_;
        address actualTo_;
        uint256 actualAmount_;

        for (uint256 i = 0; i < logs_.length; i++) {
            if (logs_[i].emitter != root_) continue;
            if (logs_[i].topics.length == 0 || logs_[i].topics[0] != TRANSFER_TOPIC) continue;

            count_++;
            actualFrom_ = address(uint160(uint256(logs_[i].topics[1])));
            actualTo_ = address(uint160(uint256(logs_[i].topics[2])));
            actualAmount_ = abi.decode(logs_[i].data, (uint256));
        }

        if (!expected_.emitted) {
            assertEq(count_, 0, _matrixCellLabel("unexpected wrapper Transfer", fromIndex_, toIndex_));
            return;
        }

        assertEq(count_, 1, _matrixCellLabel("wrapper Transfer count", fromIndex_, toIndex_));
        assertEq(actualFrom_, expected_.from, _matrixCellLabel("wrapper Transfer from", fromIndex_, toIndex_));
        assertEq(actualTo_, expected_.to, _matrixCellLabel("wrapper Transfer to", fromIndex_, toIndex_));
        assertEq(actualAmount_, 0, _matrixCellLabel("wrapper Transfer amount", fromIndex_, toIndex_));
    }

    function _indexTokenTransferLogs(address token_, Vm.Log[] memory logs_) private {
        for (uint256 i = 0; i < logs_.length; i++) {
            if (logs_[i].emitter != token_) continue;
            if (logs_[i].topics.length == 0 || logs_[i].topics[0] != TRANSFER_TOPIC) continue;

            address from_ = address(uint160(uint256(logs_[i].topics[1])));
            address to_ = address(uint160(uint256(logs_[i].topics[2])));
            uint256 amount_ = abi.decode(logs_[i].data, (uint256));

            _trackIndexedHolder(from_);
            _trackIndexedHolder(to_);

            if (from_ != address(0)) indexedBalances[from_] -= amount_;
            if (to_ != address(0)) indexedBalances[to_] += amount_;
        }
    }

    function _assertExplorerEventAddressProjection(address token_, Vm.Log[] memory logs_, address registeredAccount_)
        private
        view
    {
        uint256 tokenTransferCount_;
        for (uint256 i = 0; i < logs_.length; i++) {
            if (logs_[i].emitter != token_) continue;
            if (logs_[i].topics.length == 0 || logs_[i].topics[0] != TRANSFER_TOPIC) continue;

            tokenTransferCount_++;
            address from_ = address(uint160(uint256(logs_[i].topics[1])));
            address to_ = address(uint160(uint256(logs_[i].topics[2])));

            assertTrue(_isAllowedExplorerEventAddress(from_, registeredAccount_), "unexpected Transfer from projection");
            assertTrue(_isAllowedExplorerEventAddress(to_, registeredAccount_), "unexpected Transfer to projection");
        }
        assertGt(tokenTransferCount_, 0, "token Transfer logs");
    }

    function _isAllowedExplorerEventAddress(address account_, address registeredAccount_) private view returns (bool) {
        return account_ == address(0) || account_ == registeredAccount_ || account_ == alice || account_ == bob
            || account_ == carol;
    }

    function _trackIndexedHolder(address holder_) private {
        for (uint256 i = 0; i < indexedHolders.length; i++) {
            if (indexedHolders[i] == holder_) return;
        }
        indexedHolders.push(holder_);
    }

    function _assertIndexedHolder(address token_, address holder_) private view {
        if (holder_ == address(0)) {
            assertEq(indexedBalances[holder_], 0, "zero address must not index as holder");
            return;
        }
        assertEq(indexedBalances[holder_], ERC20Wrapper(token_).balanceOf(holder_), "indexed holder balance");
    }

    function _indexedHolderCount() private view returns (uint256 count_) {
        for (uint256 i = 0; i < indexedHolders.length; i++) {
            address holder_ = indexedHolders[i];
            if (holder_ != address(0) && indexedBalances[holder_] != 0) count_++;
        }
    }

    function _indexedSupply() private view returns (uint256 supply_) {
        for (uint256 i = 0; i < indexedHolders.length; i++) {
            address holder_ = indexedHolders[i];
            if (holder_ != address(0)) supply_ += indexedBalances[holder_];
        }
    }

    function _matrixCellLabel(string memory prefix_, uint256 fromIndex_, uint256 toIndex_)
        private
        pure
        returns (string memory)
    {
        return string.concat(prefix_, " [", _matrixLabel(fromIndex_), " -> ", _matrixLabel(toIndex_), "]");
    }

    function _matrixLabel(uint256 index_) private pure returns (string memory) {
        if (index_ == 0) return "U2D";
        if (index_ == 1) return "U>D";
        if (index_ == 2) return "U>C";
        if (index_ == 3) return "R2D";
        if (index_ == 4) return "R2C";
        if (index_ == 5) return "R>D";
        return "R>C";
    }
}
