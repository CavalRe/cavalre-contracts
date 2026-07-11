// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/src/Test.sol";

import {Dispatcher} from "../../modules/Dispatcher.sol";
import {ILedger, Ledger, ERC20Wrapper, LedgerLib} from "../../modules/Ledger.sol";
import {Tree} from "../../modules/Tree.sol";

import {TestLedger, MockERC20} from "./Ledger.t.sol";

contract ERC20WrapperTest is Test {
    Dispatcher internal dispatcher;
    TestLedger internal ledgers; // will point to Dispatcher after module add
    Tree internal tree;
    ERC20Wrapper internal token;
    MockERC20 internal externalToken;

    address internal owner = address(0xA11CE);
    address internal alice = address(0xB0B);
    address internal bob = address(0xCA11);
    address internal carol = address(0xD00D);
    address internal source_;

    function setUp() public {
        bool isVerbose = false;

        if (isVerbose) console.log("setUp");
        vm.startPrank(owner);

        // Deploy Ledger impl, register in Dispatcher, then speak to it at Dispatcher address
        if (isVerbose) console.log("Deploying Ledger impl");
        TestLedger impl = new TestLedger(18, 18);
        Tree treeImpl = new Tree();
        if (isVerbose) console.log("Deploying Dispatcher");
        dispatcher = new Dispatcher(owner);
        if (isVerbose) console.log("Registering Ledger impl");
        dispatcher.addModule(address(impl));
        dispatcher.addModule(address(treeImpl));
        if (isVerbose) console.log("Instantiating Test Ledger");
        ledgers = TestLedger(payable(address(dispatcher)));
        tree = Tree(payable(address(dispatcher)));

        if (isVerbose) console.log("Initializing Test Ledger");
        ledgers.initializeTestLedger();
        source_ = address(0);

        if (isVerbose) console.log("Adding new token to ledger");
        (address token_,) = ledgers.createInternalToken("Internal Test Token", "ITT", 18);
        token = ERC20Wrapper(token_);
        ledgers.addSubAccount(address(token), source_, "Zero Address", true);

        if (isVerbose) console.log("Creating external token");
        externalToken = new MockERC20("External Token", "EXT", 18);
        ledgers.addExternalToken(address(externalToken));
        ledgers.addSubAccount(address(externalToken), source_, "Zero Address", true);

        if (isVerbose) console.log("Token added");

        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Metadata
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperInit() public view {
        bool isVerbose = true;

        if (isVerbose) console.log("Display Account Hierarchy");
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(dispatcher));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(token));
        if (isVerbose) console.log("--------------------");
        if (isVerbose) tree.debugTree(address(externalToken));
        if (isVerbose) console.log("--------------------");

        assertEq(token.totalSupply(), 0);
    }

    function testERC20WrapperMetadata() public view {
        assertEq(token.name(), "Internal Test Token");
        assertEq(token.symbol(), "ITT");
        assertEq(token.decimals(), 18);
        assertEq(token.dispatcher(), address(dispatcher));
        assertEq(token.token(), address(token));
        assertEq(token.totalSupply(), 0);

        assertEq(ledgers.name(address(token)), "Internal Test Token");
        assertEq(ledgers.symbol(address(token)), "ITT");
        assertEq(ledgers.decimals(address(token)), 18);
        assertEq(ledgers.totalSupply(address(token)), 0);
    }

    function testERC20WrapperCreateInternalToken() public {
        vm.startPrank(owner);

        (address _newRoot,) = ledgers.createInternalToken("New Test Token", "NTT", 18);
        address _newToken = _newRoot;
        assertEq(ERC20Wrapper(_newToken).name(), "New Test Token");
        assertEq(ERC20Wrapper(_newToken).symbol(), "NTT");
        assertEq(ERC20Wrapper(_newToken).decimals(), 18);
        assertEq(ERC20Wrapper(_newToken).totalSupply(), 0);

        assertEq(ledgers.name(_newRoot), "New Test Token");
        assertEq(ledgers.symbol(_newRoot), "NTT");
        assertEq(ledgers.decimals(_newRoot), 18);
    }

    function testERC20WrapperClaimRootMintTransferBurn() public {
        vm.startPrank(owner);
        (address claimToken_,) = ledgers.createClaimToken("Claim Token", "CLM", 18, address(token), source_);
        vm.stopPrank();

        ERC20Wrapper claim = ERC20Wrapper(claimToken_);

        vm.prank(owner);
        ledgers.mint(claimToken_, alice, 1_000);

        assertEq(claim.totalSupply(), 1_000);
        assertEq(claim.balanceOf(alice), 1_000);

        vm.prank(alice);
        assertTrue(claim.transfer(bob, 400));

        assertEq(claim.balanceOf(alice), 600);
        assertEq(claim.balanceOf(bob), 400);
        assertEq(claim.totalSupply(), 1_000);

        vm.prank(owner);
        ledgers.burn(claimToken_, bob, 150);

        assertEq(claim.balanceOf(bob), 250);
        assertEq(claim.totalSupply(), 850);
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
        assertEq(token.balanceOf(address(0)), 1_000);

        if (isVerbose) console.log("balanceOf(alice)");
        assertEq(token.balanceOf(alice), 1_000);

        if (isVerbose) {
            console.log("Transfer -> ERC20 Transfer(alice, bob, 700)");
        }
        assertTrue(token.transfer(bob, 700));

        assertEq(token.balanceOf(alice), 300);
        assertEq(token.balanceOf(bob), 700);
        assertEq(token.totalSupply(), 1_000);
        assertEq(token.balanceOf(address(0)), 1_000);

        if (isVerbose) console.log("Burn -> ERC20 Transfer(bob, 0x0, 200)");
        vm.stopPrank();
        vm.startPrank(bob);

        ledgers.burn(address(token), bob, 200);

        assertEq(token.balanceOf(bob), 500);
        assertEq(token.totalSupply(), 800);
        assertEq(token.balanceOf(address(0)), 800);
    }

    function testERC20WrapperTransferToSelfEmitsTransfer() public {
        vm.prank(owner);
        ledgers.mint(address(token), alice, 1_000);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(alice, alice, 250);
        assertTrue(token.transfer(alice, 250));

        assertEq(token.balanceOf(alice), 1_000);
        assertEq(token.totalSupply(), 1_000);
    }

    function testERC20WrapperZeroTransferEmitsTransfer() public {
        vm.prank(owner);
        ledgers.mint(address(token), alice, 1_000);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(alice, bob, 0);
        assertTrue(token.transfer(bob, 0));

        assertEq(token.balanceOf(alice), 1_000);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.totalSupply(), 1_000);
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
        bool okInc = token.increaseAllowance(bob, 70);
        assertTrue(okInc);
        assertEq(token.allowance(alice, bob), 100);

        // decreaseAllowance by alice (-40 ⇒ 60)
        // vm.expectEmit(true, true, true, true);
        // emit ERC20Wrapper.Approval(alice, bob, 60);
        if (isVerbose) console.log("Decrease Allowance (alice -> bob: 40)");
        bool okDec = token.decreaseAllowance(bob, 40);
        assertTrue(okDec);
        assertEq(token.allowance(alice, bob), 60);

        // decreaseAllowance underflow should revert with ILedger.InsufficientAllowance
        vm.expectRevert(
            abi.encodeWithSelector(ILedger.InsufficientAllowance.selector, address(token), alice, bob, 60, 61)
        );
        token.decreaseAllowance(bob, 61);

        // forceApprove non-zero→non-zero (safety pattern inside LedgerLib)
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
    // Mint/Burn emit ERC20 Transfer events
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperMintBurnEmitsTransfer() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(address(0), alice, 50);
        ledgers.mint(address(token), alice, 50);

        vm.expectEmit(true, true, true, true, address(token));
        emit ERC20Wrapper.Transfer(alice, address(0), 20);
        ledgers.burn(address(token), alice, 20);

        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Reverts: direct calls into wrapper transfer path MUST fail
    // We intentionally call LedgerLib.transfer first in Ledger.transfer(...) so
    // root/flags/root-mismatch validation stays centralized there.
    // ─────────────────────────────────────────────────────────────────────────
    function testERC20WrapperLedgerWrapperFunctionsUnauthorized() public {
        bool isVerbose = false;

        // Any external calling Ledger.*Wrapper (not the token itself) should revert
        if (isVerbose) {
            console.log("Expect revert: Ledger.*Wrapper transfer called externally");
        }
        vm.expectRevert();
        ledgers.transfer(address(token), alice, address(token), bob, 1);
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
