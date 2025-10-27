// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../modules/Router.sol";
import {ERC20, ERC20Lib} from "../../examples/ERC20.sol";
import {ModuleLib} from "../../modules/Module.sol";
import {TestToken, TokenLib} from "../../examples/Token.sol";

import {Test, console} from "forge-std/src/Test.sol";

contract TestTokenTest is Test {
    TestToken token;
    Router router;

    address alice = address(1);
    address bob = address(2);
    address carol = address(3);

    error InvalidInitialization();

    error NotInitializing();

    function setUp() public {
        vm.startPrank(alice);
        token = new TestToken(18);
        router = new Router(alice);
        router.addModule(address(token));

        token = TestToken(payable(router));

        token.initializeTestToken("TestToken", "TOKEN");
    }

    function testTestTokenInitialize() public {
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        token.initializeTestToken("TestToken", "TOKEN");

        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TOKEN");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(alice), 0);
    }

    function testTestTokenMint() public {
        vm.startPrank(alice);

        token.mint(1000);

        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(alice), 1000);
    }

    function testTestTokenBurn() public {
        vm.startPrank(alice);

        token.mint(1000);
        token.burn(700);

        assertEq(token.totalSupply(), 300);
        assertEq(token.balanceOf(alice), 300);
    }
}
