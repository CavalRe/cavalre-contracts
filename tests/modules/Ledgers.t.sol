// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ─────────────────────────────────────────────────────────────────────────────
// Import split layout (interfaces + lib + module + infra)
// Adjust paths if your repo layout differs.
// ─────────────────────────────────────────────────────────────────────────────
import {ILedgers} from "../../interfaces/ILedgers.sol";
import {LedgersLib as LLib} from "../../libraries/LedgersLib.sol";
import {Ledgers} from "../../modules/Ledgers.sol";
import {Module} from "../../modules/Module.sol";
import {Router} from "../../modules/Router.sol";

import {Test, console} from "forge-std/src/Test.sol";

// ─────────────────────────────────────────────────────────────────────────────
// Tree helpers
// ─────────────────────────────────────────────────────────────────────────────
library Tree {
    function logTree(Ledgers ledgers, address root, string memory prefix, bool isFirst, bool isLast) internal view {
        string memory label = ledgers.name(root);
        bool isGroup = ledgers.isGroup(root);
        console.log(
            "%s%s%s",
            prefix,
            isFirst ? "" : (isLast ? (isGroup ? unicode"└─ " : unicode"└● ") : (isGroup ? unicode"├─ " : unicode"├● ")),
            label
        );
        string memory subPrefix = string(abi.encodePacked(prefix, isFirst ? "" : (isLast ? "   " : unicode"│  ")));

        address[] memory subs = ledgers.subAccounts(root);
        for (uint256 i = 0; i < subs.length; i++) {
            string memory _name = ledgers.name(subs[i]);
            logTree(ledgers, LLib.toGroupAddress(root, _name), subPrefix, false, i == subs.length - 1);
        }
    }

    function debugTree(Ledgers ledgers, address root) internal view {
        logTree(ledgers, root, "", true, true);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test module that exposes LedgersLib via external funcs for Router delegatecall
// ─────────────────────────────────────────────────────────────────────────────
contract TestLedgers is Ledgers {
    constructor(uint8 decimals_, uint8 /*maxDepth_*/ ) Ledgers(decimals_) {}

    // Keep command registry so Router can “register” the module (if you use it)
    function commands() external pure virtual override returns (bytes4[] memory _commands) {
        uint256 n;
        _commands = new bytes4[](28);
        _commands[n++] = bytes4(keccak256("initializeTestLedgers()"));
        _commands[n++] = bytes4(keccak256("addSubAccount(address,string,bool,bool)"));
        _commands[n++] = bytes4(keccak256("removeSubAccount(address,string)"));
        _commands[n++] = bytes4(keccak256("mint(address,uint256)"));
        _commands[n++] = bytes4(keccak256("burn(address,uint256)"));
        _commands[n++] = bytes4(keccak256("addLedger(address,string,string,uint8)"));
        _commands[n++] = bytes4(keccak256("name(address)"));
        _commands[n++] = bytes4(keccak256("symbol(address)"));
        _commands[n++] = bytes4(keccak256("decimals(address)"));
        _commands[n++] = bytes4(keccak256("root(address)"));
        _commands[n++] = bytes4(keccak256("parent(address)"));
        _commands[n++] = bytes4(keccak256("isGroup(address)"));
        _commands[n++] = bytes4(keccak256("subAccounts(address)"));
        _commands[n++] = bytes4(keccak256("hasSubAccount(address)"));
        _commands[n++] = bytes4(keccak256("subAccountIndex(address)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,string)"));
        _commands[n++] = bytes4(keccak256("balanceOf(address,address)"));
        _commands[n++] = bytes4(keccak256("totalSupply(address)"));
        _commands[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approve(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("allowance(address,address,address,address)"));
        _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("approveWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("increaseAllowanceWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("decreaseAllowanceWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("forceApproveWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("transferWrapper(address,address,address,uint256)"));
        _commands[n++] = bytes4(keccak256("transferFromWrapper(address,address,address,address,address,uint256)"));
        if (n != _commands.length) revert InvalidCommandsLength(n);
    }

    function initializeTestLedgers() external initializer {
        enforceIsOwner();
        initializeLedgers_unchained();
    }

    // Library passthroughs (emitEvent_ = true)
    function addSubAccount(address parent_, string memory name_, bool isGroup_, bool isCredit_)
        external
        returns (address)
    {
        return LLib.addSubAccount(parent_, name_, isGroup_, isCredit_);
    }

    function removeSubAccount(address parent_, string memory name_) external returns (address) {
        return LLib.removeSubAccount(parent_, name_);
    }

    function addLedger(address token_, string memory name_, string memory symbol_, uint8 decimals_) external {
        LLib.addLedger(token_, name_, symbol_, decimals_);
    }

    function mint(address parent_, uint256 amount_) external {
        LLib.mint(parent_, msg.sender, amount_);
    }

    function burn(address parent_, uint256 amount_) external {
        LLib.burn(parent_, msg.sender, amount_);
    }

    // // Routed ops for tests
    // function transfer(address fromParent_, address toParent_, address to_, uint256 amount_) external returns (bool) {
    //     return LLib.transfer(fromParent_, msg.sender, toParent_, to_, amount_, true);
    // }

    // function approve(address ownerParent_, address spenderParent_, address spender_, uint256 amount_)
    //     external
    //     returns (bool)
    // {
    //     return LLib.approve(ownerParent_, msg.sender, spenderParent_, spender_, amount_, true);
    // }

    // function allowance(address ownerParent_, address owner_, address spenderParent_, address spender_)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     return LLib.allowance(ownerParent_, owner_, spenderParent_, spender_);
    // }

    // function transferFrom(
    //     address fromParent_,
    //     address from_,
    //     address spenderParent_,
    //     address toParent_,
    //     address to_,
    //     uint256 amount_
    // ) external returns (bool) {
    //     return LLib.transferFrom(fromParent_, from_, spenderParent_, msg.sender, toParent_, to_, amount_, true);
    // }

    // // ERC20 wrapper-like surface (same-token parents)
    // function approveWrapper(address token_, address owner_, address spender_, uint256 amount_)
    //     external
    //     returns (bool)
    // {
    //     return LLib.approve(token_, owner_, token_, spender_, amount_, true);
    // }

    // function transferWrapper(address token_, address from_, address to_, uint256 amount_) external returns (bool) {
    //     return LLib.transfer(token_, from_, token_, to_, amount_, true);
    // }

    // function transferFromWrapper(address token_, address from_, address spender_, address to_, uint256 amount_)
    //     external
    //     returns (bool)
    // {
    //     return LLib.transferFrom(token_, from_, token_, spender_, token_, to_, amount_, true);
    // }

    receive() external payable {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────
contract LedgersTest is Test {
    Router router;
    TestLedgers ledgers;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);

    address testLedger;

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
        ledgers = new TestLedgers(18, 10);
        router = new Router(alice);
        router.addModule(address(ledgers));
        ledgers = TestLedgers(payable(router));

        ledgers.initializeTestLedgers();

        // Add a standalone ledger tree for misc checks
        testLedger = LLib.toNamedAddress("Test Ledger");
        ledgers.addLedger(testLedger, "Test Ledger", "TL", 18);
        ledgers.addSubAccount(
            ledgers.addSubAccount(ledgers.addSubAccount(testLedger, "1", true, false), "10", true, false),
            "100",
            true,
            false
        );

        // Add token r1 and its sub-groups
        ledgers.addLedger(r1, "1", "1", 18);
        ledgers.addSubAccount(r1, "10", true, false);
        ledgers.addSubAccount(r1, "11", true, false);
        ledgers.addSubAccount(r10, "100", true, false);
        ledgers.addSubAccount(r10, "101", true, false);
        ledgers.addSubAccount(r11, "110", true, false);
        ledgers.addSubAccount(r11, "111", true, false);
    }

    // Matches your old “InvalidInitialization” guard
    error InvalidInitialization();

    // ─────────────────────────────────────────────────────────────────────────
    // Structure / initialization
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgersInit() public {
        // Visual (optional): Tree.debugTree(ledgers, r1);

        vm.startPrank(alice);
        vm.expectRevert(InvalidInitialization.selector);
        ledgers.initializeTestLedgers(); // re-init should revert

        // Tree shape sanity
        assertEq(ledgers.subAccounts(testLedger).length, 1, "Subaccounts (testLedger)");
        assertEq(ledgers.subAccounts(r1).length, 2, "Subaccounts (r1)");
        assertEq(ledgers.subAccounts(r10).length, 2, "Subaccounts (r10)");
        assertEq(ledgers.subAccounts(r11).length, 2, "Subaccounts (r11)");

        assertEq(ledgers.subAccountIndex(r1), 0, "idx(r1)");
        assertEq(ledgers.subAccountIndex(r10), 1, "idx(r10)");
        assertEq(ledgers.subAccountIndex(r11), 2, "idx(r11)");
        assertEq(ledgers.subAccountIndex(r100), 1, "idx(r100)");
        assertEq(ledgers.subAccountIndex(r101), 2, "idx(r101)");
        assertEq(ledgers.subAccountIndex(r110), 1, "idx(r110)");
        assertEq(ledgers.subAccountIndex(r111), 2, "idx(r111)");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AddSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgersAddSubAccount() public {
        vm.startPrank(alice);

        // Add a fresh sub under r1
        address added = ledgers.addSubAccount(r1, "newSubAccount", true, false);
        assertEq(added, LLib.toGroupAddress(r1, "newSubAccount"), "address mismatch");
        assertEq(ledgers.parent(added), r1, "parent mismatch");
        assertEq(ledgers.subAccountIndex(added), ledgers.subAccounts(r1).length, "index should equal #subs");
        assertTrue(ledgers.hasSubAccount(r1), "r1 should have subs");

        // Re-adding the same name with same flags should idempotently return same addr or revert by your rules.
        // Your lib currently treats “same name + same flags” as OK (returns existing). Verify:
        address idempotent = ledgers.addSubAccount(r1, "newSubAccount", true, false);
        assertEq(idempotent, added, "expected same sub account address");
    }

    function testLedgersAddSubAccountZeroParentReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedgers.InvalidAccountGroup.selector, address(0)));
        ledgers.addSubAccount(address(0), "zeroParent", true, false);
    }

    function testLedgersAddSubAccountEmptyNameReverts() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(ILedgers.InvalidSubAccount.selector, "", true, false));
        ledgers.addSubAccount(r1, "", true, false);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RemoveSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgersRemoveSubAccountHappyPath() public {
        vm.startPrank(alice);
        address leaf = ledgers.addSubAccount(r1, "leafSub", true, false);
        ledgers.removeSubAccount(r1, "leafSub");

        address leafAddr = LLib.toGroupAddress(r1, "leafSub");
        assertEq(ledgers.parent(leafAddr), address(0), "parent reset");
        assertEq(ledgers.subAccountIndex(leafAddr), 0, "index reset");
        assertEq(ledgers.name(leafAddr), "", "name cleared");
        assertFalse(ledgers.hasSubAccount(leafAddr), "no children");
    }

    function testLedgersRemoveSubAccountThatDoesNotExistReverts() public {
        vm.startPrank(alice);
        address nonExistent = LLib.toGroupAddress(r1, "nope");
        vm.expectRevert(abi.encodeWithSelector(ILedgers.InvalidAccountGroup.selector, nonExistent));
        ledgers.removeSubAccount(r1, "nope");
    }

    function testLedgersRemoveSubAccountWithChildrenReverts() public {
        vm.startPrank(alice);
        address parentWithChild = ledgers.addSubAccount(r1, "parentWithChild", true, false);
        ledgers.addSubAccount(parentWithChild, "sub", true, false);
        vm.expectRevert(abi.encodeWithSelector(ILedgers.HasSubAccount.selector, "parentWithChild"));
        ledgers.removeSubAccount(r1, "parentWithChild");
    }

    function testLedgersRemoveSubAccountWithBalanceReverts() public {
        vm.startPrank(alice);
        ledgers.mint(r100, 1000);
        vm.expectRevert(abi.encodeWithSelector(ILedgers.HasBalance.selector, "100"));
        ledgers.removeSubAccount(r10, "100");
    }

    function testLedgersRemoveSubAccountInvalidAddresses() public {
        vm.startPrank(alice);
        address valid = ledgers.addSubAccount(r1, "validSub", true, false);

        // Zero parent
        vm.expectRevert(ILedgers.ZeroAddress.selector);
        ledgers.removeSubAccount(address(0), "validSub");

        // Parent == child group (nonsense) => InvalidAccountGroup on computed subAddress
        vm.expectRevert(
            abi.encodeWithSelector(ILedgers.InvalidAccountGroup.selector, LLib.toGroupAddress(valid, "validSub"))
        );
        ledgers.removeSubAccount(valid, "validSub");
    }

    function testLedgersRemoveUpdatesSiblingIndices() public {
        vm.startPrank(alice);
        address s1 = ledgers.addSubAccount(r1, "s1", true, false);
        ledgers.addSubAccount(r1, "s2", true, false);
        address s3 = ledgers.addSubAccount(r1, "s3", true, false);

        uint256 before = ledgers.subAccounts(r1).length;
        ledgers.removeSubAccount(r1, "s2");

        address[] memory subs = ledgers.subAccounts(r1);
        assertEq(subs.length, before - 1, "length");
        assertEq(subs[before - 3], s1, "first remains s1");
        assertEq(subs[before - 2], s3, "second becomes s3");

        assertEq(ledgers.subAccountIndex(LLib.toGroupAddress(r1, "s1")), before - 2, "s1 idx");
        assertEq(ledgers.subAccountIndex(LLib.toGroupAddress(r1, "s3")), before - 1, "s3 idx");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parents / roots / hasSubAccount
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgersParents() public view {
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

    function testLedgersHasSubAccount() public view {
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
    function testLedgersMint() public {
        bool isVerbose = false;

        if (isVerbose) {
            console.log("--------------------");
            Tree.debugTree(ledgers, address(router));
            console.log("--------------------");
            Tree.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint address(this): Alice");
        ledgers.mint(address(ledgers), 1000);

        assertEq(ledgers.balanceOf(address(ledgers), alice), 1000, "balanceOf(alice)");
        assertEq(ledgers.totalSupply(address(ledgers)), 1000, "totalSupply");

        if (isVerbose) console.log("Mint token 1: Alice");
        ledgers.mint(r100, 1000);
        assertEq(ledgers.balanceOf(r100, alice), 1000, "balanceOf(r100, alice)");
        assertEq(ledgers.balanceOf(r10, "100"), 1000, 'balanceOf(r10, "100")');
        assertEq(ledgers.balanceOf(r1, "10"), 1000, 'balanceOf(r1, "10")');
        assertEq(ledgers.totalSupply(r1), 1000, "totalSupply(r1)");
    }

    function testLedgersBurn() public {
        vm.startPrank(alice);

        ledgers.mint(address(ledgers), 1000);
        ledgers.burn(address(ledgers), 700);

        assertEq(ledgers.balanceOf(address(ledgers), alice), 300, "balanceOf(alice)");
        assertEq(ledgers.totalSupply(address(ledgers)), 300, "totalSupply");

        ledgers.mint(r100, 1000);
        ledgers.burn(r100, 600);

        assertEq(ledgers.balanceOf(r100, alice), 400, "balanceOf(r100, alice)");
        assertEq(ledgers.balanceOf(r10, "100"), 400, 'balanceOf(r10, "100")');
        assertEq(ledgers.balanceOf(r1, "10"), 400, 'balanceOf(r1, "10")');
        assertEq(ledgers.totalSupply(r1), 400, "totalSupply(r1)");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Transfers / approvals / allowance / transferFrom (routed)
    // ─────────────────────────────────────────────────────────────────────────
    function testLedgersTransfer() public {
        vm.startPrank(alice);

        address routerRoot = address(ledgers);

        // Mint → transfer to bob under the same root
        ledgers.mint(routerRoot, 1000);
        // elm: fromParent = routerRoot, toParent = routerRoot, to = bob
        ledgers.transfer(routerRoot, routerRoot, bob, 700);

        assertEq(ledgers.balanceOf(routerRoot, alice), 300, "alice");
        assertEq(ledgers.balanceOf(routerRoot, bob), 700, "bob");
        assertEq(ledgers.totalSupply(routerRoot), 1000, "supply");

        // Different roots should revert
        vm.expectRevert(abi.encodeWithSelector(ILedgers.DifferentRoots.selector, routerRoot, r1));
        // attempt: fromParent=routerRoot, toParent=r1 (different root)
        ledgers.transfer(routerRoot, r1, bob, 100);
    }

    function testLedgersApproveAndAllowance() public {
        vm.startPrank(alice);

        address routerRoot = address(ledgers);
        ledgers.mint(routerRoot, 1000);

        // approve(ownerParent=routerRoot, spenderParent=routerRoot, spender=bob, amount=100)
        ledgers.approve(routerRoot, routerRoot, bob, 100);

        assertEq(ledgers.allowance(routerRoot, alice, routerRoot, bob), 100, "allowance(alice->bob)");
        assertEq(ledgers.allowance(routerRoot, bob, routerRoot, alice), 0, "allowance(bob->alice)");
        assertEq(ledgers.allowance(routerRoot, bob, routerRoot, bob), 0, "allowance(bob->bob)");
        assertEq(ledgers.allowance(routerRoot, alice, routerRoot, alice), 0, "allowance(alice->alice)");
    }

    function testLedgersTransferFrom() public {
        vm.startPrank(alice);

        ledgers.mint(address(ledgers), 1000);
        ledgers.approve(address(ledgers), address(ledgers), bob, 100);

        vm.startPrank(bob);

        ledgers.transferFrom(address(ledgers), alice, address(ledgers), address(ledgers), bob, 100);

        assertEq(ledgers.balanceOf(address(ledgers), alice), 900, "balanceOf(alice)");
        assertEq(ledgers.balanceOf(address(ledgers), bob), 100, "balanceOf(bob)");
        assertEq(ledgers.totalSupply(address(ledgers)), 1000, "totalSupply()");

        vm.startPrank(alice);

        ledgers.mint(r1, 1000);
        ledgers.approve(r1, r1, bob, 100);

        vm.startPrank(bob);

        ledgers.transferFrom(r1, alice, r1, r10, _100, 100);

        assertEq(ledgers.balanceOf(r1, alice), 900, "balanceOf(_1, alice)");
        assertEq(ledgers.balanceOf(r1, bob), 0, "balanceOf(_1, bob)");
        assertEq(ledgers.balanceOf(r10, _100), 100, "balanceOf(_10, _100)");
        assertEq(ledgers.totalSupply(_1), 1000, "totalSupply(_1)");
    }
}

// import {Module, Lib as MLib} from "../../modules/Module.sol";
// import {Router} from "../../modules/Router.sol";
// import {ILedgers, Ledgers, Lib as LLib} from "../../modules/Ledgers.sol";

// import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
// import {Test, console} from "forge-std/src/Test.sol";

// library Lib {
//     function addressToString(address addr_) internal pure returns (string memory) {
//         bytes32 value = bytes32(uint256(uint160(addr_)));
//         bytes memory alphabet = "0123456789abcdef";

//         bytes memory str = new bytes(42);
//         str[0] = "0";
//         str[1] = "x";
//         for (uint256 i = 0; i < 20; i++) {
//             str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
//             str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
//         }
//         return string(str);
//     }

//     function logTree(Ledgers ledgers, address root, string memory prefix, bool isFirst, bool isLast) internal view {
//         string memory label = ledgers.name(root);
//         bool isGroup = ledgers.isGroup(root);
//         // Print the current node
//         console.log(
//             "%s%s%s",
//             prefix,
//             isFirst ? "" : isLast ? isGroup ? unicode"└─ " : unicode"└● " : isGroup ? unicode"├─ " : unicode"├● ",
//             label
//         );

//         // Update the prefix for subAccount nodes
//         string memory subAccountPrefix = string(abi.encodePacked(prefix, isFirst ? "" : isLast ? "   " : unicode"│  "));

//         // Recursively log subAccounts
//         address[] memory subAccounts = ledgers.subAccounts(root);
//         uint256 subAccountCount = subAccounts.length;
//         // console.log("SubAccount count", subAccountCount);
//         for (uint256 i = 0; i < subAccountCount; i++) {
//             string memory _name = ledgers.name(subAccounts[i]);
//             // console.log("name", _name);
//             logTree(
//                 ledgers,
//                 LLib.toGroupAddress(root, _name),
//                 subAccountPrefix,
//                 false,
//                 i == subAccountCount - 1 // Check if this is the last subAccount
//             );
//         }
//     }

//     function debugTree(Ledgers ledgers, address root) public view {
//         // console.log("Tree Structure:");
//         logTree(ledgers, root, "", true, true);
//     }
// }

// contract TestLedgers is Ledgers {
//     event Deposit(address indexed dst, uint256 wad);
//     event Withdrawal(address indexed src, uint256 wad);

//     constructor(uint8 decimals_, uint8 maxDepth_) Ledgers(decimals_) {}

//     function commands() external pure virtual override returns (bytes4[] memory _commands) {
//         uint256 n;
//         _commands = new bytes4[](25);
//         _commands[n++] = bytes4(keccak256("initializeTestLedgers()"));
//         _commands[n++] = bytes4(keccak256("addSubAccount(address,string,bool,bool)"));
//         _commands[n++] = bytes4(keccak256("removeSubAccount(address,string)"));
//         _commands[n++] = bytes4(keccak256("mint(address,uint256)"));
//         _commands[n++] = bytes4(keccak256("burn(address,uint256)"));
//         _commands[n++] = bytes4(keccak256("addLedger(address,string,string,uint8)"));
//         _commands[n++] = bytes4(keccak256("name(address)"));
//         _commands[n++] = bytes4(keccak256("symbol(address)"));
//         _commands[n++] = bytes4(keccak256("decimals(address)"));
//         _commands[n++] = bytes4(keccak256("root(address)"));
//         _commands[n++] = bytes4(keccak256("parent(address)"));
//         _commands[n++] = bytes4(keccak256("isGroup(address)"));
//         _commands[n++] = bytes4(keccak256("subAccounts(address)"));
//         _commands[n++] = bytes4(keccak256("hasSubAccount(address)"));
//         _commands[n++] = bytes4(keccak256("subAccountIndex(address)"));
//         _commands[n++] = bytes4(keccak256("balanceOf(address,string)"));
//         _commands[n++] = bytes4(keccak256("balanceOf(address,address)"));
//         _commands[n++] = bytes4(keccak256("totalSupply(address)"));
//         _commands[n++] = bytes4(keccak256("transfer(address,address,address,uint256)"));
//         _commands[n++] = bytes4(keccak256("approve(address,address,address,uint256)"));
//         _commands[n++] = bytes4(keccak256("allowance(address,address,address,address)"));
//         _commands[n++] = bytes4(keccak256("transferFrom(address,address,address,address,address,uint256)"));
//         _commands[n++] = bytes4(keccak256("approveWrapper(address,address,address,uint256)"));
//         _commands[n++] = bytes4(keccak256("transferWrapper(address,address,address,uint256)"));
//         _commands[n++] = bytes4(keccak256("transferFromWrapper(address,address,address,address,address,uint256)"));

//         if (n != _commands.length) revert InvalidCommandsLength(n);
//     }

//     // Commands
//     function initializeTestLedgers() external initializer {
//         enforceIsOwner();
//         initializeLedgers_unchained();
//     }

//     function addSubAccount(address parent_, string memory name_, bool isGroup_, bool isCredit_)
//         external
//         returns (address)
//     {
//         return LLib.addSubAccount(parent_, name_, isGroup_, isCredit_);
//     }

//     function removeSubAccount(address parent_, string memory name_) external returns (address) {
//         return LLib.removeSubAccount(parent_, name_);
//     }

//     function addLedger(address token_, string memory name_, string memory symbol_, uint8 decimals_) external {
//         LLib.addLedger(token_, name_, symbol_, decimals_);
//     }

//     function mint(address parent_, uint256 amount_) external {
//         LLib.mint(parent_, msg.sender, amount_);
//     }

//     function burn(address parent_, uint256 _amount) external {
//         LLib.burn(parent_, msg.sender, _amount);
//     }

//     receive() external payable {}
// }

// contract LedgersTest is Test {
//     Router router;
//     TestLedgers ledgers;

//     address alice = address(1);
//     address bob = address(2);
//     address charlie = address(3);

//     address testLedger;

//     // Root
//     address _1 = LLib.toNamedAddress("1");
//     // Depth 1
//     address _10 = LLib.toNamedAddress("10");
//     address _11 = LLib.toNamedAddress("11");
//     // Depth 2
//     address _100 = LLib.toNamedAddress("100");
//     address _101 = LLib.toNamedAddress("101");
//     address _110 = LLib.toNamedAddress("110");
//     address _111 = LLib.toNamedAddress("111");

//     address r1 = LLib.toNamedAddress("1");
//     address r10 = LLib.toGroupAddress(r1, "10");
//     address r11 = LLib.toGroupAddress(r1, "11");
//     address r100 = LLib.toGroupAddress(r10, "100");
//     address r101 = LLib.toGroupAddress(r10, "101");
//     address r110 = LLib.toGroupAddress(r11, "110");
//     address r111 = LLib.toGroupAddress(r11, "111");

//     function setUp() public {
//         bool isVerbose = false;

//         vm.startPrank(alice);
//         ledgers = new TestLedgers(18, 10);
//         router = new Router(alice);
//         router.addModule(address(ledgers));
//         ledgers = TestLedgers(payable(router));

//         if (isVerbose) console.log("Initializing Ledgers");
//         ledgers.initializeTestLedgers();
//         if (isVerbose) console.log("Adding test ledger");
//         testLedger = LLib.toNamedAddress("Test Ledger");
//         ledgers.addLedger(testLedger, "Test Ledger", "TL", 18);

//         if (isVerbose) console.log("Adding subAccounts");
//         ledgers.addSubAccount(
//             ledgers.addSubAccount(ledgers.addSubAccount(testLedger, "1", true, false), "10", true, false),
//             "100",
//             true,
//             false
//         );

//         if (isVerbose) console.log("Adding token 1");
//         ledgers.addLedger(r1, "1", "1", 18);

//         if (isVerbose) console.log("Adding subAccounts for token 1");
//         ledgers.addSubAccount(r1, "10", true, false);
//         ledgers.addSubAccount(r1, "11", true, false);
//         ledgers.addSubAccount(r10, "100", true, false);
//         ledgers.addSubAccount(r10, "101", true, false);
//         ledgers.addSubAccount(r11, "110", true, false);
//         ledgers.addSubAccount(r11, "111", true, false);
//     }

//     error InvalidInitialization();

//     function testLedgersInit() public {
//         bool isVerbose = true;

//         if (isVerbose) console.log("Display Account Hierarchy");
//         if (isVerbose) console.log("--------------------");
//         if (isVerbose) Lib.debugTree(ledgers, address(router));
//         if (isVerbose) console.log("--------------------");
//         if (isVerbose) Lib.debugTree(ledgers, testLedger);
//         if (isVerbose) console.log("--------------------");
//         if (isVerbose) Lib.debugTree(ledgers, r1);
//         if (isVerbose) console.log("--------------------");

//         vm.startPrank(alice);

//         vm.expectRevert(InvalidInitialization.selector);
//         ledgers.initializeTestLedgers();

//         // assertEq(ledgers.name(), "Scale");

//         // assertEq(ledgers.symbol(), unicode"𝑆");

//         // assertEq(ledgers.decimals(), 18, "Decimals mismatch");

//         // assertEq(ledgers.totalSupply(), 0, "Total supply mismatch");

//         // assertEq(ledgers.balanceOf(alice), 0, "Balance mismatch");

//         // assertEq(ledgers.balanceOf(address(ledgers)), 0, "Balance mismatch");

//         assertEq(ledgers.subAccounts(testLedger).length, 1, "Subaccounts mismatch (router)");

//         assertEq(ledgers.subAccounts(r1).length, 2, "Subaccounts mismatch (r1)");

//         assertEq(ledgers.subAccounts(r10).length, 2, "Subaccounts mismatch (r10)");

//         assertEq(ledgers.subAccounts(r11).length, 2, "Subaccounts mismatch (r11)");

//         assertEq(ledgers.subAccountIndex(r1), 0, "SubAccount index mismatch (r1)");

//         assertEq(ledgers.subAccountIndex(r11), 2, "SubAccount index mismatch (r11)");

//         assertEq(ledgers.subAccountIndex(r10), 1, "SubAccount index mismatch (r10)");

//         assertEq(ledgers.subAccountIndex(r100), 1, "SubAccount index mismatch (r100)");

//         assertEq(ledgers.subAccountIndex(r101), 2, "SubAccount index mismatch (r101)");

//         assertEq(ledgers.subAccountIndex(r110), 1, "SubAccount index mismatch (r110)");

//         assertEq(ledgers.subAccountIndex(r111), 2, "SubAccount index mismatch (r111)");
//     }

//     // function testLedgersAddSubAccount() public {
//     //     bool isVerbose = false;

//     //     if (isVerbose) {
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, address(router));
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");
//     //     }

//     //     vm.startPrank(alice);

//     //     if (isVerbose) console.log("Adding a new valid subAccount");
//     //     address added = ledgers.addSubAccount(r1, "newSubAccount", true, false);
//     //     assertEq(added, LLib.toGroupAddress(r1, "newSubAccount"), "addSubAccount address");
//     //     assertEq(ledgers.parent(added), r1, "Parent should be r1");
//     //     assertEq(
//     //         ledgers.subAccountIndex(added),
//     //         ledgers.subAccounts(r1).length,
//     //         "SubAccount index should match subAccounts length"
//     //     );
//     //     assertTrue(ledgers.hasSubAccount(r1), "r1 should have subAccounts");

//     //     if (isVerbose) console.log("Adding a subAccount that already exists");
//     //     setUp();
//     //     ledgers.addSubAccount(r1, "newSubAccount", true, false);

//     //     if (isVerbose) {
//     //         console.log("Adding a subAccount whose parent is address(0)");
//     //     }
//     //     setUp();
//     //     vm.expectRevert(abi.encodeWithSelector(ILedgers.InvalidAccountGroup.selector, address(0)));
//     //     ledgers.addSubAccount(address(0), "zeroParentSubAccount", true, false);

//     //     if (isVerbose) {
//     //         console.log('Adding a subAccount whose name is ""');
//     //     }
//     //     setUp();
//     //     vm.expectRevert(abi.encodeWithSelector(ILedgers.InvalidSubAccount.selector, "", true, false));
//     //     ledgers.addSubAccount(r1, "", true, false);
//     // }

//     // function testLedgersRemoveSubAccount() public {
//     //     bool isVerbose = false;

//     //     vm.startPrank(alice);

//     //     // First run the tree visualization tests
//     //     if (isVerbose) {
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, address(router));
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         console.log("Remove SubAccount 111");
//     //         ledgers.removeSubAccount(r11, "111");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         console.log("Remove SubAccount 110");
//     //         ledgers.removeSubAccount(r11, "110");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         console.log("Remove SubAccount 101");
//     //         ledgers.removeSubAccount(r10, "101");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         console.log("Remove SubAccount 100");
//     //         ledgers.removeSubAccount(r10, "100");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         console.log("Remove SubAccount 11");
//     //         ledgers.removeSubAccount(r1, "11");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         console.log("Remove SubAccount 10");
//     //         ledgers.removeSubAccount(r1, "10");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");

//     //         setUp();
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");
//     //     }

//     //     // Now run the validation tests
//     //     if (isVerbose) {
//     //         console.log("Test 1: Remove a valid subAccount (leaf node)");
//     //     }
//     //     ledgers.addSubAccount(r1, "leafSubAccount", true, false);
//     //     ledgers.removeSubAccount(r1, "leafSubAccount");
//     //     assertEq(ledgers.parent(LLib.toGroupAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
//     //     assertEq(
//     //         ledgers.subAccountIndex(LLib.toGroupAddress(r1, "leafSubAccount")), 0, "SubAccount index should be reset"
//     //     );
//     //     assertEq(ledgers.name(LLib.toGroupAddress(r1, "leafSubAccount")), "", "Name should be cleared");
//     //     assertFalse(ledgers.hasSubAccount(LLib.toGroupAddress(r1, "leafSubAccount")), "Should not have subAccounts");

//     //     if (isVerbose) {
//     //         console.log("Test 2: Remove a subAccount that doesn't exist");
//     //     }
//     //     address nonExistentSubAccount = LLib.toGroupAddress(r1, "nonExistentSubAccount");
//     //     vm.expectRevert(abi.encodeWithSelector(ILedgers.InvalidAccountGroup.selector, nonExistentSubAccount));
//     //     ledgers.removeSubAccount(r1, "nonExistentSubAccount");

//     //     if (isVerbose) {
//     //         console.log("Test 3: Remove a subAccount that has subAccounts");
//     //     }
//     //     address parentWithSubAccount = ledgers.addSubAccount(r1, "parentWithSubAccount", true, false);
//     //     ledgers.addSubAccount(parentWithSubAccount, "subAccountOfParent", true, false);
//     //     vm.expectRevert(abi.encodeWithSelector(ILedgers.HasSubAccount.selector, "parentWithSubAccount"));
//     //     ledgers.removeSubAccount(r1, "parentWithSubAccount");

//     //     if (isVerbose) {
//     //         console.log("Test 4: Remove a subAccount that has a balance");
//     //     }
//     //     ledgers.mint(r100, 1000);
//     //     vm.expectRevert(abi.encodeWithSelector(ILedgers.HasBalance.selector, "100"));
//     //     ledgers.removeSubAccount(r10, "100");

//     //     if (isVerbose) {
//     //         console.log("Test 5: Remove a subAccount with invalid addresses");
//     //     }
//     //     address validSubAccount = ledgers.addSubAccount(r1, "validSubAccount", true, false);

//     //     // Try to remove with address(0) as parent
//     //     vm.expectRevert(ILedgers.ZeroAddress.selector);
//     //     ledgers.removeSubAccount(address(0), "validSubAccount");

//     //     // Try to remove with same address for parent and subAccount
//     //     vm.expectRevert(
//     //         abi.encodeWithSelector(
//     //             ILedgers.InvalidAccountGroup.selector, LLib.toGroupAddress(validSubAccount, "validSubAccount")
//     //         )
//     //     );
//     //     ledgers.removeSubAccount(validSubAccount, "validSubAccount");

//     //     if (isVerbose) {
//     //         console.log("Test 6: Remove a subAccount and verify parent's subAccounts array is updated correctly");
//     //     }
//     //     setUp();
//     //     address subAccount1 = ledgers.addSubAccount(r1, "subAccount1", true, false);
//     //     ledgers.addSubAccount(r1, "subAccount2", true, false);
//     //     address subAccount3 = ledgers.addSubAccount(r1, "subAccount3", true, false);

//     //     uint256 subAccountCount = ledgers.subAccounts(r1).length;

//     //     if (isVerbose) {
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");
//     //     }

//     //     // Remove subAccount2 (middle subAccount)
//     //     ledgers.removeSubAccount(r1, "subAccount2");

//     //     // Verify subAccounts array is updated correctly
//     //     address[] memory subAccounts = ledgers.subAccounts(r1);
//     //     assertEq(subAccounts.length, subAccountCount - 1, "Incorrect number of subAccounts after removal");
//     //     assertEq(subAccounts[subAccountCount - 3], subAccount1, "First subAccount should be subAccount1");
//     //     assertEq(subAccounts[subAccountCount - 2], subAccount3, "Second subAccount should be subAccount3");

//     //     if (isVerbose) console.log("Verify subAccount indices are updated");
//     //     assertEq(
//     //         ledgers.subAccountIndex(LLib.toGroupAddress(r1, "subAccount1")),
//     //         subAccountCount - 2,
//     //         "subAccount1 index incorrect"
//     //     );
//     //     if (isVerbose) {
//     //         console.log("Display subaccounts");
//     //         for (uint256 i = 0; i < subAccounts.length; i++) {
//     //             console.log(
//     //                 "SubAccount", ledgers.name(subAccounts[i]), subAccounts[i], ledgers.subAccountIndex(subAccounts[i])
//     //             );
//     //         }
//     //     }
//     //     assertEq(
//     //         ledgers.subAccountIndex(LLib.toGroupAddress(r1, "subAccount3")),
//     //         subAccountCount - 1,
//     //         "subAccount3 index incorrect"
//     //     );
//     // }

//     // function testLedgersMint() public {
//     //     bool isVerbose = false;

//     //     if (isVerbose) {
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, address(router));
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");
//     //     }

//     //     vm.startPrank(alice);

//     //     if (isVerbose) console.log("Initial mint address(this): Alice");
//     //     ledgers.mint(address(ledgers), 1000);

//     //     assertEq(ledgers.balanceOf(alice), 1000, "balanceOf(alice)");
//     //     assertEq(ledgers.totalSupply(), 1000, "totalSupply");

//     //     if (isVerbose) console.log("Mint token 1: Alice");
//     //     ledgers.mint(r100, 1000);
//     //     assertEq(ledgers.balanceOf(r100, alice), 1000, "balanceOf(r100, alice)");
//     //     assertEq(ledgers.balanceOf(r10, "100"), 1000, 'balanceOf(r10, "100")');
//     //     assertEq(ledgers.balanceOf(r1, "10"), 1000, 'balanceOf(r1, "10")');
//     //     assertEq(ledgers.totalSupply(r1), 1000, "totalSupply(r1)");
//     // }

//     // function testLedgersBurn() public {
//     //     vm.startPrank(alice);

//     //     ledgers.mint(address(ledgers), 1000);
//     //     ledgers.burn(address(ledgers), 700);

//     //     assertEq(ledgers.balanceOf(alice), 300, "balanceOf(alice)");
//     //     assertEq(ledgers.totalSupply(), 300, "totalSupply");

//     //     ledgers.mint(r100, 1000);
//     //     ledgers.burn(r100, 600);

//     //     assertEq(ledgers.balanceOf(r100, alice), 400, "balanceOf(r100, alice)");
//     //     assertEq(ledgers.balanceOf(r10, "100"), 400, 'balanceOf(r10, "100")');
//     //     assertEq(ledgers.balanceOf(r1, "10"), 400, 'balanceOf(r1, "10")');
//     //     assertEq(ledgers.totalSupply(r1), 400, "totalSupply(r1)");
//     // }

//     // function testLedgersParents() public view {
//     //     assertEq(ledgers.root(r10), r1, "root(_10)");
//     //     assertEq(ledgers.root(r11), r1, "root(_11)");
//     //     assertEq(ledgers.root(r100), r1, "root(_100)");
//     //     assertEq(ledgers.root(r101), r1, "root(_101)");
//     //     assertEq(ledgers.root(r110), r1, "root(_110)");
//     //     assertEq(ledgers.root(r111), r1, "root(_111)");

//     //     assertEq(ledgers.parent(r10), r1, "parent(_10)");
//     //     assertEq(ledgers.parent(r11), r1, "parent(_11)");
//     //     assertEq(ledgers.parent(r100), r10, "parent(_100)");
//     //     assertEq(ledgers.parent(r101), r10, "parent(_101)");
//     //     assertEq(ledgers.parent(r110), r11, "parent(_110)");
//     //     assertEq(ledgers.parent(r111), r11, "parent(_111)");
//     // }

//     // function testLedgersHasSubAccount() public view {
//     //     assertTrue(ledgers.hasSubAccount(r1), "hasSubAccount(r1)");
//     //     assertTrue(ledgers.hasSubAccount(r10), "hasSubAccount(r10)");
//     //     assertTrue(ledgers.hasSubAccount(r11), "hasSubAccount(r11)");
//     //     assertFalse(ledgers.hasSubAccount(r100), "hasSubAccount(r100)");
//     //     assertFalse(ledgers.hasSubAccount(r101), "hasSubAccount(r101)");
//     //     assertFalse(ledgers.hasSubAccount(r110), "hasSubAccount(r110)");
//     //     assertFalse(ledgers.hasSubAccount(r111), "hasSubAccount(r111)");
//     // }

//     // function testLedgersTransfer() public {
//     //     bool isVerbose = false;

//     //     if (isVerbose) {
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, address(router));
//     //         console.log("--------------------");
//     //         Lib.debugTree(ledgers, r1);
//     //         console.log("--------------------");
//     //     }

//     //     vm.startPrank(alice);

//     //     if (isVerbose) console.log("Initial mint and transfer");
//     //     ledgers.mint(address(ledgers), 1000);
//     //     ledgers.transfer(bob, 700);

//     //     assertEq(ledgers.balanceOf(address(ledgers)), 0, "balanceOf(this)");
//     //     assertEq(ledgers.balanceOf(alice), 300, "balanceOf(alice)");
//     //     assertEq(ledgers.balanceOf(bob), 700, "balanceOf(bob)");
//     //     assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

//     //     if (isVerbose) console.log("Transfer from alice to bob");
//     //     ledgers.transfer(address(ledgers), address(ledgers), bob, 100);

//     //     assertEq(ledgers.balanceOf(alice), 200, "balanceOf(alice)");
//     //     assertEq(ledgers.balanceOf(bob), 800, "balanceOf(bob)");
//     //     assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

//     //     if (isVerbose) console.log("Expect revert if sender and receiver have different roots");
//     //     vm.expectRevert(abi.encodeWithSelector(ILedgers.DifferentRoots.selector, address(ledgers), r1));
//     //     ledgers.transfer(address(ledgers), _1, _10, 100);
//     // }

//     // function testLedgersApprove() public {
//     //     bool isVerbose = false;

//     //     vm.startPrank(alice);

//     //     if (isVerbose) console.log("Initial mint and approve");
//     //     ledgers.mint(address(ledgers), 1000);
//     //     ledgers.approve(bob, 100);

//     //     assertEq(ledgers.allowance(alice, bob), 100, "allowance(alice, bob)");
//     //     assertEq(ledgers.allowance(bob, alice), 0, "allowance(bob, alice)");
//     //     assertEq(ledgers.allowance(bob, bob), 0, "allowance(bob, bob)");
//     //     assertEq(ledgers.allowance(alice, alice), 0, "allowance(alice, alice)");
//     // }

//     // function testLedgersTransferFrom() public {
//     //     vm.startPrank(alice);

//     //     ledgers.mint(address(ledgers), 1000);
//     //     ledgers.approve(bob, 100);

//     //     vm.startPrank(bob);

//     //     ledgers.transferFrom(alice, bob, 100);

//     //     assertEq(ledgers.balanceOf(alice), 900, "balanceOf(alice)");
//     //     assertEq(ledgers.balanceOf(bob), 100, "balanceOf(bob)");
//     //     assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

//     //     vm.startPrank(alice);

//     //     ledgers.mint(r1, 1000);
//     //     ledgers.approve(r1, r1, bob, 100);

//     //     vm.startPrank(bob);

//     //     ledgers.transferFrom(r1, alice, r1, r10, _100, 100);

//     //     assertEq(ledgers.balanceOf(r1, alice), 900, "balanceOf(_1, alice)");
//     //     assertEq(ledgers.balanceOf(r1, bob), 0, "balanceOf(_1, bob)");
//     //     assertEq(ledgers.balanceOf(r10, _100), 100, "balanceOf(_10, _100)");
//     //     assertEq(ledgers.totalSupply(_1), 1000, "totalSupply(_1)");
//     // }
// }
