// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../../contracts/Router.sol";
import {Multitoken, Lib as MTLib, Store} from "../../../contracts/Ledgers/Ledgers.sol";
import {Module, Lib as MLib} from "../../../contracts/Module.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test, console} from "forge-std/src/Test.sol";

library Lib {
    // Selectors
    bytes4 internal constant INITIALIZE_TEST_TOKEN =
        bytes4(keccak256("initializeTestMultitoken(string,string)"));
    bytes4 internal constant ADD_SUBACCOUNT =
        bytes4(keccak256("addSubAccount(string,address,address)"));
    bytes4 internal constant REMOVE_SUBACCOUNT =
        bytes4(keccak256("removeSubAccount(address,address)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
    bytes4 internal constant ADD_TOKEN_SOURCE =
        bytes4(keccak256("addTokenSource(string,address)"));
    bytes4 internal constant REMOVE_TOKEN_SOURCE =
        bytes4(keccak256("removeTokenSource(string,address)"));
    bytes4 internal constant ADD_TOKEN =
        bytes4(keccak256("addToken(address,string,string,uint8)"));

    function addressToString(
        address addr_
    ) internal pure returns (string memory) {
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

    function logTree(
        Multitoken mt,
        address root,
        string memory prefix,
        bool isFirst,
        bool isLast
    ) internal view {
        string memory label = mt.name(root);
        // Print the current node
        console.log(
            "%s%s%s",
            prefix,
            isFirst ? "" : isLast ? unicode"└─ " : unicode"├─ ",
            label
        );

        // Update the prefix for subAccount nodes
        string memory subAccountPrefix = string(
            abi.encodePacked(
                prefix,
                isFirst ? "" : isLast ? "   " : unicode"│  "
            )
        );

        // Recursively log subAccounts
        address[] memory subAccounts = mt.subAccounts(root);
        uint256 subAccountCount = subAccounts.length;
        // console.log("SubAccount count", subAccountCount);
        for (uint256 i = 0; i < subAccountCount; i++) {
            logTree(
                mt,
                MTLib.toAddress(root, subAccounts[i]),
                subAccountPrefix,
                false,
                i == subAccountCount - 1 // Check if this is the last subAccount
            );
        }
    }

    function debugTree(Multitoken mt, address root) public view {
        // console.log("Tree Structure:");
        logTree(mt, root, "", true, true);
    }
}

contract TestMultitoken is Multitoken {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(uint8 decimals_, uint8 maxDepth_) Multitoken(decimals_) {}

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](32);
        _commands[0] = Lib.INITIALIZE_TEST_TOKEN;
        _commands[1] = MTLib.SET_NAME;
        _commands[2] = MTLib.SET_SYMBOL;
        _commands[3] = MTLib.GET_ROOT;
        _commands[4] = MTLib.GET_NAME;
        _commands[5] = MTLib.GET_SYMBOL;
        _commands[6] = MTLib.GET_DECIMALS;
        _commands[7] = MTLib.GET_PARENTACCOUNT;
        _commands[8] = MTLib.GET_SUBACCOUNTS;
        _commands[9] = MTLib.GET_HAS_SUBACCOUNT;
        _commands[10] = MTLib.GET_SUBACCOUNT_INDEX;
        _commands[11] = MTLib.GET_BASE_NAME;
        _commands[12] = MTLib.GET_BASE_SYMBOL;
        _commands[13] = MTLib.GET_BASE_DECIMALS;
        _commands[14] = MTLib.BALANCE_OF;
        _commands[15] = MTLib.BASE_BALANCE_OF;
        _commands[16] = MTLib.TOTAL_SUPPLY;
        _commands[17] = MTLib.BASE_TOTAL_SUPPLY;
        _commands[18] = MTLib.TRANSFER;
        _commands[19] = MTLib.BASE_TRANSFER;
        _commands[20] = MTLib.APPROVE;
        _commands[21] = MTLib.BASE_APPROVE;
        _commands[22] = MTLib.ALLOWANCE;
        _commands[23] = MTLib.TRANSFER_FROM;
        _commands[24] = MTLib.BASE_TRANSFER_FROM;
        _commands[25] = Lib.ADD_SUBACCOUNT;
        _commands[26] = Lib.REMOVE_SUBACCOUNT;
        _commands[27] = Lib.MINT;
        _commands[28] = Lib.BURN;
        _commands[29] = Lib.ADD_TOKEN_SOURCE;
        _commands[30] = Lib.REMOVE_TOKEN_SOURCE;
        _commands[31] = Lib.ADD_TOKEN;
    }

    // Commands
    function initializeTestMultitoken(
        string memory name_,
        string memory symbol_
    ) public initializer {
        enforceIsOwner();
        initializeMultitoken_unchained(name_, symbol_);
    }

    function addSubAccount(
        string memory name_,
        address parentAccount_,
        address subAccount_
    ) public returns (address) {
        return MTLib.addSubAccount(name_, parentAccount_, subAccount_);
    }

    function removeSubAccount(
        address parentAccount_,
        address subAccount_
    ) public returns (address) {
        return MTLib.removeSubAccount(parentAccount_, subAccount_);
    }

    function addTokenSource(
        string memory appName_,
        address tokenAddress_
    ) public {
        MTLib.addTokenSource(appName_, tokenAddress_);
    }

    function removeTokenSource(
        string memory appName_,
        address tokenAddress_
    ) public {
        MTLib.removeTokenSource(appName_, tokenAddress_);
    }

    function addToken(
        address tokenAddress_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        MTLib.addToken(tokenAddress_, name_, symbol_, decimals_);
    }

    function mint(address parentAccountAddress_, uint256 amount_) public {
        MTLib.mint(parentAccountAddress_, msg.sender, amount_);
    }

    function burn(address parentAccountAddress_, uint256 _amount) public {
        MTLib.burn(parentAccountAddress_, msg.sender, _amount);
    }

    receive() external payable {}
}

contract MultitokenTest is Test {
    Router router;
    TestMultitoken mt;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    // Root
    address _1 = MTLib.toAddress("1");
    // Depth 1
    address _10 = MTLib.toAddress("10");
    address _11 = MTLib.toAddress("11");
    // Depth 2
    address _100 = MTLib.toAddress("100");
    address _101 = MTLib.toAddress("101");
    address _110 = MTLib.toAddress("110");
    address _111 = MTLib.toAddress("111");

    address r1 = _1;
    address r10 = MTLib.toAddress(r1, _10);
    address r11 = MTLib.toAddress(r1, _11);
    address r100 = MTLib.toAddress(r10, _100);
    address r101 = MTLib.toAddress(r10, _101);
    address r110 = MTLib.toAddress(r11, _110);
    address r111 = MTLib.toAddress(r11, _111);

    function setUp() public {
        bool isVerbose = false;

        vm.startPrank(alice);
        mt = new TestMultitoken(18, 10);
        router = new Router(alice);
        router.addModule(address(mt));
        mt = TestMultitoken(payable(router));

        if (isVerbose) console.log("Initializing Multitoken");
        mt.initializeTestMultitoken("Test Multitoken", "MULTI");

        if (isVerbose) console.log("Adding subAccounts");
        mt.addSubAccount(
            "100",
            mt.addSubAccount(
                "10",
                mt.addSubAccount("1", address(router), _1),
                _10
            ),
            _100
        );
        if (isVerbose) console.log("Adding token sources");
        mt.addTokenSource("Source", address(router));

        if (isVerbose) console.log("Adding tokens");
        mt.addToken(r1, "1", "1", 18);

        if (isVerbose) console.log("Adding subAccounts for 1");
        mt.addSubAccount("10", r1, _10);
        mt.addSubAccount("11", r1, _11);
        mt.addSubAccount("100", r10, _100);
        mt.addSubAccount("101", r10, _101);
        mt.addSubAccount("110", r11, _110);
        mt.addSubAccount("111", r11, _111);
    }

    error InvalidInitialization();

    function testMultitokenInit() public {
        console.log("--------------------");
        Lib.debugTree(mt, address(router));
        console.log("--------------------");
        Lib.debugTree(mt, r1);
        console.log("--------------------");

        vm.startPrank(alice);

        vm.expectRevert(InvalidInitialization.selector);
        mt.initializeTestMultitoken("Clone", "CLONE");

        assertEq(mt.name(), "Test Multitoken");

        assertEq(mt.symbol(), "MULTI");

        assertEq(mt.decimals(), 18, "Decimals mismatch");

        assertEq(mt.totalSupply(), 0, "Total supply mismatch");

        assertEq(mt.balanceOf(alice), 0, "Balance mismatch");

        assertEq(mt.balanceOf(address(mt)), 0, "Balance mismatch");

        assertEq(
            mt.parentAccount(
                MTLib.toAddress(address(router), MTLib.TOTAL_ADDRESS)
            ),
            address(router),
            "Parent mismatch"
        );

        assertEq(
            mt.subAccounts(address(router)).length,
            2,
            "Subaccounts mismatch (router)"
        );

        assertEq(mt.subAccounts(r1).length, 3, "Subaccounts mismatch (r1)");

        assertEq(mt.subAccounts(r10).length, 2, "Subaccounts mismatch (r10)");

        assertEq(mt.subAccounts(r11).length, 2, "Subaccounts mismatch (r11)");

        assertEq(mt.subAccountIndex(r1), 0, "SubAccount index mismatch (r1)");

        assertEq(mt.subAccountIndex(r11), 3, "SubAccount index mismatch (r11)");

        assertEq(mt.subAccountIndex(r10), 2, "SubAccount index mismatch (r10)");

        assertEq(
            mt.subAccountIndex(r100),
            1,
            "SubAccount index mismatch (r100)"
        );

        assertEq(
            mt.subAccountIndex(r101),
            2,
            "SubAccount index mismatch (r101)"
        );

        assertEq(
            mt.subAccountIndex(r110),
            1,
            "SubAccount index mismatch (r110)"
        );

        assertEq(
            mt.subAccountIndex(r111),
            2,
            "SubAccount index mismatch (r111)"
        );
    }

    function testMultitokenTokenSource() public {
        vm.startPrank(alice);

        // address _appAddress2 = MTLib.toAddress("Test Application 2");
        // vm.expectRevert(
        //     abi.encodeWithSelector(MTLib.SubAccountNotFound.selector, _appAddress2)
        // );
        // mt.removeTokenSource("Test Application 2", address(router));

        mt.addTokenSource("Test Application 2", address(router));
        address _rawAppAddress = MTLib.toAddress(
            MTLib.toAddress(address(router), MTLib.TOTAL_ADDRESS),
            MTLib.toAddress("Test Application 2")
        );
        assertEq(
            mt.parentAccount(_rawAppAddress),
            MTLib.toAddress(address(router), MTLib.TOTAL_ADDRESS),
            "Parent"
        );

        mt.removeTokenSource("Test Application 2", address(router));
        assertEq(mt.parentAccount(_rawAppAddress), address(0), "Parent");
    }

    function testMultitokenAddSubAccount() public {
        vm.startPrank(alice);

        bool isVerbose = true;

        if (isVerbose) console.log("Adding a new valid subAccount");
        address newSubAccount = MTLib.toAddress("newSubAccount");
        address added = mt.addSubAccount("newSubAccount", r1, newSubAccount);
        assertEq(
            added,
            MTLib.toAddress(r1, newSubAccount),
            "addSubAccount address"
        );
        assertEq(mt.parentAccount(added), r1, "Parent should be r1");
        assertEq(
            mt.subAccountIndex(added),
            mt.subAccounts(r1).length,
            "SubAccount index should match subAccounts length"
        );
        assertTrue(mt.hasSubAccount(r1), "r1 should have subAccounts");

        if (isVerbose) console.log("Adding a subAccount that already exists");
        setUp();
        mt.addSubAccount("newSubAccount", r1, newSubAccount);

        if (isVerbose)
            console.log("Adding a subAccount whose parentAccount is itself");
        setUp();
        address selfSubAccount = MTLib.toAddress("selfSubAccount");
        vm.expectRevert(MTLib.InvalidAddress.selector);
        mt.addSubAccount("selfSubAccount", selfSubAccount, selfSubAccount);

        if (isVerbose)
            console.log(
                "Adding a subAccount whose parentAccount is address(0)"
            );
        setUp();
        address zeroParentSubAccount = MTLib.toAddress("zeroParentSubAccount");
        vm.expectRevert(MTLib.InvalidAddress.selector);
        mt.addSubAccount(
            "zeroParentSubAccount",
            address(0),
            zeroParentSubAccount
        );

        if (isVerbose)
            console.log("Adding a subAccount whose address is address(0)");
        setUp();
        vm.expectRevert(MTLib.InvalidAddress.selector);
        mt.addSubAccount("zeroSubAccount", r1, address(0));

        // if (isVerbose)
        //     console.log("Adding a subAccount that already has subAccounts");
        // setUp();
        // // First add a parentAccount and its subAccount
        // address parentAccountWithSubAccount = MTLib.toAddress("parentAccountWithSubAccount");
        // mt.name(parentAccountWithSubAccount, "parentAccountWithSubAccount");
        // address subAccountOfParent = MTLib.toAddress("subAccountOfParent");
        // mt.addSubAccount("subAccountOfParent", parentAccountWithSubAccount, subAccountOfParent);
        // vm.expectRevert(
        //     abi.encodeWithSelector(MTLib.HasSubAccount.selector, "parentAccountWithSubAccount")
        // );
        // mt.addSubAccount("parentAccountWithSubAccount", r1, parentAccountWithSubAccount);

        if (isVerbose)
            console.log(
                "Adding a subAccount whose parentAccount holds a balance"
            );
        setUp();
        address parentAccountWithBalance = mt.addSubAccount(
            "parentAccountWithBalance",
            r1,
            MTLib.toAddress("parentAccountWithBalance")
        );
        mt.mint(parentAccountWithBalance, 1000);
        address subAccountOfParentWithBalance = MTLib.toAddress(
            "subAccountOfParentWithBalance"
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.HasBalance.selector,
                "parentAccountWithBalance"
            )
        );
        mt.addSubAccount(
            "subAccountOfParentWithBalance",
            parentAccountWithBalance,
            subAccountOfParentWithBalance
        );

        if (isVerbose) console.log("Adding a subAccount that holds a balance");
        setUp();
        // First add a subAccount
        address subAccountWithBalance = MTLib.toAddress(
            "subAccountWithBalance"
        );
        mt.addSubAccount("subAccountWithBalance", r1, subAccountWithBalance);
        // Mint tokens to the subAccount
        mt.mint(MTLib.toAddress(r1, subAccountWithBalance), 500);
        // Try to add another subAccount to the subAccount with balance
        address grandSubAccount = MTLib.toAddress("grandSubAccount");
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.HasBalance.selector,
                "subAccountWithBalance"
            )
        );
        mt.addSubAccount(
            "grandSubAccount",
            MTLib.toAddress(r1, subAccountWithBalance),
            grandSubAccount
        );
    }

    function testMultitokenRemoveSubAccount() public {
        vm.startPrank(alice);

        bool isVerbose = false;

        // First run the tree visualization tests
        if (isVerbose) {
            console.log("--------------------");
            Lib.debugTree(mt, address(router));
            console.log("--------------------");
            Lib.debugTree(mt, r1);
            console.log("--------------------");

            mt.removeSubAccount(r11, _111);
            Lib.debugTree(mt, r1);
            console.log("--------------------");

            mt.removeSubAccount(r11, _110);
            Lib.debugTree(mt, r1);
            console.log("--------------------");

            mt.removeSubAccount(r10, _101);
            Lib.debugTree(mt, r1);
            console.log("--------------------");
            mt.removeSubAccount(r10, _100);
            Lib.debugTree(mt, r1);
            console.log("--------------------");
            mt.removeSubAccount(r1, _11);
            Lib.debugTree(mt, r1);
            console.log("--------------------");
            mt.removeSubAccount(r1, _10);
            Lib.debugTree(mt, r1);
            console.log("--------------------");

            setUp();
            Lib.debugTree(mt, r1);
            console.log("--------------------");
        }

        // Now run the validation tests
        if (isVerbose)
            console.log("Test 1: Remove a valid subAccount (leaf node)");
        address leafSubAccount = MTLib.toAddress("leafSubAccount");
        mt.addSubAccount("leafSubAccount", r1, leafSubAccount);
        mt.removeSubAccount(r1, leafSubAccount);
        assertEq(
            mt.parentAccount(MTLib.toAddress(r1, leafSubAccount)),
            address(0),
            "Parent should be reset"
        );
        assertEq(
            mt.subAccountIndex(MTLib.toAddress(r1, leafSubAccount)),
            0,
            "SubAccount index should be reset"
        );
        assertEq(
            mt.name(MTLib.toAddress(r1, leafSubAccount)),
            "",
            "Name should be cleared"
        );
        assertFalse(
            mt.hasSubAccount(MTLib.toAddress(r1, leafSubAccount)),
            "Should not have subAccounts"
        );

        if (isVerbose)
            console.log("Test 2: Remove a subAccount that doesn't exist");
        address nonExistentSubAccount = MTLib.toAddress(
            "nonExistentSubAccount"
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.SubAccountNotFound.selector,
                nonExistentSubAccount
            )
        );
        mt.removeSubAccount(r1, nonExistentSubAccount);

        if (isVerbose)
            console.log("Test 3: Remove a subAccount that has subAccounts");
        address parentAccountWithSubAccount = mt.addSubAccount(
            "parentAccountWithSubAccount",
            r1,
            MTLib.toAddress("parentAccountWithSubAccount")
        );
        address subAccountOfParent = MTLib.toAddress("subAccountOfParent");
        mt.addSubAccount(
            "subAccountOfParent",
            parentAccountWithSubAccount,
            subAccountOfParent
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.HasSubAccount.selector,
                "parentAccountWithSubAccount"
            )
        );
        mt.removeSubAccount(r1, MTLib.toAddress("parentAccountWithSubAccount"));

        if (isVerbose)
            console.log("Test 4: Remove a subAccount that has a balance");
        address subAccountWithBalance = MTLib.toAddress(
            "subAccountWithBalance"
        );
        mt.addSubAccount("subAccountWithBalance", r1, subAccountWithBalance);
        mt.mint(MTLib.toAddress(r1, subAccountWithBalance), 1000);
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.HasBalance.selector,
                "subAccountWithBalance"
            )
        );
        mt.removeSubAccount(r1, subAccountWithBalance);

        if (isVerbose)
            console.log("Test 5: Remove a subAccount with invalid addresses");
        address validSubAccount = MTLib.toAddress("validSubAccount");
        mt.addSubAccount("validSubAccount", r1, validSubAccount);

        // Try to remove with address(0) as parentAccount
        vm.expectRevert(MTLib.InvalidAddress.selector);
        mt.removeSubAccount(address(0), validSubAccount);

        // Try to remove with address(0) as subAccount
        vm.expectRevert(MTLib.InvalidAddress.selector);
        mt.removeSubAccount(r1, address(0));

        // Try to remove with same address for parentAccount and subAccount
        vm.expectRevert(MTLib.InvalidAddress.selector);
        mt.removeSubAccount(validSubAccount, validSubAccount);

        if (isVerbose) {
            console.log(
                "Test 6: Remove a subAccount that's not a subAccount of the specified parentAccount"
            );
        }
        address subAccountOfR1 = MTLib.toAddress("subAccountOfR1");
        address subAccountOfR10 = MTLib.toAddress("subAccountOfR10");
        mt.addSubAccount("subAccountOfR1", r1, subAccountOfR1);
        mt.addSubAccount("subAccountOfR10", r10, subAccountOfR10);

        // Try to remove subAccountOfR10 using r1 as parentAccount
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.SubAccountNotFound.selector,
                subAccountOfR10
            )
        );
        mt.removeSubAccount(r1, subAccountOfR10);

        if (isVerbose) {
            console.log(
                "Test 7: Remove a subAccount and verify parentAccount's subAccounts array is updated correctly"
            );
        }
        setUp();
        address subAccount1 = MTLib.toAddress("subAccount1");
        address subAccount2 = MTLib.toAddress("subAccount2");
        address subAccount3 = MTLib.toAddress("subAccount3");
        mt.addSubAccount("subAccount1", r1, subAccount1);
        mt.addSubAccount("subAccount2", r1, subAccount2);
        mt.addSubAccount("subAccount3", r1, subAccount3);

        uint256 subAccountCount = mt.subAccounts(r1).length;

        if (isVerbose) {
            Lib.debugTree(mt, r1);
            console.log("--------------------");
        }

        // Remove subAccount2 (middle subAccount)
        mt.removeSubAccount(r1, subAccount2);

        // Verify subAccounts array is updated correctly
        address[] memory subAccounts = mt.subAccounts(r1);
        assertEq(
            subAccounts.length,
            subAccountCount - 1,
            "Incorrect number of subAccounts after removal"
        );
        assertEq(
            subAccounts[subAccountCount - 3],
            subAccount1,
            "First subAccount should be subAccount1"
        );
        assertEq(
            subAccounts[subAccountCount - 2],
            subAccount3,
            "Second subAccount should be subAccount3"
        );

        // Verify subAccount indices are updated
        assertEq(
            mt.subAccountIndex(MTLib.toAddress(r1, subAccount1)),
            subAccountCount - 2,
            "subAccount1 index incorrect"
        );
        if (isVerbose) {
            for (uint256 i = 0; i < subAccounts.length; i++) {
                console.log(
                    "SubAccount",
                    mt.name(MTLib.toAddress(r1, subAccounts[i])),
                    subAccounts[i],
                    mt.subAccountIndex(MTLib.toAddress(r1, subAccounts[i]))
                );
            }
        }
        assertEq(
            mt.subAccountIndex(MTLib.toAddress(r1, subAccount3)),
            subAccountCount - 1,
            "subAccount3 index incorrect"
        );
    }

    function testMultitokenMint() public {
        vm.startPrank(alice);

        console.log("Initial mint address(this): Alice");
        mt.mint(address(mt), 1000);

        assertEq(mt.balanceOf(address(mt)), 0, "balanceOf(address(this))");
        assertEq(mt.balanceOf(alice), 1000, "balanceOf(alice)");
        assertEq(mt.totalSupply(), 1000, "totalSupply");

        console.log("Mint token 1: Alice");
        mt.mint(_1, 1000);
        assertEq(mt.balanceOf(_1, alice), 1000, "balanceOf(_1, alice)");
        assertEq(mt.totalSupply(_1), 1000, "totalSupply(_1)");

        vm.startPrank(_100);

        // console.log("Mint token 1: 100");
        mt.mint(r10, 1000);

        assertEq(mt.balanceOf(r10, _100), 1000, "balanceOf(r10, _100)");
        assertEq(mt.balanceOf(r1, _10), 1000, "balanceOf(r1, _10)");
        assertEq(mt.totalSupply(r1), 2000, "totalSupply(_1)");
    }

    function testMultitokenBurn() public {
        vm.startPrank(alice);

        mt.mint(address(mt), 1000);
        mt.burn(address(mt), 700);

        assertEq(mt.balanceOf(address(mt)), 0, "balanceOf(address(this))");
        assertEq(mt.balanceOf(alice), 300, "balanceOf(alice)");
        assertEq(mt.totalSupply(), 300, "totalSupply");

        mt.mint(_1, 1000);
        mt.burn(_1, 700);

        assertEq(mt.balanceOf(_100), 0, "balanceOf(_1)");
        assertEq(mt.balanceOf(_1, alice), 300, "balanceOf(_1, alice)");
        assertEq(mt.totalSupply(_1), 300, "totalSupply(_1)");
    }

    function testMultitokenParents() public view {
        assertEq(mt.root(r10), r1, "root(_10)");
        assertEq(mt.root(r11), r1, "root(_11)");
        assertEq(mt.root(r100), r1, "root(_100)");
        assertEq(mt.root(r101), r1, "root(_101)");
        assertEq(mt.root(r110), r1, "root(_110)");
        assertEq(mt.root(r111), r1, "root(_111)");

        assertEq(mt.parentAccount(r10), r1, "parentAccount(_10)");
        assertEq(mt.parentAccount(r11), r1, "parentAccount(_11)");
        assertEq(mt.parentAccount(r100), r10, "parentAccount(_100)");
        assertEq(mt.parentAccount(r101), r10, "parentAccount(_101)");
        assertEq(mt.parentAccount(r110), r11, "parentAccount(_110)");
        assertEq(mt.parentAccount(r111), r11, "parentAccount(_111)");
    }

    function testMultitokenHasSubAccount() public view {
        assertTrue(mt.hasSubAccount(r1), "hasSubAccount(r1)");
        assertTrue(mt.hasSubAccount(r10), "hasSubAccount(r10)");
        assertTrue(mt.hasSubAccount(r11), "hasSubAccount(r11)");
        assertFalse(mt.hasSubAccount(r100), "hasSubAccount(r100)");
        assertFalse(mt.hasSubAccount(r101), "hasSubAccount(r101)");
        assertFalse(mt.hasSubAccount(r110), "hasSubAccount(r110)");
        assertFalse(mt.hasSubAccount(r111), "hasSubAccount(r111)");
    }

    function testMultitokenTransfer() public {
        vm.startPrank(alice);

        mt.mint(address(mt), 1000);
        mt.transfer(bob, 700);

        assertEq(mt.balanceOf(address(mt)), 0, "balanceOf(this)");
        assertEq(mt.balanceOf(alice), 300, "balanceOf(alice)");
        assertEq(mt.balanceOf(bob), 700, "balanceOf(bob)");
        assertEq(mt.totalSupply(), 1000, "totalSupply()");

        mt.transfer(address(mt), address(mt), bob, 100);

        assertEq(mt.balanceOf(alice), 200, "balanceOf(alice)");
        assertEq(mt.balanceOf(address(mt)), 0, "balanceOf(this)");
        assertEq(mt.balanceOf(bob), 800, "balanceOf(bob)");
        assertEq(mt.totalSupply(), 1000, "totalSupply()");

        // Expect revert if sender and receiver have different roots
        vm.expectRevert(
            abi.encodeWithSelector(
                MTLib.DifferentRoots.selector,
                address(mt),
                _1
            )
        );
        mt.transfer(address(mt), _1, _10, 100);

        // Expect revert if sender has subAccounts
        vm.expectRevert(
            abi.encodeWithSelector(MTLib.HasSubAccount.selector, "1")
        );
        mt.transfer(address(mt), address(mt), _1, 100);

        mt.mint(_1, 1000);
        mt.transfer(r1, r10, _100, 800);
        mt.transfer(r1, r10, _101, 50);
        mt.transfer(r1, r11, _110, 75);

        assertEq(mt.balanceOf(r1, alice), 75, "balanceOf(_1, alice)");
        assertEq(mt.balanceOf(r1), 0, "balanceOf(_1)");
        assertEq(mt.balanceOf(r1, _10), 850, "balanceOf(_1, _10)");
        assertEq(mt.balanceOf(r10, _100), 800, "balanceOf(_10, _100)");
        assertEq(mt.balanceOf(r10, _101), 50, "balanceOf(_10, _101)");
        assertEq(mt.balanceOf(r11, _110), 75, "balanceOf(_11, _110)");
        assertEq(mt.totalSupply(_1), 1000, "totalSupply(_1)");
    }

    function testMultitokenApprove() public {
        vm.startPrank(alice);

        mt.mint(address(mt), 1000);
        mt.approve(bob, 100);

        assertEq(mt.allowance(alice, bob), 100, "allowance(alice, bob)");
        assertEq(mt.allowance(bob, alice), 0, "allowance(bob, alice)");
        assertEq(mt.allowance(bob, bob), 0, "allowance(bob, bob)");
        assertEq(mt.allowance(alice, alice), 0, "allowance(alice, alice)");

        mt.mint(r1, 1000);
        // Expect revert if spender has a subAccount
        vm.expectRevert(
            abi.encodeWithSelector(MTLib.HasSubAccount.selector, "10")
        );
        mt.approve(r1, r1, _10, 100);
    }

    function testMultitokenTransferFrom() public {
        vm.startPrank(alice);

        mt.mint(address(mt), 1000);
        mt.approve(bob, 100);

        vm.startPrank(bob);

        mt.transferFrom(alice, bob, 100);

        assertEq(mt.balanceOf(alice), 900, "balanceOf(alice)");
        assertEq(mt.balanceOf(bob), 100, "balanceOf(bob)");
        assertEq(mt.totalSupply(), 1000, "totalSupply()");

        vm.startPrank(alice);

        mt.mint(r1, 1000);
        mt.approve(r1, r1, bob, 100);

        vm.startPrank(bob);

        mt.transferFrom(r1, alice, r1, r10, _100, 100);

        assertEq(mt.balanceOf(r1, alice), 900, "balanceOf(_1, alice)");
        assertEq(mt.balanceOf(r1, bob), 0, "balanceOf(_1, bob)");
        assertEq(mt.balanceOf(r10, _100), 100, "balanceOf(_10, _100)");
        assertEq(mt.totalSupply(_1), 1000, "totalSupply(_1)");
    }
}
