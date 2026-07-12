// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";

import {ILedger} from "../../modules/ledger/ILedger.sol";
import {ERC20} from "../../examples/LedgerERC20.sol";
import {Ledger} from "../../modules/ledger/Ledger.sol";
import {Dispatchable} from "../../modules/dispatcher/Dispatchable.sol";
import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {LedgerLib} from "../../modules/ledger/LedgerLib.sol";

contract MintModule is Dispatchable {
    function signatures() external pure override returns (string[] memory _signatures) {
        _signatures = new string[](1);
        _signatures[0] = "mintCanonical(address,uint256)";
    }

    function selectors() external pure override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = bytes4(keccak256("mintCanonical(address,uint256)"));
    }

    function mintCanonical(address to_, uint256 amount_) external {
        enforceIsOwner();
        LedgerLib.transfer(address(this), address(0), address(this), to_, amount_);
    }
}

contract LedgerERC20Test is Test {
    Dispatcher dispatcher;
    Ledger ledgers;
    ERC20 token;
    MintModule minter;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);
    address source_;

    error InvalidInitialization();

    function setUp() public {
        vm.startPrank(alice);

        ledgers = new Ledger(18, "Ethereum", "ETH", 18);
        token = new ERC20();
        minter = new MintModule();
        dispatcher = new Dispatcher(alice);

        dispatcher.addModule(address(ledgers));
        dispatcher.addModule(address(token));
        dispatcher.addModule(address(minter));

        ledgers = Ledger(payable(dispatcher));
        token = ERC20(payable(dispatcher));
        minter = MintModule(payable(dispatcher));

        ledgers.initializeLedger("Canonical Root", "ROOT");
        source_ = address(0);
        ledgers.addSubAccount(address(dispatcher), source_, "Zero Address", true);
        token.initializeERC20();
    }

    function testERC20Init() public {
        vm.startPrank(alice);

        vm.expectRevert(InvalidInitialization.selector);
        token.initializeERC20();

        assertEq(token.name(), "Canonical Root");
        assertEq(token.symbol(), "ROOT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(alice), 0);
    }

    function testERC20Transfer() public {
        vm.startPrank(alice);

        minter.mintCanonical(alice, 1000);
        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(address(0)), 1000);

        assertTrue(token.transfer(bob, 700));

        assertEq(token.balanceOf(alice), 300);
        assertEq(token.balanceOf(bob), 700);
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(address(0)), 1000);
    }

    function testERC20TransferToSelfEmitsTransfer() public {
        vm.startPrank(alice);
        minter.mintCanonical(alice, 1000);

        vm.expectEmit(true, true, true, true, address(dispatcher));
        emit ILedger.Transfer(alice, alice, 250);
        assertTrue(token.transfer(alice, 250));

        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.totalSupply(), 1000);
    }

    function testERC20ZeroTransferEmitsTransfer() public {
        vm.startPrank(alice);
        minter.mintCanonical(alice, 1000);

        vm.expectEmit(true, true, true, true, address(dispatcher));
        emit ILedger.Transfer(alice, bob, 0);
        assertTrue(token.transfer(bob, 0));

        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), 1000);
    }

    function testERC20ApproveTransferFromAndAllowanceMutators() public {
        vm.startPrank(alice);
        minter.mintCanonical(alice, 1000);

        assertTrue(token.approve(bob, 150));
        assertEq(token.allowance(alice, bob), 150);

        vm.startPrank(bob);
        assertTrue(token.transferFrom(alice, charlie, 120));
        assertEq(token.balanceOf(alice), 880);
        assertEq(token.balanceOf(charlie), 120);
        assertEq(token.allowance(alice, bob), 30);

        vm.startPrank(alice);
        assertTrue(token.increaseAllowance(bob, 70));
        assertEq(token.allowance(alice, bob), 100);

        assertTrue(token.decreaseAllowance(bob, 40));
        assertEq(token.allowance(alice, bob), 60);

        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InsufficientAllowance.selector, address(dispatcher), alice, bob, 60, 61)
        );
        token.decreaseAllowance(bob, 61);

        assertTrue(token.forceApprove(bob, 200));
        assertEq(token.allowance(alice, bob), 200);
    }

    function testERC20TransferRejectsCanonicalCreditLeafSender() public {
        vm.startPrank(alice);
        minter.mintCanonical(alice, 1000);
        vm.stopPrank();

        vm.startPrank(source_);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, address(dispatcher)));
        token.transfer(bob, 1);
        vm.stopPrank();
    }

    function testERC20TransferFromRejectsCanonicalCreditLeafSender() public {
        vm.startPrank(alice);
        minter.mintCanonical(alice, 1000);
        vm.stopPrank();

        vm.prank(source_);
        token.approve(bob, 10);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(ILedger.InvalidLedgerAccount.selector, address(dispatcher)));
        token.transferFrom(source_, charlie, 1);
        vm.stopPrank();
    }
}
