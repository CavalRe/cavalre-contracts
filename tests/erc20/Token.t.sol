// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouter, Router} from "../../contracts/router/Router.sol";
import {ERC20} from "../../contracts/ERC20/ERC20.sol";
import {Token, TokenFactory, TokenLib as TL} from "../../contracts/ERC20/Token.sol";
import {Module, ModuleLib as ML} from "../../contracts/router/Module.sol";
import {Sentry, SentryLib as SL} from "../../contracts/sentry/Sentry.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/src/Test.sol";

contract TokenTest is Test, Token {
    Token token;
    TokenFactory factory;
    Router router;
    Sentry sentry;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    bool success;
    bytes data;

    bytes4[] commands_;

    function setUp() public {
        vm.startPrank(alice);
        token = new Token();
        factory = new TokenFactory();
        // sentry = new Sentry();
        // router.addModule(address(sentry));
        router = new Router();
        router.addModule(address(token));
        router.addModule(address(factory));
    }

    function testTokenInit() public {
        commands_ = router.getCommands(address(token));
        assertEq(
            router.module(commands_[0]),
            address(token),
            "TokenTest: Initialize not set"
        );
        assertEq(
            router.module(commands_[1]),
            address(token),
            "TokenTest: Name not set"
        );
        assertEq(
            router.module(commands_[2]),
            address(token),
            "TokenTest: Symbol not set"
        );
        assertEq(
            router.module(commands_[3]),
            address(token),
            "TokenTest: Decimals not set"
        );
        assertEq(
            router.module(commands_[4]),
            address(token),
            "TokenTest: TotalSupply not set"
        );
        assertEq(
            router.module(commands_[5]),
            address(token),
            "TokenTest: BalanceOf not set"
        );
        assertEq(
            router.module(commands_[6]),
            address(token),
            "TokenTest: Transfer not set"
        );
        assertEq(
            router.module(commands_[7]),
            address(token),
            "TokenTest: TransferFrom not set"
        );
        assertEq(
            router.module(commands_[8]),
            address(token),
            "TokenTest: Approve not set"
        );
        assertEq(
            router.module(commands_[9]),
            address(token),
            "TokenTest: Allowance not set"
        );
        assertEq(
            router.module(commands_[10]),
            address(token),
            "TokenTest: Mint not set"
        );
        assertEq(
            router.module(commands_[11]),
            address(token),
            "TokenTest: Burn not set"
        );

        commands_ = router.getCommands(address(factory));
        assertEq(
            router.module(commands_[0]),
            address(factory),
            "TokenTest: Create not set"
        );
    }

    function testTokenInitialize() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(token));

        Token(clone).initialize("Clone", "CLONE");

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        Token(clone).initialize("Clone", "CLONE");

        assertEq(Token(clone).name(), "Clone");

        assertEq(Token(clone).symbol(), "CLONE");

        assertEq(Token(clone).decimals(), 18);

        assertEq(Token(clone).totalSupply(), 0);

        assertEq(Token(clone).balanceOf(alice), 0);
    }

    function testTokenMint() public {
        vm.startPrank(alice);

        // address clone = Clones.clone(address(token));
        address clone = Clones.clone(address(token));

        Token(clone).initialize("Clone", "CLONE");

        Token(clone).mint(bob, 1000);

        assertEq(Token(clone).totalSupply(), 1000);

        assertEq(Token(clone).balanceOf(bob), 1000);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
        Token(clone).mint(bob, 1000);
    }

    function testTokenBurn() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(token));
        Token(clone).initialize("Clone", "CLONE");

        Token(clone).mint(bob, 1000);

        Token(clone).burn(bob, 700);

        assertEq(Token(clone).totalSupply(), 300);

        assertEq(Token(clone).balanceOf(bob), 300);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
        Token(clone).burn(bob, 300);
    }

    function testTokenFactoryCreate() public {
        vm.startPrank(alice);

        (success, data) = address(router).call(
            abi.encodeWithSignature(
                "createToken(string,string,uint8,uint256)",
                "Clone",
                "CLONE",
                18,
                1000
            )
        );
        assertTrue(success, "TokenTest: createToken failed");
        address clone = abi.decode(data, (address));

        assertEq(Token(clone).name(), "Clone");

        assertEq(Token(clone).symbol(), "CLONE");

        assertEq(Token(clone).decimals(), 18);

        assertEq(Token(clone).totalSupply(), 0);

        assertEq(Token(clone).balanceOf(Token(clone).deployer()), 0);
    }
}
