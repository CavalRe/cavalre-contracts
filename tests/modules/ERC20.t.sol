// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/src/Test.sol";

import {ILedger} from "../../interfaces/ILedger.sol";
import {ERC20} from "../../modules/ERC20.sol";
import {Ledger} from "../../modules/Ledger.sol";
import {Module} from "../../modules/Module.sol";
import {Router} from "../../modules/Router.sol";
import {LedgerLib} from "../../libraries/LedgerLib.sol";

contract MintModule is Module {
    function selectors() external pure override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = bytes4(keccak256("mintCanonical(address,uint256)"));
    }

    function mintCanonical(address to_, uint256 amount_) external {
        enforceIsOwner();
        LedgerLib.transfer(address(this), LedgerLib.SOURCE_ADDRESS, address(this), to_, amount_);
    }
}

contract ERC20Test is Test {
    Router router;
    Ledger ledgers;
    ERC20 token;
    MintModule minter;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address charlie = address(0xCA11);

    error InvalidInitialization();

    function setUp() public {
        vm.startPrank(alice);

        ledgers = new Ledger(18, "Ethereum", "ETH");
        token = new ERC20();
        minter = new MintModule();
        router = new Router(alice);

        router.addModule(address(ledgers));
        router.addModule(address(token));
        router.addModule(address(minter));

        ledgers = Ledger(payable(router));
        token = ERC20(payable(router));
        minter = MintModule(payable(router));

        ledgers.initializeLedger("Canonical Root", "ROOT");
        ledgers.addSubAccount(address(router), LedgerLib.SOURCE_ADDRESS, "Source", true);
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

        assertTrue(token.transfer(bob, 700));

        assertEq(token.balanceOf(alice), 300);
        assertEq(token.balanceOf(bob), 700);
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
            abi.encodeWithSelector(ILedger.InsufficientAllowance.selector, address(router), alice, bob, 60, 61)
        );
        token.decreaseAllowance(bob, 61);

        assertTrue(token.forceApprove(bob, 200));
        assertEq(token.allowance(alice, bob), 200);
    }
}
