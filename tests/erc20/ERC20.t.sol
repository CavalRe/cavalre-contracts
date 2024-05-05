// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {ERC20} from "../../contracts/ERC20/ERC20.sol";
import {Module, ModuleLib as ML} from "../../contracts/router/Module.sol";
// import {Sentry, SentryLib as SL} from "@cavalre/contracts/sentry/Sentry.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/src/Test.sol";

contract ERC20Test is Test, ERC20 {
    ERC20 erc20;
    Router router;
    // Sentry sentry;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    bool success;
    bytes data;

    function setUp() public {
        vm.startPrank(alice);
        erc20 = new ERC20();
        // sentry = new Sentry();
        // router.addModule(address(sentry));
        router = new Router();
        router.addModule(address(erc20));
    }

    function testERC20Init() public {
        assertEq(router.module(INITIALIZE), address(erc20), "ERC20Test: Initialize not set");
        assertEq(router.module(NAME), address(erc20), "ERC20Test: Name not set");
        assertEq(router.module(SYMBOL), address(erc20), "ERC20Test: Symbol not set");
        assertEq(router.module(DECIMALS), address(erc20), "ERC20Test: Decimals not set");
        assertEq(router.module(TOTAL_SUPPLY), address(erc20), "ERC20Test: TotalSupply not set");
        assertEq(router.module(BALANCE_OF), address(erc20), "ERC20Test: BalanceOf not set");
        assertEq(router.module(TRANSFER), address(erc20), "ERC20Test: Transfer not set");
        assertEq(router.module(TRANSFER_FROM), address(erc20), "ERC20Test: TransferFrom not set");
        assertEq(router.module(APPROVE), address(erc20), "ERC20Test: Approve not set");
        assertEq(router.module(ALLOWANCE), address(erc20), "ERC20Test: Allowance not set");
    }

    function testERC20Initialize() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(erc20));
        ERC20(clone).initialize("Clone", "CLONE");

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        ERC20(clone).initialize("Clone", "CLONE");

        assertEq(ERC20(clone).name(), "Clone");

        assertEq(ERC20(clone).symbol(), "CLONE");

        assertEq(ERC20(clone).decimals(), 18);

        assertEq(ERC20(clone).totalSupply(), 0);

        assertEq(ERC20(clone).balanceOf(alice), 0);
    }
}
