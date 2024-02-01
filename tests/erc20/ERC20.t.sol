// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "@cavalre/router/Router.sol";
import {IERC20, ERC20, ERC20Lib as EL} from "@cavalre/erc20/ERC20.sol";
import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
import {Sentry, SentryLib as SL} from "@cavalre/sentry/Sentry.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/Test.sol";

contract ERC20Test is Test {
    ERC20 erc20;
    Router router;
    Sentry sentry;

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
        assertEq(router.module(EL.CLONE), address(erc20), "ERC20Test: Clone not set");
        assertEq(router.module(EL.INITIALIZE), address(erc20), "ERC20Test: Initialize not set");
        assertEq(router.module(EL.NAME), address(erc20), "ERC20Test: Name not set");
        assertEq(router.module(EL.SYMBOL), address(erc20), "ERC20Test: Symbol not set");
        assertEq(router.module(EL.DECIMALS), address(erc20), "ERC20Test: Decimals not set");
        assertEq(router.module(EL.TOTAL_SUPPLY), address(erc20), "ERC20Test: TotalSupply not set");
        assertEq(router.module(EL.BALANCE_OF), address(erc20), "ERC20Test: BalanceOf not set");
        assertEq(router.module(EL.TRANSFER), address(erc20), "ERC20Test: Transfer not set");
        assertEq(router.module(EL.TRANSFER_FROM), address(erc20), "ERC20Test: TransferFrom not set");
        assertEq(router.module(EL.APPROVE), address(erc20), "ERC20Test: Approve not set");
        assertEq(router.module(EL.ALLOWANCE), address(erc20), "ERC20Test: Allowance not set");
        assertEq(router.module(EL.INCREASE_ALLOWANCE), address(erc20), "ERC20Test: IncreaseAllowance not set");
        assertEq(router.module(EL.DECREASE_ALLOWANCE), address(erc20), "ERC20Test: DecreaseAllowance not set");
    }

    function testERC20Initialize() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(erc20));
        IERC20(clone).initialize("Clone", "CLONE", 18, 1000);

        vm.expectRevert("ERC20: Already initialized");
        IERC20(clone).initialize("Clone", "CLONE", 18, 1000);

        assertEq(IERC20(clone).name(), "Clone");

        assertEq(IERC20(clone).symbol(), "CLONE");

        assertEq(IERC20(clone).decimals(), 18);

        assertEq(IERC20(clone).totalSupply(), 1000);

        assertEq(IERC20(clone).balanceOf(alice), 1000);
    }
}
