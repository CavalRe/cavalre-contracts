// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ─────────────────────────────────────────────────────────────────────────────
// Import split layout (interfaces + lib + module + infra)
// Adjust paths if your repo layout differs.
// ─────────────────────────────────────────────────────────────────────────────
import {ILedger} from "../../interfaces/ILedger.sol";
import {LedgerLib} from "../../libraries/LedgerLib.sol";
import {Ledger} from "../../modules/Ledger.sol";
import {Module} from "../../modules/Module.sol";
import {Router} from "../../modules/Router.sol";
import {TreeLib} from "../../libraries/TreeLib.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Test, console} from "forge-std/src/Test.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Test module that exposes LedgerLib via external funcs for Router delegatecall
// ─────────────────────────────────────────────────────────────────────────────
contract TestLedger is Ledger {
    constructor(uint8 decimals_) Ledger(decimals_) {}

    // Keep command registry so Router can “register” the module (if you use it)
    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](35);
        // From Ledger
        _selectors[n++] = bytes4(keccak256("initializeTestLedger(string)"));
        _selectors[n++] = bytes4(keccak256("addSubAccountGroup(address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addSubAccount(address,address,string,bool)"));
        _selectors[n++] = bytes4(keccak256("addLedger(address,address,string,string,uint8,bool,bool)"));
        _selectors[n++] = bytes4(keccak256("createWrappedToken(address)"));
        _selectors[n++] = bytes4(keccak256("createInternalToken(string,string,uint8,bool)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccount(address,address)"));
        _selectors[n++] = bytes4(keccak256("removeSubAccountGroup(address,string)"));
        _selectors[n++] = bytes4(keccak256("name(address)"));
        _selectors[n++] = bytes4(keccak256("symbol(address)"));
        _selectors[n++] = bytes4(keccak256("decimals(address)"));
        _selectors[n++] = bytes4(keccak256("root(address)"));
        _selectors[n++] = bytes4(keccak256("parent(address)"));
        _selectors[n++] = bytes4(keccak256("flags(address)"));
        _selectors[n++] = bytes4(keccak256("wrapper(address)"));
        _selectors[n++] = bytes4(keccak256("isGroup(address)"));
        _selectors[n++] = bytes4(keccak256("isCredit(address)"));
        _selectors[n++] = bytes4(keccak256("isInternal(address)"));
        _selectors[n++] = bytes4(keccak256("subAccounts(address)"));
        _selectors[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _selectors[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _selectors[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _selectors[n++] = bytes4(keccak256("totalSupply(address)"));
        _selectors[n++] = bytes4(keccak256("reserveAddress(address)"));
        _selectors[n++] = bytes4(keccak256("scaleAddress(address)"));
        _selectors[n++] = bytes4(keccak256("reserve(address)"));
        _selectors[n++] = bytes4(keccak256("scale(address)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256,bool)"));
        _selectors[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _selectors[n++] = bytes4(keccak256("unwrap(address,uint256)"));
        // Extra test-exposing commands
        _selectors[n++] = bytes4(keccak256("mint(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("burn(address,address,uint256)"));
        _selectors[n++] = bytes4(keccak256("reallocate(address,address,uint256)"));
        if (n != 35) revert InvalidCommandsLength(n);
    }

    function initializeTestLedger(string memory nativeTokenSymbol_) external initializer {
        enforceIsOwner();
        initializeLedger_unchained(nativeTokenSymbol_);
    }

    function mint(address toParent_, address to_, uint256 amount_) external {
        LedgerLib.mint(toParent_, to_, amount_);
    }

    function burn(address fromParent_, address from_, uint256 amount_) external {
        LedgerLib.burn(fromParent_, from_, amount_);
    }

    function reallocate(address fromToken_, address toToken_, uint256 amount_) external {
        LedgerLib.reallocate(fromToken_, toToken_, amount_);
    }

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

contract DummyWrapper {}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────
contract LedgerTest is Test {
    Router router;
    TestLedger ledgers;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);
    address native = LedgerLib.NATIVE_ADDRESS;

    address testLedger;
    MockERC20 externalToken;
    MockERC20 unlistedToken;
    address externalWrapper;

    // Root
    address _1 = LedgerLib.toNamedAddress("1");
    // Depth 1
    address _10 = LedgerLib.toNamedAddress("10");
    address _11 = LedgerLib.toNamedAddress("11");
    // Depth 2
    address _100 = LedgerLib.toNamedAddress("100");
    address _101 = LedgerLib.toNamedAddress("101");
    address _110 = LedgerLib.toNamedAddress("110");
    address _111 = LedgerLib.toNamedAddress("111");

    address r1;
    address r10;
    address r11;
    address r100;
    address r101;
    address r110;
    address r111;

    function setUp() public {
        bool isVerbose = false;

        vm.startPrank(alice);
        if (isVerbose) console.log("Deploying TestLedger");
        ledgers = new TestLedger(18);
        if (isVerbose) console.log("Deploying Router");
        router = new Router(alice);
        if (isVerbose) console.log("Adding Ledger module to Router");
        router.addModule(address(ledgers));
        ledgers = TestLedger(payable(router));

        if (isVerbose) console.log("Initializing Test Ledger");
        ledgers.initializeTestLedger("AVAX");

        // Add a standalone ledger tree for misc checks
        // testLedger = LedgerLib.toNamedAddress("Test Ledger");
        if (isVerbose) console.log("Creating Test Ledger token");
        testLedger = ledgers.createInternalToken("Test Ledger", "TL", 18, false);
        if (isVerbose) console.log("Adding sub-groups to Test Ledger");
        ledgers.addSubAccountGroup(
            ledgers.addSubAccountGroup(ledgers.addSubAccountGroup(testLedger, "1", false), "10", false), "100", false
        );

        // Add token r1 and its sub-groups
        if (isVerbose) console.log("Creating root token '1'");
        r1 = ledgers.createInternalToken("1", "1", 18, true);
        if (isVerbose) console.log("Adding sub-group '10' to root token '1'");
        r10 = ledgers.addSubAccountGroup(r1, "10", false);
        if (isVerbose) console.log("Adding sub-group '11' to root token '1'");
        r11 = ledgers.addSubAccountGroup(r1, "11", false);
        if (isVerbose) console.log("Adding sub-groups '100' to '10'");
        r100 = ledgers.addSubAccountGroup(r10, "100", false);
        if (isVerbose) console.log("Adding sub-groups '101' to '10'");
        r101 = ledgers.addSubAccountGroup(r10, "101", false);
        if (isVerbose) console.log("Adding sub-groups '110' to '11'");
        r110 = ledgers.addSubAccountGroup(r11, "110", false);
        if (isVerbose) console.log("Adding sub-groups '111' to '11'");
        r111 = ledgers.addSubAccountGroup(r11, "111", false);

        if (isVerbose) console.log("Creating external token and its wrapper");
        externalToken = new MockERC20("External Token", "EXT", 18);
        ledgers.createWrappedToken(address(externalToken));
        externalWrapper = ledgers.wrapper(address(externalToken));

        unlistedToken = new MockERC20("Unlisted Token", "UNL", 18);
    }

    // Matches your old “InvalidInitialization” guard
    error InvalidInitialization();

    // ─────────────────────────────────────────────────────────────────────────
    // Structure / initialization
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerInit() public {
        bool isVerbose = false;

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledgers, address(router));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledgers, testLedger);
        if (isVerbose) console.log("--------------------");
        if (isVerbose) TreeLib.debugTree(ledgers, r1);
        if (isVerbose) console.log("--------------------");
        // Visual (optional): TreeLib.debugTree(ledgers, r1);

        vm.startPrank(alice);
        vm.expectRevert(InvalidInitialization.selector);
        ledgers.initializeTestLedger("AVAX II"); // re-init should revert

        // Tree shape sanity
        assertEq(ledgers.subAccounts(testLedger).length, 3, "Subaccounts (testLedger)");
        assertEq(ledgers.subAccounts(r1).length, 3, "Subaccounts (r1)");
        assertEq(ledgers.subAccounts(r10).length, 2, "Subaccounts (r10)");
        assertEq(ledgers.subAccounts(r11).length, 2, "Subaccounts (r11)");

        assertEq(ledgers.subAccountIndex(r1, _10), 2, "idx(r10)");
        assertEq(ledgers.subAccountIndex(r1, _11), 3, "idx(r11)");
        assertEq(ledgers.subAccountIndex(r10, _100), 1, "idx(r100)");
        assertEq(ledgers.subAccountIndex(r10, _101), 2, "idx(r101)");
        assertEq(ledgers.subAccountIndex(r11, _110), 1, "idx(r110)");
        assertEq(ledgers.subAccountIndex(r11, _111), 2, "idx(r111)");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AddSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerAddSubAccountGroup() public {
        vm.startPrank(alice);

        // Add a fresh sub under r1
        address added = ledgers.addSubAccountGroup(r1, "newSubAccount", false);
        assertEq(added, LedgerLib.toGroupAddress(r1, "newSubAccount"), "address mismatch");
        assertEq(ledgers.parent(added), r1, "parent mismatch");
        assertEq(
            ledgers.subAccountIndex(r1, LedgerLib.toNamedAddress("newSubAccount")),
            ledgers.subAccounts(r1).length,
            "index should equal #subs"
        );
        assertTrue(ledgers.hasSubAccount(r1), "r1 should have subs");

        // Re-adding the same name with same flags should idempotently return same addr or revert by your rules.
        // Your lib currently treats “same name + same flags” as OK (returns existing). Verify:
        address idempotent = ledgers.addSubAccountGroup(r1, "newSubAccount", false);
        assertEq(idempotent, added, "expected same sub account address");
    }

    function testLedgerAddSubAccountZeroParentReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, address(0)));
        ledgers.addSubAccountGroup(address(0), "zeroParent", false);
    }

    function testLedgerAddSubAccountEmptyNameReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidString.selector, ""));
        ledgers.addSubAccountGroup(r1, "", false);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RemoveSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerRemoveSubAccountHappyPath() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Removing subaccount");
        ledgers.removeSubAccountGroup(r10, "100");

        if (isVerbose) console.log("Check parent");
        assertEq(ledgers.parent(_100), address(0), "parent reset");
        if (isVerbose) console.log("Check index");
        assertEq(ledgers.subAccountIndex(r10, _100), 0, "index reset");
        if (isVerbose) console.log("Check name");
        assertEq(ledgers.name(_100), "", "name cleared");
        if (isVerbose) console.log("Check hasSubAccount");
        assertFalse(ledgers.hasSubAccount(_100), "no children");
    }

    function testLedgerRemoveSubAccountThatDoesNotExistReverts() public {
        vm.startPrank(alice);
        address nonExistent = LedgerLib.toGroupAddress(r1, "nope");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, nonExistent));
        ledgers.removeSubAccountGroup(r1, "nope");
    }

    function testLedgerRemoveSubAccountWithChildrenReverts() public {
        vm.startPrank(alice);
        address parentWithChild = ledgers.addSubAccountGroup(r1, "parentWithChild", false);
        ledgers.addSubAccountGroup(parentWithChild, "sub", false);
        vm.expectRevert(abi.encodeWithSelector(ILedger.HasSubAccount.selector, parentWithChild));
        ledgers.removeSubAccountGroup(r1, "parentWithChild");
    }

    function testLedgerRemoveSubAccountWithBalanceReverts() public {
        vm.startPrank(alice);
        ledgers.mint(r100, alice, 1000);

        vm.expectRevert(abi.encodeWithSelector(ILedger.HasBalance.selector, r100));
        ledgers.removeSubAccountGroup(r10, "100");
    }

    function testLedgerRemoveSubAccountInvalidAddresses() public {
        vm.startPrank(alice);
        address _valid = ledgers.addSubAccountGroup(r1, "validSub", false);

        // Zero parent
        vm.expectRevert(ILedger.ZeroAddress.selector);
        ledgers.removeSubAccountGroup(address(0), "validSub");

        // Parent == child group (nonsense) => InvalidAccountGroup on computed subAddress
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, LedgerLib.toGroupAddress(_valid, "validSub"))
        );
        ledgers.removeSubAccountGroup(_valid, "validSub");
    }

    function testLedgerRemoveUpdatesSiblingIndices() public {
        vm.startPrank(alice);
        address _s1 = LedgerLib.toNamedAddress("s1");
        address _s3 = LedgerLib.toNamedAddress("s3");

        ledgers.addSubAccountGroup(r1, "s1", false);
        ledgers.addSubAccountGroup(r1, "s2", false);
        ledgers.addSubAccountGroup(r1, "s3", false);

        uint256 before = ledgers.subAccounts(r1).length;
        ledgers.removeSubAccountGroup(r1, "s2");

        address[] memory subs = ledgers.subAccounts(r1);
        assertEq(subs.length, before - 1, "length");
        assertEq(subs[before - 3], _s1, "first remains s1");
        assertEq(subs[before - 2], _s3, "second becomes s3");

        assertEq(ledgers.subAccountIndex(r1, _s1), before - 2, "s1 idx");
        assertEq(ledgers.subAccountIndex(r1, _s3), before - 1, "s3 idx");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parents / roots / hasSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerParents() public view {
        assertEq(ledgers.root(r10), r1, "root r10");
        assertEq(ledgers.root(r11), r1, "root r11");
        assertEq(ledgers.root(r100), r1, "root r100");
        assertEq(ledgers.root(r101), r1, "root r101");
        assertEq(ledgers.root(r110), r1, "root r110");
        assertEq(ledgers.root(r111), r1, "root r111");

        assertEq(ledgers.parent(r10), r1, "parent r10");
        assertEq(ledgers.parent(r11), r1, "parent r11");
        assertEq(ledgers.parent(r100), r10, "parent r100");
        assertEq(ledgers.parent(r101), r10, "parent r101");
        assertEq(ledgers.parent(r110), r11, "parent r110");
        assertEq(ledgers.parent(r111), r11, "parent r111");
    }

    function testLedgerHasSubAccount() public view {
        assertTrue(ledgers.hasSubAccount(r1), "r1");
        assertTrue(ledgers.hasSubAccount(r10), "r10");
        assertTrue(ledgers.hasSubAccount(r11), "r11");
        assertFalse(ledgers.hasSubAccount(r100), "r100");
        assertFalse(ledgers.hasSubAccount(r101), "r101");
        assertFalse(ledgers.hasSubAccount(r110), "r110");
        assertFalse(ledgers.hasSubAccount(r111), "r111");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mint / Burn
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerMint() public {
        bool isVerbose = false;

        if (isVerbose) {
            console.log("--------------------");
            TreeLib.debugTree(ledgers, address(router));
            console.log("--------------------");
            TreeLib.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint address(this): Alice");
        ledgers.mint(address(ledgers), alice, 1000);

        assertEq(ledgers.balanceOf(address(ledgers), alice), 1000, "balanceOf(alice)");
        assertEq(ledgers.totalSupply(address(ledgers)), 1000, "totalSupply");

        if (isVerbose) console.log("Mint token 1: Alice");
        ledgers.mint(r100, alice, 1000);
        assertEq(ledgers.balanceOf(r100, alice), 1000, "balanceOf(r100, alice)");
        assertEq(ledgers.balanceOf(r10, "100"), 1000, 'balanceOf(r10, "100")');
        assertEq(ledgers.balanceOf(r1, "10"), 1000, 'balanceOf(r1, "10")');
        assertEq(ledgers.totalSupply(r1), 1000, "totalSupply(r1)");
    }

    function testLedgerBurn() public {
        vm.startPrank(alice);

        ledgers.mint(address(ledgers), alice, 1000);
        ledgers.burn(address(ledgers), alice, 700);

        assertEq(ledgers.balanceOf(address(ledgers), alice), 300, "balanceOf(alice)");
        assertEq(ledgers.totalSupply(address(ledgers)), 300, "totalSupply");

        ledgers.mint(r100, alice, 1000);
        ledgers.burn(r100, alice, 600);

        assertEq(ledgers.balanceOf(r100, alice), 400, "balanceOf(r100, alice)");
        assertEq(ledgers.balanceOf(r10, "100"), 400, 'balanceOf(r10, "100")');
        assertEq(ledgers.balanceOf(r1, "10"), 400, 'balanceOf(r1, "10")');
        assertEq(ledgers.totalSupply(r1), 400, "totalSupply(r1)");
    }

    function testLedgerReallocate() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        address tokenA = ledgers.createInternalToken("Realloc A", "REA", 18, false);
        address tokenB = ledgers.createInternalToken("Realloc B", "REB", 18, false);

        uint256 initialAmount = 1_000 ether;
        uint256 shift = 400 ether;

        if (isVerbose) console.log("Minting initial amount to tokenA");
        ledgers.mint(address(ledgers), tokenA, initialAmount);

        if (isVerbose) console.log("Reallocating from tokenA to tokenB");
        ledgers.reallocate(tokenA, tokenB, shift);
        assertEq(ledgers.balanceOf(address(ledgers), tokenA), initialAmount - shift, "tokenA debited");
        assertEq(ledgers.balanceOf(address(ledgers), tokenB), shift, "tokenB credited");

        uint256 shiftBack = 125 ether;
        if (isVerbose) console.log("Reallocating back from tokenB to tokenA");
        ledgers.reallocate(tokenB, tokenA, shiftBack);
        assertEq(
            ledgers.balanceOf(address(ledgers), tokenA), initialAmount - shift + shiftBack, "tokenA after rebalancing"
        );
        assertEq(ledgers.balanceOf(address(ledgers), tokenB), shift - shiftBack, "tokenB after rebalancing");
    }

    function testLedgerWrap() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        uint256 unlistedAmount = 50;
        unlistedToken.mint(alice, unlistedAmount);
        unlistedToken.approve(address(ledgers), unlistedAmount);
        if (isVerbose) console.log("Attempt wrap of unlisted token (should revert)");
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, address(unlistedToken)));
        ledgers.wrap(address(unlistedToken), unlistedAmount);

        uint256 wrapAmount = 120;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledgers), wrapAmount);
        if (isVerbose) console.log("Wrapping external token");
        ledgers.wrap(address(externalToken), wrapAmount);

        assertEq(externalToken.balanceOf(address(router)), wrapAmount, "router holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledgers.balanceOf(address(externalToken), alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledgers.totalSupply(address(externalToken)), wrapAmount, "total supply after wrap");

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, address(unlistedToken)));
        ledgers.unwrap(address(unlistedToken), 10);

        uint256 firstUnwrap = 45;
        ledgers.unwrap(address(externalToken), firstUnwrap);
        assertEq(
            externalToken.balanceOf(address(router)), wrapAmount - firstUnwrap, "router balance after partial unwrap"
        );
        assertEq(externalToken.balanceOf(alice), firstUnwrap, "alice external balance after partial unwrap");
        assertEq(
            ledgers.balanceOf(address(externalToken), alice),
            wrapAmount - firstUnwrap,
            "ledger balance after partial unwrap"
        );
        assertEq(
            ledgers.totalSupply(address(externalToken)), wrapAmount - firstUnwrap, "total supply after partial unwrap"
        );

        uint256 remaining = wrapAmount - firstUnwrap;
        ledgers.unwrap(address(externalToken), remaining);
        assertEq(externalToken.balanceOf(address(router)), 0, "router drained after unwrap");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "alice restored external balance");
        assertEq(ledgers.balanceOf(address(externalToken), alice), 0, "ledger balance cleared");
        assertEq(ledgers.totalSupply(address(externalToken)), 0, "total supply cleared");
    }

    function testLedgerWrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);

        uint256 wrapAmount = 2 ether;
        uint256 routerBalanceBefore = address(router).balance;
        ledgers.wrap{value: wrapAmount}(native, wrapAmount);
        vm.stopPrank();

        assertEq(address(router).balance, routerBalanceBefore + wrapAmount, "router holds native collateral");
        assertEq(ledgers.balanceOf(native, alice), wrapAmount, "ledger native balance");
        assertEq(ledgers.totalSupply(native), wrapAmount, "native total supply");
    }

    function testLedgerWrapNativeIncorrectValue() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);

        uint256 wrapAmount = 2 ether;
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, wrapAmount - 1, wrapAmount));
        ledgers.wrap{value: wrapAmount - 1}(native, wrapAmount);
        vm.stopPrank();
    }

    function testLedgerWrapNonNativeRejectsValue() public {
        vm.startPrank(alice);
        uint256 wrapAmount = 10;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledgers), wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledgers.wrap{value: 1}(address(externalToken), wrapAmount);
        vm.stopPrank();
    }

    function testLedgerUnwrapNative() public {
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);

        uint256 wrapAmount = 3 ether;
        ledgers.wrap{value: wrapAmount}(native, wrapAmount);
        uint256 routerBalanceAfterWrap = address(router).balance;
        uint256 aliceBalanceAfterWrap = alice.balance;

        uint256 unwrapAmount = 1 ether;
        ledgers.unwrap(native, unwrapAmount);
        vm.stopPrank();

        assertEq(address(router).balance, routerBalanceAfterWrap - unwrapAmount, "router native balance");
        assertEq(alice.balance, aliceBalanceAfterWrap + unwrapAmount, "alice native balance");
        assertEq(ledgers.balanceOf(native, alice), wrapAmount - unwrapAmount, "ledger native balance");
        assertEq(ledgers.totalSupply(native), wrapAmount - unwrapAmount, "native total supply");
    }

    function testLedgerUnwrapNativeRejectsValue() public {
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);

        uint256 wrapAmount = 1 ether;
        ledgers.wrap{value: wrapAmount}(native, wrapAmount);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledgers.unwrap{value: 1}(native, 0.5 ether);
        vm.stopPrank();
    }

    function testLedgerUnwrapNonNativeRejectsValue() public {
        vm.startPrank(alice);
        uint256 wrapAmount = 50;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledgers), wrapAmount);
        ledgers.wrap(address(externalToken), wrapAmount);
        vm.deal(alice, 1 ether);
        vm.expectRevert(abi.encodeWithSelector(ILedger.IncorrectAmount.selector, 1, 0));
        ledgers.unwrap{value: 1}(address(externalToken), 10);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Transfers / approvals / allowance / transferFrom (routed)
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerTransfer() public {
        vm.startPrank(alice);

        address routerRoot = address(ledgers);

        // Mint → transfer to bob under the same root
        ledgers.mint(routerRoot, alice, 1000);
        // elm: fromParent = routerRoot, toParent = routerRoot, to = bob
        ledgers.transfer(routerRoot, routerRoot, bob, 700);

        assertEq(ledgers.balanceOf(routerRoot, alice), 300, "alice");
        assertEq(ledgers.balanceOf(routerRoot, bob), 700, "bob");
        assertEq(ledgers.totalSupply(routerRoot), 1000, "supply");

        // Different roots should revert
        vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, routerRoot, r1));
        // attempt: fromParent=routerRoot, toParent=r1 (different root)
        ledgers.transfer(routerRoot, r1, bob, 100);
    }

}

// contract Bah {
// function testLedgerAddSubAccount() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, address(router));
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Adding a new valid subAccount");
//     address added = ledgers.addSubAccount(r1, "newSubAccount", true, false);
//     assertEq(added, LedgerLib.toGroupAddress(r1, "newSubAccount"), "addSubAccount address");
//     assertEq(ledgers.parent(added), r1, "Parent should be r1");
//     assertEq(
//         ledgers.subAccountIndex(added),
//         ledgers.subAccounts(r1).length,
//         "SubAccount index should match subAccounts length"
//     );
//     assertTrue(ledgers.hasSubAccount(r1), "r1 should have subAccounts");

//     if (isVerbose) console.log("Adding a subAccount that already exists");
//     setUp();
//     ledgers.addSubAccount(r1, "newSubAccount", true, false);

//     if (isVerbose) {
//         console.log("Adding a subAccount whose parent is address(0)");
//     }
//     setUp();
//     vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, address(0)));
//     ledgers.addSubAccount(address(0), "zeroParentSubAccount", true, false);

//     if (isVerbose) {
//         console.log('Adding a subAccount whose name is ""');
//     }
//     setUp();
//     vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidSubAccount.selector, "", true, false));
//     ledgers.addSubAccount(r1, "", true, false);
// }

// function testLedgerRemoveSubAccount() public {
//     bool isVerbose = false;

//     vm.startPrank(alice);

//     // First run the tree visualization tests
//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, address(router));
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 111");
//         ledgers.removeSubAccount(r11, "111");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 110");
//         ledgers.removeSubAccount(r11, "110");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 101");
//         ledgers.removeSubAccount(r10, "101");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 100");
//         ledgers.removeSubAccount(r10, "100");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 11");
//         ledgers.removeSubAccount(r1, "11");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         console.log("Remove SubAccount 10");
//         ledgers.removeSubAccount(r1, "10");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");

//         setUp();
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");
//     }

//     // Now run the validation tests
//     if (isVerbose) {
//         console.log("Test 1: Remove a valid subAccount (leaf node)");
//     }
//     ledgers.addSubAccount(r1, "leafSubAccount", true, false);
//     ledgers.removeSubAccount(r1, "leafSubAccount");
//     assertEq(ledgers.parent(LedgerLib.toGroupAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
//     assertEq(
//         ledgers.subAccountIndex(LedgerLib.toGroupAddress(r1, "leafSubAccount")), 0, "SubAccount index should be reset"
//     );
//     assertEq(ledgers.name(LedgerLib.toGroupAddress(r1, "leafSubAccount")), "", "Name should be cleared");
//     assertFalse(ledgers.hasSubAccount(LedgerLib.toGroupAddress(r1, "leafSubAccount")), "Should not have subAccounts");

//     if (isVerbose) {
//         console.log("Test 2: Remove a subAccount that doesn't exist");
//     }
//     address nonExistentSubAccount = LedgerLib.toGroupAddress(r1, "nonExistentSubAccount");
//     vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, nonExistentSubAccount));
//     ledgers.removeSubAccount(r1, "nonExistentSubAccount");

//     if (isVerbose) {
//         console.log("Test 3: Remove a subAccount that has subAccounts");
//     }
//     address parentWithSubAccount = ledgers.addSubAccount(r1, "parentWithSubAccount", true, false);
//     ledgers.addSubAccount(parentWithSubAccount, "subAccountOfParent", true, false);
//     vm.expectRevert(abi.encodeWithSelector(ILedger.HasSubAccount.selector, "parentWithSubAccount"));
//     ledgers.removeSubAccount(r1, "parentWithSubAccount");

//     if (isVerbose) {
//         console.log("Test 4: Remove a subAccount that has a balance");
//     }
//     ledgers.mint(r100, 1000);
//     vm.expectRevert(abi.encodeWithSelector(ILedger.HasBalance.selector, "100"));
//     ledgers.removeSubAccount(r10, "100");

//     if (isVerbose) {
//         console.log("Test 5: Remove a subAccount with invalid addresses");
//     }
//     address validSubAccount = ledgers.addSubAccount(r1, "validSubAccount", true, false);

//     // Try to remove with address(0) as parent
//     vm.expectRevert(ILedger.ZeroAddress.selector);
//     ledgers.removeSubAccount(address(0), "validSubAccount");

//     // Try to remove with same address for parent and subAccount
//     vm.expectRevert(
//         abi.encodeWithSelector(
//             ILedger.InvalidAccountGroup.selector, LedgerLib.toGroupAddress(validSubAccount, "validSubAccount")
//         )
//     );
//     ledgers.removeSubAccount(validSubAccount, "validSubAccount");

//     if (isVerbose) {
//         console.log("Test 6: Remove a subAccount and verify parent's subAccounts array is updated correctly");
//     }
//     setUp();
//     address subAccount1 = ledgers.addSubAccount(r1, "subAccount1", true, false);
//     ledgers.addSubAccount(r1, "subAccount2", true, false);
//     address subAccount3 = ledgers.addSubAccount(r1, "subAccount3", true, false);

//     uint256 subAccountCount = ledgers.subAccounts(r1).length;

//     if (isVerbose) {
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");
//     }

//     // Remove subAccount2 (middle subAccount)
//     ledgers.removeSubAccount(r1, "subAccount2");

//     // Verify subAccounts array is updated correctly
//     address[] memory subAccounts = ledgers.subAccounts(r1);
//     assertEq(subAccounts.length, subAccountCount - 1, "Incorrect number of subAccounts after removal");
//     assertEq(subAccounts[subAccountCount - 3], subAccount1, "First subAccount should be subAccount1");
//     assertEq(subAccounts[subAccountCount - 2], subAccount3, "Second subAccount should be subAccount3");

//     if (isVerbose) console.log("Verify subAccount indices are updated");
//     assertEq(
//         ledgers.subAccountIndex(LedgerLib.toGroupAddress(r1, "subAccount1")),
//         subAccountCount - 2,
//         "subAccount1 index incorrect"
//     );
//     if (isVerbose) {
//         console.log("Display subaccounts");
//         for (uint256 i = 0; i < subAccounts.length; i++) {
//             console.log(
//                 "SubAccount", ledgers.name(subAccounts[i]), subAccounts[i], ledgers.subAccountIndex(subAccounts[i])
//             );
//         }
//     }
//     assertEq(
//         ledgers.subAccountIndex(LedgerLib.toGroupAddress(r1, "subAccount3")),
//         subAccountCount - 1,
//         "subAccount3 index incorrect"
//     );
// }

// function testLedgerMint() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, address(router));
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Initial mint address(this): Alice");
//     ledgers.mint(address(ledgers), 1000);

//     assertEq(ledgers.balanceOf(alice), 1000, "balanceOf(alice)");
//     assertEq(ledgers.totalSupply(), 1000, "totalSupply");

//     if (isVerbose) console.log("Mint token 1: Alice");
//     ledgers.mint(r100, 1000);
//     assertEq(ledgers.balanceOf(r100, alice), 1000, "balanceOf(r100, alice)");
//     assertEq(ledgers.balanceOf(r10, "100"), 1000, 'balanceOf(r10, "100")');
//     assertEq(ledgers.balanceOf(r1, "10"), 1000, 'balanceOf(r1, "10")');
//     assertEq(ledgers.totalSupply(r1), 1000, "totalSupply(r1)");
// }

// function testLedgerBurn() public {
//     vm.startPrank(alice);

//     ledgers.mint(address(ledgers), 1000);
//     ledgers.burn(address(ledgers), 700);

//     assertEq(ledgers.balanceOf(alice), 300, "balanceOf(alice)");
//     assertEq(ledgers.totalSupply(), 300, "totalSupply");

//     ledgers.mint(r100, 1000);
//     ledgers.burn(r100, 600);

//     assertEq(ledgers.balanceOf(r100, alice), 400, "balanceOf(r100, alice)");
//     assertEq(ledgers.balanceOf(r10, "100"), 400, 'balanceOf(r10, "100")');
//     assertEq(ledgers.balanceOf(r1, "10"), 400, 'balanceOf(r1, "10")');
//     assertEq(ledgers.totalSupply(r1), 400, "totalSupply(r1)");
// }

// function testLedgerParents() public view {
//     assertEq(ledgers.root(r10), r1, "root(_10)");
//     assertEq(ledgers.root(r11), r1, "root(_11)");
//     assertEq(ledgers.root(r100), r1, "root(_100)");
//     assertEq(ledgers.root(r101), r1, "root(_101)");
//     assertEq(ledgers.root(r110), r1, "root(_110)");
//     assertEq(ledgers.root(r111), r1, "root(_111)");

//     assertEq(ledgers.parent(r10), r1, "parent(_10)");
//     assertEq(ledgers.parent(r11), r1, "parent(_11)");
//     assertEq(ledgers.parent(r100), r10, "parent(_100)");
//     assertEq(ledgers.parent(r101), r10, "parent(_101)");
//     assertEq(ledgers.parent(r110), r11, "parent(_110)");
//     assertEq(ledgers.parent(r111), r11, "parent(_111)");
// }

// function testLedgerHasSubAccount() public view {
//     assertTrue(ledgers.hasSubAccount(r1), "hasSubAccount(r1)");
//     assertTrue(ledgers.hasSubAccount(r10), "hasSubAccount(r10)");
//     assertTrue(ledgers.hasSubAccount(r11), "hasSubAccount(r11)");
//     assertFalse(ledgers.hasSubAccount(r100), "hasSubAccount(r100)");
//     assertFalse(ledgers.hasSubAccount(r101), "hasSubAccount(r101)");
//     assertFalse(ledgers.hasSubAccount(r110), "hasSubAccount(r110)");
//     assertFalse(ledgers.hasSubAccount(r111), "hasSubAccount(r111)");
// }

// function testLedgerTransfer() public {
//     bool isVerbose = false;

//     if (isVerbose) {
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, address(router));
//         console.log("--------------------");
//         TreeLib.debugTree(ledgers, r1);
//         console.log("--------------------");
//     }

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Initial mint and transfer");
//     ledgers.mint(address(ledgers), 1000);
//     ledgers.transfer(bob, 700);

//     assertEq(ledgers.balanceOf(address(ledgers)), 0, "balanceOf(this)");
//     assertEq(ledgers.balanceOf(alice), 300, "balanceOf(alice)");
//     assertEq(ledgers.balanceOf(bob), 700, "balanceOf(bob)");
//     assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

//     if (isVerbose) console.log("Transfer from alice to bob");
//     ledgers.transfer(address(ledgers), address(ledgers), bob, 100);

//     assertEq(ledgers.balanceOf(alice), 200, "balanceOf(alice)");
//     assertEq(ledgers.balanceOf(bob), 800, "balanceOf(bob)");
//     assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

//     if (isVerbose) console.log("Expect revert if sender and receiver have different roots");
//     vm.expectRevert(abi.encodeWithSelector(ILedger.DifferentRoots.selector, address(ledgers), r1));
//     ledgers.transfer(address(ledgers), _1, _10, 100);
// }

// function testLedgerApprove() public {
//     bool isVerbose = false;

//     vm.startPrank(alice);

//     if (isVerbose) console.log("Initial mint and approve");
//     ledgers.mint(address(ledgers), 1000);
//     ledgers.approve(bob, 100);

//     assertEq(ledgers.allowance(alice, bob), 100, "allowance(alice, bob)");
//     assertEq(ledgers.allowance(bob, alice), 0, "allowance(bob, alice)");
//     assertEq(ledgers.allowance(bob, bob), 0, "allowance(bob, bob)");
//     assertEq(ledgers.allowance(alice, alice), 0, "allowance(alice, alice)");
// }

// function testLedgerTransferFrom() public {
//     vm.startPrank(alice);

//     ledgers.mint(address(ledgers), 1000);
//     ledgers.approve(bob, 100);

//     vm.startPrank(bob);

//     ledgers.transferFrom(alice, bob, 100);

//     assertEq(ledgers.balanceOf(alice), 900, "balanceOf(alice)");
//     assertEq(ledgers.balanceOf(bob), 100, "balanceOf(bob)");
//     assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

//     vm.startPrank(alice);

//     ledgers.mint(r1, 1000);
//     ledgers.approve(r1, r1, bob, 100);

//     vm.startPrank(bob);

//     ledgers.transferFrom(r1, alice, r1, r10, _100, 100);

//     assertEq(ledgers.balanceOf(r1, alice), 900, "balanceOf(_1, alice)");
//     assertEq(ledgers.balanceOf(r1, bob), 0, "balanceOf(_1, bob)");
//     assertEq(ledgers.balanceOf(r10, _100), 100, "balanceOf(_10, _100)");
//     assertEq(ledgers.totalSupply(_1), 1000, "totalSupply(_1)");
// }
// }
