// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RouterTest} from "../router/Router.t.sol";
import {IRouter, Router} from "../../contracts/router/Router.sol";
import {Token, TokenLib as TL} from "../../contracts/ERC20/Token.sol";
import {ERC20Lib as EL} from "../../contracts/ERC20/ERC20.sol";
import {Module, ModuleLib as ML} from "../../contracts/router/Module.sol";

import {Test, console} from "forge-std/src/Test.sol";

contract TokenTest is RouterTest, Token {
    Token token;
    Router router;

    bytes4[] commands_;

    function setUp() public {
        vm.startPrank(alice);
        token = new Token();
        router = new Router();
        router.addModule(address(token));

        call(router, TL.INITIALIZE_TOKEN, abi.encode("Token", "TOKEN"));
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

        // commands_ = router.getCommands(address(factory));
        // assertEq(
        //     router.module(commands_[0]),
        //     address(factory),
        //     "TokenTest: Create not set"
        // );
    }

    function testTokenInitialize() public {
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        call(router, TL.INITIALIZE_TOKEN, abi.encode("Token", "TOKEN"));

        call(router, EL.NAME, abi.encode(address(token)));
        assertEq(abi.decode(data, (string)), "Token");

        call(router, EL.SYMBOL, abi.encode(address(token)));
        assertEq(abi.decode(data, (string)), "TOKEN");

        call(router, EL.DECIMALS, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint8)), 18);

        call(router, EL.TOTAL_SUPPLY, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint256)), 0);

        call(router, EL.BALANCE_OF, abi.encode(address(token), alice));
        assertEq(abi.decode(data, (uint256)), 0);
    }

    function testTokenMint() public {
        vm.startPrank(alice);

        call(router, TL.MINT, abi.encode(bob, 1000));

        call(router, EL.TOTAL_SUPPLY, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint256)), 1000);

        call(router, EL.BALANCE_OF, abi.encode(bob));
        assertEq(abi.decode(data, (uint256)), 1000);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
        call(router, TL.MINT, abi.encode(bob, 1000));
    }

    function testTokenBurn() public {
        vm.startPrank(alice);

        call(router, TL.MINT, abi.encode(bob, 1000));

        call(router, TL.BURN, abi.encode(bob, 700));

        call(router, EL.TOTAL_SUPPLY, abi.encode(address(token)));
        assertEq(abi.decode(data, (uint256)), 300);

        call(router, EL.BALANCE_OF, abi.encode(bob));
        assertEq(abi.decode(data, (uint256)), 300);

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(ML.OwnableUnauthorizedAccount.selector, bob)
        );
        call(router, TL.BURN, abi.encode(bob, 300));
    }
}
