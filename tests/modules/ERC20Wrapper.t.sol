// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/src/Test.sol";

import {Router} from "../../modules/Router.sol";
import {ILedgers, Ledgers, ERC20Wrapper, Lib} from "../../modules/Ledgers.sol";

import {TestLedgers} from "./Ledgers.t.sol";

contract ERC20WrapperTest is Test {
    Router internal router;
    TestLedgers internal ledgers; // will point to Router after module add
    ERC20Wrapper internal token;

    address internal owner = address(0xA11CE);
    address internal alice = address(0xB0B);
    address internal bob = address(0xCA11);
    address internal carol = address(0xD00D);

    function setUp() public {
        bool isVerbose = false;

        if (isVerbose) console.log("setUp");
        vm.startPrank(owner);

        // Deploy Ledgers impl, register in Router, then speak to it at Router address
        if (isVerbose) console.log("Deploying Ledgers impl");
        TestLedgers impl = new TestLedgers(18);
        if (isVerbose) console.log("Deploying Router");
        router = new Router(owner);
        if (isVerbose) console.log("Registering Ledgers impl");
        router.addModule(address(impl));
        if (isVerbose) console.log("Instantiating Test Ledgers");
        ledgers = TestLedgers(payable(address(router)));

        if (isVerbose) console.log("Initializing Test Ledgers");
        ledgers.initializeTestLedgers();

        if (isVerbose) console.log("Creating ERC20Wrapper");
        token = ERC20Wrapper(ledgers.createToken("Wrapped Test Token", "WTT", 18));

        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Metadata
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMetadata() public view {
        assertEq(token.name(), "Wrapped Test Token");
        assertEq(token.symbol(), "WTT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mint / Transfer / Burn
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMintTransferBurn() public {
        bool isVerbose = false;

        vm.startPrank(alice);

        if (isVerbose) console.log("Mint 1000 to alice");
        ledgers.mint(address(token), alice, 1_000);

        if (isVerbose) console.log("totalSupply()");
        assertEq(token.totalSupply(), 1_000);

        if (isVerbose) console.log("balanceOf(alice)");
        assertEq(token.balanceOf(alice), 1_000);

        if (isVerbose) console.log("Transfer -> ERC20 Transfer(alice, bob, 700)");
        assertTrue(token.transfer(bob, 700));

        assertEq(token.balanceOf(alice), 300);
        assertEq(token.balanceOf(bob), 700);
        assertEq(token.totalSupply(), 1_000);

        if (isVerbose) console.log("Burn -> ERC20 Transfer(bob, 0x0, 200)");
        vm.stopPrank();
        vm.startPrank(bob);

        ledgers.burn(address(token), bob, 200);

        assertEq(token.balanceOf(bob), 500);
        assertEq(token.totalSupply(), 800);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Approvals: approve / transferFrom / increase / decrease / forceApprove
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperApproveTransferFromandAllowanceMutators() public {
        bool isVerbose = false;

        vm.prank(owner);

        // Mint to alice
        if (isVerbose) console.log("Mint 1000 to alice");
        ledgers.mint(address(token), alice, 1_000);

        // approve (alice → bob: 150)
        if (isVerbose) console.log("Approve (alice -> bob: 150)");
        vm.startPrank(alice);
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 150);
        assertTrue(token.approve(bob, 150));
        assertEq(token.allowance(alice, bob), 150);

        // transferFrom by bob: 120
        vm.stopPrank();
        vm.startPrank(bob);

        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Transfer(alice, bob, 120);
        if (isVerbose) console.log("Transfer (alice -> bob: 120)");
        assertTrue(token.transferFrom(alice, bob, 120));

        assertEq(token.balanceOf(alice), 880);
        assertEq(token.balanceOf(bob), 120);
        assertEq(token.allowance(alice, bob), 30);

        // increaseAllowance by alice (+70 ⇒ 100)
        vm.stopPrank();
        vm.startPrank(alice);

        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 100);
        if (isVerbose) console.log("Increase Allowance (alice -> bob: 70)");
        (bool okInc) = token.increaseAllowance(bob, 70);
        assertTrue(okInc);
        assertEq(token.allowance(alice, bob), 100);

        // decreaseAllowance by alice (-40 ⇒ 60)
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 60);
        if (isVerbose) console.log("Decrease Allowance (alice -> bob: 40)");
        (bool okDec) = token.decreaseAllowance(bob, 40);
        assertTrue(okDec);
        assertEq(token.allowance(alice, bob), 60);

        // decreaseAllowance underflow should revert with ILedgers.InsufficientAllowance
        vm.expectRevert(
            abi.encodeWithSelector(ILedgers.InsufficientAllowance.selector, address(token), alice, bob, 60, 61)
        );
        token.decreaseAllowance(bob, 61);

        // forceApprove non-zero→non-zero (safety pattern inside LedgersLib)
        // current=60, set to 200
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 200);
        if (isVerbose) console.log("Force Approve (alice -> bob: 200)");
        assertTrue(token.forceApprove(bob, 200));
        assertEq(token.allowance(alice, bob), 200);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // transferFrom allowance depletion exact match
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperTransferFromExactAllowance() public {
        vm.startPrank(owner);
        ledgers.mint(address(token), alice, 250);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(bob, 250);
        vm.stopPrank();

        vm.startPrank(bob);
        token.transferFrom(alice, bob, 250);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 250);
        assertEq(token.allowance(alice, bob), 0);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Reverts: Direct calls into Ledgers.*Wrapper MUST be from the token
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperLedgersWrapperFunctionsUnauthorized() public {
        bool isVerbose = false;

        // Any external calling Ledgers.*Wrapper (not the token itself) should revert
        if (isVerbose) console.log("Expect revert: Ledgers.*Wrapper approve called externally");
        vm.expectRevert(abi.encodeWithSelector(ILedgers.Unauthorized.selector, address(this)));
        ledgers.approve(address(token), alice, bob, 1);

        if (isVerbose) console.log("Expect revert: Ledgers.*Wrapper transfer called externally");
        vm.expectRevert(abi.encodeWithSelector(ILedgers.Unauthorized.selector, address(this)));
        ledgers.transfer(address(token), alice, address(token), bob, 1, false);

        // if (isVerbose) console.log("Expect revert: Ledgers.*Wrapper mint called externally");
        // vm.expectRevert(abi.encodeWithSelector(ILedgers.Unauthorized.selector, address(this)));
        // ledgers.mint(address(token), alice, 1);

        // if (isVerbose) console.log("Expect revert: Ledgers.*Wrapper burn called externally");
        // vm.expectRevert(abi.encodeWithSelector(ILedgers.Unauthorized.selector, address(this)));
        // ledgers.burn(address(token), alice, 1);

        if (isVerbose) console.log("Expect revert: Ledgers.*Wrapper transferFrom called externally");
        vm.expectRevert(abi.encodeWithSelector(ILedgers.Unauthorized.selector, address(this)));
        ledgers.transferFrom(bob, address(token), alice, address(token), bob, 1, false);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Sanity: multiple holders and totals
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMultiHolderAccounting() public {
        vm.startPrank(owner);
        ledgers.mint(address(token), alice, 400);
        ledgers.mint(address(token), bob, 600);
        vm.stopPrank();

        assertEq(token.totalSupply(), 1_000);
        assertEq(token.balanceOf(alice), 400);
        assertEq(token.balanceOf(bob), 600);

        vm.prank(bob);
        token.transfer(alice, 50);

        assertEq(token.balanceOf(alice), 450);
        assertEq(token.balanceOf(bob), 550);
        assertEq(token.totalSupply(), 1_000);
    }
}
