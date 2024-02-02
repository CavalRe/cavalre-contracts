// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouter, Router} from "@cavalre/router/Router.sol";
import {IToken, Token, ITokenFactory, TokenFactory, TokenLib as TL} from "@cavalre/erc20/Token.sol";
import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
import {Sentry, SentryLib as SL} from "@cavalre/sentry/Sentry.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/Test.sol";

contract TokenTest is Test {
    Token token;
    TokenFactory factory;
    Router router;
    Sentry sentry;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    bool success;
    bytes data;

    bytes4[] commands;

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
        commands = router.getCommands(address(token));
        assertEq(
            router.module(commands[0]),
            address(token),
            "TokenTest: Clone not set"
        );
        assertEq(
            router.module(commands[1]),
            address(token),
            "TokenTest: Initialize not set"
        );
        assertEq(
            router.module(commands[2]),
            address(token),
            "TokenTest: Name not set"
        );
        assertEq(
            router.module(commands[3]),
            address(token),
            "TokenTest: Symbol not set"
        );
        assertEq(
            router.module(commands[4]),
            address(token),
            "TokenTest: Decimals not set"
        );
        assertEq(
            router.module(commands[5]),
            address(token),
            "TokenTest: TotalSupply not set"
        );
        assertEq(
            router.module(commands[6]),
            address(token),
            "TokenTest: BalanceOf not set"
        );
        assertEq(
            router.module(commands[7]),
            address(token),
            "TokenTest: Transfer not set"
        );
        assertEq(
            router.module(commands[8]),
            address(token),
            "TokenTest: TransferFrom not set"
        );
        assertEq(
            router.module(commands[9]),
            address(token),
            "TokenTest: Approve not set"
        );
        assertEq(
            router.module(commands[10]),
            address(token),
            "TokenTest: Allowance not set"
        );
        assertEq(
            router.module(commands[11]),
            address(token),
            "TokenTest: IncreaseAllowance not set"
        );
        assertEq(
            router.module(commands[12]),
            address(token),
            "TokenTest: DecreaseAllowance not set"
        );
        assertEq(
            router.module(commands[13]),
            address(token),
            "TokenTest: Mint not set"
        );
        assertEq(
            router.module(commands[14]),
            address(token),
            "TokenTest: Burn not set"
        );

        commands = router.getCommands(address(factory));
        assertEq(
            router.module(commands[0]),
            address(factory),
            "TokenTest: Create not set"
        );
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
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
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
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
        IToken(clone).burn(alice, 300);
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

        assertEq(IToken(clone).name(), "Clone");

        assertEq(IToken(clone).symbol(), "CLONE");

        assertEq(IToken(clone).decimals(), 18);

        assertEq(IToken(clone).totalSupply(), 1000);

        assertEq(IToken(clone).balanceOf(IToken(clone).deployer()), 1000);
    }
}
