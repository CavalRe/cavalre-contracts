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

    constructor(uint8 decimals_) Ledger(decimals_, "Ethereum", "ETH") {}

    // Keep command registry so Router can “register” the module (if you use it)
    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](42);
        // From Ledger
        _selectors[n++] = bytes4(keccak256("initializeTestLedger()"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addNativeToken()"));
        _selectors[n++] = bytes4(keccak256("addExternalToken(address)"));
        _selectors[n++] = bytes4(keccak256("createToken(string,string,uint8)"));
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
        _selectors[n++] = bytes4(keccak256("root(address)"));
        _selectors[n++] = bytes4(keccak256("parent(address)"));
        _selectors[n++] = bytes4(keccak256("flags(address)"));
        _selectors[n++] = bytes4(keccak256("wrapper(address)"));
        _selectors[n++] = bytes4(keccak256("isGroup(uint256)"));
        _selectors[n++] = bytes4(keccak256("isCredit(uint256)"));
        _selectors[n++] = bytes4(keccak256("effectiveFlags(address,address)"));
        _selectors[n++] = bytes4(keccak256("isInternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isNative(uint256)"));
        _selectors[n++] = bytes4(keccak256("isRegistered(uint256)"));
        _selectors[n++] = bytes4(keccak256("isExternal(uint256)"));
        _selectors[n++] = bytes4(keccak256("isRoot(uint256)"));
        _selectors[n++] = bytes4(keccak256("subAccounts(address)"));
        _selectors[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _selectors[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _selectors[n++] = bytes4(keccak256("totalSupply(address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,address,address,address,uint256)"));
        // Extra test-exposing commands
        _selectors[n++] = bytes4(keccak256("mint(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("burn(address,address,uint256)"));
        // TODO: Move to DepositLib
        // _selectors[n++] = bytes4(keccak256("reallocate(address,address,uint256)"));
        if (n != 42) revert InvalidCommandsLength(n);
    }

    function initializeTestLedger() external initializer {
        enforceIsOwner();
        initializeLedger_unchained(LEDGER_NAME, LEDGER_SYMBOL);
    }

    function mint(address toParent_, address to_, uint256 amount_) external {
        address _token = LedgerLib.root(toParent_);
        LedgerLib.transfer(_token, LedgerLib.SOURCE_ADDRESS, toParent_, to_, amount_);
        uint256 _tokenFlags = LedgerLib.flags(_token);
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
        LedgerLib.transfer(fromParent_, from_, _token, LedgerLib.SOURCE_ADDRESS, amount_);
        uint256 _tokenFlags = LedgerLib.flags(_token);
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

    Router router;
    TestLedger ledger;

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

    function setUp() public {
        isVerbose = false;

        vm.startPrank(alice);
        if (isVerbose) console.log("Deploying TestLedger");
        ledger = new TestLedger(18);
        if (isVerbose) console.log("Deploying Router");
        router = new Router(alice);
        if (isVerbose) console.log("Adding Ledger module to Router");
        router.addModule(address(ledger));
        ledger = TestLedger(payable(router));

        if (isVerbose) console.log("Initializing Test Ledger");
        ledger.initializeTestLedger();

        // Add a standalone ledger tree for misc checks
        // testLedger = LedgerLib.toAddress("Test Ledger");
        if (isVerbose) console.log("Creating Test Ledger token");
        (testLedger,) = ledger.createToken("Test Ledger", "TL", 18);
        ledger.addSubAccount(testLedger, LedgerLib.SOURCE_ADDRESS, "Source", true);
        if (isVerbose) console.log("Adding sub-groups to Test Ledger");
        (address testLedger_1_,) = ledger.addSubAccountGroup(testLedger, "1", false);
        (address testLedger_10_,) = ledger.addSubAccountGroup(testLedger_1_, "10", false);
        ledger.addSubAccountGroup(testLedger_10_, "100", false);

        // Add token r1 and its sub-groups
        if (isVerbose) console.log("Creating root token '1'");
        (r1,) = ledger.createToken("1", "1", 18);
        ledger.addSubAccount(r1, LedgerLib.SOURCE_ADDRESS, "Source", true);
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
        ledger.addSubAccount(address(externalToken), LedgerLib.SOURCE_ADDRESS, "Source", true);
        externalWrapper = ledger.wrapper(address(externalToken));

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
        if (isVerbose) TreeLib.debugTree(ledger, address(router));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledger, testLedger);
        if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledger, r1);
        if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledger, address(externalToken));
        if (isVerbose) console.log("--------------------");
        // Visual (optional): TreeLib.debugTree(ledger, r1);

        vm.startPrank(alice);
        vm.expectRevert(InvalidInitialization.selector);
        ledger.initializeTestLedger(); // re-init should revert

        // Tree shape sanity
        assertEq(ledger.name(address(router)), "Ledger", "ledger name");
        assertEq(ledger.symbol(address(router)), "LEDGER", "ledger symbol");
        assertEq(ledger.subAccounts(testLedger).length, 2, "Subaccounts (testLedger)");
        assertEq(ledger.subAccounts(r1).length, 3, "Subaccounts (r1)");
        assertEq(ledger.subAccounts(r10).length, 2, "Subaccounts (r10)");
        assertEq(ledger.subAccounts(r11).length, 2, "Subaccounts (r11)");

        assertEq(ledger.subAccountIndex(r1, _10), 2, "idx(r10)");
        assertEq(ledger.subAccountIndex(r1, _11), 3, "idx(r11)");
        assertEq(ledger.subAccountIndex(r10, _100), 1, "idx(r100)");
        assertEq(ledger.subAccountIndex(r10, _101), 2, "idx(r101)");
        assertEq(ledger.subAccountIndex(r11, _110), 1, "idx(r110)");
        assertEq(ledger.subAccountIndex(r11, _111), 2, "idx(r111)");
    }

    function testNativeWrapperNotCreatedDuringInit() public view {
        assertEq(ledger.wrapper(native), address(0), "wrapper unset");
        assertEq(ledger.root(native), address(0), "root unset");
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

        assertEq(ledger.wrapper(native), wrapper, "wrapper set");
        assertEq(wrapperAgain, wrapper, "wrapper idempotent");
        assertEq(ledger.root(native), native, "root native");
        assertEq(ledger.name(native), "Ethereum", "name");
        assertEq(ledger.symbol(native), "ETH", "symbol");
        assertEq(ledger.decimals(native), 18, "decimals");
        assertTrue((ledger.flags(native) & LedgerLib.FLAG_IS_NATIVE) != 0, "native flag set");
        assertTrue(ledger.wrapper(native) != address(0), "wrapper set");
        assertEq(ledger.flags(native) & LedgerLib.FLAG_IS_INTERNAL, 0, "native not internal");
        assertFalse(LedgerLib.isExternal(ledger.flags(native)), "native not external");
    }

    function testLedgerCreateWrapperCanonicalRootIsIdempotent() public {
        vm.startPrank(alice);
        (address wrapper_,) = ledger.createWrapper(address(ledger));
        (address wrapperAgain_,) = ledger.createWrapper(address(ledger));
        vm.stopPrank();

        assertEq(wrapperAgain_, wrapper_, "same wrapper");
        assertEq(ledger.wrapper(address(ledger)), wrapper_, "wrapper stored");
        assertEq(ledger.root(address(ledger)), address(ledger), "root unchanged");
    }

    function testLedgerCreateWrapperInternalRootIsIdempotent() public {
        vm.startPrank(alice);
        (address wrapper_,) = ledger.createWrapper(r1);
        (address wrapperAgain_,) = ledger.createWrapper(r1);
        vm.stopPrank();

        assertEq(wrapper_, r1, "internal self wrapper");
        assertEq(wrapperAgain_, wrapper_, "same wrapper");
    }

    function testLedgerCreateTokenDoesNotRegisterUnderRoot() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createToken("Neutral Token", "NT", 18);
        vm.stopPrank();

        address rootAccount_ = LedgerLib.toAddress(address(ledger), token_);
        assertEq(ledger.flags(rootAccount_), 0, "not auto-registered under root");
    }

    function testLedgerCreateTokenIsIdempotent() public {
        vm.startPrank(alice);
        (address token_,) = ledger.createToken("Neutral Token", "NT", 18);
        (address tokenAgain_,) = ledger.createToken("Neutral Token", "NT", 18);
        vm.stopPrank();

        assertEq(tokenAgain_, token_, "same token");
        assertEq(ledger.root(token_), token_, "root registered");
        assertEq(ledger.wrapper(token_), token_, "self wrapped");
    }

    function testLedgerAddExternalTokenAndCreateWrapperAreIdempotent() public {
        vm.startPrank(alice);
        ledger.addExternalToken(address(unlistedToken));
        (address wrapper_,) = ledger.createWrapper(address(unlistedToken));
        ledger.addExternalToken(address(unlistedToken));
        (address wrapperAgain_,) = ledger.createWrapper(address(unlistedToken));
        vm.stopPrank();

        assertEq(ledger.root(address(unlistedToken)), address(unlistedToken), "root registered");
        assertEq(wrapperAgain_, wrapper_, "wrapper idempotent");
        assertEq(ledger.wrapper(address(unlistedToken)), wrapper_, "wrapper unchanged");
    }

    function testLedgerRootFlagsByTokenType() public view {
        uint256 internalFlags = ledger.flags(r1);
        assertTrue((internalFlags & LedgerLib.FLAG_IS_INTERNAL) != 0, "internal token flag set");
        assertTrue(ledger.wrapper(r1) != address(0), "internal wrapper set");
        assertEq(internalFlags & LedgerLib.FLAG_IS_NATIVE, 0, "internal token not native");
        assertFalse(LedgerLib.isExternal(internalFlags), "internal token not external");
        assertTrue(ledger.isRoot(internalFlags), "internal root");

        uint256 externalFlags = ledger.flags(address(externalToken));
        assertEq(externalFlags & LedgerLib.FLAG_IS_INTERNAL, 0, "external token not internal");
        assertTrue(ledger.wrapper(address(externalToken)) != address(0), "external wrapper set");
        assertTrue(LedgerLib.isExternal(externalFlags), "external flag set");
        assertEq(externalFlags & LedgerLib.FLAG_IS_NATIVE, 0, "external token not native");
        assertTrue(ledger.isRoot(externalFlags), "external root");
        assertFalse(ledger.isRoot(ledger.flags(r10)), "child not root");
    }

    function testLedgerEffectiveFlags() public {
        vm.startPrank(alice);
        (address creditParent_,) = ledger.addSubAccountGroup(r1, "creditParent", true);
        (address debitAddr_, uint256 debitFlags_) = ledger.effectiveFlags(r1, LedgerLib.toAddress("missingDebit"));

        assertEq(debitAddr_, LedgerLib.toAddress(r1, LedgerLib.toAddress("missingDebit")), "absolute address");
        assertFalse(ledger.isCredit(debitFlags_), "inherits debit parent");
        assertEq(LedgerLib.parent(debitFlags_), r1, "inherits parent");
        ledger.addSubAccount(r1, LedgerLib.SOURCE_ADDRESS, "Source", true);
        (, uint256 sourceFlags_) = ledger.effectiveFlags(r1, LedgerLib.SOURCE_ADDRESS);
        assertTrue(ledger.isCredit(sourceFlags_), "registered credit leaf");
        (, uint256 missingCreditFlags_) = ledger.effectiveFlags(creditParent_, LedgerLib.toAddress("missingCredit"));
        assertTrue(ledger.isCredit(missingCreditFlags_), "inherits credit parent");
    }

    function testPackedParentAndWrapperMapping() public view {
        assertEq(address(uint160(ledger.flags(r10) >> 96)), r1, "packed parent r10");
        assertEq(address(uint160(ledger.flags(r100) >> 96)), r10, "packed parent r100");
        assertEq(address(uint160(ledger.flags(r1) >> 96)), address(0), "packed parent root");

        assertEq(ledger.wrapper(r10), address(0), "non-root wrapper unset");
        assertEq(ledger.wrapper(r1), r1, "internal root wrapper");
        assertEq(ledger.wrapper(address(externalToken)), externalWrapper, "external root wrapper");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AddSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerAddSubAccountGroup() public {
        vm.startPrank(alice);

        // Add a fresh sub under r1
        (address added,) = ledger.addSubAccountGroup(r1, "newSubAccount", false);
        assertEq(added, LedgerLib.toAddress(r1, "newSubAccount"), "address mismatch");
        assertEq(ledger.parent(added), r1, "parent mismatch");
        assertEq(
            ledger.subAccountIndex(r1, LedgerLib.toAddress("newSubAccount")),
            ledger.subAccounts(r1).length,
            "index should equal #subs"
        );
        assertTrue(ledger.hasSubAccount(r1), "r1 should have subs");

        // Re-adding the same name with same flags should idempotently return same addr or revert by your rules.
        // Your lib currently treats “same name + same flags” as OK (returns existing). Verify:
        (address idempotent,) = ledger.addSubAccountGroup(r1, "newSubAccount", false);
        assertEq(idempotent, added, "expected same sub account address");
    }

    function testLedgerAddSubAccountGroupAddressFormIsIdempotent() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("groupByAddr");
        (address added_, uint256 flags_) = ledger.addSubAccountGroup(r1, relative_, "groupByAddr", false);
        (address addedAgain_, uint256 flagsAgain_) = ledger.addSubAccountGroup(r1, relative_, "groupByAddr", false);

        assertEq(addedAgain_, added_, "same address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(ledger.subAccounts(r1)[ledger.subAccounts(r1).length - 1], relative_, "no duplicate child");
    }

    function testLedgerAddSubAccountNameDelegatesToAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("leafSubAccount");
        (address added_,) = ledger.addSubAccount(r1, "leafSubAccount", false);

        assertEq(added_, LedgerLib.toAddress(r1, relative_), "address mismatch");
        assertEq(ledger.subAccounts(r1)[ledger.subAccounts(r1).length - 1], relative_, "relative addr stored");
    }

    function testLedgerAddSubAccountIsIdempotent() public {
        vm.startPrank(alice);

        (address added_, uint256 flags_) = ledger.addSubAccount(r1, "leafSubAccount", false);
        (address addedAgain_, uint256 flagsAgain_) = ledger.addSubAccount(r1, "leafSubAccount", false);

        assertEq(addedAgain_, added_, "same address");
        assertEq(flagsAgain_, flags_, "same flags");
        assertEq(
            ledger.subAccounts(r1)[ledger.subAccounts(r1).length - 1],
            LedgerLib.toAddress("leafSubAccount"),
            "no duplicate child"
        );
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
        assertEq(ledger.parent(_100), address(0), "parent reset");
        if (isVerbose) console.log("Check index");
        assertEq(ledger.subAccountIndex(r10, _100), 0, "index reset");
        if (isVerbose) console.log("Check name");
        assertEq(ledger.name(_100), "", "name cleared");
        if (isVerbose) console.log("Check hasSubAccount");
        assertFalse(ledger.hasSubAccount(_100), "no children");
    }

    function testLedgerRemoveSubAccountGroupIsIdempotent() public {
        vm.startPrank(alice);

        address removed_ = ledger.removeSubAccountGroup(r10, "100");
        address removedAgain_ = ledger.removeSubAccountGroup(r10, "100");

        assertEq(removedAgain_, removed_, "same address");
        assertEq(ledger.flags(removed_), 0, "cleared");
        assertEq(ledger.subAccountIndex(r10, _100), 0, "index reset");
    }

    function testLedgerRemoveSubAccountGroupAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("groupByAddr");
        (address added_,) = ledger.addSubAccountGroup(r1, relative_, "groupByAddr", false);
        ledger.removeSubAccountGroup(r1, relative_);

        assertEq(ledger.parent(added_), address(0), "parent reset");
        assertEq(ledger.subAccountIndex(r1, relative_), 0, "index reset");
        assertEq(ledger.name(added_), "", "name cleared");
    }

    function testLedgerRemoveSubAccountNameDelegatesToAddressForm() public {
        vm.startPrank(alice);

        address relative_ = LedgerLib.toAddress("leafByName");
        (address added_,) = ledger.addSubAccount(r1, "leafByName", false);
        ledger.removeSubAccount(r1, "leafByName");

        assertEq(ledger.parent(added_), address(0), "parent reset");
        assertEq(ledger.subAccountIndex(r1, relative_), 0, "index reset");
        assertEq(ledger.name(added_), "", "name cleared");
    }

    function testLedgerRemoveSubAccountIsIdempotent() public {
        vm.startPrank(alice);

        (address added_,) = ledger.addSubAccount(r1, "leafToRemove", false);
        address removed_ = ledger.removeSubAccount(r1, "leafToRemove");
        address removedAgain_ = ledger.removeSubAccount(r1, "leafToRemove");

        assertEq(removed_, added_, "removed address");
        assertEq(removedAgain_, removed_, "same address");
        assertEq(ledger.flags(removed_), 0, "cleared");
    }

    function testLedgerRemoveSubAccountMissingGroupIsIdempotent() public {
        vm.startPrank(alice);
        address nonExistent = LedgerLib.toAddress(r1, "nope");
        address removed_ = ledger.removeSubAccountGroup(r1, "nope");
        assertEq(removed_, nonExistent, "same address");
        assertEq(ledger.flags(removed_), 0, "still absent");
    }

    function testLedgerRemoveSubAccountMissingLeafIsIdempotent() public {
        vm.startPrank(alice);
        address relative_ = LedgerLib.toAddress("missingLeaf");
        address removed_ = ledger.removeSubAccount(r1, "missingLeaf");
        assertEq(removed_, LedgerLib.toAddress(r1, relative_), "same address");
        assertEq(ledger.flags(removed_), 0, "still absent");
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

        uint256 before = ledger.subAccounts(r1).length;
        ledger.removeSubAccountGroup(r1, "s2");

        address[] memory subs = ledger.subAccounts(r1);
        assertEq(subs.length, before - 1, "length");
        assertEq(subs[before - 3], _s1, "first remains s1");
        assertEq(subs[before - 2], _s3, "second becomes s3");

        assertEq(ledger.subAccountIndex(r1, _s1), before - 2, "s1 idx");
        assertEq(ledger.subAccountIndex(r1, _s3), before - 1, "s3 idx");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parents / roots / hasSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerParents() public view {
        assertEq(ledger.root(r10), r1, "root r10");
        assertEq(ledger.root(r11), r1, "root r11");
        assertEq(ledger.root(r100), r1, "root r100");
        assertEq(ledger.root(r101), r1, "root r101");
        assertEq(ledger.root(r110), r1, "root r110");
        assertEq(ledger.root(r111), r1, "root r111");

        assertEq(ledger.parent(r10), r1, "parent r10");
        assertEq(ledger.parent(r11), r1, "parent r11");
        assertEq(ledger.parent(r100), r10, "parent r100");
        assertEq(ledger.parent(r101), r10, "parent r101");
        assertEq(ledger.parent(r110), r11, "parent r110");
        assertEq(ledger.parent(r111), r11, "parent r111");
    }

    function testLedgerHasSubAccount() public view {
        assertTrue(ledger.hasSubAccount(r1), "r1");
        assertTrue(ledger.hasSubAccount(r10), "r10");
        assertTrue(ledger.hasSubAccount(r11), "r11");
        assertFalse(ledger.hasSubAccount(r100), "r100");
        assertFalse(ledger.hasSubAccount(r101), "r101");
        assertFalse(ledger.hasSubAccount(r110), "r110");
        assertFalse(ledger.hasSubAccount(r111), "r111");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mint / Burn
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerMint() public {
        isVerbose = true;

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint r1: Alice");
        ledger.mint(r1, alice, 1000e18);

        assertEq(ledger.balanceOf(r1, alice), 1000e18, "balanceOf(alice)");
        assertEq(ledger.totalSupply(r1), 1000e18, "totalSupply");

        if (isVerbose) console.log("Mint token 1: Alice");
        ledger.mint(r100, alice, 1000e18);
        assertEq(ledger.balanceOf(r100, alice), 1000e18, "balanceOf(r100, alice)");
        assertEq(ledger.balanceOf(r10, "100"), 1000e18, 'balanceOf(r10, "100")');
        assertEq(ledger.balanceOf(r1, "10"), 1000e18, 'balanceOf(r1, "10")');
        assertEq(ledger.totalSupply(r1), 2000e18, "totalSupply(r1)");

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, address(router));
        // if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, testLedger);
        // if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledger, r1);
        if (isVerbose) console.log("--------------------");
        // if (isVerbose) TreeLib.debugTree(ledger, address(externalToken));
        // if (isVerbose) console.log("--------------------");
    }

    function testLedgerBurn() public {
        vm.startPrank(alice);

        ledger.mint(r1, alice, 1000e18);
        ledger.burn(r1, alice, 700e18);

        assertEq(ledger.balanceOf(r1, alice), 300e18, "balanceOf(alice)");
        assertEq(ledger.totalSupply(r1), 300e18, "totalSupply");

        ledger.mint(r100, alice, 1000e18);
        ledger.burn(r100, alice, 600e18);

        assertEq(ledger.balanceOf(r100, alice), 400e18, "balanceOf(r100, alice)");
        assertEq(ledger.balanceOf(r10, "100"), 400e18, 'balanceOf(r10, "100")');
        assertEq(ledger.balanceOf(r1, "10"), 400e18, 'balanceOf(r1, "10")');
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

        uint256 wrapAmount = 120;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        if (isVerbose) console.log("Wrapping external token");
        ledger.wrap(address(externalToken), LedgerLib.SOURCE_ADDRESS, address(externalToken), alice, wrapAmount);

        assertEq(externalToken.balanceOf(address(router)), wrapAmount, "router holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledger.balanceOf(address(externalToken), alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledger.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");

        vm.expectRevert(abi.encodeWithSelector(ILedger.ZeroAddress.selector));
        ledger.unwrap(address(unlistedToken), alice, address(unlistedToken), alice, 10);

        uint256 firstUnwrap = 45;
        ledger.unwrap(address(externalToken), alice, address(externalToken), LedgerLib.SOURCE_ADDRESS, firstUnwrap);
        assertEq(
            externalToken.balanceOf(address(router)), wrapAmount - firstUnwrap, "router balance after partial unwrap"
        );
        assertEq(externalToken.balanceOf(alice), firstUnwrap, "alice external balance after partial unwrap");
        assertEq(
            ledger.balanceOf(address(externalToken), alice),
            wrapAmount - firstUnwrap,
            "ledger balance after partial unwrap"
        );
        assertEq(
            ledger.totalSupply(address(externalToken)), wrapAmount - firstUnwrap, "total supply after partial unwrap"
        );

        uint256 remaining = wrapAmount - firstUnwrap;
        ledger.unwrap(address(externalToken), alice, address(externalToken), LedgerLib.SOURCE_ADDRESS, remaining);
        assertEq(externalToken.balanceOf(address(router)), 0, "router drained after unwrap");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "alice restored external balance");
        assertEq(ledger.balanceOf(address(externalToken), alice), 0, "ledger balance cleared");
        assertEq(ledger.totalSupply(address(externalToken)), 0, "total supply cleared");
    }

    function testLedgerWrapUsesExplicitSourceNotCaller() public {
        vm.startPrank(bob);

        uint256 wrapAmount = 120;
        externalToken.mint(bob, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);

        address totalParent = address(externalToken);

        // Caller is bob, but source accounting is unallocated.
        ledger.wrap(totalParent, LedgerLib.SOURCE_ADDRESS, address(externalToken), bob, wrapAmount);

        assertEq(ledger.balanceOf(address(externalToken), bob), wrapAmount, "caller received wrapped balance");
        assertEq(ledger.balanceOf(totalParent, LedgerLib.SOURCE_ADDRESS), wrapAmount, "source ledger entry credited");

        // Unwrap using same source to close out source ledger entry.
        ledger.unwrap(address(externalToken), bob, totalParent, LedgerLib.SOURCE_ADDRESS, wrapAmount);

        assertEq(ledger.balanceOf(address(externalToken), bob), 0, "wrapped caller balance cleared");
        assertEq(ledger.balanceOf(totalParent, LedgerLib.SOURCE_ADDRESS), 0, "source ledger entry cleared");
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
        ledger.wrap(totalParent, LedgerLib.SOURCE_ADDRESS, address(externalToken), alice, wrapAmount);

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
        ledger.wrap(address(externalToken), LedgerLib.SOURCE_ADDRESS, address(externalToken), alice, wrapAmount);

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, alice, true));
        ledger.unwrap(address(externalToken), alice, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, LedgerLib.SOURCE_ADDRESS, "Source", true);

        uint256 wrapAmount = 2 ether;
        uint256 routerBalanceBefore = address(router).balance;
        ledger.wrap{value: wrapAmount}(native, LedgerLib.SOURCE_ADDRESS, native, alice, wrapAmount);
        vm.stopPrank();

        assertEq(address(router).balance, routerBalanceBefore + wrapAmount, "router holds native collateral");
        assertEq(ledger.balanceOf(native, alice), wrapAmount, "ledger native balance");
        assertEq(ledger.totalSupply(native), wrapAmount, "native total supply");
    }

    function testLedgerWrapReentrancyGuard() public {
        // Deploy a token that reenters during transferFrom
        ReenterToken reToken = new ReenterToken("ReToken", "RET", 18);
        reToken.setTarget(address(ledger));
        ledger.addExternalToken(address(reToken));
        ledger.addSubAccount(address(reToken), LedgerLib.SOURCE_ADDRESS, "Source", true);

        // Fund Alice and approve the ledger
        vm.startPrank(alice);
        reToken.mint(alice, 10);
        reToken.approve(address(ledger), 10);
        reToken.setReenter(true);
        vm.expectRevert(ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector);
        ledger.wrap(address(reToken), LedgerLib.SOURCE_ADDRESS, address(reToken), alice, 5);
        vm.stopPrank();
    }

    function testLedgerWrapNativeIncorrectValue() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, LedgerLib.SOURCE_ADDRESS, "Source", true);

        uint256 wrapAmount = 2 ether;
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, wrapAmount - 1, wrapAmount));
        ledger.wrap{value: wrapAmount - 1}(native, LedgerLib.SOURCE_ADDRESS, native, alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapNonNativeRejectsValue() public {
        vm.startPrank(alice);
        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.wrap{value: 1}(address(externalToken), LedgerLib.SOURCE_ADDRESS, address(externalToken), alice, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, LedgerLib.SOURCE_ADDRESS, "Source", true);

        uint256 wrapAmount = 3 ether;
        ledger.wrap{value: wrapAmount}(native, LedgerLib.SOURCE_ADDRESS, native, alice, wrapAmount);
        uint256 routerBalanceAfterWrap = address(router).balance;
        uint256 aliceBalanceAfterWrap = alice.balance;

        uint256 unwrapAmount = 1 ether;
        ledger.unwrap(native, alice, native, LedgerLib.SOURCE_ADDRESS, unwrapAmount);
        vm.stopPrank();

        assertEq(address(router).balance, routerBalanceAfterWrap - unwrapAmount, "router native balance");
        assertEq(alice.balance, aliceBalanceAfterWrap + unwrapAmount, "alice native balance");
        assertEq(ledger.balanceOf(native, alice), wrapAmount - unwrapAmount, "ledger native balance");
        assertEq(ledger.totalSupply(native), wrapAmount - unwrapAmount, "native total supply");
    }

    function testLedgerUnwrapNativeRejectsValue() public {
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        ledger.addNativeToken();
        ledger.addSubAccount(native, LedgerLib.SOURCE_ADDRESS, "Source", true);

        uint256 wrapAmount = 1 ether;
        ledger.wrap{value: wrapAmount}(native, LedgerLib.SOURCE_ADDRESS, native, alice, wrapAmount);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledger.unwrap{value: 1}(native, alice, native, alice, 0.5 ether);
        vm.stopPrank();
    }

    function testLedgerUnwrapNonNativeRejectsValue() public {
        vm.startPrank(alice);
        uint256 wrapAmount = 50;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledger), wrapAmount);
        ledger.wrap(address(externalToken), LedgerLib.SOURCE_ADDRESS, address(externalToken), alice, wrapAmount);
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

        assertEq(ledger.balanceOf(routerRoot, alice), 300, "alice");
        assertEq(ledger.balanceOf(routerRoot, bob), 700, "bob");
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

        assertEq(ledger.balanceOf(r100, alice), 600, "r100/alice debited");
        assertEq(ledger.balanceOf(r101, bob), 400, "r101/bob credited");
        assertEq(ledger.balanceOf(r10, "100"), 600, 'r10/"100" updated');
        assertEq(ledger.balanceOf(r10, "101"), 400, 'r10/"101" updated');
        assertEq(ledger.balanceOf(r1, "10"), 1000, 'r1/"10" unchanged above common ancestor');
        assertEq(ledger.totalSupply(r1), 1000, "total supply unchanged");
    }

    function testLedgerTransferRejectsCreditFromParent() public {
        vm.startPrank(alice);
        address sourceParent_ = LedgerLib.toAddress(r1, LedgerLib.SOURCE_ADDRESS);

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
//     assertEq(ledger.parent(added), r1, "Parent should be r1");
//     assertEq(
//         ledger.subAccountIndex(added),
//         ledger.subAccounts(r1).length,
//         "SubAccount index should match subAccounts length"
//     );
//     assertTrue(ledger.hasSubAccount(r1), "r1 should have subAccounts");

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
//     assertEq(ledger.parent(LedgerLib.toAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
//     assertEq(
//         ledger.subAccountIndex(LedgerLib.toAddress(r1, "leafSubAccount")), 0, "SubAccount index should be reset"
//     );
//     assertEq(ledger.name(LedgerLib.toAddress(r1, "leafSubAccount")), "", "Name should be cleared");
//     assertFalse(ledger.hasSubAccount(LedgerLib.toAddress(r1, "leafSubAccount")), "Should not have subAccounts");

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

//     uint256 subAccountCount = ledger.subAccounts(r1).length;

//     if (isVerbose) {
//         TreeLib.debugTree(ledger, r1);
//         console.log("--------------------");
//     }

//     // Remove subAccount2 (middle subAccount)
//     ledger.removeSubAccount(r1, "subAccount2");

//     // Verify subAccounts array is updated correctly
//     address[] memory subAccounts = ledger.subAccounts(r1);
//     assertEq(subAccounts.length, subAccountCount - 1, "Incorrect number of subAccounts after removal");
//     assertEq(subAccounts[subAccountCount - 3], subAccount1, "First subAccount should be subAccount1");
//     assertEq(subAccounts[subAccountCount - 2], subAccount3, "Second subAccount should be subAccount3");

//     if (isVerbose) console.log("Verify subAccount indices are updated");
//     assertEq(
//         ledger.subAccountIndex(LedgerLib.toAddress(r1, "subAccount1")),
//         subAccountCount - 2,
//         "subAccount1 index incorrect"
//     );
//     if (isVerbose) {
//         console.log("Display subaccounts");
//         for (uint256 i = 0; i < subAccounts.length; i++) {
//             console.log(
//                 "SubAccount", ledger.name(subAccounts[i]), subAccounts[i], ledger.subAccountIndex(subAccounts[i])
//             );
//         }
//     }
//     assertEq(
//         ledger.subAccountIndex(LedgerLib.toAddress(r1, "subAccount3")),
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
//     assertEq(ledger.root(r10), r1, "root(_10)");
//     assertEq(ledger.root(r11), r1, "root(_11)");
//     assertEq(ledger.root(r100), r1, "root(_100)");
//     assertEq(ledger.root(r101), r1, "root(_101)");
//     assertEq(ledger.root(r110), r1, "root(_110)");
//     assertEq(ledger.root(r111), r1, "root(_111)");

//     assertEq(ledger.parent(r10), r1, "parent(_10)");
//     assertEq(ledger.parent(r11), r1, "parent(_11)");
//     assertEq(ledger.parent(r100), r10, "parent(_100)");
//     assertEq(ledger.parent(r101), r10, "parent(_101)");
//     assertEq(ledger.parent(r110), r11, "parent(_110)");
//     assertEq(ledger.parent(r111), r11, "parent(_111)");
// }

// function testLedgerHasSubAccount() public view {
//     assertTrue(ledger.hasSubAccount(r1), "hasSubAccount(r1)");
//     assertTrue(ledger.hasSubAccount(r10), "hasSubAccount(r10)");
//     assertTrue(ledger.hasSubAccount(r11), "hasSubAccount(r11)");
//     assertFalse(ledger.hasSubAccount(r100), "hasSubAccount(r100)");
//     assertFalse(ledger.hasSubAccount(r101), "hasSubAccount(r101)");
//     assertFalse(ledger.hasSubAccount(r110), "hasSubAccount(r110)");
//     assertFalse(ledger.hasSubAccount(r111), "hasSubAccount(r111)");
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
