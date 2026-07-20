// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ─────────────────────────────────────────────────────────────────────────────
// Import split layout (interfaces + lib + module + infra)
// Adjust paths if your repo layout differs.
// ─────────────────────────────────────────────────────────────────────────────
import {ILedger} from "../../modules/ledger/ILedger.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";
import {Ledger} from "../../modules/ledger/Ledger.sol";
import {LedgerView} from "../../modules/ledger/LedgerView.sol";
import {Dispatchable} from "../../modules/dispatcher/Dispatchable.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {TreeView} from "../../modules/tree/TreeView.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {TreeLib} from "../../modules/tree/TreeLib.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Test, console} from "forge-std/src/Test.sol";
import {Vm} from "forge-std/src/Vm.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Test module that exposes LedgerLib via external funcs for Dispatcher delegatecall
// ─────────────────────────────────────────────────────────────────────────────
contract TestLedger is Ledger {
    string internal constant LEDGER_NAME = "Ledger";
    string internal constant LEDGER_SYMBOL = "LEDGER";

    constructor(uint8 decimals_, uint8 nativeDecimals_) Ledger(decimals_, "Ethereum", "ETH", nativeDecimals_) {}

    // Keep command registry so Dispatcher can “register” the module (if you use it)
    function signatures() external pure virtual override returns (string[] memory _signatures) {
        _signatures = new string[](26);
        _signatures[0] = "initializeTestLedger()";
        _signatures[1] = "addSubAccountGroup(address,address,string,bool)";
        _signatures[2] = "addSubAccountGroup(address,address,address,string,bool)";
        _signatures[3] = "addSubAccount(address,address,string,bool)";
        _signatures[4] = "addSubAccount(address,address,address,string,bool)";
        _signatures[5] = "addNativeToken()";
        _signatures[6] = "addExternalToken(address)";
        _signatures[7] = "createInternalToken(string,string,uint8,string)";
        _signatures[8] = "createClaimToken(string,string,uint8,address,address,address,string)";
        _signatures[9] = "removeSubAccountGroup(address,address,string)";
        _signatures[10] = "removeSubAccountGroup(address,address,address)";
        _signatures[11] = "removeSubAccount(address,address,string)";
        _signatures[12] = "removeSubAccount(address,address,address)";
        _signatures[13] = "transfer(address,address,address,address,address,uint256)";
        _signatures[14] = "transfer(address,address,address,address,uint256)";
        _signatures[15] = "wrap(address,uint256)";
        _signatures[16] = "unwrap(address,uint256)";
        _signatures[17] = "handleNative()";
        _signatures[18] = "mint(address,address,address,uint256)";
        _signatures[19] = "burn(address,address,address,uint256)";
        _signatures[20] = "enforceNativeValue(uint256)";
        _signatures[21] = "wrapThenUnwrap(address,uint256,address,uint256)";
        _signatures[22] = "wrapThenWrap(address,uint256,address,uint256)";
        _signatures[23] = "rawTransfer(address,address,address,address,address,uint256)";
        _signatures[24] = "wrapFrom(address,address,address,address,address,address,uint256)";
        _signatures[25] = "unwrapTo(address,address,address,address,address,address,uint256)";
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](26);
        // From Ledger
        _selectors[n++] = bytes4(keccak256("initializeTestLedger()"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addNativeToken()"));
        _selectors[n++] = bytes4(keccak256("addExternalToken(address)"));
        _selectors[n++] = bytes4(keccak256("createInternalToken(string,string,uint8,string)"));
        _selectors[n++] = bytes4(keccak256("createClaimToken(string,string,uint8,address,address,address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,address,address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("handleNative()"));
        // Extra test-exposing commands
        _selectors[n++] = bytes4(keccak256("mint(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("burn(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("enforceNativeValue(uint256)"));
        _selectors[n++] = bytes4(keccak256("wrapThenUnwrap(address,uint256,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrapThenWrap(address,uint256,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("rawTransfer(address,address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrapFrom(address,address,address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrapTo(address,address,address,address,address,address,uint256)"));
        // TODO: Move to DepositLib
        // _selectors[n++] = bytes4(keccak256("reallocate(address,address,uint256)"));
        if (n != 26) revert InvalidCommandsLength(n);
    }

    function initializeTestLedger() external initializer {
        enforceIsOwner();
        initializeLedger_unchained(LEDGER_NAME, LEDGER_SYMBOL);
    }

    function mint(address root_, address toHolderParent_, address to_, uint256 amount_) external {
        uint256 _tokenFlags = LedgerLib.flags(root_);
        if (LedgerLib.isCredit(_tokenFlags)) {
            LedgerLib.transfer(root_, toHolderParent_, to_, root_, address(0), amount_);
        } else {
            LedgerLib.transfer(root_, root_, address(0), toHolderParent_, to_, amount_);
        }
    }

    function burn(address root_, address fromHolderParent_, address from_, uint256 amount_) external {
        uint256 _tokenFlags = LedgerLib.flags(root_);
        if (LedgerLib.isCredit(_tokenFlags)) {
            LedgerLib.transfer(root_, root_, address(0), fromHolderParent_, from_, amount_);
        } else {
            LedgerLib.transfer(root_, fromHolderParent_, from_, root_, address(0), amount_);
        }
    }

    function enforceNativeValue(uint256 expected_) external payable {
        LedgerLib.enforceNativeValue(expected_);
    }

    function wrapThenUnwrap(address payToken_, uint256 payAmount_, address recToken_, uint256 recAmount_)
        external
        payable
    {
        LedgerLib.wrap(msg.sender, payToken_, payToken_, address(0), payToken_, msg.sender, payAmount_);
        LedgerLib.unwrap(msg.sender, recToken_, recToken_, msg.sender, recToken_, address(0), recAmount_);
    }

    function wrapThenWrap(address nativeToken_, uint256 nativeAmount_, address externalToken_, uint256 externalAmount_)
        external
        payable
    {
        LedgerLib.wrap(msg.sender, nativeToken_, nativeToken_, address(0), nativeToken_, msg.sender, nativeAmount_);
        LedgerLib.wrap(
            msg.sender, externalToken_, externalToken_, address(0), externalToken_, msg.sender, externalAmount_
        );
    }

    function rawTransfer(
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        uint256 amount_
    ) external {
        LedgerLib.transfer(root_, fromHolderParent_, from_, toHolderParent_, to_, amount_);
    }

    function wrapFrom(
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        address payer_,
        uint256 amount_
    ) external payable {
        LedgerLib.wrap(payer_, root_, fromHolderParent_, from_, toHolderParent_, to_, amount_);
    }

    function unwrapTo(
        address root_,
        address fromHolderParent_,
        address from_,
        address toHolderParent_,
        address to_,
        address recipient_,
        uint256 amount_
    ) external {
        LedgerLib.unwrap(recipient_, root_, fromHolderParent_, from_, toHolderParent_, to_, amount_);
    }

    // TODO: Move to DepositLib
    // function reallocate(address fromToken_, address toToken_, uint256 amount_) external {
    //     LedgerLib.reallocate(fromToken_, toToken_, amount_);
    // }

    receive() external payable {}
}

contract MockERC20 is ERC20 {
    uint8 private immutable _mockDecimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _mockDecimals = decimals_;
    }

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }

    function decimals() public view override returns (uint8) {
        return _mockDecimals;
    }
}

contract FeeOnTransferToken is MockERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) MockERC20(name_, symbol_, decimals_) {}

    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        uint256 fee_ = amount_ / 50;
        _spendAllowance(from_, _msgSender(), amount_);
        _transfer(from_, to_, amount_ - fee_);
        _burn(from_, fee_);
        return true;
    }
}

contract FeeOnTransferOutToken is MockERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) MockERC20(name_, symbol_, decimals_) {}

    function transfer(address to_, uint256 amount_) public override returns (bool) {
        uint256 fee_ = amount_ / 50;
        _transfer(_msgSender(), to_, amount_ - fee_);
        _burn(_msgSender(), fee_);
        return true;
    }
}

contract ReenterToken is ERC20 {
    address public target;
    bool public reenter;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    uint8 private immutable _decimals;

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }

    function setTarget(address target_) external {
        target = target_;
    }

    function setReenter(bool reenter_) external {
        reenter = reenter_;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool) {
        bool ok = super.transferFrom(from_, to_, amount_);
        if (reenter) {
            reenter = false;
            // TODO: Move to DepositLib
            // Ledger(target).wrap(address(this), LedgerLib.SOURCE_ADDRESS, address(this), address(this), 1);
        }
        return ok;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────
contract LedgerTest is Test {
    bool isVerbose;

    Dispatcher dispatcher;
    TestLedger ledger;
    LedgerView ledgerView;
    TreeView tree;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);
    address native = LedgerLib.NATIVE_ADDRESS;

    address testLedger;
    MockERC20 externalToken;
    MockERC20 unlistedToken;

    // Root
    address _1 = LedgerLib.toAddress("1");
    // Depth 1
    address _10 = LedgerLib.toAddress("10");
    address _11 = LedgerLib.toAddress("11");
    // Depth 2
    address _100 = LedgerLib.toAddress("100");
    address _101 = LedgerLib.toAddress("101");
    address _110 = LedgerLib.toAddress("110");
    address _111 = LedgerLib.toAddress("111");

    address r1;
    address r10;
    address r11;
    address r100;
    address r101;
    address r110;
    address r111;
    address source_;

    function setUp() public {
        isVerbose = false;

        vm.startPrank(alice);
        if (isVerbose) console.log("Deploying TestLedger");
        ledger = new TestLedger(18, 18);
        LedgerView ledgerViewImpl = new LedgerView();
        TreeView treeImpl = new TreeView();
        if (isVerbose) console.log("Deploying Dispatcher");
        dispatcher = new Dispatcher(alice);
        if (isVerbose) console.log("Adding Ledger module to Dispatcher");
        dispatcher.addModule(address(ledger));
        dispatcher.addModule(address(ledgerViewImpl));
        dispatcher.addModule(address(treeImpl));
        ledger = TestLedger(payable(dispatcher));
        ledgerView = LedgerView(payable(address(dispatcher)));
        tree = TreeView(payable(address(dispatcher)));

        if (isVerbose) console.log("Initializing Test Ledger");
        ledger.initializeTestLedger();
        source_ = address(0);

        // Add a standalone ledger tree for misc checks
        // testLedger = LedgerLib.toAddress("Test Ledger");
        if (isVerbose) console.log("Creating Test Ledger token");
        (testLedger,) = ledger.createInternalToken("Test Ledger", "TL", 18, "");
        ledger.addSubAccount(testLedger, testLedger, source_, "Zero Address", true);
        if (isVerbose) console.log("Adding sub-groups to Test Ledger");
        (address testLedger_1_,) = ledger.addSubAccountGroup(testLedger, testLedger, "1", false);
        (address testLedger_10_,) = ledger.addSubAccountGroup(testLedger, testLedger_1_, "10", false);
        ledger.addSubAccountGroup(testLedger, testLedger_10_, "100", false);

        // Add token r1 and its sub-groups
        if (isVerbose) console.log("Creating root token '1'");
        (r1,) = ledger.createInternalToken("1", "1", 18, "");
        ledger.addSubAccount(r1, r1, source_, "Zero Address", true);
        if (isVerbose) console.log("Adding sub-group '10' to root token '1'");
        (r10,) = ledger.addSubAccountGroup(r1, r1, "10", false);
        if (isVerbose) console.log("Adding sub-group '11' to root token '1'");
        (r11,) = ledger.addSubAccountGroup(r1, r1, "11", false);
        if (isVerbose) console.log("Adding sub-groups '100' to '10'");
        (r100,) = ledger.addSubAccountGroup(r1, r10, "100", false);
        if (isVerbose) console.log("Adding sub-groups '101' to '10'");
        (r101,) = ledger.addSubAccountGroup(r1, r10, "101", false);
        if (isVerbose) console.log("Adding sub-groups '110' to '11'");
        (r110,) = ledger.addSubAccountGroup(r1, r11, "110", false);
        if (isVerbose) console.log("Adding sub-groups '111' to '11'");
        (r111,) = ledger.addSubAccountGroup(r1, r11, "111", false);

        if (isVerbose) console.log("Creating external token");
        externalToken = new MockERC20("External Token", "EXT", 18);
        ledger.addExternalToken(address(externalToken));
        ledger.addSubAccount(address(externalToken), address(externalToken), source_, "Zero Address", true);

        unlistedToken = new MockERC20("Unlisted Token", "UNL", 18);
    }

    // Matches your old “InvalidInitialization” guard
    error InvalidInitialization();

    // ─────────────────────────────────────────────────────────────────────────
    // Structure / initialization
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerInit() public {
        isVerbose = true;

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(dispatcher));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(testLedger);
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(r1);
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(externalToken));
        if (isVerbose) console.log("--------------------");
        // Visual (optional): TreeLib.debugTree(ledger, r1);

        vm.startPrank(alice);
        vm.expectRevert(InvalidInitialization.selector);
        ledger.initializeTestLedger(); // re-init should revert

        // TreeView shape sanity
        assertEq(ledgerView.name(address(dispatcher)), "Ledger", "ledger name");
        assertEq(ledgerView.symbol(address(dispatcher)), "LEDGER", "ledger symbol");
        assertEq(tree.subAccounts(testLedger).length, 2, "Subaccounts (testLedger)");
        assertEq(tree.subAccounts(r1).length, 3, "Subaccounts (r1)");
        assertEq(tree.subAccounts(LedgerLib.toAddress(r1, r10)).length, 2, "Subaccounts (r10)");
        assertEq(tree.subAccounts(LedgerLib.toAddress(r1, r11)).length, 2, "Subaccounts (r11)");

        TreeLib.TreeNode memory rootNode_ = tree.treeNode(r1);
        assertEq(rootNode_.holderParent, address(0), "node root parent");
        assertEq(rootNode_.relative, r1, "node root addr");
        assertEq(rootNode_.name, "1", "node root name");
        assertFalse(rootNode_.isCredit, "node root debit");
        assertEq(rootNode_.debit, 0, "node root debit balance");
        assertEq(rootNode_.credit, 0, "node root credit balance");

        TreeLib.TreeNode memory childNode_ = tree.treeNode(r1, r1, _10);
        assertEq(childNode_.holderParent, r1, "node child parent");
        assertEq(childNode_.relative, _10, "node child addr");
        assertEq(childNode_.name, "10", "node child name");
        assertFalse(childNode_.isCredit, "node child debit");
        assertEq(childNode_.debit, 0, "node child debit balance");
        assertEq(childNode_.credit, 0, "node child credit balance");

        TreeLib.TreeNode[] memory treeNodes_ = tree.tree(r1);
        assertEq(treeNodes_.length, 8, "tree node count");
        assertEq(treeNodes_[0].relative, r1, "tree root first");
        assertEq(treeNodes_[0].holderParent, address(0), "tree root parent");
        assertEq(treeNodes_[2].relative, _10, "tree preorder child");
        assertEq(treeNodes_[2].holderParent, r1, "tree preorder child parent");

        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r10)), 2, "idx(r10)");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r11)), 3, "idx(r11)");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r100)), 1, "idx(r100)");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r101)), 2, "idx(r101)");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r110)), 1, "idx(r110)");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r111)), 2, "idx(r111)");
    }

    function testNativeWrapperNotCreatedDuringInit() public view {
        assertEq(tree.wrapper(native), address(0), "wrapper unset");
        assertEq(tree.root(native), address(0), "root unset");
        assertEq(ledgerView.name(native), "", "name empty");
        assertEq(ledgerView.symbol(native), "", "symbol empty");
    }

    function testLedgerAddNativeTokenIsIdempotentWithoutWrapper() public {
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addNativeToken();
        vm.stopPrank();

        assertEq(tree.wrapper(native), address(0), "wrapper unset");
        assertEq(tree.root(native), native, "root native");
        assertEq(ledgerView.name(native), "Ethereum", "name");
        assertEq(ledgerView.symbol(native), "ETH", "symbol");
        assertEq(ledgerView.nativeDecimals(), 18, "native decimals");
        assertEq(ledgerView.decimals(native), 18, "decimals");
        uint256 nativeFlags_ = tree.flags(native);
        assertEq(
            uint256(tree.accountKind(nativeFlags_)), uint256(LedgerLib.AccountKind.DebitGroup), "native debit root"
        );
        assertEq(uint256(tree.tokenKind(nativeFlags_)), uint256(LedgerLib.TokenKind.Native), "native flag set");
        assertTrue(tree.isNative(nativeFlags_), "native flag set");
        assertFalse(tree.isInternal(nativeFlags_), "native not internal");
        assertFalse(tree.isExternal(nativeFlags_), "native not external");
        assertFalse(tree.isClaim(nativeFlags_), "native not claim");
    }

    function testLedgerAddNativeTokenUsesConfiguredNativeDecimals() public {
        TestLedger ledgerImpl_ = new TestLedger(18, 6);
        LedgerView ledgerViewImpl_ = new LedgerView();
        TreeView treeImpl_ = new TreeView();
        Dispatcher dispatcher_ = new Dispatcher(alice);
        dispatcher_.addModule(address(ledgerImpl_));
        dispatcher_.addModule(address(ledgerViewImpl_));
        dispatcher_.addModule(address(treeImpl_));

        TestLedger ledger_ = TestLedger(payable(address(dispatcher_)));
        LedgerView ledgerView_ = LedgerView(payable(address(dispatcher_)));
        ledger_.initializeTestLedger();
        ledger_.addNativeToken();

        assertEq(ledgerView_.nativeDecimals(), 6, "native decimals");
        assertEq(ledgerView_.decimals(native), 6, "registered native decimals");
    }

    function testLedgerCreateInternalTokenDoesNotRegisterUnderRoot() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createInternalToken("Neutral Token", "NT", 18, "");
        vm.stopPrank();

        address rootAccount_ = LedgerLib.toAddress(address(ledger), token_);
        assertEq(tree.flags(rootAccount_), 0, "not auto-registered under root");
    }

    function testLedgerCreateInternalTokenIsIdempotent() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createInternalToken("Neutral Token", "NT", 18, "");
        (address tokenAgain_,) = ledger.createInternalToken("Neutral Token", "NT", 18, "");
        vm.stopPrank();

        assertEq(tokenAgain_, token_, "same token");
        assertEq(tree.root(token_), token_, "root registered");
        assertEq(tree.wrapper(token_), token_, "self wrapped");
        assertEq(ledgerView.name(token_), "Neutral Token", "name stable");
        assertEq(ledgerView.symbol(token_), "NT", "symbol stable");
        assertEq(ledgerView.decimals(token_), 18, "decimals stable");
    }

    function testLedgerCreateInternalTokenVersionChangesAddressOnly() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createInternalToken("Neutral Token", "NT", 18, "");
        (address versionedToken_,) = ledger.createInternalToken("Neutral Token", "NT", 18, "v2");
        (address versionedTokenAgain_,) = ledger.createInternalToken("Neutral Token", "NT", 18, "v2");
        vm.stopPrank();

        assertNotEq(versionedToken_, token_, "version changes address");
        assertEq(versionedTokenAgain_, versionedToken_, "versioned token idempotent");
        assertEq(ledgerView.name(versionedToken_), "Neutral Token", "name stable");
        assertEq(ledgerView.symbol(versionedToken_), "NT", "symbol stable");
        assertEq(ledgerView.decimals(versionedToken_), 18, "decimals stable");
        assertEq(tree.root(versionedToken_), versionedToken_, "versioned root registered");
        assertEq(tree.wrapper(versionedToken_), versionedToken_, "versioned self wrapped");
    }

    function testLedgerCreateClaimTokenIsIdempotent() public {
        vm.startPrank(alice);
        (address token_, uint256 flags_) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        (address tokenAgain_, uint256 flagsAgain_) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        vm.stopPrank();

        assertEq(tokenAgain_, token_, "same token");
        assertEq(flagsAgain_, flags_, "same flags");
        assertFalse(tree.isCredit(flags_), "claim root debit");
        assertTrue(tree.isClaim(flags_), "claim root");
        assertTrue(ledgerView.isClaim(token_), "ledger claim view");
        assertFalse(tree.isInternal(flags_), "claim root not internal");
        assertEq(tree.claimAccount(flags_), LedgerLib.toAddress(r1, r1, source_), "claim account");
        assertEq(ledgerView.claimAccountOf(token_), LedgerLib.toAddress(r1, r1, source_), "ledger claim account view");
        assertEq(tree.root(token_), token_, "root registered");
        assertEq(tree.wrapper(token_), token_, "self wrapped");
    }

    function testLedgerCreateClaimTokenVersionChangesAddressOnly() public {
        vm.startPrank(alice);
        (address token_, uint256 flags_) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        (address versionedToken_, uint256 versionedFlags_) =
            ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "v2");
        (address versionedTokenAgain_, uint256 versionedFlagsAgain_) =
            ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "v2");
        vm.stopPrank();

        assertNotEq(versionedToken_, token_, "version changes address");
        assertEq(versionedTokenAgain_, versionedToken_, "versioned token idempotent");
        assertEq(versionedFlagsAgain_, versionedFlags_, "versioned flags stable");
        assertEq(versionedFlags_, flags_, "metadata-independent flags stable");
        assertEq(ledgerView.name(versionedToken_), "Claim Token", "name stable");
        assertEq(ledgerView.symbol(versionedToken_), "CLM", "symbol stable");
        assertEq(ledgerView.decimals(versionedToken_), 18, "decimals stable");
        assertEq(ledgerView.claimAccountOf(versionedToken_), LedgerLib.toAddress(r1, r1, source_), "claim account stable");
        assertEq(tree.root(versionedToken_), versionedToken_, "versioned root registered");
        assertEq(tree.wrapper(versionedToken_), versionedToken_, "versioned self wrapped");
    }

    function testLedgerWrapRejectsClaimRoot() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, token_));
        ledger.wrap(token_, 1);
        vm.stopPrank();
    }

    function testLedgerUnwrapRejectsClaimRoot() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, token_));
        ledger.unwrap(token_, 1);
        vm.stopPrank();
    }

    function testLedgerCreateClaimTokenRejectsUnregisteredClaimAccount() public {
        vm.startPrank(alice);
        address relative_ = LedgerLib.toAddress("missingClaimAccount");
        address absolute_ = LedgerLib.toAddress(r1, r1, relative_);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, absolute_));
        ledger.createClaimToken("Bad Claim", "BCLM", 18, r1, r1, relative_, "");
    }

    function testLedgerCreateClaimTokenRejectsGroupClaimAccount() public {
        vm.startPrank(alice);
        address relative_ = LedgerLib.toAddress("10");

        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, LedgerLib.toAddress(r1, r10))
        );
        ledger.createClaimToken("Bad Claim", "BCLM", 18, r1, r1, relative_, "");
    }

    function testLedgerCreateClaimTokenRejectsNestedClaimRoot() public {
        vm.startPrank(alice);
        (address claimToken_,) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        address nestedClaimAccount_ = LedgerLib.toAddress(claimToken_, claimToken_, source_);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, nestedClaimAccount_));
        ledger.createClaimToken("Nested Claim", "NCLM", 18, claimToken_, claimToken_, source_, "");
    }

    function testLedgerAddExternalTokenIsIdempotentWithoutWrapper() public {
        vm.startPrank(alice);
        ledger.addExternalToken(address(unlistedToken));
        ledger.addExternalToken(address(unlistedToken));
        vm.stopPrank();

        assertEq(tree.root(address(unlistedToken)), address(unlistedToken), "root registered");
        assertEq(tree.wrapper(address(unlistedToken)), address(0), "wrapper unset");
        assertEq(ledgerView.name(address(unlistedToken)), "Unlisted Token", "name stable");
        assertEq(ledgerView.symbol(address(unlistedToken)), "UNL", "symbol stable");
        assertEq(ledgerView.decimals(address(unlistedToken)), 18, "decimals stable");
    }

    function testLedgerRootFlagsByTokenType() public view {
        uint256 internalFlags = tree.flags(r1);
        assertEq(
            uint256(tree.accountKind(internalFlags)), uint256(LedgerLib.AccountKind.DebitGroup), "internal debit root"
        );
        assertEq(
            uint256(tree.tokenKind(internalFlags)), uint256(LedgerLib.TokenKind.Internal), "internal token flag set"
        );
        assertTrue(tree.wrapper(r1) != address(0), "internal wrapper set");
        assertTrue(tree.isDebitGroup(internalFlags), "internal debit group");
        assertFalse(tree.isUnregisteredAccount(internalFlags), "internal account registered");
        assertFalse(tree.isCreditGroup(internalFlags), "internal not credit group");
        assertTrue(tree.isInternal(internalFlags), "internal flag set");
        assertFalse(tree.isUnregisteredToken(internalFlags), "internal token registered");
        assertFalse(tree.isNative(internalFlags), "internal token not native");
        assertFalse(tree.isExternal(internalFlags), "internal token not external");
        assertFalse(tree.isClaim(internalFlags), "internal token not claim");
        assertTrue(tree.isRoot(internalFlags), "internal root");

        uint256 externalFlags = tree.flags(address(externalToken));
        assertEq(
            uint256(tree.accountKind(externalFlags)), uint256(LedgerLib.AccountKind.DebitGroup), "external debit root"
        );
        assertEq(
            uint256(tree.tokenKind(externalFlags)), uint256(LedgerLib.TokenKind.External), "external token flag set"
        );
        assertFalse(tree.isInternal(externalFlags), "external token not internal");
        assertEq(tree.wrapper(address(externalToken)), address(0), "external wrapper unset");
        assertTrue(tree.isExternal(externalFlags), "external flag set");
        assertFalse(tree.isNative(externalFlags), "external token not native");
        assertFalse(tree.isClaim(externalFlags), "external token not claim");
        assertTrue(tree.isRoot(externalFlags), "external root");

        uint256 emptyFlags;
        assertTrue(tree.isUnregisteredAccount(emptyFlags), "zero account unregistered");
        assertTrue(tree.isUnregisteredToken(emptyFlags), "zero token unregistered");

        uint256 childFlags = tree.flags(LedgerLib.toAddress(r1, r10));
        assertTrue(tree.isDebitGroup(childFlags), "child debit group");
        assertFalse(tree.isRoot(childFlags), "child not root");
    }

    function testLedgerEffectiveFlags() public {
        vm.startPrank(alice);
        (address creditParent_,) = ledger.addSubAccountGroup(r1, r1, "creditParent", true);
        (uint256 debitFlags_, uint256 debitOriginalFlags_, address debitAddr_) =
            tree.effectiveFlags(r1, r1, LedgerLib.toAddress("missingDebit"));

        assertEq(debitAddr_, LedgerLib.toAddress(r1, r1, LedgerLib.toAddress("missingDebit")), "absolute address");
        assertEq(debitOriginalFlags_, 0, "unregistered original flags");
        assertFalse(tree.isCredit(debitFlags_), "inherits debit parent");
        assertEq(LedgerLib.holderParent(debitFlags_), r1, "inherits parent");
        ledger.addSubAccount(r1, r1, source_, "Zero Address", true);
        (uint256 sourceFlags_, uint256 sourceOriginalFlags_,) = tree.effectiveFlags(r1, r1, source_);
        assertTrue(tree.isCredit(sourceFlags_), "registered credit leaf");
        assertEq(sourceOriginalFlags_, sourceFlags_, "registered effective flags");
        (uint256 missingCreditFlags_,,) = tree.effectiveFlags(r1, creditParent_, LedgerLib.toAddress("missingCredit"));
        assertTrue(tree.isCredit(missingCreditFlags_), "inherits credit parent");
    }

    function testLedgerBalanceOfUsesEffectivePolarity() public {
        vm.startPrank(alice);
        address missingDebit_ = LedgerLib.toAddress("missingDebit");
        ledger.mint(r1, r1, missingDebit_, 100);

        assertEq(ledgerView.balanceOf(r1, r1, missingDebit_), 100, "unregistered debit leaf");
        assertEq(ledgerView.balanceOf(r1, r1, source_), 100, "registered credit source leaf");
    }

    function testPackedParentAndWrapperMapping() public view {
        assertEq(address(uint160(tree.flags(LedgerLib.toAddress(r1, r10)) >> 96)), r1, "packed parent r10");
        assertEq(address(uint160(tree.flags(LedgerLib.toAddress(r1, r100)) >> 96)), r10, "packed parent r100");
        assertEq(address(uint160(tree.flags(r1) >> 96)), address(0), "packed parent root");

        assertEq(tree.wrapper(r10), address(0), "non-root wrapper unset");
        assertEq(tree.wrapper(r1), r1, "internal root wrapper");
        assertEq(tree.wrapper(address(externalToken)), address(0), "external root wrapper unset");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AddSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerAddSubAccountGroup() public {
        vm.startPrank(alice);

        // Add a fresh sub under r1
        (address added, uint256 flags_) = ledger.addSubAccountGroup(r1, r1, "newSubAccount", false);
        address[] memory before_ = tree.subAccounts(r1);
        uint32 index_ = tree.subAccountIndex(LedgerLib.toAddress(r1, added));
        assertEq(added, LedgerLib.toAddress(r1, "newSubAccount"), "address mismatch");
        assertEq(tree.holderParent(LedgerLib.toAddress(r1, added)), r1, "parent mismatch");
        assertEq(index_, before_.length, "index should equal #subs");
        assertTrue(tree.hasSubAccount(r1), "r1 should have subs");
        assertEq(tree.flags(LedgerLib.toAddress(r1, added)), flags_, "flags stored");
        assertEq(ledgerView.name(LedgerLib.toAddress(r1, added)), "newSubAccount", "name stored");

        (address idempotent, uint256 flagsAgain_) = ledger.addSubAccountGroup(r1, r1, "newSubAccount", false);
        address[] memory after_ = tree.subAccounts(r1);
        assertEq(idempotent, added, "expected same sub account address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(after_.length, before_.length, "child count stable");
        assertEq(after_[after_.length - 1], before_[before_.length - 1], "child ordering stable");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, added)), index_, "index stable");
        assertEq(ledgerView.name(LedgerLib.toAddress(r1, added)), "newSubAccount", "name stable");
    }

    function testLedgerAddSubAccountGroupAddressFormIsIdempotent() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("groupByAddr");
        (address added_, uint256 flags_) = ledger.addSubAccountGroup(r1, r1, relative_, "groupByAddr", false);
        address[] memory before_ = tree.subAccounts(r1);
        uint32 index_ = tree.subAccountIndex(LedgerLib.toAddress(r1, added_));
        (address addedAgain_, uint256 flagsAgain_) = ledger.addSubAccountGroup(r1, r1, relative_, "groupByAddr", false);
        address[] memory after_ = tree.subAccounts(r1);

        assertEq(addedAgain_, added_, "same address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(after_.length, before_.length, "child count stable");
        assertEq(after_[after_.length - 1], relative_, "no duplicate child");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, added_)), index_, "index stable");
        assertEq(ledgerView.name(LedgerLib.toAddress(r1, added_)), "groupByAddr", "name stable");
    }

    function testLedgerAddSubAccountGroupRejectsFundedDebitLeaf() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("fundedGroupDebit");
        ledger.mint(r1, r1, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccountGroup.selector, "fundedGroupDebit", false));
        ledger.addSubAccountGroup(r1, r1, relative_, "fundedGroupDebit", false);
    }

    function testLedgerAddSubAccountGroupRejectsFundedCreditLeaf() public {
        vm.startPrank(alice);

        (address creditRoot_,) = ledger.createInternalToken("Credit Group Root", "CGR", 18, "");
        address relative_ = LedgerLib.toAddress("fundedGroupCredit");
        ledger.mint(creditRoot_, creditRoot_, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccountGroup.selector, "fundedGroupCredit", true));
        ledger.addSubAccountGroup(creditRoot_, creditRoot_, relative_, "fundedGroupCredit", true);
    }

    function testLedgerAddSubAccountNameDelegatesToAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("leafSubAccount");
        (address added_,) = ledger.addSubAccount(r1, r1, "leafSubAccount", false);

        assertEq(added_, LedgerLib.toAddress(r1, relative_), "address mismatch");
        assertEq(tree.subAccounts(r1)[tree.subAccounts(r1).length - 1], relative_, "relative addr stored");
    }

    function testLedgerAddSubAccountIsIdempotent() public {
        vm.startPrank(alice);

        (address added_, uint256 flags_) = ledger.addSubAccount(r1, r1, "leafSubAccount", false);
        address relative_ = LedgerLib.toAddress("leafSubAccount");
        address[] memory before_ = tree.subAccounts(r1);
        uint32 index_ = tree.subAccountIndex(LedgerLib.toAddress(r1, added_));
        (address addedAgain_, uint256 flagsAgain_) = ledger.addSubAccount(r1, r1, "leafSubAccount", false);
        address[] memory after_ = tree.subAccounts(r1);

        assertEq(addedAgain_, added_, "same address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(after_.length, before_.length, "child count stable");
        assertEq(after_[after_.length - 1], relative_, "no duplicate child");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, added_)), index_, "index stable");
        assertEq(ledgerView.name(LedgerLib.toAddress(r1, added_)), "leafSubAccount", "name stable");
    }

    function testLedgerAddSubAccountRegistersFundedDebitLeaf() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("fundedDebit");
        ledger.mint(r1, r1, relative_, 100);

        (address added_, uint256 flags_) = ledger.addSubAccount(r1, r1, relative_, "fundedDebit", false);

        assertEq(added_, LedgerLib.toAddress(r1, relative_), "registered addr");
        assertFalse(tree.isCredit(flags_), "registered debit");
        assertEq(ledgerView.balanceOf(r1, r1, relative_), 100, "balance preserved");
    }

    function testLedgerAddSubAccountRejectsFundedDebitLeafAsCredit() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("fundedDebit");
        ledger.mint(r1, r1, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, relative_, true));
        ledger.addSubAccount(r1, r1, relative_, "fundedDebit", true);
    }

    function testLedgerAddSubAccountRejectsFundedCreditLeafAsDebit() public {
        vm.startPrank(alice);

        (address creditRoot_,) = ledger.createInternalToken("Credit Root", "CRT", 18, "");
        address relative_ = LedgerLib.toAddress("fundedCredit");
        ledger.mint(creditRoot_, creditRoot_, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, relative_, true));
        ledger.addSubAccount(creditRoot_, creditRoot_, relative_, "fundedCredit", true);
    }

    function testLedgerAddSubAccountZeroParentReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, address(0)));
        ledger.addSubAccountGroup(address(0), address(0), "zeroParent", false);
    }

    function testLedgerAddSubAccountEmptyNameReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidString.selector, ""));
        ledger.addSubAccountGroup(r1, r1, "", false);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RemoveSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerRemoveSubAccountHappyPath() public {
        isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Removing subaccount");
        ledger.removeSubAccountGroup(r1, r10, "100");

        if (isVerbose) console.log("Check parent");
        assertEq(tree.holderParent(_100), address(0), "parent reset");
        if (isVerbose) console.log("Check index");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r100)), 0, "index reset");
        if (isVerbose) console.log("Check name");
        assertEq(ledgerView.name(_100), "", "name cleared");
        if (isVerbose) console.log("Check hasSubAccount");
        assertFalse(tree.hasSubAccount(_100), "no children");
    }

    function testLedgerRemoveSubAccountGroupIsIdempotent() public {
        vm.startPrank(alice);

        address removed_ = ledger.removeSubAccountGroup(r1, r10, "100");
        address removedAgain_ = ledger.removeSubAccountGroup(r1, r10, "100");

        assertEq(removedAgain_, removed_, "same address");
        assertEq(tree.flags(LedgerLib.toAddress(r1, removed_)), 0, "cleared");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, r100)), 0, "index reset");
        assertEq(tree.subAccounts(LedgerLib.toAddress(r1, r10)).length, 1, "child count stable");
    }

    function testLedgerRemoveSubAccountGroupAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("groupByAddr");
        (address added_,) = ledger.addSubAccountGroup(r1, r1, relative_, "groupByAddr", false);
        ledger.removeSubAccountGroup(r1, r1, relative_);

        assertEq(tree.holderParent(added_), address(0), "parent reset");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, added_)), 0, "index reset");
        assertEq(ledgerView.name(LedgerLib.toAddress(r1, added_)), "", "name cleared");
    }

    function testLedgerRemoveSubAccountNameDelegatesToAddressForm() public {
        vm.startPrank(alice);

        (address added_,) = ledger.addSubAccount(r1, r1, "leafByName", false);
        ledger.removeSubAccount(r1, r1, "leafByName");

        assertEq(tree.holderParent(added_), address(0), "parent reset");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, added_)), 0, "index reset");
        assertEq(ledgerView.name(LedgerLib.toAddress(r1, added_)), "", "name cleared");
    }

    function testLedgerRemoveSubAccountIsIdempotent() public {
        vm.startPrank(alice);

        (address added_,) = ledger.addSubAccount(r1, r1, "leafToRemove", false);
        address removed_ = ledger.removeSubAccount(r1, r1, "leafToRemove");
        address removedAgain_ = ledger.removeSubAccount(r1, r1, "leafToRemove");

        assertEq(removed_, added_, "removed address");
        assertEq(removedAgain_, removed_, "same address");
        assertEq(tree.flags(LedgerLib.toAddress(r1, removed_)), 0, "cleared");
        assertEq(tree.subAccounts(r1).length, 3, "child count stable");
    }

    function testLedgerRemoveSubAccountMissingGroupIsIdempotent() public {
        vm.startPrank(alice);
        address nonExistent = LedgerLib.toAddress(r1, "nope");
        address removed_ = ledger.removeSubAccountGroup(r1, r1, "nope");
        assertEq(removed_, nonExistent, "same address");
        assertEq(tree.flags(LedgerLib.toAddress(r1, removed_)), 0, "still absent");
    }

    function testLedgerRemoveSubAccountMissingLeafIsIdempotent() public {
        vm.startPrank(alice);
        address relative_ = LedgerLib.toAddress("missingLeaf");
        address removed_ = ledger.removeSubAccount(r1, r1, "missingLeaf");
        assertEq(removed_, LedgerLib.toAddress(r1, relative_), "same address");
        assertEq(tree.flags(LedgerLib.toAddress(r1, removed_)), 0, "still absent");
    }

    function testLedgerRemoveSubAccountWithChildrenReverts() public {
        vm.startPrank(alice);
        (address parentWithChild,) = ledger.addSubAccountGroup(r1, r1, "parentWithChild", false);
        ledger.addSubAccountGroup(r1, parentWithChild, "sub", false);
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.HasSubAccount.selector, LedgerLib.toAddress(r1, parentWithChild))
        );
        ledger.removeSubAccountGroup(r1, r1, "parentWithChild");
    }

    function testLedgerRemoveSubAccountWithBalanceReverts() public {
        vm.startPrank(alice);
        ledger.mint(r1, r100, alice, 1000);

        vm.expectRevert(abi.encodeWithSelector(ILedger.HasBalance.selector, LedgerLib.toAddress(r1, r100)));
        ledger.removeSubAccountGroup(r1, r10, "100");
    }

    function testLedgerRemoveSubAccountInvalidAddresses() public {
        vm.startPrank(alice);
        (address _valid,) = ledger.addSubAccountGroup(r1, r1, "validSub", false);
        address _missing = LedgerLib.toAddress(_valid, "validSub");

        // Zero root/parent resolves to an unregistered parent under the new explicit root form.
        vm.expectRevert(ILedger.InvalidAccountGroup.selector);
        ledger.removeSubAccountGroup(address(0), address(0), "validSub");

        // Valid parent + absent child => idempotent no-op.
        assertEq(ledger.removeSubAccountGroup(r1, _valid, "validSub"), _missing, "missing sub address");
    }

    function testLedgerRemoveUpdatesSiblingIndices() public {
        vm.startPrank(alice);
        address _s1 = LedgerLib.toAddress("s1");
        address _s3 = LedgerLib.toAddress("s3");

        ledger.addSubAccountGroup(r1, r1, "s1", false);
        ledger.addSubAccountGroup(r1, r1, "s2", false);
        ledger.addSubAccountGroup(r1, r1, "s3", false);

        uint256 before = tree.subAccounts(r1).length;
        ledger.removeSubAccountGroup(r1, r1, "s2");

        address[] memory subs = tree.subAccounts(r1);
        assertEq(subs.length, before - 1, "length");
        assertEq(subs[before - 3], _s1, "first remains s1");
        assertEq(subs[before - 2], _s3, "second becomes s3");

        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, LedgerLib.toAddress(r1, _s1))), before - 2, "s1 idx");
        assertEq(tree.subAccountIndex(LedgerLib.toAddress(r1, LedgerLib.toAddress(r1, _s3))), before - 1, "s3 idx");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parents / roots / hasSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerParents() public view {
        assertEq(tree.root(LedgerLib.toAddress(r1, r10)), r1, "root r10");
        assertEq(tree.root(LedgerLib.toAddress(r1, r11)), r1, "root r11");
        assertEq(tree.root(LedgerLib.toAddress(r1, r100)), r1, "root r100");
        assertEq(tree.root(LedgerLib.toAddress(r1, r101)), r1, "root r101");
        assertEq(tree.root(LedgerLib.toAddress(r1, r110)), r1, "root r110");
        assertEq(tree.root(LedgerLib.toAddress(r1, r111)), r1, "root r111");

        assertEq(tree.holderParent(LedgerLib.toAddress(r1, r10)), r1, "parent r10");
        assertEq(tree.holderParent(LedgerLib.toAddress(r1, r11)), r1, "parent r11");
        assertEq(tree.holderParent(LedgerLib.toAddress(r1, r100)), r10, "parent r100");
        assertEq(tree.holderParent(LedgerLib.toAddress(r1, r101)), r10, "parent r101");
        assertEq(tree.holderParent(LedgerLib.toAddress(r1, r110)), r11, "parent r110");
        assertEq(tree.holderParent(LedgerLib.toAddress(r1, r111)), r11, "parent r111");
    }

    function testLedgerHasSubAccount() public view {
        assertTrue(tree.hasSubAccount(r1), "r1");
        assertTrue(tree.hasSubAccount(LedgerLib.toAddress(r1, r10)), "r10");
        assertTrue(tree.hasSubAccount(LedgerLib.toAddress(r1, r11)), "r11");
        assertFalse(tree.hasSubAccount(r100), "r100");
        assertFalse(tree.hasSubAccount(r101), "r101");
        assertFalse(tree.hasSubAccount(r110), "r110");
        assertFalse(tree.hasSubAccount(r111), "r111");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mint / Burn
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerMint() public {
        isVerbose = true;

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint r1: Alice");
        ledger.mint(r1, r1, alice, 1000e18);

        assertEq(ledgerView.debitBalanceOf(r1, r1, alice), 1000e18, "debitBalanceOf(alice)");
        assertEq(ledgerView.totalSupply(r1), 1000e18, "totalSupply");

        if (isVerbose) console.log("Mint token 1: Alice");
        ledger.mint(r1, r100, alice, 1000e18);
        assertEq(ledgerView.debitBalanceOf(r1, r100, alice), 1000e18, "debitBalanceOf(r100, alice)");
        assertEq(ledgerView.debitBalanceOf(r1, r10, LedgerLib.toAddress("100")), 1000e18, 'debitBalanceOf(r10, "100")');
        assertEq(ledgerView.debitBalanceOf(r1, r1, LedgerLib.toAddress("10")), 1000e18, 'debitBalanceOf(r1, "10")');
        assertEq(ledgerView.totalSupply(r1), 2000e18, "totalSupply(r1)");

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, address(dispatcher));
        // if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, testLedger);
        // if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(r1);
        if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, address(externalToken));
        // if (isVerbose) console.log("--------------------");
    }

    function testLedgerBurn() public {
        vm.startPrank(alice);

        ledger.mint(r1, r1, alice, 1000e18);
        ledger.burn(r1, r1, alice, 700e18);

        assertEq(ledgerView.debitBalanceOf(r1, r1, alice), 300e18, "debitBalanceOf(alice)");
        assertEq(ledgerView.totalSupply(r1), 300e18, "totalSupply");

        ledger.mint(r1, r100, alice, 1000e18);
        ledger.burn(r1, r100, alice, 600e18);

        assertEq(ledgerView.debitBalanceOf(r1, r100, alice), 400e18, "debitBalanceOf(r100, alice)");
        assertEq(ledgerView.debitBalanceOf(r1, r10, LedgerLib.toAddress("100")), 400e18, 'debitBalanceOf(r10, "100")');
        assertEq(ledgerView.debitBalanceOf(r1, r1, LedgerLib.toAddress("10")), 400e18, 'debitBalanceOf(r1, "10")');
        assertEq(ledgerView.totalSupply(r1), 700e18, "totalSupply(r1)");
    }

    // TODO: Move to DepositLib
    // function testLedgerReallocate() public {
    //     isVerbose = false;

    //     vm.startPrank(alice);

    //     (address tokenA,) = ledger.createInternalToken("Realloc A", "REA", 18);
    //     (address tokenB,) = ledger.createInternalToken("Realloc B", "REB", 18);
    //     ledger.addSubAccount(address(ledger), LedgerLib.SOURCE_ADDRESS, "Source", true);
    //     ledger.addSubAccount(address(ledger), tokenA, "Realloc A", false);
    //     ledger.addSubAccount(address(ledger), tokenB, "Realloc B", false);

    //     uint256 initialAmount = 1_000 ether;
    //     uint256 shift = 400 ether;

    //     if (isVerbose) console.log("Minting initial amount to tokenA");
    //     ledger.mint(address(ledger), tokenA, initialAmount);
    //     assertEq(ledger.totalSupply(address(ledger)), initialAmount, "root supply after mint");

    //     if (isVerbose) console.log("Reallocating from tokenA to tokenB");
    //     ledger.reallocate(tokenA, tokenB, shift);
    //     assertEq(ledger.totalSupply(address(ledger)), initialAmount, "root supply invariant after reallocate");
    //     assertEq(ledger.balanceOf(address(ledger), tokenA), initialAmount - shift, "tokenA debited");
    //     assertEq(ledger.balanceOf(address(ledger), tokenB), shift, "tokenB credited");

    //     uint256 shiftBack = 125 ether;
    //     if (isVerbose) console.log("Reallocating back from tokenB to tokenA");
    //     ledger.reallocate(tokenB, tokenA, shiftBack);
    //     assertEq(ledger.totalSupply(address(ledger)), initialAmount, "root supply invariant after rebalance");
    //     assertEq(
    //         ledger.balanceOf(address(ledger), tokenA), initialAmount - shift + shiftBack, "tokenA after rebalancing"
    //     );
    //     assertEq(ledger.balanceOf(address(ledger), tokenB), shift - shiftBack, "tokenB after rebalancing");
    // }

    function testLedgerWrapExternalToken() public {
        uint256 wrapAmount = 120;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), wrapAmount);
        vm.stopPrank();

        assertEq(externalToken.balanceOf(address(dispatcher)), wrapAmount, "dispatcher holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledgerView.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");
    }

    function testLedgerWrapExternalTokenUsesExplicitPayer() public {
        uint256 wrapAmount = 120;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        vm.stopPrank();

        vm.prank(bob);
        ledger.wrapFrom(address(externalToken), address(externalToken), source_, address(externalToken), charlie, alice, wrapAmount);

        assertEq(externalToken.balanceOf(address(dispatcher)), wrapAmount, "dispatcher holds payer tokens");
        assertEq(externalToken.balanceOf(alice), 0, "payer external balance consumed");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), bob), 0, "caller not credited");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), charlie), wrapAmount, "recipient ledger credited");
        assertEq(ledgerView.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");
    }

    function testLedgerWrapExternalTokenRejectsDirectValue() public {
        uint256 wrapAmount = 120;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.wrap{value: 1}(address(externalToken), wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapRejectsFeeOnTransferToken() public {
        uint256 wrapAmount = 100;
        FeeOnTransferToken feeToken_ = new FeeOnTransferToken("Fee Token", "FEE", 18);

        vm.startPrank(alice);
        ledger.addExternalToken(address(feeToken_));
        ledger.addSubAccount(address(feeToken_), address(feeToken_), source_, "Zero Address", true);
        feeToken_.mint(alice, wrapAmount);
        feeToken_.approve(address(ledger), wrapAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.UnsupportedTokenBehavior.selector, address(feeToken_), wrapAmount, wrapAmount - 2
            )
        );
        ledger.wrap(address(feeToken_), wrapAmount);
        vm.stopPrank();

        assertEq(feeToken_.balanceOf(address(dispatcher)), 0, "dispatcher should not keep partial receipt");
        assertEq(feeToken_.balanceOf(alice), wrapAmount, "alice balance should roll back");
        assertEq(ledgerView.debitBalanceOf(address(feeToken_), address(feeToken_), alice), 0, "ledger balance should roll back");
        assertEq(ledgerView.totalSupply(address(feeToken_)), 0, "total supply should roll back");
    }

    function testLedgerUnwrapRejectsFeeOnTransferToken() public {
        uint256 wrapAmount = 100;
        FeeOnTransferOutToken feeToken_ = new FeeOnTransferOutToken("Fee Out Token", "FOUT", 18);

        vm.startPrank(alice);
        ledger.addExternalToken(address(feeToken_));
        ledger.addSubAccount(address(feeToken_), address(feeToken_), source_, "Zero Address", true);
        feeToken_.mint(alice, wrapAmount);
        feeToken_.approve(address(ledger), wrapAmount);
        ledger.wrap(address(feeToken_), wrapAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.UnsupportedTokenBehavior.selector, address(feeToken_), wrapAmount, wrapAmount - 2
            )
        );
        ledger.unwrap(address(feeToken_), wrapAmount);
        vm.stopPrank();

        assertEq(feeToken_.balanceOf(address(dispatcher)), wrapAmount, "dispatcher should keep wrapped balance");
        assertEq(feeToken_.balanceOf(alice), 0, "alice should not receive partial unwrap");
        assertEq(ledgerView.debitBalanceOf(address(feeToken_), address(feeToken_), alice), wrapAmount, "ledger balance should roll back");
        assertEq(ledgerView.totalSupply(address(feeToken_)), wrapAmount, "total supply should roll back");
    }

    function testLedgerHandleNativeWrapsMsgValueToSender() public {
        uint256 wrapAmount = 1 ether;

        vm.startPrank(alice);
        ledger.addNativeToken();
        vm.stopPrank();

        vm.deal(bob, wrapAmount);
        vm.prank(bob);
        ledger.handleNative{value: wrapAmount}();

        assertEq(address(dispatcher).balance, wrapAmount, "dispatcher native balance");
        assertEq(ledgerView.debitBalanceOf(native, native, bob), wrapAmount, "bob native ledger balance");
        assertEq(ledgerView.totalSupply(native), wrapAmount, "native total supply");
    }

    function testLedgerWrapNativeRejectsExplicitNonCallerPayer() public {
        uint256 wrapAmount = 1 ether;

        vm.startPrank(alice);
        ledger.addNativeToken();
        vm.stopPrank();

        vm.deal(bob, wrapAmount);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidNativePayer.selector, alice, bob));
        ledger.wrapFrom{value: wrapAmount}(native, native, source_, native, alice, alice, wrapAmount);
    }

    function testLedgerUnwrapNativeUsesExplicitRecipient() public {
        uint256 wrapAmount = 1 ether;
        uint256 unwrapAmount = 0.4 ether;

        vm.startPrank(alice);
        ledger.addNativeToken();
        vm.deal(alice, wrapAmount);
        ledger.wrap{value: wrapAmount}(native, wrapAmount);
        vm.stopPrank();

        uint256 charlieBalanceBefore_ = charlie.balance;

        vm.prank(bob);
        ledger.unwrapTo(native, native, alice, native, source_, charlie, unwrapAmount);

        assertEq(charlie.balance, charlieBalanceBefore_ + unwrapAmount, "recipient native balance");
        assertEq(ledgerView.debitBalanceOf(native, native, alice), wrapAmount - unwrapAmount, "ledger native balance");
        assertEq(ledgerView.totalSupply(native), wrapAmount - unwrapAmount, "native total supply");
    }

    function testDispatcherReceiveWrapsNativeToOriginalSender() public {
        uint256 wrapAmount = 1 ether;

        vm.startPrank(alice);
        ledger.addNativeToken();
        vm.stopPrank();

        vm.deal(bob, wrapAmount);
        vm.prank(bob);
        (bool success,) = address(dispatcher).call{value: wrapAmount}("");

        assertTrue(success, "dispatcher receive failed");
        assertEq(address(dispatcher).balance, wrapAmount, "dispatcher native balance");
        assertEq(ledgerView.debitBalanceOf(native, native, bob), wrapAmount, "bob native ledger balance");
        assertEq(ledgerView.totalSupply(native), wrapAmount, "native total supply");
    }

    function testLedgerEnforceNativeValue() public {
        vm.deal(alice, 5 ether);

        vm.startPrank(alice);
        ledger.enforceNativeValue{value: 2 ether}(2 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1 ether, 2 ether));
        ledger.enforceNativeValue{value: 1 ether}(2 ether);
        vm.stopPrank();
    }

    function testLedgerUnwrapExternalToken() public {
        uint256 wrapAmount = 120;
        uint256 unwrapAmount = 45;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), wrapAmount);
        ledger.unwrap(address(externalToken), unwrapAmount);
        vm.stopPrank();

        assertEq(
            externalToken.balanceOf(address(dispatcher)), wrapAmount - unwrapAmount, "dispatcher balance after unwrap"
        );
        assertEq(externalToken.balanceOf(alice), unwrapAmount, "alice external balance after unwrap");
        assertEq(
            ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice),
            wrapAmount - unwrapAmount,
            "ledger balance after unwrap"
        );
        assertEq(ledgerView.totalSupply(address(externalToken)), wrapAmount - unwrapAmount, "total supply after unwrap");
    }

    function testLedgerUnwrapExternalTokenUsesExplicitRecipient() public {
        uint256 wrapAmount = 120;
        uint256 unwrapAmount = 45;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), wrapAmount);
        vm.stopPrank();

        vm.prank(bob);
        ledger.unwrapTo(address(externalToken), address(externalToken), alice, address(externalToken), source_, charlie, unwrapAmount);

        assertEq(externalToken.balanceOf(charlie), unwrapAmount, "recipient external balance after unwrap");
        assertEq(externalToken.balanceOf(bob), 0, "caller receives no external tokens");
        assertEq(
            ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice),
            wrapAmount - unwrapAmount,
            "ledger balance after unwrap"
        );
        assertEq(ledgerView.totalSupply(address(externalToken)), wrapAmount - unwrapAmount, "total supply after unwrap");
    }

    function testLedgerUnwrapExternalTokenRevertsWhenUndercollateralized() public {
        uint256 wrapAmount = 120;
        uint256 drainAmount = 1;
        uint256 unwrapAmount = 45;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), wrapAmount);
        vm.stopPrank();

        vm.prank(address(dispatcher));
        externalToken.transfer(charlie, drainAmount);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.UndercollateralizedToken.selector, address(externalToken), wrapAmount, wrapAmount - drainAmount
            )
        );
        ledger.unwrap(address(externalToken), unwrapAmount);

        assertEq(externalToken.balanceOf(address(dispatcher)), wrapAmount - drainAmount, "dispatcher collateral");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice), wrapAmount, "ledger balance unchanged");
        assertEq(ledgerView.totalSupply(address(externalToken)), wrapAmount, "total supply unchanged");
    }

    function testLedgerUnwrapExternalTokenRejectsDirectValue() public {
        uint256 wrapAmount = 120;
        uint256 unwrapAmount = 45;

        vm.startPrank(alice);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.unwrap{value: 1}(address(externalToken), unwrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapNativeRevertsWhenUndercollateralized() public {
        uint256 wrapAmount = 3 ether;
        uint256 drainAmount = 1 wei;
        uint256 unwrapAmount = 1 ether;

        vm.deal(alice, wrapAmount);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.wrap{value: wrapAmount}(native, wrapAmount);
        vm.stopPrank();

        vm.deal(address(dispatcher), wrapAmount - drainAmount);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.UndercollateralizedToken.selector, native, wrapAmount, wrapAmount - drainAmount
            )
        );
        ledger.unwrap(native, unwrapAmount);

        assertEq(address(dispatcher).balance, wrapAmount - drainAmount, "dispatcher native collateral");
        assertEq(ledgerView.debitBalanceOf(native, native, alice), wrapAmount, "ledger native balance unchanged");
        assertEq(ledgerView.totalSupply(native), wrapAmount, "native total supply unchanged");
    }

    function testLedgerUnwrapExternalTokenAfterNativeWrapAllowsCallValue() public {
        uint256 nativeWrapAmount = 1 ether;
        uint256 externalUnwrapAmount = 45;

        vm.startPrank(alice);
        externalToken.mint(alice, externalUnwrapAmount);
        externalToken.approve(address(ledger), externalUnwrapAmount);
        ledger.wrap(address(externalToken), externalUnwrapAmount);
        vm.deal(alice, nativeWrapAmount);
        ledger.addNativeToken();
        ledger.wrapThenUnwrap{value: nativeWrapAmount}(
            native, nativeWrapAmount, address(externalToken), externalUnwrapAmount
        );
        vm.stopPrank();

        assertEq(externalToken.balanceOf(alice), externalUnwrapAmount, "alice external balance after unwrap");
        assertEq(externalToken.balanceOf(address(dispatcher)), 0, "dispatcher external balance after unwrap");
        assertEq(ledgerView.debitBalanceOf(native, native, alice), nativeWrapAmount, "native ledger balance after wrap");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice), 0, "external ledger balance after unwrap");
    }

    function testLedgerWrapExternalTokenAfterNativeWrapAllowsCallValue() public {
        uint256 nativeWrapAmount = 1 ether;
        uint256 externalWrapAmount = 45;

        vm.startPrank(alice);
        externalToken.mint(alice, externalWrapAmount);
        externalToken.approve(address(ledger), externalWrapAmount);
        vm.deal(alice, nativeWrapAmount);
        ledger.addNativeToken();
        ledger.wrapThenWrap{value: nativeWrapAmount}(
            native, nativeWrapAmount, address(externalToken), externalWrapAmount
        );
        vm.stopPrank();

        assertEq(externalToken.balanceOf(alice), 0, "alice external balance after wrap");
        assertEq(
            externalToken.balanceOf(address(dispatcher)), externalWrapAmount, "dispatcher external balance after wrap"
        );
        assertEq(ledgerView.debitBalanceOf(native, native, alice), nativeWrapAmount, "native ledger balance after wrap");
        assertEq(
            ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice),
            externalWrapAmount,
            "external ledger balance after wrap"
        );
    }

    function testLedgerWrapClaimRootReverts() public {
        vm.startPrank(alice);
        (address claimRoot_,) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, claimRoot_));
        ledger.wrap(claimRoot_, 1);
        vm.stopPrank();
    }

    function testLedgerUnwrapClaimRootReverts() public {
        vm.startPrank(alice);
        (address claimRoot_,) = ledger.createClaimToken("Claim Token", "CLM", 18, r1, r1, source_, "");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, claimRoot_));
        ledger.unwrap(claimRoot_, 1);
        vm.stopPrank();
    }

    /* TODO: Move to DepositLib
    function testLedgerWrap() public {
        isVerbose = false;

        vm.startPrank(alice);

        uint256 unlistedAmount = 50;
        unlistedToken.mint(alice, unlistedAmount);
        unlistedToken.approve(address(ledger), unlistedAmount);
        if (isVerbose) {
            console.log("Attempt wrap of unlisted token (should revert)");
        }
        vm.expectRevert(abi.encodeWithSelector(ILedger.ZeroAddress.selector));
        ledger.wrap(address(unlistedToken), alice, address(unlistedToken), alice, unlistedAmount);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, r1));
        ledger.wrap(r1, source_, r1, alice, 1);

        uint256 wrapAmount = 120;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        if (isVerbose) console.log("Wrapping external token");
        ledger.wrap(address(externalToken), source_, address(externalToken), alice, wrapAmount);

        assertEq(externalToken.balanceOf(address(dispatcher)), wrapAmount, "dispatcher holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledgerView.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");

        vm.expectRevert(abi.encodeWithSelector(ILedger.ZeroAddress.selector));
        ledger.unwrap(address(unlistedToken), alice, address(unlistedToken), alice, 10);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, r1));
        ledger.unwrap(r1, alice, r1, source_, 1);

        uint256 firstUnwrap = 45;
        ledger.unwrap(address(externalToken), alice, address(externalToken), source_, firstUnwrap);
        assertEq(
            externalToken.balanceOf(address(dispatcher)), wrapAmount - firstUnwrap, "dispatcher balance after partial unwrap"
        );
        assertEq(externalToken.balanceOf(alice), firstUnwrap, "alice external balance after partial unwrap");
        assertEq(
            ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice),
            wrapAmount - firstUnwrap,
            "ledger balance after partial unwrap"
        );
        assertEq(
            ledgerView.totalSupply(address(externalToken)), wrapAmount - firstUnwrap, "total supply after partial unwrap"
        );

        uint256 remaining = wrapAmount - firstUnwrap;
        ledger.unwrap(address(externalToken), alice, address(externalToken), source_, remaining);
        assertEq(externalToken.balanceOf(address(dispatcher)), 0, "dispatcher drained after unwrap");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "alice restored external balance");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice), 0, "ledger balance cleared");
        assertEq(ledgerView.totalSupply(address(externalToken)), 0, "total supply cleared");
    }

    function testLedgerWrapUsesExplicitSourceNotCaller() public {
        vm.startPrank(bob);

        uint256 wrapAmount = 120;
        externalToken.mint(bob, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);

        address totalParent = address(externalToken);

        // Caller is bob, but source accounting is unallocated.
        ledger.wrap(totalParent, source_, address(externalToken), bob, wrapAmount);

        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), bob), wrapAmount, "caller received wrapped balance");
        assertEq(ledgerView.creditBalanceOf(totalParent, source_), wrapAmount, "source ledger entry credited");

        // Unwrap using same source to close out source ledger entry.
        ledger.unwrap(address(externalToken), bob, totalParent, source_, wrapAmount);

        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), bob), 0, "wrapped caller balance cleared");
        assertEq(ledgerView.creditBalanceOf(totalParent, source_), 0, "source ledger entry cleared");
        vm.stopPrank();
    }

    function testLedgerWrapInvalidSourceParentReverts() public {
        vm.startPrank(alice);

        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);

        vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, alice, address(externalToken)));
        ledger.wrap(alice, alice, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapCrossRootSourceRevertsDifferentRoots() public {
        vm.startPrank(alice);

        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);

        // r1 belongs to a different root tree than externalToken.
        vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, r1, address(externalToken)));
        ledger.wrap(r1, alice, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapRequiresCreditSourceAndDebitDestination() public {
        vm.startPrank(alice);

        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, alice, true));
        ledger.wrap(address(externalToken), alice, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapToDifferentEmptyCreditSourceReverts() public {
        vm.startPrank(alice);

        uint256 wrapAmount = 50;
        address totalParent = address(externalToken);
        address explicitSource_ = address(0x5150);
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.addSubAccount(totalParent, explicitSource_, "Explicit Source", true);

        // Wrap using unallocated source.
        ledger.wrap(totalParent, source_, address(externalToken), alice, wrapAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InsufficientBalance.selector,
                address(externalToken),
                totalParent,
                LedgerLib.toAddress(totalParent, explicitSource_),
                wrapAmount
            )
        );
        ledger.unwrap(address(externalToken), alice, totalParent, explicitSource_, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapRequiresDebitSourceAndCreditDestination() public {
        vm.startPrank(alice);

        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), source_, address(externalToken), alice, wrapAmount);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, alice, true));
        ledger.unwrap(address(externalToken), alice, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapDoesNotRequireCallerLedgerBalance() public {
        vm.startPrank(alice);

        uint256 wrapAmount = 25;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), source_, address(externalToken), bob, wrapAmount);

        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), alice), 0, "caller has no wrapped ledger balance");
        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), bob), wrapAmount, "bob received wrapped balance");

        ledger.unwrap(address(externalToken), bob, address(externalToken), source_, wrapAmount);

        assertEq(ledgerView.debitBalanceOf(address(externalToken), address(externalToken), bob), 0, "bob wrapped balance cleared");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "caller receives external tokens");
        vm.stopPrank();
    }

    function testLedgerWrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, source_, "Zero Address", true);

        uint256 wrapAmount = 2 ether;
        uint256 dispatcherBalanceBefore = address(dispatcher).balance;
        ledger.wrap{value: wrapAmount}(native, source_, native, alice, wrapAmount);
        vm.stopPrank();

        assertEq(address(dispatcher).balance, dispatcherBalanceBefore + wrapAmount, "dispatcher holds native collateral");
        assertEq(ledgerView.debitBalanceOf(native, native, alice), wrapAmount, "ledger native balance");
        assertEq(ledgerView.totalSupply(native), wrapAmount, "native total supply");
    }

    function testLedgerWrapReentrancyGuard() public {
        // Deploy a token that reenters during transferFrom
        ReenterToken reToken = new ReenterToken("ReToken", "RET", 18);
        reToken.setTarget(address(ledger));
        ledger.addExternalToken(address(reToken));
        ledger.addSubAccount(address(reToken), source_, "Zero Address", true);

        // Fund Alice and approve the ledger
        vm.startPrank(alice);
        reToken.mint(alice, 10);
        reToken.approve(address(ledger), 10);
        reToken.setReenter(true);
        vm.expectRevert(ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector);
        ledger.wrap(address(reToken), source_, address(reToken), alice, 5);
        vm.stopPrank();
    }

    function testLedgerWrapNativeIncorrectValue() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, source_, "Zero Address", true);

        uint256 wrapAmount = 2 ether;
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, wrapAmount - 1, wrapAmount));
        ledger.wrap{value: wrapAmount - 1}(native, source_, native, alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapNonNativeRejectsValue() public {
        vm.startPrank(alice);
        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.wrap{value: 1}(address(externalToken), source_, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, source_, "Zero Address", true);

        uint256 wrapAmount = 3 ether;
        ledger.wrap{value: wrapAmount}(native, source_, native, alice, wrapAmount);
        uint256 dispatcherBalanceAfterWrap = address(dispatcher).balance;
        uint256 aliceBalanceAfterWrap = alice.balance;

        uint256 unwrapAmount = 1 ether;
        ledger.unwrap(native, alice, native, source_, unwrapAmount);
        vm.stopPrank();

        assertEq(address(dispatcher).balance, dispatcherBalanceAfterWrap - unwrapAmount, "dispatcher native balance");
        assertEq(alice.balance, aliceBalanceAfterWrap + unwrapAmount, "alice native balance");
        assertEq(ledgerView.debitBalanceOf(native, native, alice), wrapAmount - unwrapAmount, "ledger native balance");
        assertEq(ledgerView.totalSupply(native), wrapAmount - unwrapAmount, "native total supply");
    }

    function testLedgerUnwrapNativeRejectsValue() public {
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, source_, "Zero Address", true);

        uint256 wrapAmount = 1 ether;
        ledger.wrap{value: wrapAmount}(native, source_, native, alice, wrapAmount);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.unwrap{value: 1}(native, alice, native, alice, 0.5 ether);
        vm.stopPrank();
    }

    function testLedgerUnwrapNonNativeRejectsValue() public {
        vm.startPrank(alice);
        uint256 wrapAmount = 50;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), source_, address(externalToken), alice, wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.unwrap{value: 1}(address(externalToken), alice, address(externalToken), alice, 10);
        vm.stopPrank();
    }
    */

    // ─────────────────────────────────────────────────────────────────────────
    // Transfers / approvals / allowance / transferFrom (routed)
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerTransfer() public {
        vm.startPrank(alice);

        address dispatcherRoot = r1;
        address testLedgerRoot = address(testLedger);

        // Mint → transfer to bob under the same root
        ledger.mint(dispatcherRoot, dispatcherRoot, alice, 1000);
        // elm: fromParent = dispatcherRoot, toParent = dispatcherRoot, to = bob
        ledger.transfer(dispatcherRoot, dispatcherRoot, dispatcherRoot, bob, 700);

        assertEq(ledgerView.debitBalanceOf(dispatcherRoot, dispatcherRoot, alice), 300, "alice");
        assertEq(ledgerView.debitBalanceOf(dispatcherRoot, dispatcherRoot, bob), 700, "bob");
        assertEq(ledgerView.totalSupply(dispatcherRoot), 1000, "supply");

        // Different roots should revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.DifferentRoots.selector, dispatcherRoot, LedgerLib.toAddress(dispatcherRoot, testLedgerRoot)
            )
        );
        // attempt: fromParent=dispatcherRoot, toParent=testLedgerRoot (different root)
        ledger.transfer(dispatcherRoot, dispatcherRoot, testLedgerRoot, bob, 100);
    }

    function testLedgerExplicitTransferAuthenticatesBeforeAccounting() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(ILedger.Unauthorized.selector, bob));
        ledger.transfer(r1, r1, charlie, r1, bob, 1);
        vm.stopPrank();
    }

    function testLedgerTransferAcrossSiblingBranchesPreservesAncestorBalance() public {
        vm.startPrank(alice);

        ledger.mint(r1, r100, alice, 1000);
        ledger.transfer(r1, r100, r101, bob, 400);

        assertEq(ledgerView.debitBalanceOf(r1, r100, alice), 600, "r100/alice debited");
        assertEq(ledgerView.debitBalanceOf(r1, r101, bob), 400, "r101/bob credited");
        assertEq(ledgerView.debitBalanceOf(r1, r10, LedgerLib.toAddress("100")), 600, 'r10/"100" updated');
        assertEq(ledgerView.debitBalanceOf(r1, r10, LedgerLib.toAddress("101")), 400, 'r10/"101" updated');
        assertEq(
            ledgerView.debitBalanceOf(r1, r1, LedgerLib.toAddress("10")), 1000, 'r1/"10" unchanged above common ancestor'
        );
        assertEq(ledgerView.totalSupply(r1), 1000, "total supply unchanged");
    }

    function testLedgerTransferUsesLeafPolarityThroughMixedPolarityParents() public {
        vm.startPrank(alice);

        address creditLeaf_ = LedgerLib.toAddress("creditLeaf");
        ledger.addSubAccount(r1, r10, creditLeaf_, "creditLeaf", true);

        ledger.rawTransfer(r1, r10, creditLeaf_, r111, bob, 400);

        assertEq(ledgerView.creditBalanceOf(r1, r10, creditLeaf_), 400, "credit leaf credited");
        assertEq(ledgerView.debitBalanceOf(r1, r10, creditLeaf_), 0, "credit leaf debit untouched");
        assertEq(ledgerView.creditBalanceOf(r1, r1, _10), 400, "debit parent credit balance updated");
        assertEq(ledgerView.debitBalanceOf(r1, r1, _10), 0, "debit parent debit balance untouched");
        assertEq(ledgerView.debitBalanceOf(r1, r111, bob), 400, "debit target debited");
        assertEq(ledgerView.creditBalanceOf(r1, r111, bob), 0, "debit target credit untouched");
    }

    function testLedgerDeepTransferDoesNotEmitLegacyTransferEvent() public {
        vm.startPrank(alice);

        ledger.mint(r1, r100, alice, 1000);

        bytes32 legacyTransferTopic = keccak256("Transfer(address,address,uint256)");
        bytes32 creditTopic = keccak256("Credit(address,address,uint256,uint256)");
        bytes32 debitTopic = keccak256("Debit(address,address,uint256,uint256)");

        vm.recordLogs();
        ledger.transfer(r1, r100, r101, bob, 400);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        uint256 legacyTransferCount;
        uint256 creditCount;
        uint256 debitCount;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter != address(ledger) || logs[i].topics.length == 0) continue;
            if (logs[i].topics[0] == legacyTransferTopic) legacyTransferCount++;
            if (logs[i].topics[0] == creditTopic) creditCount++;
            if (logs[i].topics[0] == debitTopic) debitCount++;
        }

        assertEq(legacyTransferCount, 0, "legacy Transfer event");
        assertEq(creditCount, 2, "Credit event");
        assertEq(debitCount, 2, "Debit event");
    }

    function testLedgerDeepTransferEmitsCreditAndDebitEvents() public {
        vm.startPrank(alice);

        ledger.mint(r1, r100, alice, 1000);

        vm.expectEmit(true, true, false, true, address(ledger));
        emit ILedger.Credit(r1, LedgerLib.toAddress(r1, LedgerLib.toAddress(r100, alice)), 400, 600);
        vm.expectEmit(true, true, false, true, address(ledger));
        emit ILedger.Debit(r1, LedgerLib.toAddress(r1, LedgerLib.toAddress(r101, bob)), 400, 400);
        ledger.transfer(r1, r100, r101, bob, 400);
    }

    function testLedgerTransferRejectsCreditFromParent() public {
        vm.startPrank(alice);
        address sourceParent_ = LedgerLib.toAddress(r1, source_);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, sourceParent_));
        ledger.transfer(r1, sourceParent_, r1, bob, 1);
    }

    function testLedgerTransferAllowsBurnToZeroAddress() public {
        vm.startPrank(alice);

        ledger.mint(r1, r100, alice, 1000);

        ledger.transfer(r1, r100, r1, source_, 400);

        assertEq(ledgerView.debitBalanceOf(r1, r100, alice), 600, "alice debited");
        assertEq(ledgerView.creditBalanceOf(r1, r1, source_), 600, "source supply burned");
        assertEq(ledgerView.totalSupply(r1), 600, "supply burned");
    }

    function testLedgerTransferRejectsMintFromZeroAddress() public {
        vm.startPrank(alice);
        ledger.mint(r1, r100, alice, 1000);
        vm.stopPrank();

        vm.prank(r1);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, r1));
        ledger.transfer(r1, r1, source_, r100, bob, 400);
    }

    function testLedgerTransferRejectsMintFromCreditLeaf() public {
        address creditLeaf_ = LedgerLib.toAddress("creditLeaf");

        vm.startPrank(alice);
        ledger.addSubAccount(r1, r10, creditLeaf_, "creditLeaf", true);
        vm.stopPrank();

        vm.prank(creditLeaf_);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, r10));
        ledger.transfer(r1, r10, r100, bob, 400);
    }

    function testLedgerTransferAllowsBurnToCreditLeaf() public {
        address creditLeaf_ = LedgerLib.toAddress("creditLeaf");

        vm.startPrank(alice);
        ledger.addSubAccount(r1, r10, creditLeaf_, "creditLeaf", true);
        ledger.mint(r1, r100, alice, 1000);
        ledger.rawTransfer(r1, r10, creditLeaf_, r1, source_, 400);

        ledger.transfer(r1, r100, r10, creditLeaf_, 400);

        assertEq(ledgerView.debitBalanceOf(r1, r100, alice), 600, "alice debited");
        assertEq(ledgerView.creditBalanceOf(r1, r10, creditLeaf_), 0, "credit target burned");
        assertEq(ledgerView.totalSupply(r1), 600, "supply burned");
    }

    function testLedgerTransferAllowsCreditToCredit() public {
        address creditLeaf_ = LedgerLib.toAddress("creditLeaf");
        address otherCreditLeaf_ = LedgerLib.toAddress("otherCreditLeaf");

        vm.startPrank(alice);
        ledger.addSubAccount(r1, r10, creditLeaf_, "creditLeaf", true);
        ledger.addSubAccount(r1, r10, otherCreditLeaf_, "otherCreditLeaf", true);
        ledger.mint(r1, r100, alice, 1000);
        ledger.rawTransfer(r1, r10, otherCreditLeaf_, r1, source_, 400);
        vm.stopPrank();

        vm.prank(creditLeaf_);
        ledger.transfer(r1, r10, r10, otherCreditLeaf_, 150);

        assertEq(ledgerView.creditBalanceOf(r1, r10, creditLeaf_), 150, "credit source increased");
        assertEq(ledgerView.creditBalanceOf(r1, r10, otherCreditLeaf_), 250, "credit target decreased");
    }

    function testLedgerTransferInsufficientBalanceReportsDeepUnregisteredLeafContext() public {
        vm.startPrank(alice);

        ledger.mint(r1, r100, alice, 1000);

        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InsufficientBalance.selector,
                r1,
                r100,
                LedgerLib.toAddress(r1, LedgerLib.toAddress(r100, alice)),
                1001
            )
        );
        ledger.transfer(r1, r100, r101, bob, 1001);
    }
}

// contract Bah {
// function testLedgerAddSubAccount() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(dispatcher));
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Adding a new valid subAccount");
//     address added = ledger.addSubAccount(r1, r1, "newSubAccount", true, false);
//     assertEq(added, LedgerLib.toAddress(r1, "newSubAccount"), "addSubAccount address");
//     assertEq(tree.holderParent(added), r1, "Parent should be r1");
//     assertEq(
//         tree.subAccountIndex(added),
//         tree.subAccounts(r1).length,
//         "SubAccount index should match subAccounts length"
//     );
//     assertTrue(tree.hasSubAccount(r1), "r1 should have subAccounts");

//     if (isVerbose) console.log("Adding a subAccount that already exists");
//     setUp();
//     ledger.addSubAccount(r1, r1, "newSubAccount", true, false);

//     if (isVerbose) {
//         console.log("Adding a subAccount whose parent is address(0)");
//     }
//     setUp();
//     vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, address(0)));
//     ledger.addSubAccount(address(0), "zeroParentSubAccount", true, false);

//     if (isVerbose) {
//         console.log('Adding a subAccount whose name is ""');
//     }
//     setUp();
//     vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, "", true, false));
//     ledger.addSubAccount(r1, r1, "", true, false);
// }

// function testLedgerRemoveSubAccount() public {
//     bool isVerbose = false;

//     vm.startPrank(alice);

//     // First run the tree visualization tests
//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(dispatcher));
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 111");
//         ledger.removeSubAccount(r1, r11, "111");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 110");
//         ledger.removeSubAccount(r1, r11, "110");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 101");
//         ledger.removeSubAccount(r1, r10, "101");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 100");
//         ledger.removeSubAccount(r1, r10, "100");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 11");
//         ledger.removeSubAccount(r1, r1, "11");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 10");
//         ledger.removeSubAccount(r1, r1, "10");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         setUp();
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     // Now run the validation tests
//     if (isVerbose) {
//         console.log("Test 1: Remove a valid subAccount (leaf node)");
//     }
//     ledger.addSubAccount(r1, r1, "leafSubAccount", true, false);
//     ledger.removeSubAccount(r1, r1, "leafSubAccount");
//     assertEq(tree.holderParent(LedgerLib.toAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
//     assertEq(
//         tree.subAccountIndex(LedgerLib.toAddress(r1, "leafSubAccount")), 0, "SubAccount index should be reset"
//     );
//     assertEq(ledger.name(LedgerLib.toAddress(r1, "leafSubAccount")), "", "Name should be cleared");
//     assertFalse(tree.hasSubAccount(LedgerLib.toAddress(r1, "leafSubAccount")), "Should not have subAccounts");

//     if (isVerbose) {
//         console.log("Test 2: Remove a subAccount that doesn't exist");
//     }
//     address nonExistentSubAccount = LedgerLib.toAddress(r1, "nonExistentSubAccount");
//     vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, nonExistentSubAccount));
//     ledger.removeSubAccount(r1, r1, "nonExistentSubAccount");

//     if (isVerbose) {
//         console.log("Test 3: Remove a subAccount that has subAccounts");
//     }
//     address parentWithSubAccount = ledger.addSubAccount(r1, r1, "parentWithSubAccount", true, false);
//     ledger.addSubAccount(parentWithSubAccount, "subAccountOfParent", true, false);
//     vm.expectRevert(abi.encodeWithSelector(ILedger.HasSubAccount.selector, "parentWithSubAccount"));
//     ledger.removeSubAccount(r1, r1, "parentWithSubAccount");

//     if (isVerbose) {
//         console.log("Test 4: Remove a subAccount that has a balance");
//     }
//     ledger.mint(r1, r100, 1000);
//     vm.expectRevert(abi.encodeWithSelector(ILedger.HasBalance.selector, "100"));
//     ledger.removeSubAccount(r1, r10, "100");

//     if (isVerbose) {
//         console.log("Test 5: Remove a subAccount with invalid addresses");
//     }
//     address validSubAccount = ledger.addSubAccount(r1, r1, "validSubAccount", true, false);

//     // Try to remove with address(0) as parent
//     vm.expectRevert(ILedger.ZeroAddress.selector);
//     ledger.removeSubAccount(address(0), "validSubAccount");

//     // Try to remove with same address for parent and subAccount
//     vm.expectRevert(
//         abi.encodeWithSelector(
//             ILedger.InvalidAccountGroup.selector, LedgerLib.toAddress(validSubAccount, "validSubAccount")
//         )
//     );
//     ledger.removeSubAccount(validSubAccount, "validSubAccount");

//     if (isVerbose) {
//         console.log("Test 6: Remove a subAccount and verify parent's subAccounts array is updated correctly");
//     }
//     setUp();
//     address subAccount1 = ledger.addSubAccount(r1, r1, "subAccount1", true, false);
//     ledger.addSubAccount(r1, r1, "subAccount2", true, false);
//     address subAccount3 = ledger.addSubAccount(r1, r1, "subAccount3", true, false);

//     uint256 subAccountCount = tree.subAccounts(r1).length;

//     if (isVerbose) {
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     // Remove subAccount2 (middle subAccount)
//     ledger.removeSubAccount(r1, r1, "subAccount2");

//     // Verify subAccounts array is updated correctly
//     address[] memory subAccounts = tree.subAccounts(r1);
//     assertEq(subAccounts.length, subAccountCount - 1, "Incorrect number of subAccounts after removal");
//     assertEq(subAccounts[subAccountCount - 3], subAccount1, "First subAccount should be subAccount1");
//     assertEq(subAccounts[subAccountCount - 2], subAccount3, "Second subAccount should be subAccount3");

//     if (isVerbose) console.log("Verify subAccount indices are updated");
//     assertEq(
//         tree.subAccountIndex(LedgerLib.toAddress(r1, "subAccount1")),
//         subAccountCount - 2,
//         "subAccount1 index incorrect"
//     );
//     if (isVerbose) {
//         console.log("Display subaccounts");
//         for (uint256 i = 0; i < subAccounts.length; i++) {
//             console.log(
//                 "SubAccount", ledger.name(subAccounts[i]), subAccounts[i], tree.subAccountIndex(subAccounts[i])
//             );
//         }
//     }
//     assertEq(
//         tree.subAccountIndex(LedgerLib.toAddress(r1, "subAccount3")),
//         subAccountCount - 1,
//         "subAccount3 index incorrect"
//     );
// }

// function testLedgerMint() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(dispatcher));
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Initial mint address(this): Alice");
//     ledger.mint(address(ledger), 1000);

//     assertEq(ledger.balanceOf(alice), 1000, "balanceOf(alice)");
//     assertEq(ledger.totalSupply(), 1000, "totalSupply");

//     if (isVerbose) console.log("Mint token 1: Alice");
//     ledger.mint(r1, r100, 1000);
//     assertEq(ledger.balanceOf(r100, alice), 1000, "balanceOf(r100, alice)");
//     assertEq(ledger.balanceOf(r10, "100"), 1000, 'balanceOf(r10, "100")');
//     assertEq(ledger.balanceOf(r1, "10"), 1000, 'balanceOf(r1, "10")');
//     assertEq(ledger.totalSupply(r1), 1000, "totalSupply(r1)");
// }

// function testLedgerBurn() public {
//     vm.startPrank(alice);

//     ledger.mint(address(ledger), 1000);
//     ledger.burn(address(ledger), 700);

//     assertEq(ledger.balanceOf(alice), 300, "balanceOf(alice)");
//     assertEq(ledger.totalSupply(), 300, "totalSupply");

//     ledger.mint(r1, r100, 1000);
//     ledger.burn(r1, r100, 600);

//     assertEq(ledger.balanceOf(r100, alice), 400, "balanceOf(r100, alice)");
//     assertEq(ledger.balanceOf(r10, "100"), 400, 'balanceOf(r10, "100")');
//     assertEq(ledger.balanceOf(r1, "10"), 400, 'balanceOf(r1, "10")');
//     assertEq(ledger.totalSupply(r1), 400, "totalSupply(r1)");
// }

// function testLedgerParents() public view {
//     assertEq(tree.root(r10), r1, "root(_10)");
//     assertEq(tree.root(r11), r1, "root(_11)");
//     assertEq(tree.root(r100), r1, "root(_100)");
//     assertEq(tree.root(r101), r1, "root(_101)");
//     assertEq(tree.root(r110), r1, "root(_110)");
//     assertEq(tree.root(r111), r1, "root(_111)");

//     assertEq(tree.holderParent(r10), r1, "parent(_10)");
//     assertEq(tree.holderParent(r11), r1, "parent(_11)");
//     assertEq(tree.holderParent(r100), r10, "parent(_100)");
//     assertEq(tree.holderParent(r101), r10, "parent(_101)");
//     assertEq(tree.holderParent(r110), r11, "parent(_110)");
//     assertEq(tree.holderParent(r111), r11, "parent(_111)");
// }

// function testLedgerHasSubAccount() public view {
//     assertTrue(tree.hasSubAccount(r1), "hasSubAccount(r1)");
//     assertTrue(tree.hasSubAccount(r10), "hasSubAccount(r10)");
//     assertTrue(tree.hasSubAccount(LedgerLib.toAddress(r1, r11)), "hasSubAccount(r11)");
//     assertFalse(tree.hasSubAccount(r100), "hasSubAccount(r100)");
//     assertFalse(tree.hasSubAccount(r101), "hasSubAccount(r101)");
//     assertFalse(tree.hasSubAccount(r110), "hasSubAccount(r110)");
//     assertFalse(tree.hasSubAccount(r111), "hasSubAccount(r111)");
// }

// function testLedgerTransfer() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(dispatcher));
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Initial mint and transfer");
//     ledger.mint(address(ledger), 1000);
//     ledger.transfer(bob, 700);

//     assertEq(ledger.balanceOf(address(ledger)), 0, "balanceOf(this)");
//     assertEq(ledger.balanceOf(alice), 300, "balanceOf(alice)");
//     assertEq(ledger.balanceOf(bob), 700, "balanceOf(bob)");
//     assertEq(ledger.totalSupply(), 1000, "totalSupply()");

//     if (isVerbose) console.log("Transfer from alice to bob");
//     ledger.transfer(address(ledger), address(ledger), bob, 100);

//     assertEq(ledger.balanceOf(alice), 200, "balanceOf(alice)");
//     assertEq(ledger.balanceOf(bob), 800, "balanceOf(bob)");
//     assertEq(ledger.totalSupply(), 1000, "totalSupply()");

//     if (isVerbose) console.log("Expect revert if sender and receiver have different roots");
//     vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, address(ledger), r1));
//     ledger.transfer(address(ledger), _1, _10, 100);
// }

// function testLedgerApprove() public {
//     bool isVerbose = false;

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Initial mint and approve");
//     ledger.mint(address(ledger), 1000);
//     ledger.approve(bob, 100);

//     assertEq(ledger.allowance(alice, bob), 100, "allowance(alice, bob)");
//     assertEq(ledger.allowance(bob, alice), 0, "allowance(bob, alice)");
//     assertEq(ledger.allowance(bob, bob), 0, "allowance(bob, bob)");
//     assertEq(ledger.allowance(alice, alice), 0, "allowance(alice, alice)");
// }

// function testLedgerTransferFrom() public {
//     vm.startPrank(alice);

//     ledger.mint(address(ledger), 1000);
//     ledger.approve(bob, 100);

//     vm.startPrank(bob);

//     ledger.transferFrom(alice, bob, 100);

//     assertEq(ledger.balanceOf(alice), 900, "balanceOf(alice)");
//     assertEq(ledger.balanceOf(bob), 100, "balanceOf(bob)");
//     assertEq(ledger.totalSupply(), 1000, "totalSupply()");

//     vm.startPrank(alice);

//     ledger.mint(r1, r1, 1000);
//     ledger.approve(r1, r1, bob, 100);

//     vm.startPrank(bob);

//     ledger.transferFrom(r1, alice, r1, r10, _100, 100);

//     assertEq(ledger.balanceOf(r1, alice), 900, "balanceOf(_1, alice)");
//     assertEq(ledger.balanceOf(r1, bob), 0, "balanceOf(_1, bob)");
//     assertEq(ledger.balanceOf(r10, _100), 100, "balanceOf(_10, _100)");
//     assertEq(ledger.totalSupply(_1), 1000, "totalSupply(_1)");
// }
// }
