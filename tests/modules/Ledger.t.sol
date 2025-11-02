// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ─────────────────────────────────────────────────────────────────────────────
// Import split layout (interfaces + lib + module + infra)
// Adjust paths if your repo layout differs.
// ─────────────────────────────────────────────────────────────────────────────
import {ILedger} from "../../interfaces/ILedger.sol";
import {LedgerLib as LLib} from "../../libraries/LedgerLib.sol";
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
    function commands() external pure virtual override returns (bytes4[] memory _commands) {
        uint256 n;
        _commands = new bytes4[](39);
        _commands[n++] = bytes4(keccak256("initializeTestLedger()"));
        _commands[n++] = bytes4(keccak256("addSubAccount(address,address,string,bool)"));
        _commands[n++] = bytes4(keccak256("addSubAccountGroup(address,string,bool)"));
        _commands[n++] = bytes4(keccak256("removeSubAccount(address,address)"));
        _commands[n++] = bytes4(keccak256("removeSubAccountGroup(address,string)"));
        _commands[n++] = bytes4(keccak256("mint(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("burn(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("addLedger(address,string,string,uint8,bool,bool)"));
        _commands[n++] = bytes4(keccak256("createToken(string,string,uint8,bool)"));
        _commands[n++] = bytes4(keccak256("name(address)"));
        _commands[n++] = bytes4(keccak256("symbol(address)"));
        _commands[n++] = bytes4(keccak256("decimals(address)"));
        _commands[n++] = bytes4(keccak256("root(address)"));
        _commands[n++] = bytes4(keccak256("parent(address)"));
        _commands[n++] = bytes4(keccak256("isGroup(address)"));
        _commands[n++] = bytes4(keccak256("isCredit(address)"));
        _commands[n++] = bytes4(keccak256("isInternal(address)"));
        _commands[n++] = bytes4(keccak256("subAccounts(address)"));
        _commands[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _commands[n++] = bytes4(keccak256("subAccountIndex(address,address)"));
        _commands[n++] = bytes4(keccak256("wrapper(address)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _commands[n++] = bytes4(keccak256("totalSupply(address)"));
        _commands[n++] = bytes4(keccak256("transfer(address,address,address,address,uint256,bool)"));
        _commands[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approve(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approve(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("increaseAllowance(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("increaseAllowance(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("decreaseAllowance(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("decreaseAllowance(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("forceApprove(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("forceApprove(address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("allowance(address,address,address)"));
        _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,address,uint256,bool)"));
        _commands[n++] = bytes4(keccak256("wrap(address,uint256)"));
        _commands[n++] = bytes4(keccak256("unwrap(address,uint256)"));
        if (n != _commands.length) revert InvalidCommandsLength(n);
    }

    function initializeTestLedger() external initializer {
        enforceIsOwner();
        initializeLedger_unchained();
    }

    function addSubAccountGroup(address parent_, string memory name_, bool isCredit_) external returns (address) {
        return LLib.addSubAccountGroup(parent_, name_, isCredit_);
    }

    function addSubAccount(address parent_, address addr_, string memory name_, bool isCredit_)
        external
        returns (address)
    {
        return LLib.addSubAccount(parent_, addr_, name_, isCredit_);
    }

    function removeSubAccountGroup(address parent_, string memory name_) external returns (address) {
        return LLib.removeSubAccountGroup(parent_, name_);
    }

    function removeSubAccount(address parent_, address addr_) external returns (address) {
        return LLib.removeSubAccount(parent_, addr_);
    }

    function addLedger(
        address token_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bool isCredit_,
        bool isInternal_
    ) external {
        LLib.addLedger(token_, name_, symbol_, decimals_, isCredit_, isInternal_);
    }

    function mint(address toParent_, address to_, uint256 amount_) external {
        LLib.mint(toParent_, to_, amount_);
    }

    function burn(address fromParent_, address from_, uint256 amount_) external {
        LLib.burn(fromParent_, from_, amount_);
    }

    function wrap(address token_, uint256 amount_) external {
        LLib.wrap(token_, amount_);
    }

    function unwrap(address token_, uint256 amount_) external {
        LLib.unwrap(token_, amount_);
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

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────
contract LedgerTest is Test {
    Router router;
    TestLedger ledgers;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);

    address testLedger;
    MockERC20 externalToken;
    address externalWrapper;

    // Root
    address _1 = LLib.toNamedAddress("1");
    // Depth 1
    address _10 = LLib.toNamedAddress("10");
    address _11 = LLib.toNamedAddress("11");
    // Depth 2
    address _100 = LLib.toNamedAddress("100");
    address _101 = LLib.toNamedAddress("101");
    address _110 = LLib.toNamedAddress("110");
    address _111 = LLib.toNamedAddress("111");

    // Root token and sub-groups
    address r1 = LLib.toNamedAddress("1");
    address r10 = LLib.toGroupAddress(r1, "10");
    address r11 = LLib.toGroupAddress(r1, "11");
    address r100 = LLib.toGroupAddress(r10, "100");
    address r101 = LLib.toGroupAddress(r10, "101");
    address r110 = LLib.toGroupAddress(r11, "110");
    address r111 = LLib.toGroupAddress(r11, "111");

    function setUp() public {
        vm.startPrank(alice);
        ledgers = new TestLedger(18);
        router = new Router(alice);
        router.addModule(address(ledgers));
        ledgers = TestLedger(payable(router));

        ledgers.initializeTestLedger();

        // Add a standalone ledger tree for misc checks
        testLedger = LLib.toNamedAddress("Test Ledger");
        ledgers.addLedger(testLedger, "Test Ledger", "TL", 18, false, true);
        ledgers.addSubAccountGroup(
            ledgers.addSubAccountGroup(ledgers.addSubAccountGroup(testLedger, "1", false), "10", false), "100", false
        );

        // Add token r1 and its sub-groups
        ledgers.addLedger(r1, "1", "1", 18, true, true);
        ledgers.addSubAccountGroup(r1, "10", false);
        ledgers.addSubAccountGroup(r1, "11", false);
        ledgers.addSubAccountGroup(r10, "100", false);
        ledgers.addSubAccountGroup(r10, "101", false);
        ledgers.addSubAccountGroup(r11, "110", false);
        ledgers.addSubAccountGroup(r11, "111", false);

        externalToken = new MockERC20("External Token", "EXT", 18);
        ledgers.addLedger(address(externalToken), "External Token", "EXT", 18, false, false);
        externalWrapper = ledgers.wrapper(address(externalToken));
    }

    // Matches your old “InvalidInitialization” guard
    error InvalidInitialization();

    // ─────────────────────────────────────────────────────────────────────────
    // Structure / initialization
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgerInit() public {
        bool isVerbose = true;

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
        ledgers.initializeTestLedger(); // re-init should revert

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
        assertEq(added, LLib.toGroupAddress(r1, "newSubAccount"), "address mismatch");
        assertEq(ledgers.parent(added), r1, "parent mismatch");
        assertEq(
            ledgers.subAccountIndex(r1, LLib.toNamedAddress("newSubAccount")),
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
        address nonExistent = LLib.toGroupAddress(r1, "nope");
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
            abi.encodeWithSelector(ILedger.InvalidAccountGroup.selector, LLib.toGroupAddress(_valid, "validSub"))
        );
        ledgers.removeSubAccountGroup(_valid, "validSub");
    }

    function testLedgerRemoveUpdatesSiblingIndices() public {
        vm.startPrank(alice);
        address _s1 = LLib.toNamedAddress("s1");
        address _s3 = LLib.toNamedAddress("s3");

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

    function testLedgerWrap() public {
        vm.startPrank(alice);

        MockERC20 unlisted = new MockERC20("Unlisted Token", "UNL", 18);
        uint256 unlistedAmount = 50;
        unlisted.mint(alice, unlistedAmount);
        unlisted.approve(address(ledgers), unlistedAmount);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, address(unlisted)));
        ledgers.wrap(address(unlisted), unlistedAmount);

        uint256 wrapAmount = 120;
        externalToken.mint(alice, wrapAmount);
        externalToken.approve(address(ledgers), wrapAmount);
        ledgers.wrap(address(externalToken), wrapAmount);

        assertEq(externalToken.balanceOf(address(router)), wrapAmount, "router holds wrapped tokens");
        assertEq(externalToken.balanceOf(alice), 0, "alice external balance consumed");
        assertEq(ledgers.balanceOf(externalWrapper, alice), wrapAmount, "ledger balance after wrap");
        assertEq(ledgers.totalSupply(externalWrapper), wrapAmount, "total supply after wrap");

        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidAddress.selector, address(unlisted)));
        ledgers.unwrap(address(unlisted), 10);

        uint256 firstUnwrap = 45;
        ledgers.unwrap(address(externalToken), firstUnwrap);
        assertEq(
            externalToken.balanceOf(address(router)), wrapAmount - firstUnwrap, "router balance after partial unwrap"
        );
        assertEq(externalToken.balanceOf(alice), firstUnwrap, "alice external balance after partial unwrap");
        assertEq(
            ledgers.balanceOf(externalWrapper, alice), wrapAmount - firstUnwrap, "ledger balance after partial unwrap"
        );
        assertEq(ledgers.totalSupply(externalWrapper), wrapAmount - firstUnwrap, "total supply after partial unwrap");

        uint256 remaining = wrapAmount - firstUnwrap;
        ledgers.unwrap(address(externalToken), remaining);
        assertEq(externalToken.balanceOf(address(router)), 0, "router drained after unwrap");
        assertEq(externalToken.balanceOf(alice), wrapAmount, "alice restored external balance");
        assertEq(ledgers.balanceOf(externalWrapper, alice), 0, "ledger balance cleared");
        assertEq(ledgers.totalSupply(externalWrapper), 0, "total supply cleared");
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

    function testLedgerApproveAndAllowance() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Mint 1000 to alice");
        address routerRoot = address(ledgers);
        ledgers.mint(routerRoot, alice, 1000);

        if (isVerbose) console.log("Approve bob 100");
        // approve(ownerParent=routerRoot, spenderParent=routerRoot, spender=bob, amount=100)
        ledgers.approve(routerRoot, bob, 100);

        if (isVerbose) console.log("Check allowance");
        assertEq(ledgers.allowance(routerRoot, alice, bob), 100, "allowance(alice->bob)");
        assertEq(ledgers.allowance(routerRoot, bob, alice), 0, "allowance(bob->alice)");
        assertEq(ledgers.allowance(routerRoot, bob, bob), 0, "allowance(bob->bob)");
        assertEq(ledgers.allowance(routerRoot, alice, alice), 0, "allowance(alice->alice)");
    }

    function testLedgerTransferFrom() public {
        vm.startPrank(alice);

        ledgers.mint(address(ledgers), alice, 1000);
        ledgers.approve(address(ledgers), bob, 100);

        vm.startPrank(bob);

        ledgers.transferFrom(address(ledgers), alice, address(ledgers), bob, 100);

        assertEq(ledgers.balanceOf(address(ledgers), alice), 900, "balanceOf(alice)");
        assertEq(ledgers.balanceOf(address(ledgers), bob), 100, "balanceOf(bob)");
        assertEq(ledgers.totalSupply(address(ledgers)), 1000, "totalSupply()");

        vm.startPrank(alice);

        ledgers.mint(r1, alice, 1000);
        ledgers.approve(r1, bob, 100);

        vm.startPrank(bob);

        ledgers.transferFrom(r1, alice, r1, r10, 100);

        assertEq(ledgers.balanceOf(r1, alice), 900, "balanceOf(r1, alice)");
        assertEq(ledgers.balanceOf(r1, bob), 0, "balanceOf(r1, bob)");
        assertEq(ledgers.balanceOf(r10, _100), 0, "balanceOf(r10, _100)");
        assertEq(ledgers.totalSupply(_1), 1000, "totalSupply(r1)");
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
//     assertEq(added, LLib.toGroupAddress(r1, "newSubAccount"), "addSubAccount address");
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
//     assertEq(ledgers.parent(LLib.toGroupAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
//     assertEq(
//         ledgers.subAccountIndex(LLib.toGroupAddress(r1, "leafSubAccount")), 0, "SubAccount index should be reset"
//     );
//     assertEq(ledgers.name(LLib.toGroupAddress(r1, "leafSubAccount")), "", "Name should be cleared");
//     assertFalse(ledgers.hasSubAccount(LLib.toGroupAddress(r1, "leafSubAccount")), "Should not have subAccounts");

//     if (isVerbose) {
//         console.log("Test 2: Remove a subAccount that doesn't exist");
//     }
//     address nonExistentSubAccount = LLib.toGroupAddress(r1, "nonExistentSubAccount");
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
//             ILedger.InvalidAccountGroup.selector, LLib.toGroupAddress(validSubAccount, "validSubAccount")
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
//         ledgers.subAccountIndex(LLib.toGroupAddress(r1, "subAccount1")),
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
//         ledgers.subAccountIndex(LLib.toGroupAddress(r1, "subAccount3")),
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
