// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../../contracts/Router.sol";
import {Ledgers, Lib as LLib, Store} from "../../../contracts/Ledgers/Ledgers.sol";
import {Module, Lib as MLib} from "../../../contracts/Module.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test, console} from "forge-std/src/Test.sol";

library Lib {
    // Selectors
    bytes4 internal constant INITIALIZE_TEST_LEDGERS = bytes4(keccak256("initializeTestLedgers()"));
    bytes4 internal constant ADD_SUBACCOUNT = bytes4(keccak256("addSubAccount(address,string,bool,bool)"));
    bytes4 internal constant REMOVE_SUBACCOUNT = bytes4(keccak256("removeSubAccount(address,string)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
    bytes4 internal constant ADD_LEDGER = bytes4(keccak256("addLedger(address,string,string,uint8)"));

    function addressToString(address addr_) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr_)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function logTree(Ledgers ledgers, address root, string memory prefix, bool isFirst, bool isLast) internal view {
        string memory label = ledgers.name(root);
        bool isGroup = ledgers.isGroup(root);
        // Print the current node
        console.log(
            "%s%s%s",
            prefix,
            isFirst ? "" : isLast ? isGroup ? unicode"└─ " : unicode"└● " : isGroup ? unicode"├─ " : unicode"├● ",
            label
        );

        // Update the prefix for subAccount nodes
        string memory subAccountPrefix = string(abi.encodePacked(prefix, isFirst ? "" : isLast ? "   " : unicode"│  "));

        // Recursively log subAccounts
        address[] memory subAccounts = ledgers.subAccounts(root);
        uint256 subAccountCount = subAccounts.length;
        // console.log("SubAccount count", subAccountCount);
        for (uint256 i = 0; i < subAccountCount; i++) {
            string memory _name = ledgers.name(subAccounts[i]);
            // console.log("name", _name);
            logTree(
                ledgers,
                LLib.toGroupAddress(root, _name),
                subAccountPrefix,
                false,
                i == subAccountCount - 1 // Check if this is the last subAccount
            );
        }
    }

    function debugTree(Ledgers ledgers, address root) public view {
        // console.log("Tree Structure:");
        logTree(ledgers, root, "", true, true);
    }
}

contract TestLedgers is Ledgers {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(uint8 decimals_, uint8 maxDepth_) Ledgers(decimals_) {}

    function commands() public pure virtual override returns (bytes4[] memory _commands) {
        uint256 n;
        _commands = new bytes4[](31);
        _commands[n++] = Lib.INITIALIZE_TEST_LEDGERS;
        _commands[n++] = Lib.ADD_SUBACCOUNT;
        _commands[n++] = Lib.REMOVE_SUBACCOUNT;
        _commands[n++] = Lib.MINT;
        _commands[n++] = Lib.BURN;
        _commands[n++] = Lib.ADD_LEDGER;
        _commands[n++] = LLib.NAME;
        _commands[n++] = LLib.SYMBOL;
        _commands[n++] = LLib.DECIMALS;
        _commands[n++] = LLib.ROOT;
        _commands[n++] = LLib.PARENT;
        _commands[n++] = LLib.IS_GROUP;
        _commands[n++] = LLib.SUBACCOUNTS;
        _commands[n++] = LLib.HAS_SUBACCOUNT;
        _commands[n++] = LLib.SUBACCOUNT_INDEX;
        _commands[n++] = LLib.BASE_NAME;
        _commands[n++] = LLib.BASE_SYMBOL;
        _commands[n++] = LLib.BASE_DECIMALS;
        _commands[n++] = LLib.GROUP_BALANCE_OF;
        _commands[n++] = LLib.BALANCE_OF;
        _commands[n++] = LLib.BASE_BALANCE_OF;
        _commands[n++] = LLib.TOTAL_SUPPLY;
        _commands[n++] = LLib.BASE_TOTAL_SUPPLY;
        _commands[n++] = LLib.TRANSFER;
        _commands[n++] = LLib.BASE_TRANSFER;
        _commands[n++] = LLib.APPROVE;
        _commands[n++] = LLib.BASE_APPROVE;
        _commands[n++] = LLib.ALLOWANCE;
        _commands[n++] = LLib.BASE_ALLOWANCE;
        _commands[n++] = LLib.TRANSFER_FROM;
        _commands[n++] = LLib.BASE_TRANSFER_FROM;
    }

    // Commands
    function initializeTestLedgers() public initializer {
        enforceIsOwner();
        initializeLedgers_unchained();
    }

    function addSubAccount(address parent_, string memory name_, bool isGroup_, bool isCredit_)
        public
        returns (address)
    {
        return LLib.addSubAccount(parent_, name_, isGroup_, isCredit_);
    }

    function removeSubAccount(address parent_, string memory name_) public returns (address) {
        return LLib.removeSubAccount(parent_, name_);
    }

    function addLedger(address token_, string memory name_, string memory symbol_, uint8 decimals_) public {
        LLib.addLedger(token_, name_, symbol_, decimals_);
    }

    function mint(address parent_, uint256 amount_) public {
        LLib.mint(parent_, msg.sender, amount_);
    }

    function burn(address parent_, uint256 _amount) public {
        LLib.burn(parent_, msg.sender, _amount);
    }

    receive() external payable {}
}

contract LedgersTest is Test {
    Router router;
    TestLedgers ledgers;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

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

    address r1 = LLib.toNamedAddress("1");
    address r10 = LLib.toGroupAddress(r1, "10");
    address r11 = LLib.toGroupAddress(r1, "11");
    address r100 = LLib.toGroupAddress(r10, "100");
    address r101 = LLib.toGroupAddress(r10, "101");
    address r110 = LLib.toGroupAddress(r11, "110");
    address r111 = LLib.toGroupAddress(r11, "111");

    function setUp() public {
        bool isVerbose = true;

        vm.startPrank(alice);
        ledgers = new TestLedgers(18, 10);
        router = new Router(alice);
        router.addModule(address(ledgers));
        ledgers = TestLedgers(payable(router));

        if (isVerbose) console.log("Initializing Ledgers");
        ledgers.initializeTestLedgers();
        if (isVerbose) console.log("Adding test ledger");
        testLedger = LLib.toNamedAddress("Test Ledger");
        ledgers.addLedger(testLedger, "Test Ledger", "TL", 18);

        if (isVerbose) console.log("Adding subAccounts");
        ledgers.addSubAccount(
            ledgers.addSubAccount(ledgers.addSubAccount(testLedger, "1", true, false), "10", true, false),
            "100",
            true,
            false
        );

        if (isVerbose) console.log("Adding token 1");
        ledgers.addLedger(r1, "1", "1", 18);

        if (isVerbose) console.log("Adding subAccounts for token 1");
        ledgers.addSubAccount(r1, "10", true, false);
        ledgers.addSubAccount(r1, "11", true, false);
        ledgers.addSubAccount(r10, "100", true, false);
        ledgers.addSubAccount(r10, "101", true, false);
        ledgers.addSubAccount(r11, "110", true, false);
        ledgers.addSubAccount(r11, "111", true, false);
    }

    error InvalidInitialization();

    function testLedgersInit() public {
        bool isVerbose = true;

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        if (isVerbose) Lib.debugTree(ledgers, address(router));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) Lib.debugTree(ledgers, testLedger);
        if (isVerbose) console.log("--------------------");
        if (isVerbose) Lib.debugTree(ledgers, r1);
        if (isVerbose) console.log("--------------------");

        vm.startPrank(alice);

        vm.expectRevert(InvalidInitialization.selector);
        ledgers.initializeTestLedgers();

        assertEq(ledgers.name(), "Scale");

        assertEq(ledgers.symbol(), unicode"𝑆");

        assertEq(ledgers.decimals(), 18, "Decimals mismatch");

        assertEq(ledgers.totalSupply(), 0, "Total supply mismatch");

        assertEq(ledgers.balanceOf(alice), 0, "Balance mismatch");

        assertEq(ledgers.balanceOf(address(ledgers)), 0, "Balance mismatch");

        assertEq(ledgers.subAccounts(testLedger).length, 1, "Subaccounts mismatch (router)");

        assertEq(ledgers.subAccounts(r1).length, 2, "Subaccounts mismatch (r1)");

        assertEq(ledgers.subAccounts(r10).length, 2, "Subaccounts mismatch (r10)");

        assertEq(ledgers.subAccounts(r11).length, 2, "Subaccounts mismatch (r11)");

        assertEq(ledgers.subAccountIndex(r1), 0, "SubAccount index mismatch (r1)");

        assertEq(ledgers.subAccountIndex(r11), 2, "SubAccount index mismatch (r11)");

        assertEq(ledgers.subAccountIndex(r10), 1, "SubAccount index mismatch (r10)");

        assertEq(ledgers.subAccountIndex(r100), 1, "SubAccount index mismatch (r100)");

        assertEq(ledgers.subAccountIndex(r101), 2, "SubAccount index mismatch (r101)");

        assertEq(ledgers.subAccountIndex(r110), 1, "SubAccount index mismatch (r110)");

        assertEq(ledgers.subAccountIndex(r111), 2, "SubAccount index mismatch (r111)");
    }

    function testLedgersAddSubAccount() public {
        bool isVerbose = true;

        if (isVerbose) {
            console.log("--------------------");
            Lib.debugTree(ledgers, address(router));
            console.log("--------------------");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        vm.startPrank(alice);

        if (isVerbose) console.log("Adding a new valid subAccount");
        address added = ledgers.addSubAccount(r1, "newSubAccount", true, false);
        assertEq(added, LLib.toGroupAddress(r1, "newSubAccount"), "addSubAccount address");
        assertEq(ledgers.parent(added), r1, "Parent should be r1");
        assertEq(
            ledgers.subAccountIndex(added),
            ledgers.subAccounts(r1).length,
            "SubAccount index should match subAccounts length"
        );
        assertTrue(ledgers.hasSubAccount(r1), "r1 should have subAccounts");

        if (isVerbose) console.log("Adding a subAccount that already exists");
        setUp();
        ledgers.addSubAccount(r1, "newSubAccount", true, false);

        if (isVerbose) {
            console.log("Adding a subAccount whose parent is address(0)");
        }
        setUp();
        vm.expectRevert(abi.encodeWithSelector(LLib.InvalidAccountGroup.selector, address(0)));
        ledgers.addSubAccount(address(0), "zeroParentSubAccount", true, false);

        if (isVerbose) {
            console.log('Adding a subAccount whose name is ""');
        }
        setUp();
        vm.expectRevert(abi.encodeWithSelector(LLib.InvalidSubAccount.selector, "", true, false));
        ledgers.addSubAccount(r1, "", true, false);
    }

    function testLedgersRemoveSubAccount() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        // First run the tree visualization tests
        if (isVerbose) {
            console.log("--------------------");
            Lib.debugTree(ledgers, address(router));
            console.log("--------------------");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            console.log("Remove SubAccount 111");
            ledgers.removeSubAccount(r11, "111");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            console.log("Remove SubAccount 110");
            ledgers.removeSubAccount(r11, "110");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            console.log("Remove SubAccount 101");
            ledgers.removeSubAccount(r10, "101");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            console.log("Remove SubAccount 100");
            ledgers.removeSubAccount(r10, "100");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            console.log("Remove SubAccount 11");
            ledgers.removeSubAccount(r1, "11");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            console.log("Remove SubAccount 10");
            ledgers.removeSubAccount(r1, "10");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");

            setUp();
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        // Now run the validation tests
        if (isVerbose) {
            console.log("Test 1: Remove a valid subAccount (leaf node)");
        }
        ledgers.addSubAccount(r1, "leafSubAccount", true, false);
        ledgers.removeSubAccount(r1, "leafSubAccount");
        assertEq(ledgers.parent(LLib.toGroupAddress(r1, "leafSubAccount")), address(0), "Parent should be reset");
        assertEq(
            ledgers.subAccountIndex(LLib.toGroupAddress(r1, "leafSubAccount")), 0, "SubAccount index should be reset"
        );
        assertEq(ledgers.name(LLib.toGroupAddress(r1, "leafSubAccount")), "", "Name should be cleared");
        assertFalse(ledgers.hasSubAccount(LLib.toGroupAddress(r1, "leafSubAccount")), "Should not have subAccounts");

        if (isVerbose) {
            console.log("Test 2: Remove a subAccount that doesn't exist");
        }
        address nonExistentSubAccount = LLib.toGroupAddress(r1, "nonExistentSubAccount");
        vm.expectRevert(abi.encodeWithSelector(LLib.InvalidAccountGroup.selector, nonExistentSubAccount));
        ledgers.removeSubAccount(r1, "nonExistentSubAccount");

        if (isVerbose) {
            console.log("Test 3: Remove a subAccount that has subAccounts");
        }
        address parentWithSubAccount = ledgers.addSubAccount(r1, "parentWithSubAccount", true, false);
        ledgers.addSubAccount(parentWithSubAccount, "subAccountOfParent", true, false);
        vm.expectRevert(abi.encodeWithSelector(LLib.HasSubAccount.selector, "parentWithSubAccount"));
        ledgers.removeSubAccount(r1, "parentWithSubAccount");

        if (isVerbose) {
            console.log("Test 4: Remove a subAccount that has a balance");
        }
        ledgers.mint(r100, 1000);
        vm.expectRevert(abi.encodeWithSelector(LLib.HasBalance.selector, "100"));
        ledgers.removeSubAccount(r10, "100");

        if (isVerbose) {
            console.log("Test 5: Remove a subAccount with invalid addresses");
        }
        address validSubAccount = ledgers.addSubAccount(r1, "validSubAccount", true, false);

        // Try to remove with address(0) as parent
        vm.expectRevert(LLib.ZeroAddress.selector);
        ledgers.removeSubAccount(address(0), "validSubAccount");

        // Try to remove with same address for parent and subAccount
        vm.expectRevert(
            abi.encodeWithSelector(
                LLib.InvalidAccountGroup.selector, LLib.toGroupAddress(validSubAccount, "validSubAccount")
            )
        );
        ledgers.removeSubAccount(validSubAccount, "validSubAccount");

        if (isVerbose) {
            console.log("Test 6: Remove a subAccount and verify parent's subAccounts array is updated correctly");
        }
        setUp();
        address subAccount1 = ledgers.addSubAccount(r1, "subAccount1", true, false);
        ledgers.addSubAccount(r1, "subAccount2", true, false);
        address subAccount3 = ledgers.addSubAccount(r1, "subAccount3", true, false);

        uint256 subAccountCount = ledgers.subAccounts(r1).length;

        if (isVerbose) {
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        // Remove subAccount2 (middle subAccount)
        ledgers.removeSubAccount(r1, "subAccount2");

        // Verify subAccounts array is updated correctly
        address[] memory subAccounts = ledgers.subAccounts(r1);
        assertEq(subAccounts.length, subAccountCount - 1, "Incorrect number of subAccounts after removal");
        assertEq(subAccounts[subAccountCount - 3], subAccount1, "First subAccount should be subAccount1");
        assertEq(subAccounts[subAccountCount - 2], subAccount3, "Second subAccount should be subAccount3");

        if (isVerbose) console.log("Verify subAccount indices are updated");
        assertEq(
            ledgers.subAccountIndex(LLib.toGroupAddress(r1, "subAccount1")),
            subAccountCount - 2,
            "subAccount1 index incorrect"
        );
        if (isVerbose) {
            console.log("Display subaccounts");
            for (uint256 i = 0; i < subAccounts.length; i++) {
                console.log(
                    "SubAccount", ledgers.name(subAccounts[i]), subAccounts[i], ledgers.subAccountIndex(subAccounts[i])
                );
            }
        }
        assertEq(
            ledgers.subAccountIndex(LLib.toGroupAddress(r1, "subAccount3")),
            subAccountCount - 1,
            "subAccount3 index incorrect"
        );
    }

    function testLedgersMint() public {
        bool isVerbose = false;

        if (isVerbose) {
            console.log("--------------------");
            Lib.debugTree(ledgers, address(router));
            console.log("--------------------");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint address(this): Alice");
        ledgers.mint(address(ledgers), 1000);

        assertEq(ledgers.balanceOf(alice), 1000, "balanceOf(alice)");
        assertEq(ledgers.totalSupply(), 1000, "totalSupply");

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

        assertEq(ledgers.balanceOf(alice), 300, "balanceOf(alice)");
        assertEq(ledgers.totalSupply(), 300, "totalSupply");

        ledgers.mint(r100, 1000);
        ledgers.burn(r100, 600);

        assertEq(ledgers.balanceOf(r100, alice), 400, "balanceOf(r100, alice)");
        assertEq(ledgers.balanceOf(r10, "100"), 400, 'balanceOf(r10, "100")');
        assertEq(ledgers.balanceOf(r1, "10"), 400, 'balanceOf(r1, "10")');
        assertEq(ledgers.totalSupply(r1), 400, "totalSupply(r1)");
    }

    function testLedgersParents() public view {
        assertEq(ledgers.root(r10), r1, "root(_10)");
        assertEq(ledgers.root(r11), r1, "root(_11)");
        assertEq(ledgers.root(r100), r1, "root(_100)");
        assertEq(ledgers.root(r101), r1, "root(_101)");
        assertEq(ledgers.root(r110), r1, "root(_110)");
        assertEq(ledgers.root(r111), r1, "root(_111)");

        assertEq(ledgers.parent(r10), r1, "parent(_10)");
        assertEq(ledgers.parent(r11), r1, "parent(_11)");
        assertEq(ledgers.parent(r100), r10, "parent(_100)");
        assertEq(ledgers.parent(r101), r10, "parent(_101)");
        assertEq(ledgers.parent(r110), r11, "parent(_110)");
        assertEq(ledgers.parent(r111), r11, "parent(_111)");
    }

    function testLedgersHasSubAccount() public view {
        assertTrue(ledgers.hasSubAccount(r1), "hasSubAccount(r1)");
        assertTrue(ledgers.hasSubAccount(r10), "hasSubAccount(r10)");
        assertTrue(ledgers.hasSubAccount(r11), "hasSubAccount(r11)");
        assertFalse(ledgers.hasSubAccount(r100), "hasSubAccount(r100)");
        assertFalse(ledgers.hasSubAccount(r101), "hasSubAccount(r101)");
        assertFalse(ledgers.hasSubAccount(r110), "hasSubAccount(r110)");
        assertFalse(ledgers.hasSubAccount(r111), "hasSubAccount(r111)");
    }

    function testLedgersTransfer() public {
        bool isVerbose = false;

        if (isVerbose) {
            console.log("--------------------");
            Lib.debugTree(ledgers, address(router));
            console.log("--------------------");
            Lib.debugTree(ledgers, r1);
            console.log("--------------------");
        }

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint and transfer");
        ledgers.mint(address(ledgers), 1000);
        ledgers.transfer(bob, 700);

        assertEq(ledgers.balanceOf(address(ledgers)), 0, "balanceOf(this)");
        assertEq(ledgers.balanceOf(alice), 300, "balanceOf(alice)");
        assertEq(ledgers.balanceOf(bob), 700, "balanceOf(bob)");
        assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

        if (isVerbose) console.log("Transfer from alice to bob");
        ledgers.transfer(address(ledgers), address(ledgers), bob, 100);

        assertEq(ledgers.balanceOf(alice), 200, "balanceOf(alice)");
        assertEq(ledgers.balanceOf(bob), 800, "balanceOf(bob)");
        assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

        if (isVerbose) console.log("Expect revert if sender and receiver have different roots");
        vm.expectRevert(abi.encodeWithSelector(LLib.DifferentRoots.selector, address(ledgers), r1));
        ledgers.transfer(address(ledgers), _1, _10, 100);
    }

    function testLedgersApprove() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Initial mint and approve");
        ledgers.mint(address(ledgers), 1000);
        ledgers.approve(bob, 100);

        assertEq(ledgers.allowance(alice, bob), 100, "allowance(alice, bob)");
        assertEq(ledgers.allowance(bob, alice), 0, "allowance(bob, alice)");
        assertEq(ledgers.allowance(bob, bob), 0, "allowance(bob, bob)");
        assertEq(ledgers.allowance(alice, alice), 0, "allowance(alice, alice)");
    }

    function testLedgersTransferFrom() public {
        vm.startPrank(alice);

        ledgers.mint(address(ledgers), 1000);
        ledgers.approve(bob, 100);

        vm.startPrank(bob);

        ledgers.transferFrom(alice, bob, 100);

        assertEq(ledgers.balanceOf(alice), 900, "balanceOf(alice)");
        assertEq(ledgers.balanceOf(bob), 100, "balanceOf(bob)");
        assertEq(ledgers.totalSupply(), 1000, "totalSupply()");

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
