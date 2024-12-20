// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {Multitoken, Lib as MTLib, Store} from "../../contracts/Multitoken/Multitoken.sol";
import {Module, ModuleLib as ML} from "../../contracts/router/Module.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test, console} from "forge-std/src/Test.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library TTLib {
    // Selectors
    bytes4 internal constant INITIALIZE_TEST_TOKEN =
        bytes4(keccak256("initializeTestMultitoken(string,string)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

contract TestMultitoken is Multitoken {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        uint8 decimals_,
        uint8 maxDepth_
    ) Multitoken(decimals_, maxDepth_) {}

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](26);
        _commands[0] = TTLib.INITIALIZE_TEST_TOKEN;
        _commands[1] = MTLib.SET_NAME;
        _commands[2] = MTLib.SET_SYMBOL;
        _commands[3] = MTLib.GET_ROOT;
        _commands[4] = MTLib.GET_NAME;
        _commands[5] = MTLib.GET_SYMBOL;
        _commands[6] = MTLib.GET_DECIMALS;
        _commands[7] = MTLib.GET_PARENT;
        _commands[8] = MTLib.GET_HAS_CHILD;
        _commands[9] = MTLib.GET_BASE_NAME;
        _commands[10] = MTLib.GET_BASE_SYMBOL;
        _commands[11] = MTLib.GET_BASE_DECIMALS;
        _commands[12] = MTLib.BALANCE_OF;
        _commands[13] = MTLib.BASE_BALANCE_OF;
        _commands[14] = MTLib.TOTAL_SUPPLY;
        _commands[15] = MTLib.BASE_TOTAL_SUPPLY;
        _commands[16] = MTLib.TRANSFER;
        _commands[17] = MTLib.BASE_TRANSFER;
        _commands[18] = MTLib.APPROVE;
        _commands[19] = MTLib.BASE_APPROVE;
        _commands[20] = MTLib.ALLOWANCE;
        _commands[21] = MTLib.TRANSFER_FROM;
        _commands[22] = MTLib.BASE_TRANSFER_FROM;
        _commands[23] = TTLib.MINT;
        _commands[24] = TTLib.BURN;
    }

    // Commands
    function initializeTestMultitoken(
        string memory name_,
        string memory symbol_
    ) public initializer {
        enforceIsOwner();
        // initializeMultitoken(name_, symbol_);
        Store storage s = MTLib.store();
        s.name[address(this)] = name_;
        s.symbol[address(this)] = symbol_;

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
        address r10 = MTLib.toAddress(_1, _10);
        address r11 = MTLib.toAddress(_1, _11);

        __addChild(r1, _10);
        __addChild(r1, _11);
        __addChild(r10, _100);
        __addChild(r10, _101);
        __addChild(r11, _110);
        __addChild(r11, _111);
    }

    function addChild(address parent_, address child_) public {
        super.__addChild(parent_, child_);
    }

    function mint(address assetAddress_, uint256 amount_) public {
        super.__mint(assetAddress_, msg.sender, amount_);
    }

    function burn(address assetAddress_, uint256 _amount) public {
        super.__burn(assetAddress_, msg.sender, _amount);
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
    address r10 = MTLib.toAddress(_1, _10);
    address r11 = MTLib.toAddress(_1, _11);
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
    }

    function testMultitokenInit() public {
        vm.startPrank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(Initializable.InvalidInitialization.selector)
        );
        mt.initializeTestMultitoken("Clone", "CLONE");

        assertEq(mt.name(), "Test Multitoken");

        assertEq(mt.symbol(), "MULTI");

        assertEq(mt.decimals(), 18);

        assertEq(mt.totalSupply(), 0);

        assertEq(mt.balanceOf(alice), 0);

        assertEq(mt.balanceOf(address(mt)), 0);
    }

    function testMultitokenMint() public {
        vm.startPrank(alice);

        mt.mint(address(mt), 1000);

        assertEq(mt.balanceOf(address(mt)), 0, "balanceOf(address(this))");
        assertEq(mt.balanceOf(alice), 1000, "balanceOf(alice)");
        assertEq(mt.totalSupply(), 1000, "totalSupply");

        mt.mint(_1, 1000);
        assertEq(mt.balanceOf(_100), 0, "balanceOf(_100)");
        assertEq(mt.totalSupply(_1), 1000, "totalSupply");
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
                Multitoken.DifferentRoots.selector,
                address(mt),
                _1
            )
        );
        mt.transfer(address(mt), _1, _10, 100);

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

        mt.mint(_1, 1000);

        // Expect revert if spender has children
        // vm.expectRevert(
        //     abi.encodeWithSelector(Multitoken.HasChild.selector, _1)
        // );
        // mt.approve(r1, 100);

        // Expert revert if parents have different roots
        // vm.expectRevert(
        //     abi.encodeWithSelector(Multitoken.DifferentRoots.selector, _10, alice)
        // );
        // mt.approve(_1, _10, address(mt), 100);
    }
}
