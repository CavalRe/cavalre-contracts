// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ─────────────────────────────────────────────────────────────────────────────
// Import split layout (interfaces + lib + module + infra)
// Adjust paths if your repo layout differs.
// ─────────────────────────────────────────────────────────────────────────────
import {ILedger} from "../../interfaces/ILedger.sol";
import {LedgerLib} from "../../libraries/LedgerLib.sol";
import {Ledger, ERC20Wrapper} from "../../modules/Ledger.sol";
import {Module} from "../../modules/Module.sol";
import {Router} from "../../modules/Router.sol";
import {Tree} from "../../modules/Tree.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {TreeLib} from "../../libraries/TreeLib.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Test, console} from "forge-std/src/Test.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Test module that exposes LedgerLib via external funcs for Router delegatecall
// ─────────────────────────────────────────────────────────────────────────────
contract TestLedger is Ledger {
    string internal constant LEDGER_NAME = "Ledger";
    string internal constant LEDGER_SYMBOL = "LEDGER";
    string internal constant DEFAULT_SOURCE_NAME = "Source";

    constructor(uint8 decimals_) Ledger(decimals_, "Ethereum", "ETH", DEFAULT_SOURCE_NAME) {}

    // Keep command registry so Router can “register” the module (if you use it)
    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](28);
        // From Ledger
        _selectors[n++] = bytes4(keccak256("initializeTestLedger()"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addNativeToken()"));
        _selectors[n++] = bytes4(keccak256("addExternalToken(address)"));
        _selectors[n++] = bytes4(keccak256("createToken(string,string,uint8,bool)"));
        _selectors[n++] = bytes4(keccak256("createWrapper(address)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,address)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,string)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,address)"));
        _selectors[n++] = bytes4(keccak256("name(address)"));
        _selectors[n++] = bytes4(keccak256("symbol(address)"));
        _selectors[n++] = bytes4(keccak256("decimals(address)"));
        _selectors[n++] = bytes4(keccak256("nativeName()"));
        _selectors[n++] = bytes4(keccak256("nativeSymbol()"));
        _selectors[n++] = bytes4(keccak256("debitBalanceOf(address,address)"));
        _selectors[n++] = bytes4(keccak256("creditBalanceOf(address,address)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _selectors[n++] = bytes4(keccak256("totalSupply(address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,uint256)"));
        // Extra test-exposing commands
        _selectors[n++] = bytes4(keccak256("mint(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("burn(address,address,uint256)"));
        // TODO: Move to DepositLib
        // _selectors[n++] = bytes4(keccak256("reallocate(address,address,uint256)"));
        if (n != 28) revert InvalidCommandsLength(n);
    }

    function initializeTestLedger() external initializer {
        enforceIsOwner();
        initializeLedger_unchained(LEDGER_NAME, LEDGER_SYMBOL);
    }

    function mint(address toParent_, address to_, uint256 amount_) external {
        address _token = LedgerLib.root(toParent_);
        uint256 _tokenFlags = LedgerLib.flags(_token);
        if (LedgerLib.isCredit(_tokenFlags)) {
            LedgerLib.transfer(toParent_, to_, _token, LedgerLib.toAddress(DEFAULT_SOURCE_NAME), amount_);
        } else {
            LedgerLib.transfer(_token, LedgerLib.toAddress(DEFAULT_SOURCE_NAME), toParent_, to_, amount_);
        }
        // Emit event from wrapper address
        if (LedgerLib.isInternal(_tokenFlags)) {
            address _wrapper = LedgerLib.wrapper(_token);
            if (_wrapper != address(0)) {
                ERC20Wrapper(_wrapper).mint(to_, amount_);
            }
        }
    }

    function burn(address fromParent_, address from_, uint256 amount_) external {
        address _token = LedgerLib.root(fromParent_);
        uint256 _tokenFlags = LedgerLib.flags(_token);
        if (LedgerLib.isCredit(_tokenFlags)) {
            LedgerLib.transfer(_token, LedgerLib.toAddress(DEFAULT_SOURCE_NAME), fromParent_, from_, amount_);
        } else {
            LedgerLib.transfer(fromParent_, from_, _token, LedgerLib.toAddress(DEFAULT_SOURCE_NAME), amount_);
        }
        // Emit event from wrapper address
        if (LedgerLib.isInternal(_tokenFlags)) {
            address _wrapper = LedgerLib.wrapper(_token);
            if (_wrapper != address(0)) {
                ERC20Wrapper(_wrapper).burn(from_, amount_);
            }
        }
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
    string internal constant DEFAULT_SOURCE_NAME = "Source";

    Router router;
    TestLedger ledger;
    Tree tree;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);
    address native = LedgerLib.NATIVE_ADDRESS;

    address testLedger;
    MockERC20 externalToken;
    MockERC20 unlistedToken;
    address externalWrapper;

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
        ledger = new TestLedger(18);
        Tree treeImpl = new Tree();
        if (isVerbose) console.log("Deploying Router");
        router = new Router(alice);
        if (isVerbose) console.log("Adding Ledger module to Router");
        router.addModule(address(ledger));
        router.addModule(address(treeImpl));
        ledger = TestLedger(payable(router));
        tree = Tree(payable(address(router)));

        if (isVerbose) console.log("Initializing Test Ledger");
        ledger.initializeTestLedger();
        source_ = LedgerLib.toAddress(DEFAULT_SOURCE_NAME);

        // Add a standalone ledger tree for misc checks
        // testLedger = LedgerLib.toAddress("Test Ledger");
        if (isVerbose) console.log("Creating Test Ledger token");
        (testLedger,) = ledger.createToken("Test Ledger", "TL", 18, false);
        ledger.addSubAccount(testLedger, source_, "Source", true);
        if (isVerbose) console.log("Adding sub-groups to Test Ledger");
        (address testLedger_1_,) = ledger.addSubAccountGroup(testLedger, "1", false);
        (address testLedger_10_,) = ledger.addSubAccountGroup(testLedger_1_, "10", false);
        ledger.addSubAccountGroup(testLedger_10_, "100", false);

        // Add token r1 and its sub-groups
        if (isVerbose) console.log("Creating root token '1'");
        (r1,) = ledger.createToken("1", "1", 18, false);
        ledger.addSubAccount(r1, source_, "Source", true);
        if (isVerbose) console.log("Adding sub-group '10' to root token '1'");
        (r10,) = ledger.addSubAccountGroup(r1, "10", false);
        if (isVerbose) console.log("Adding sub-group '11' to root token '1'");
        (r11,) = ledger.addSubAccountGroup(r1, "11", false);
        if (isVerbose) console.log("Adding sub-groups '100' to '10'");
        (r100,) = ledger.addSubAccountGroup(r10, "100", false);
        if (isVerbose) console.log("Adding sub-groups '101' to '10'");
        (r101,) = ledger.addSubAccountGroup(r10, "101", false);
        if (isVerbose) console.log("Adding sub-groups '110' to '11'");
        (r110,) = ledger.addSubAccountGroup(r11, "110", false);
        if (isVerbose) console.log("Adding sub-groups '111' to '11'");
        (r111,) = ledger.addSubAccountGroup(r11, "111", false);

        if (isVerbose) console.log("Creating external token and its wrapper");
        externalToken = new MockERC20("External Token", "EXT", 18);
        ledger.addExternalToken(address(externalToken));
        ledger.createWrapper(address(externalToken));
        ledger.addSubAccount(address(externalToken), source_, "Source", true);
        externalWrapper = tree.wrapper(address(externalToken));

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
        if (isVerbose) tree.debugTree(address(router));
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

        // Tree shape sanity
        assertEq(ledger.name(address(router)), "Ledger", "ledger name");
        assertEq(ledger.symbol(address(router)), "LEDGER", "ledger symbol");
        assertEq(tree.subAccounts(testLedger).length, 2, "Subaccounts (testLedger)");
        assertEq(tree.subAccounts(r1).length, 3, "Subaccounts (r1)");
        assertEq(tree.subAccounts(r10).length, 2, "Subaccounts (r10)");
        assertEq(tree.subAccounts(r11).length, 2, "Subaccounts (r11)");

        TreeLib.TreeNode memory rootNode_ = tree.treeNode(r1);
        assertEq(rootNode_.addr, r1, "node root addr");
        assertEq(rootNode_.parent, address(0), "node root parent");
        assertEq(rootNode_.root, r1, "node root");
        assertEq(rootNode_.name, "1", "node root name");
        assertEq(rootNode_.symbol, "1", "node root symbol");
        assertEq(rootNode_.decimals, 18, "node root decimals");
        assertEq(rootNode_.flags, tree.flags(r1), "node root flags");
        assertEq(rootNode_.subs.length, 3, "node root subs");

        TreeLib.TreeNode memory childNode_ = tree.treeNode(r1, _10);
        assertEq(childNode_.addr, r10, "node child addr");
        assertEq(childNode_.parent, r1, "node child parent");
        assertEq(childNode_.root, r1, "node child root");
        assertEq(childNode_.name, "10", "node child name");
        assertEq(childNode_.decimals, 18, "node child decimals");
        assertEq(childNode_.flags, tree.flags(r10), "node child flags");
        assertEq(childNode_.subs.length, 2, "node child subs");

        assertEq(tree.subAccountIndex(r1, _10), 2, "idx(r10)");
        assertEq(tree.subAccountIndex(r1, _11), 3, "idx(r11)");
        assertEq(tree.subAccountIndex(r10, _100), 1, "idx(r100)");
        assertEq(tree.subAccountIndex(r10, _101), 2, "idx(r101)");
        assertEq(tree.subAccountIndex(r11, _110), 1, "idx(r110)");
        assertEq(tree.subAccountIndex(r11, _111), 2, "idx(r111)");
    }

    function testNativeWrapperNotCreatedDuringInit() public view {
        assertEq(tree.wrapper(native), address(0), "wrapper unset");
        assertEq(tree.root(native), address(0), "root unset");
        assertEq(ledger.name(native), "", "name empty");
        assertEq(ledger.symbol(native), "", "symbol empty");
    }

    function testLedgerAddNativeTokenAndCreateWrapper() public {
        vm.startPrank(alice);
        ledger.addNativeToken();
        (address wrapper,) = ledger.createWrapper(native);
        ledger.addNativeToken();
        (address wrapperAgain,) = ledger.createWrapper(native);
        vm.stopPrank();

        assertEq(tree.wrapper(native), wrapper, "wrapper set");
        assertEq(wrapperAgain, wrapper, "wrapper idempotent");
        assertEq(tree.root(native), native, "root native");
        assertEq(ledger.name(native), "Ethereum", "name");
        assertEq(ledger.symbol(native), "ETH", "symbol");
        assertEq(ledger.decimals(native), 18, "decimals");
        assertTrue((tree.flags(native) & LedgerLib.FLAG_IS_NATIVE) != 0, "native flag set");
        assertTrue(tree.wrapper(native) != address(0), "wrapper set");
        assertEq(tree.flags(native) & LedgerLib.FLAG_IS_INTERNAL, 0, "native not internal");
        assertFalse(LedgerLib.isExternal(tree.flags(native)), "native not external");
    }

    function testLedgerCreateWrapperCanonicalRootIsIdempotent() public {
        vm.startPrank(alice);
        (address wrapper_,) = ledger.createWrapper(address(ledger));
        (address wrapperAgain_,) = ledger.createWrapper(address(ledger));
        vm.stopPrank();

        assertEq(wrapperAgain_, wrapper_, "same wrapper");
        assertEq(tree.wrapper(address(ledger)), wrapper_, "wrapper stored");
        assertEq(tree.root(address(ledger)), address(ledger), "root unchanged");
        assertEq(ledger.name(address(ledger)), "Ledger", "name stable");
    }

    function testLedgerCreateWrapperInternalRootIsIdempotent() public {
        vm.startPrank(alice);
        (address wrapper_,) = ledger.createWrapper(r1);
        (address wrapperAgain_,) = ledger.createWrapper(r1);
        vm.stopPrank();

        assertEq(wrapper_, r1, "internal self wrapper");
        assertEq(wrapperAgain_, wrapper_, "same wrapper");
        assertEq(tree.wrapper(r1), r1, "wrapper stable");
        assertEq(tree.root(r1), r1, "root stable");
    }

    function testLedgerCreateTokenDoesNotRegisterUnderRoot() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createToken("Neutral Token", "NT", 18, false);
        vm.stopPrank();

        address rootAccount_ = LedgerLib.toAddress(address(ledger), token_);
        assertEq(tree.flags(rootAccount_), 0, "not auto-registered under root");
    }

    function testLedgerCreateTokenIsIdempotent() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createToken("Neutral Token", "NT", 18, false);
        (address tokenAgain_,) = ledger.createToken("Neutral Token", "NT", 18, false);
        vm.stopPrank();

        assertEq(tokenAgain_, token_, "same token");
        assertEq(tree.root(token_), token_, "root registered");
        assertEq(tree.wrapper(token_), token_, "self wrapped");
        assertEq(ledger.name(token_), "Neutral Token", "name stable");
        assertEq(ledger.symbol(token_), "NT", "symbol stable");
        assertEq(ledger.decimals(token_), 18, "decimals stable");
    }

    function testLedgerCreateCreditTokenIsIdempotent() public {
        vm.startPrank(alice);
        (address token_, uint256 flags_) = ledger.createToken("Claim Token", "CLM", 18, true);
        (address tokenAgain_, uint256 flagsAgain_) = ledger.createToken("Claim Token", "CLM", 18, true);
        vm.stopPrank();

        assertEq(tokenAgain_, token_, "same token");
        assertEq(flagsAgain_, flags_, "same flags");
        assertTrue(tree.isCredit(flags_), "credit root");
        assertEq(tree.root(token_), token_, "root registered");
        assertEq(tree.wrapper(token_), token_, "self wrapped");
    }

    function testLedgerAddExternalTokenAndCreateWrapperAreIdempotent() public {
        vm.startPrank(alice);
        ledger.addExternalToken(address(unlistedToken));
        (address wrapper_,) = ledger.createWrapper(address(unlistedToken));
        ledger.addExternalToken(address(unlistedToken));
        (address wrapperAgain_,) = ledger.createWrapper(address(unlistedToken));
        vm.stopPrank();

        assertEq(tree.root(address(unlistedToken)), address(unlistedToken), "root registered");
        assertEq(wrapperAgain_, wrapper_, "wrapper idempotent");
        assertEq(tree.wrapper(address(unlistedToken)), wrapper_, "wrapper unchanged");
        assertEq(ledger.name(address(unlistedToken)), "Unlisted Token", "name stable");
        assertEq(ledger.symbol(address(unlistedToken)), "UNL", "symbol stable");
        assertEq(ledger.decimals(address(unlistedToken)), 18, "decimals stable");
    }

    function testLedgerRootFlagsByTokenType() public view {
        uint256 internalFlags = tree.flags(r1);
        assertTrue((internalFlags & LedgerLib.FLAG_IS_INTERNAL) != 0, "internal token flag set");
        assertTrue(tree.wrapper(r1) != address(0), "internal wrapper set");
        assertEq(internalFlags & LedgerLib.FLAG_IS_NATIVE, 0, "internal token not native");
        assertFalse(LedgerLib.isExternal(internalFlags), "internal token not external");
        assertTrue(tree.isRoot(internalFlags), "internal root");

        uint256 externalFlags = tree.flags(address(externalToken));
        assertEq(externalFlags & LedgerLib.FLAG_IS_INTERNAL, 0, "external token not internal");
        assertTrue(tree.wrapper(address(externalToken)) != address(0), "external wrapper set");
        assertTrue(LedgerLib.isExternal(externalFlags), "external flag set");
        assertEq(externalFlags & LedgerLib.FLAG_IS_NATIVE, 0, "external token not native");
        assertTrue(tree.isRoot(externalFlags), "external root");
        assertFalse(tree.isRoot(tree.flags(r10)), "child not root");
    }

    function testLedgerEffectiveFlags() public {
        vm.startPrank(alice);
        (address creditParent_,) = ledger.addSubAccountGroup(r1, "creditParent", true);
        (address debitAddr_, uint256 debitFlags_) = tree.effectiveFlags(r1, LedgerLib.toAddress("missingDebit"));

        assertEq(debitAddr_, LedgerLib.toAddress(r1, LedgerLib.toAddress("missingDebit")), "absolute address");
        assertFalse(tree.isCredit(debitFlags_), "inherits debit parent");
        assertEq(LedgerLib.parent(debitFlags_), r1, "inherits parent");
        ledger.addSubAccount(r1, source_, "Source", true);
        (, uint256 sourceFlags_) = tree.effectiveFlags(r1, source_);
        assertTrue(tree.isCredit(sourceFlags_), "registered credit leaf");
        (, uint256 missingCreditFlags_) = tree.effectiveFlags(creditParent_, LedgerLib.toAddress("missingCredit"));
        assertTrue(tree.isCredit(missingCreditFlags_), "inherits credit parent");
    }

    function testLedgerBalanceOfUsesEffectivePolarity() public {
        vm.startPrank(alice);
        address missingDebit_ = LedgerLib.toAddress("missingDebit");
        ledger.mint(r1, missingDebit_, 100);

        assertEq(ledger.balanceOf(r1, missingDebit_), 100, "unregistered debit leaf");
        assertEq(ledger.balanceOf(r1, source_), 100, "registered credit source leaf");
    }

    function testPackedParentAndWrapperMapping() public view {
        assertEq(address(uint160(tree.flags(r10) >> 96)), r1, "packed parent r10");
        assertEq(address(uint160(tree.flags(r100) >> 96)), r10, "packed parent r100");
        assertEq(address(uint160(tree.flags(r1) >> 96)), address(0), "packed parent root");

        assertEq(tree.wrapper(r10), address(0), "non-root wrapper unset");
        assertEq(tree.wrapper(r1), r1, "internal root wrapper");
        assertEq(tree.wrapper(address(externalToken)), externalWrapper, "external root wrapper");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AddSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerAddSubAccountGroup() public {
        vm.startPrank(alice);

        // Add a fresh sub under r1
        (address added, uint256 flags_) = ledger.addSubAccountGroup(r1, "newSubAccount", false);
        address[] memory before_ = tree.subAccounts(r1);
        uint32 index_ = tree.subAccountIndex(r1, LedgerLib.toAddress("newSubAccount"));
        assertEq(added, LedgerLib.toAddress(r1, "newSubAccount"), "address mismatch");
        assertEq(tree.parent(added), r1, "parent mismatch");
        assertEq(index_, before_.length, "index should equal #subs");
        assertTrue(tree.hasSubAccount(r1), "r1 should have subs");
        assertEq(tree.flags(added), flags_, "flags stored");
        assertEq(ledger.name(added), "newSubAccount", "name stored");

        (address idempotent, uint256 flagsAgain_) = ledger.addSubAccountGroup(r1, "newSubAccount", false);
        address[] memory after_ = tree.subAccounts(r1);
        assertEq(idempotent, added, "expected same sub account address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(after_.length, before_.length, "child count stable");
        assertEq(after_[after_.length - 1], before_[before_.length - 1], "child ordering stable");
        assertEq(tree.subAccountIndex(r1, LedgerLib.toAddress("newSubAccount")), index_, "index stable");
        assertEq(ledger.name(added), "newSubAccount", "name stable");
    }

    function testLedgerAddSubAccountGroupAddressFormIsIdempotent() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("groupByAddr");
        (address added_, uint256 flags_) = ledger.addSubAccountGroup(r1, relative_, "groupByAddr", false);
        address[] memory before_ = tree.subAccounts(r1);
        uint32 index_ = tree.subAccountIndex(r1, relative_);
        (address addedAgain_, uint256 flagsAgain_) = ledger.addSubAccountGroup(r1, relative_, "groupByAddr", false);
        address[] memory after_ = tree.subAccounts(r1);

        assertEq(addedAgain_, added_, "same address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(after_.length, before_.length, "child count stable");
        assertEq(after_[after_.length - 1], relative_, "no duplicate child");
        assertEq(tree.subAccountIndex(r1, relative_), index_, "index stable");
        assertEq(ledger.name(added_), "groupByAddr", "name stable");
    }

    function testLedgerAddSubAccountGroupRejectsFundedDebitLeaf() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("fundedGroupDebit");
        ledger.mint(r1, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccountGroup.selector, "fundedGroupDebit", false));
        ledger.addSubAccountGroup(r1, relative_, "fundedGroupDebit", false);
    }

    function testLedgerAddSubAccountGroupRejectsFundedCreditLeaf() public {
        vm.startPrank(alice);

        (address creditRoot_,) = ledger.createToken("Credit Group Root", "CGR", 18, true);
        ledger.addSubAccount(creditRoot_, source_, "Source", false);
        address relative_ = LedgerLib.toAddress("fundedGroupCredit");
        ledger.mint(creditRoot_, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccountGroup.selector, "fundedGroupCredit", true));
        ledger.addSubAccountGroup(creditRoot_, relative_, "fundedGroupCredit", true);
    }

    function testLedgerAddSubAccountNameDelegatesToAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("leafSubAccount");
        (address added_,) = ledger.addSubAccount(r1, "leafSubAccount", false);

        assertEq(added_, LedgerLib.toAddress(r1, relative_), "address mismatch");
        assertEq(tree.subAccounts(r1)[tree.subAccounts(r1).length - 1], relative_, "relative addr stored");
    }

    function testLedgerAddSubAccountIsIdempotent() public {
        vm.startPrank(alice);

        (address added_, uint256 flags_) = ledger.addSubAccount(r1, "leafSubAccount", false);
        address relative_ = LedgerLib.toAddress("leafSubAccount");
        address[] memory before_ = tree.subAccounts(r1);
        uint32 index_ = tree.subAccountIndex(r1, relative_);
        (address addedAgain_, uint256 flagsAgain_) = ledger.addSubAccount(r1, "leafSubAccount", false);
        address[] memory after_ = tree.subAccounts(r1);

        assertEq(addedAgain_, added_, "same address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(after_.length, before_.length, "child count stable");
        assertEq(after_[after_.length - 1], relative_, "no duplicate child");
        assertEq(tree.subAccountIndex(r1, relative_), index_, "index stable");
        assertEq(ledger.name(added_), "leafSubAccount", "name stable");
    }

    function testLedgerAddSubAccountRegistersFundedDebitLeaf() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("fundedDebit");
        ledger.mint(r1, relative_, 100);

        (address added_, uint256 flags_) = ledger.addSubAccount(r1, relative_, "fundedDebit", false);

        assertEq(added_, LedgerLib.toAddress(r1, relative_), "registered addr");
        assertFalse(tree.isCredit(flags_), "registered debit");
        assertEq(ledger.balanceOf(r1, relative_), 100, "balance preserved");
    }

    function testLedgerAddSubAccountRejectsFundedDebitLeafAsCredit() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("fundedDebit");
        ledger.mint(r1, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, relative_, true));
        ledger.addSubAccount(r1, relative_, "fundedDebit", true);
    }

    function testLedgerAddSubAccountRejectsFundedCreditLeafAsDebit() public {
        vm.startPrank(alice);

        (address creditRoot_,) = ledger.createToken("Credit Root", "CRT", 18, true);
        ledger.addSubAccount(creditRoot_, source_, "Source", false);
        address relative_ = LedgerLib.toAddress("fundedCredit");
        ledger.mint(creditRoot_, relative_, 100);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, relative_, false));
        ledger.addSubAccount(creditRoot_, relative_, "fundedCredit", false);
    }

    function testLedgerAddSubAccountZeroParentReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, address(0)));
        ledger.addSubAccountGroup(address(0), "zeroParent", false);
    }

    function testLedgerAddSubAccountEmptyNameReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidString.selector, ""));
        ledger.addSubAccountGroup(r1, "", false);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RemoveSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerRemoveSubAccountHappyPath() public {
        isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Removing subaccount");
        ledger.removeSubAccountGroup(r10, "100");

        if (isVerbose) console.log("Check parent");
        assertEq(tree.parent(_100), address(0), "parent reset");
        if (isVerbose) console.log("Check index");
        assertEq(tree.subAccountIndex(r10, _100), 0, "index reset");
        if (isVerbose) console.log("Check name");
        assertEq(ledger.name(_100), "", "name cleared");
        if (isVerbose) console.log("Check hasSubAccount");
        assertFalse(tree.hasSubAccount(_100), "no children");
    }

    function testLedgerRemoveSubAccountGroupIsIdempotent() public {
        vm.startPrank(alice);

        address removed_ = ledger.removeSubAccountGroup(r10, "100");
        address removedAgain_ = ledger.removeSubAccountGroup(r10, "100");

        assertEq(removedAgain_, removed_, "same address");
        assertEq(tree.flags(removed_), 0, "cleared");
        assertEq(tree.subAccountIndex(r10, _100), 0, "index reset");
        assertEq(tree.subAccounts(r10).length, 1, "child count stable");
    }

    function testLedgerRemoveSubAccountGroupAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("groupByAddr");
        (address added_,) = ledger.addSubAccountGroup(r1, relative_, "groupByAddr", false);
        ledger.removeSubAccountGroup(r1, relative_);

        assertEq(tree.parent(added_), address(0), "parent reset");
        assertEq(tree.subAccountIndex(r1, relative_), 0, "index reset");
        assertEq(ledger.name(added_), "", "name cleared");
    }

    function testLedgerRemoveSubAccountNameDelegatesToAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("leafByName");
        (address added_,) = ledger.addSubAccount(r1, "leafByName", false);
        ledger.removeSubAccount(r1, "leafByName");

        assertEq(tree.parent(added_), address(0), "parent reset");
        assertEq(tree.subAccountIndex(r1, relative_), 0, "index reset");
        assertEq(ledger.name(added_), "", "name cleared");
    }

    function testLedgerRemoveSubAccountIsIdempotent() public {
        vm.startPrank(alice);

        (address added_,) = ledger.addSubAccount(r1, "leafToRemove", false);
        address removed_ = ledger.removeSubAccount(r1, "leafToRemove");
        address removedAgain_ = ledger.removeSubAccount(r1, "leafToRemove");

        assertEq(removed_, added_, "removed address");
        assertEq(removedAgain_, removed_, "same address");
        assertEq(tree.flags(removed_), 0, "cleared");
        assertEq(tree.subAccounts(r1).length, 3, "child count stable");
    }

    function testLedgerRemoveSubAccountMissingGroupIsIdempotent() public {
        vm.startPrank(alice);
        address nonExistent = LedgerLib.toAddress(r1, "nope");
        address removed_ = ledger.removeSubAccountGroup(r1, "nope");
        assertEq(removed_, nonExistent, "same address");
        assertEq(tree.flags(removed_), 0, "still absent");
    }

    function testLedgerRemoveSubAccountMissingLeafIsIdempotent() public {
        vm.startPrank(alice);
        address relative_ = LedgerLib.toAddress("missingLeaf");
        address removed_ = ledger.removeSubAccount(r1, "missingLeaf");
        assertEq(removed_, LedgerLib.toAddress(r1, relative_), "same address");
        assertEq(tree.flags(removed_), 0, "still absent");
    }

    function testLedgerRemoveSubAccountWithChildrenReverts() public {
        vm.startPrank(alice);
        (address parentWithChild,) = ledger.addSubAccountGroup(r1, "parentWithChild", false);
        ledger.addSubAccountGroup(parentWithChild, "sub", false);
        vm.expectRevert(abi.encodeWithSelector(ILedger.HasSubAccount.selector, parentWithChild));
        ledger.removeSubAccountGroup(r1, "parentWithChild");
    }

    function testLedgerRemoveSubAccountWithBalanceReverts() public {
        vm.startPrank(alice);
        ledger.mint(r100, alice, 1000);

        vm.expectRevert(abi.encodeWithSelector(ILedger.HasBalance.selector, r100));
        ledger.removeSubAccountGroup(r10, "100");
    }

    function testLedgerRemoveSubAccountInvalidAddresses() public {
        vm.startPrank(alice);
        (address _valid,) = ledger.addSubAccountGroup(r1, "validSub", false);
        address _missing = LedgerLib.toAddress(_valid, "validSub");

        // Zero parent
        vm.expectRevert(ILedger.ZeroAddress.selector);
        ledger.removeSubAccountGroup(address(0), "validSub");

        // Valid parent + absent child => idempotent no-op.
        assertEq(ledger.removeSubAccountGroup(_valid, "validSub"), _missing, "missing sub address");
    }

    function testLedgerRemoveUpdatesSiblingIndices() public {
        vm.startPrank(alice);
        address _s1 = LedgerLib.toAddress("s1");
        address _s3 = LedgerLib.toAddress("s3");

        ledger.addSubAccountGroup(r1, "s1", false);
        ledger.addSubAccountGroup(r1, "s2", false);
        ledger.addSubAccountGroup(r1, "s3", false);

        uint256 before = tree.subAccounts(r1).length;
        ledger.removeSubAccountGroup(r1, "s2");

        address[] memory subs = tree.subAccounts(r1);
        assertEq(subs.length, before - 1, "length");
        assertEq(subs[before - 3], _s1, "first remains s1");
        assertEq(subs[before - 2], _s3, "second becomes s3");

        assertEq(tree.subAccountIndex(r1, _s1), before - 2, "s1 idx");
        assertEq(tree.subAccountIndex(r1, _s3), before - 1, "s3 idx");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parents / roots / hasSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerParents() public view {
        assertEq(tree.root(r10), r1, "root r10");
        assertEq(tree.root(r11), r1, "root r11");
        assertEq(tree.root(r100), r1, "root r100");
        assertEq(tree.root(r101), r1, "root r101");
        assertEq(tree.root(r110), r1, "root r110");
        assertEq(tree.root(r111), r1, "root r111");

        assertEq(tree.parent(r10), r1, "parent r10");
        assertEq(tree.parent(r11), r1, "parent r11");
        assertEq(tree.parent(r100), r10, "parent r100");
        assertEq(tree.parent(r101), r10, "parent r101");
        assertEq(tree.parent(r110), r11, "parent r110");
        assertEq(tree.parent(r111), r11, "parent r111");
    }

    function testLedgerHasSubAccount() public view {
        assertTrue(tree.hasSubAccount(r1), "r1");
        assertTrue(tree.hasSubAccount(r10), "r10");
        assertTrue(tree.hasSubAccount(r11), "r11");
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
        ledger.mint(r1, alice, 1000e18);

        assertEq(ledger.debitBalanceOf(r1, alice), 1000e18, "debitBalanceOf(alice)");
        assertEq(ledger.totalSupply(r1), 1000e18, "totalSupply");

        if (isVerbose) console.log("Mint token 1: Alice");
        ledger.mint(r100, alice, 1000e18);
        assertEq(ledger.debitBalanceOf(r100, alice), 1000e18, "debitBalanceOf(r100, alice)");
        assertEq(ledger.debitBalanceOf(r10, LedgerLib.toAddress("100")), 1000e18, 'debitBalanceOf(r10, "100")');
        assertEq(ledger.debitBalanceOf(r1, LedgerLib.toAddress("10")), 1000e18, 'debitBalanceOf(r1, "10")');
        assertEq(ledger.totalSupply(r1), 2000e18, "totalSupply(r1)");

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, address(router));
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

        ledger.mint(r1, alice, 1000e18);
        ledger.burn(r1, alice, 700e18);

        assertEq(ledger.debitBalanceOf(r1, alice), 300e18, "debitBalanceOf(alice)");
        assertEq(ledger.totalSupply(r1), 300e18, "totalSupply");

        ledger.mint(r100, alice, 1000e18);
        ledger.burn(r100, alice, 600e18);

        assertEq(ledger.debitBalanceOf(r100, alice), 400e18, "debitBalanceOf(r100, alice)");
        assertEq(ledger.debitBalanceOf(r10, LedgerLib.toAddress("100")), 400e18, 'debitBalanceOf(r10, "100")');
        assertEq(ledger.debitBalanceOf(r1, LedgerLib.toAddress("10")), 400e18, 'debitBalanceOf(r1, "10")');
        assertEq(ledger.totalSupply(r1), 700e18, "totalSupply(r1)");
    }

    // TODO: Move to DepositLib
    // function testLedgerReallocate() public {
    //     isVerbose = false;

    //     vm.startPrank(alice);

    //     (address tokenA,) = ledger.createToken("Realloc A", "REA", 18);
    //     (address tokenB,) = ledger.createToken("Realloc B", "REB", 18);
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

        assertEq(externalToken.balanceOf(address(router)), wrapAmount, "router holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledger.debitBalanceOf(address(externalToken), alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledger.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");
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

        assertEq(externalToken.balanceOf(address(router)), wrapAmount - unwrapAmount, "router balance after unwrap");
        assertEq(externalToken.balanceOf(alice), unwrapAmount, "alice external balance after unwrap");
        assertEq(
            ledger.debitBalanceOf(address(externalToken), alice),
            wrapAmount - unwrapAmount,
            "ledger balance after unwrap"
        );
        assertEq(ledger.totalSupply(address(externalToken)), wrapAmount - unwrapAmount, "total supply after unwrap");
    }

    function testLedgerWrapCreditRootReverts() public {
        vm.startPrank(alice);
        (address creditRoot_,) = ledger.createToken("Claim Token", "CLM", 18, true);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, creditRoot_));
        ledger.wrap(creditRoot_, 1);
        vm.stopPrank();
    }

    function testLedgerUnwrapCreditRootReverts() public {
        vm.startPrank(alice);
        (address creditRoot_,) = ledger.createToken("Claim Token", "CLM", 18, true);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, creditRoot_));
        ledger.unwrap(creditRoot_, 1);
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

        assertEq(externalToken.balanceOf(address(router)), wrapAmount, "router holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledger.debitBalanceOf(address(externalToken), alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledger.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");

        vm.expectRevert(abi.encodeWithSelector(ILedger.ZeroAddress.selector));
        ledger.unwrap(address(unlistedToken), alice, address(unlistedToken), alice, 10);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, r1));
        ledger.unwrap(r1, alice, r1, source_, 1);

        uint256 firstUnwrap = 45;
        ledger.unwrap(address(externalToken), alice, address(externalToken), source_, firstUnwrap);
        assertEq(
            externalToken.balanceOf(address(router)), wrapAmount - firstUnwrap, "router balance after partial unwrap"
        );
        assertEq(externalToken.balanceOf(alice), firstUnwrap, "alice external balance after partial unwrap");
        assertEq(
            ledger.debitBalanceOf(address(externalToken), alice),
            wrapAmount - firstUnwrap,
            "ledger balance after partial unwrap"
        );
        assertEq(
            ledger.totalSupply(address(externalToken)), wrapAmount - firstUnwrap, "total supply after partial unwrap"
        );

        uint256 remaining = wrapAmount - firstUnwrap;
        ledger.unwrap(address(externalToken), alice, address(externalToken), source_, remaining);
        assertEq(externalToken.balanceOf(address(router)), 0, "router drained after unwrap");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "alice restored external balance");
        assertEq(ledger.debitBalanceOf(address(externalToken), alice), 0, "ledger balance cleared");
        assertEq(ledger.totalSupply(address(externalToken)), 0, "total supply cleared");
    }

    function testLedgerWrapUsesExplicitSourceNotCaller() public {
        vm.startPrank(bob);

        uint256 wrapAmount = 120;
        externalToken.mint(bob, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);

        address totalParent = address(externalToken);

        // Caller is bob, but source accounting is unallocated.
        ledger.wrap(totalParent, source_, address(externalToken), bob, wrapAmount);

        assertEq(ledger.debitBalanceOf(address(externalToken), bob), wrapAmount, "caller received wrapped balance");
        assertEq(ledger.creditBalanceOf(totalParent, source_), wrapAmount, "source ledger entry credited");

        // Unwrap using same source to close out source ledger entry.
        ledger.unwrap(address(externalToken), bob, totalParent, source_, wrapAmount);

        assertEq(ledger.debitBalanceOf(address(externalToken), bob), 0, "wrapped caller balance cleared");
        assertEq(ledger.creditBalanceOf(totalParent, source_), 0, "source ledger entry cleared");
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

        assertEq(ledger.debitBalanceOf(address(externalToken), alice), 0, "caller has no wrapped ledger balance");
        assertEq(ledger.debitBalanceOf(address(externalToken), bob), wrapAmount, "bob received wrapped balance");

        ledger.unwrap(address(externalToken), bob, address(externalToken), source_, wrapAmount);

        assertEq(ledger.debitBalanceOf(address(externalToken), bob), 0, "bob wrapped balance cleared");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "caller receives external tokens");
        vm.stopPrank();
    }

    function testLedgerWrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, source_, "Source", true);

        uint256 wrapAmount = 2 ether;
        uint256 routerBalanceBefore = address(router).balance;
        ledger.wrap{value: wrapAmount}(native, source_, native, alice, wrapAmount);
        vm.stopPrank();

        assertEq(address(router).balance, routerBalanceBefore + wrapAmount, "router holds native collateral");
        assertEq(ledger.debitBalanceOf(native, alice), wrapAmount, "ledger native balance");
        assertEq(ledger.totalSupply(native), wrapAmount, "native total supply");
    }

    function testLedgerWrapReentrancyGuard() public {
        // Deploy a token that reenters during transferFrom
        ReenterToken reToken = new ReenterToken("ReToken", "RET", 18);
        reToken.setTarget(address(ledger));
        ledger.addExternalToken(address(reToken));
        ledger.addSubAccount(address(reToken), source_, "Source", true);

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
        ledger.addSubAccount(native, source_, "Source", true);

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
        ledger.addSubAccount(native, source_, "Source", true);

        uint256 wrapAmount = 3 ether;
        ledger.wrap{value: wrapAmount}(native, source_, native, alice, wrapAmount);
        uint256 routerBalanceAfterWrap = address(router).balance;
        uint256 aliceBalanceAfterWrap = alice.balance;

        uint256 unwrapAmount = 1 ether;
        ledger.unwrap(native, alice, native, source_, unwrapAmount);
        vm.stopPrank();

        assertEq(address(router).balance, routerBalanceAfterWrap - unwrapAmount, "router native balance");
        assertEq(alice.balance, aliceBalanceAfterWrap + unwrapAmount, "alice native balance");
        assertEq(ledger.debitBalanceOf(native, alice), wrapAmount - unwrapAmount, "ledger native balance");
        assertEq(ledger.totalSupply(native), wrapAmount - unwrapAmount, "native total supply");
    }

    function testLedgerUnwrapNativeRejectsValue() public {
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, source_, "Source", true);

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

        address routerRoot = r1;
        address testLedgerRoot = address(testLedger);

        // Mint → transfer to bob under the same root
        ledger.mint(routerRoot, alice, 1000);
        // elm: fromParent = routerRoot, toParent = routerRoot, to = bob
        ledger.transfer(routerRoot, routerRoot, bob, 700);

        assertEq(ledger.debitBalanceOf(routerRoot, alice), 300, "alice");
        assertEq(ledger.debitBalanceOf(routerRoot, bob), 700, "bob");
        assertEq(ledger.totalSupply(routerRoot), 1000, "supply");

        // Different roots should revert
        vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, routerRoot, testLedgerRoot));
        // attempt: fromParent=routerRoot, toParent=testLedgerRoot (different root)
        ledger.transfer(routerRoot, testLedgerRoot, bob, 100);
    }

    function testLedgerTransferAcrossSiblingBranchesPreservesAncestorBalance() public {
        vm.startPrank(alice);

        ledger.mint(r100, alice, 1000);
        ledger.transfer(r100, r101, bob, 400);

        assertEq(ledger.debitBalanceOf(r100, alice), 600, "r100/alice debited");
        assertEq(ledger.debitBalanceOf(r101, bob), 400, "r101/bob credited");
        assertEq(ledger.debitBalanceOf(r10, LedgerLib.toAddress("100")), 600, 'r10/"100" updated');
        assertEq(ledger.debitBalanceOf(r10, LedgerLib.toAddress("101")), 400, 'r10/"101" updated');
        assertEq(ledger.debitBalanceOf(r1, LedgerLib.toAddress("10")), 1000, 'r1/"10" unchanged above common ancestor');
        assertEq(ledger.totalSupply(r1), 1000, "total supply unchanged");
    }

    function testLedgerTransferRejectsCreditFromParent() public {
        vm.startPrank(alice);
        address sourceParent_ = LedgerLib.toAddress(r1, source_);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, sourceParent_));
        ledger.transfer(sourceParent_, r1, bob, 1);
    }

    function testLedgerTransferInsufficientBalanceReportsDeepUnregisteredLeafContext() public {
        vm.startPrank(alice);

        ledger.mint(r100, alice, 1000);

        vm.expectRevert(
            abi.encodeWithSelector(
                ILedger.InsufficientBalance.selector, r1, r100, LedgerLib.toAddress(r100, alice), 1001
            )
        );
        ledger.transfer(r100, r101, bob, 1001);
    }
}

// contract Bah {
// function testLedgerAddSubAccount() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(router));
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Adding a new valid subAccount");
//     address added = ledger.addSubAccount(r1, "newSubAccount", true, false);
//     assertEq(added, LedgerLib.toAddress(r1, "newSubAccount"), "addSubAccount address");
//     assertEq(tree.parent(added), r1, "Parent should be r1");
//     assertEq(
//         tree.subAccountIndex(added),
//         tree.subAccounts(r1).length,
//         "SubAccount index should match subAccounts length"
//     );
//     assertTrue(tree.hasSubAccount(r1), "r1 should have subAccounts");

//     if (isVerbose) console.log("Adding a subAccount that already exists");
//     setUp();
//     ledger.addSubAccount(r1, "newSubAccount", true, false);

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
//     ledger.addSubAccount(r1, "", true, false);
// }

// function testLedgerRemoveSubAccount() public {
//     bool isVerbose = false;

//     vm.startPrank(alice);

//     // First run the tree visualization tests
//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(router));
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 111");
//         ledger.removeSubAccount(r11, "111");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 110");
//         ledger.removeSubAccount(r11, "110");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 101");
//         ledger.removeSubAccount(r10, "101");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 100");
//         ledger.removeSubAccount(r10, "100");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 11");
//         ledger.removeSubAccount(r1, "11");
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 10");
//         ledger.removeSubAccount(r1, "10");
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
//     ledger.addSubAccount(r1, "leafSubAccount", true, false);
//     ledger.removeSubAccount(r1, "leafSubAccount");
//     assertEq(tree.parent(LedgerLib.toAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
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
//     ledger.removeSubAccount(r1, "nonExistentSubAccount");

//     if (isVerbose) {
//         console.log("Test 3: Remove a subAccount that has subAccounts");
//     }
//     address parentWithSubAccount = ledger.addSubAccount(r1, "parentWithSubAccount", true, false);
//     ledger.addSubAccount(parentWithSubAccount, "subAccountOfParent", true, false);
//     vm.expectRevert(abi.encodeWithSelector(ILedger.HasSubAccount.selector, "parentWithSubAccount"));
//     ledger.removeSubAccount(r1, "parentWithSubAccount");

//     if (isVerbose) {
//         console.log("Test 4: Remove a subAccount that has a balance");
//     }
//     ledger.mint(r100, 1000);
//     vm.expectRevert(abi.encodeWithSelector(ILedger.HasBalance.selector, "100"));
//     ledger.removeSubAccount(r10, "100");

//     if (isVerbose) {
//         console.log("Test 5: Remove a subAccount with invalid addresses");
//     }
//     address validSubAccount = ledger.addSubAccount(r1, "validSubAccount", true, false);

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
//     address subAccount1 = ledger.addSubAccount(r1, "subAccount1", true, false);
//     ledger.addSubAccount(r1, "subAccount2", true, false);
//     address subAccount3 = ledger.addSubAccount(r1, "subAccount3", true, false);

//     uint256 subAccountCount = tree.subAccounts(r1).length;

//     if (isVerbose) {
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     // Remove subAccount2 (middle subAccount)
//     ledger.removeSubAccount(r1, "subAccount2");

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
//         TreeLib.debugTree(ledger, address(router));
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
//     ledger.mint(r100, 1000);
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

//     ledger.mint(r100, 1000);
//     ledger.burn(r100, 600);

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

//     assertEq(tree.parent(r10), r1, "parent(_10)");
//     assertEq(tree.parent(r11), r1, "parent(_11)");
//     assertEq(tree.parent(r100), r10, "parent(_100)");
//     assertEq(tree.parent(r101), r10, "parent(_101)");
//     assertEq(tree.parent(r110), r11, "parent(_110)");
//     assertEq(tree.parent(r111), r11, "parent(_111)");
// }

// function testLedgerHasSubAccount() public view {
//     assertTrue(tree.hasSubAccount(r1), "hasSubAccount(r1)");
//     assertTrue(tree.hasSubAccount(r10), "hasSubAccount(r10)");
//     assertTrue(tree.hasSubAccount(r11), "hasSubAccount(r11)");
//     assertFalse(tree.hasSubAccount(r100), "hasSubAccount(r100)");
//     assertFalse(tree.hasSubAccount(r101), "hasSubAccount(r101)");
//     assertFalse(tree.hasSubAccount(r110), "hasSubAccount(r110)");
//     assertFalse(tree.hasSubAccount(r111), "hasSubAccount(r111)");
// }

// function testLedgerTransfer() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledger, address(router));
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

//     ledger.mint(r1, 1000);
//     ledger.approve(r1, r1, bob, 100);

//     vm.startPrank(bob);

//     ledger.transferFrom(r1, alice, r1, r10, _100, 100);

//     assertEq(ledger.balanceOf(r1, alice), 900, "balanceOf(_1, alice)");
//     assertEq(ledger.balanceOf(r1, bob), 0, "balanceOf(_1, bob)");
//     assertEq(ledger.balanceOf(r10, _100), 100, "balanceOf(_10, _100)");
//     assertEq(ledger.totalSupply(_1), 1000, "totalSupply(_1)");
// }
// }
