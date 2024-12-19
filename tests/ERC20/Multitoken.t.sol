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
        _commands[4] = MTLib.ADD_CHILD;
        _commands[5] = MTLib.GET_NAME;
        _commands[6] = MTLib.GET_SYMBOL;
        _commands[7] = MTLib.GET_DECIMALS;
        _commands[8] = MTLib.GET_PARENT;
        _commands[9] = MTLib.GET_HAS_CHILD;
        _commands[10] = MTLib.GET_BASE_NAME;
        _commands[11] = MTLib.GET_BASE_SYMBOL;
        _commands[12] = MTLib.GET_BASE_DECIMALS;
        _commands[13] = MTLib.BALANCE_OF;
        _commands[14] = MTLib.BASE_BALANCE_OF;
        _commands[15] = MTLib.TOTAL_SUPPLY;
        _commands[16] = MTLib.BASE_TOTAL_SUPPLY;
        _commands[17] = MTLib.TRANSFER;
        _commands[18] = MTLib.BASE_TRANSFER;
        _commands[19] = MTLib.APPROVE;
        _commands[20] = MTLib.BASE_APPROVE;
        _commands[21] = MTLib.ALLOWANCE;
        _commands[22] = MTLib.TRANSFER_FROM;
        _commands[23] = MTLib.BASE_TRANSFER_FROM;
        _commands[24] = TTLib.MINT;
        _commands[25] = TTLib.BURN;
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
    }

    function mint(address assetAddress_, uint256 amount_) public {
        super.__mint(assetAddress_, msg.sender, amount_);
    }

    function burn(address assetAddress_, uint256 _amount) public {
        super.__burn(assetAddress_, msg.sender, _amount);
    }

    receive() external payable {
        // deposit();
    }

    // function deposit() public payable {
    //     mint(msg.value);
    //     emit Deposit(msg.sender, msg.value);
    // }

    // function withdraw(uint256 wad) public {
    //     require(balanceOf(msg.sender) >= wad);
    //     burn(wad);
    //     (bool success, ) = payable(msg.sender).call{value: wad}("");
    //     require(success, "Transfer failed");
    //     emit Withdrawal(msg.sender, wad);
    // }
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

    function setUp() public {
        vm.startPrank(alice);
        mt = new TestMultitoken(18, 10);
        router = new Router(alice);
        router.addModule(address(mt));
        mt = TestMultitoken(payable(router));

        mt.initializeTestMultitoken("Test Multitoken", "MULTI");

        mt.addChild(_1, _10);
        mt.addChild(_1, _11);
        mt.addChild(_10, _100);
        mt.addChild(_10, _101);
        mt.addChild(_11, _110);
        mt.addChild(_11, _111);
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

        assertEq(mt.balanceOf(address(this)), 0);
    }

    function testMultitokenMint() public {
        vm.startPrank(alice);

        mt.mint(address(this), 1000);

        assertEq(mt.balanceOf(address(this)), 0);
        assertEq(mt.totalSupply(), 1000);
        assertEq(mt.balanceOf(alice), 1000);
    }

    function testMultitokenBurn() public {
        vm.startPrank(alice);

        mt.mint(address(this), 1000);
        mt.burn(address(this), 700);

        assertEq(mt.totalSupply(), 300);
        assertEq(mt.balanceOf(alice), 300);
    }
}