// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouter, Router} from "@cavalre/router/Router.sol";
import {IToken, Token, TokenLib as TL} from "@cavalre/erc20/Token.sol";
import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
import {Sentry, SentryLib as SL} from "@cavalre/sentry/Sentry.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/Test.sol";

contract TokenTest is Test, Token {
    Token token;
    Router router;
    Sentry sentry;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    bool success;
    bytes data;

    function setUp() public {
        vm.startPrank(alice);
        token = new Token();
        // sentry = new Sentry();
        // router.addModule(address(sentry));
        router = new Router();
        router.addModule(address(token));
    }

    function testTokenInit() public {
        assertEq(router.module(CLONE), address(token), "TokenTest: Clone not set");
        assertEq(router.module(INITIALIZE), address(token), "TokenTest: Initialize not set");
        assertEq(router.module(NAME), address(token), "TokenTest: Name not set");
        assertEq(router.module(SYMBOL), address(token), "TokenTest: Symbol not set");
        assertEq(router.module(DECIMALS), address(token), "TokenTest: Decimals not set");
        assertEq(router.module(TOTAL_SUPPLY), address(token), "TokenTest: TotalSupply not set");
        assertEq(router.module(BALANCE_OF), address(token), "TokenTest: BalanceOf not set");
        assertEq(router.module(TRANSFER), address(token), "TokenTest: Transfer not set");
        assertEq(router.module(TRANSFER_FROM), address(token), "TokenTest: TransferFrom not set");
        assertEq(router.module(APPROVE), address(token), "TokenTest: Approve not set");
        assertEq(router.module(ALLOWANCE), address(token), "TokenTest: Allowance not set");
        assertEq(router.module(INCREASE_ALLOWANCE), address(token), "TokenTest: IncreaseAllowance not set");
        assertEq(router.module(DECREASE_ALLOWANCE), address(token), "TokenTest: DecreaseAllowance not set");
        assertEq(router.module(MINT), address(token), "TokenTest: Mint not set");
        assertEq(router.module(BURN), address(token), "TokenTest: Burn not set");
    }

    function testTokenInitialize() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(token));

        IToken(clone).initialize("Clone", "CLONE", 18, 1000);

        vm.expectRevert("ERC20: Already initialized");
        IToken(clone).initialize("Clone", "CLONE", 18, 1000);

        assertEq(IToken(clone).name(), "Clone");

        assertEq(IToken(clone).symbol(), "CLONE");

        assertEq(IToken(clone).decimals(), 18);

        assertEq(IToken(clone).totalSupply(), 1000);

        assertEq(IToken(clone).balanceOf(alice), 1000);
    }

    function testTokenMint() public {
        vm.startPrank(alice);

        // address clone = Clones.clone(address(token));
        address clone = Clones.clone(address(token));

        IToken(clone).initialize("Clone", "CLONE", 18, 1000);

        IToken(clone).mint(bob, 1000);

        assertEq(IToken(clone).totalSupply(), 2000);

        assertEq(IToken(clone).balanceOf(bob), 1000);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob));
        IToken(clone).mint(bob, 1000);
    }

    function testTokenBurn() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(token));
        IToken(clone).initialize("Clone", "CLONE", 18, 1000);

        IToken(clone).burn(alice, 700);

        assertEq(IToken(clone).totalSupply(), 300);

        assertEq(IToken(clone).balanceOf(alice), 300);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob));
        IToken(clone).burn(alice, 300);
    }
}
