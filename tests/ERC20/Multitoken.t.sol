// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {Multitoken, Lib as MTLib, Store} from "../../contracts/Multitoken/Multitoken.sol";
import {Module, Lib as MLib} from "../../contracts/router/Module.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test, console} from "forge-std/src/Test.sol";

library Lib {
    // Selectors
    bytes4 internal constant INITIALIZE_TEST_TOKEN =
        bytes4(keccak256("initializeTestMultitoken(string,string)"));
    bytes4 internal constant ADD_CHILD =
        bytes4(keccak256("addChild(string,address,address)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
    bytes4 internal constant ADD_APPLICATION =
        bytes4(keccak256("addTokenSource(string,address)"));
    bytes4 internal constant REMOVE_APPLICATION =
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

        // Update the prefix for child nodes
        string memory childPrefix = string(
            abi.encodePacked(
                prefix,
                isFirst ? "" : isLast ? "   " : unicode"│  "
            )
        );

        // Recursively log children
        address[] memory children = mt.children(root);
        uint256 childCount = children.length;
        // console.log("Child count", childCount);
        for (uint256 i = 0; i < childCount; i++) {
            logTree(
                mt,
                MTLib.toAddress(root, children[i]),
                childPrefix,
                false,
                i == childCount - 1 // Check if this is the last child
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
        _commands = new bytes4[](31);
        _commands[0] = Lib.INITIALIZE_TEST_TOKEN;
        _commands[1] = MTLib.SET_NAME;
        _commands[2] = MTLib.SET_SYMBOL;
        _commands[3] = MTLib.GET_ROOT;
        _commands[4] = MTLib.GET_NAME;
        _commands[5] = MTLib.GET_SYMBOL;
        _commands[6] = MTLib.GET_DECIMALS;
        _commands[7] = MTLib.GET_PARENT;
        _commands[8] = MTLib.GET_CHILDREN;
        _commands[9] = MTLib.GET_HAS_CHILD;
        _commands[10] = MTLib.GET_CHILD_INDEX;
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
        _commands[25] = Lib.ADD_CHILD;
        _commands[26] = Lib.MINT;
        _commands[27] = Lib.BURN;
        _commands[28] = Lib.ADD_APPLICATION;
        _commands[29] = Lib.REMOVE_APPLICATION;
        _commands[30] = Lib.ADD_TOKEN;
    }

    // Commands
    function initializeTestMultitoken(
        string memory name_,
        string memory symbol_
    ) public initializer {
        enforceIsOwner();
        initializeMultitoken_unchained(name_, symbol_);
        // Store storage s = MTLib.store();
        // s.name[address(this)] = name_;
        // s.symbol[address(this)] = symbol_;
    }

    function addChild(
        string memory name_,
        address parent_,
        address child_
    ) public returns (address) {
        return MTLib.addChild(name_, parent_, child_);
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

    function mint(address parentAddress_, uint256 amount_) public {
        MTLib.mint(parentAddress_, msg.sender, amount_);
    }

    function burn(address parentAddress_, uint256 _amount) public {
        MTLib.burn(parentAddress_, msg.sender, _amount);
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
        vm.startPrank(alice);
        mt = new TestMultitoken(18, 10);
        router = new Router(alice);
        router.addModule(address(mt));
        mt = TestMultitoken(payable(router));

        mt.initializeTestMultitoken("Test Multitoken", "MULTI");

        mt.addChild(
            "100",
            mt.addChild("10", mt.addChild("1", address(router), _1), _10),
            _100
        );
        mt.addTokenSource("Source", address(router));

        mt.addToken(r1, "1", "1", 18);

        mt.addChild("10", r1, _10);
        mt.addChild("11", r1, _11);
        mt.addChild("100", r10, _100);
        mt.addChild("101", r10, _101);
        mt.addChild("110", r11, _110);
        mt.addChild("111", r11, _111);
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
            mt.parent(MTLib.toAddress(address(router), MTLib.TOTAL_ADDRESS)),
            address(router),
            "Parent mismatch"
        );

        assertEq(
            mt.children(address(router)).length,
            1,
            "Children mismatch (router)"
        );

        assertEq(mt.children(r1).length, 2, "Children mismatch (r1)");

        assertEq(mt.children(r10).length, 2, "Children mismatch (r10)");

        assertEq(mt.children(r11).length, 2, "Children mismatch (r11)");

        assertEq(mt.childIndex(r1), 0, "Child index mismatch (r1)");

        assertEq(mt.childIndex(r11), 2, "Child index mismatch (r11)");

        assertEq(mt.childIndex(r10), 1, "Child index mismatch (r10)");

        assertEq(mt.childIndex(r100), 1, "Child index mismatch (r100)");

        assertEq(mt.childIndex(r101), 2, "Child index mismatch (r101)");

        assertEq(mt.childIndex(r110), 1, "Child index mismatch (r110)");

        assertEq(mt.childIndex(r111), 2, "Child index mismatch (r111)");
    }

    function testMultitokenTokenSource() public {
        vm.startPrank(alice);

        // address _appAddress2 = MTLib.toAddress("Test Application 2");
        // vm.expectRevert(
        //     abi.encodeWithSelector(MTLib.ChildNotFound.selector, _appAddress2)
        // );
        // mt.removeTokenSource("Test Application 2", address(router));

        mt.addTokenSource("Test Application 2", address(router));
        address _rawAppAddress = MTLib.toAddress(
            MTLib.toAddress(address(router), MTLib.TOTAL_ADDRESS),
            MTLib.toAddress("Test Application 2")
        );
        assertEq(
            mt.parent(_rawAppAddress),
            MTLib.toAddress(address(router), MTLib.TOTAL_ADDRESS),
            "Parent"
        );

        mt.removeTokenSource("Test Application 2", address(router));
        assertEq(mt.parent(_rawAppAddress), address(0), "Parent");
    }

    // TODO: Implement addChild, removeChild
    function testAddChild() public {}

    function testRemoveChild() public {}

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

        assertEq(mt.parent(r10), r1, "parent(_10)");
        assertEq(mt.parent(r11), r1, "parent(_11)");
        assertEq(mt.parent(r100), r10, "parent(_100)");
        assertEq(mt.parent(r101), r10, "parent(_101)");
        assertEq(mt.parent(r110), r11, "parent(_110)");
        assertEq(mt.parent(r111), r11, "parent(_111)");
    }

    function testMultitokenHasChild() public view {
        assertTrue(mt.hasChild(r1), "hasChild(r1)");
        assertTrue(mt.hasChild(r10), "hasChild(r10)");
        assertTrue(mt.hasChild(r11), "hasChild(r11)");
        assertFalse(mt.hasChild(r100), "hasChild(r100)");
        assertFalse(mt.hasChild(r101), "hasChild(r101)");
        assertFalse(mt.hasChild(r110), "hasChild(r110)");
        assertFalse(mt.hasChild(r111), "hasChild(r111)");
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

        // Expect revert if sender has children
        vm.expectRevert(abi.encodeWithSelector(MTLib.HasChild.selector, "1"));
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
        // Expect revert if spender has a child
        vm.expectRevert(abi.encodeWithSelector(MTLib.HasChild.selector, "10"));
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
