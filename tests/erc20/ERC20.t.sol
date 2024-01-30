// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {Router} from "@cavalre/router/Router.sol";
// import {ERC20, ERC20Lib as EL} from "@cavalre/erc20/ERC20.sol";
// import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
// import {Sentry, SentryLib as SL} from "@cavalre/sentry/Sentry.sol";
// import {Test} from "forge-std/Test.sol";

// contract ERC20Test is Test {
//     ERC20 erc20;
//     Router router;
//     Sentry sentry;

//     address alice = address(1);
//     address bob = address(2);
//     address charlie = address(3);

//     bool success;
//     bytes data;

//     function setUp() public {
//         vm.startPrank(alice);
//         erc20 = new ERC20();
//         // sentry = new Sentry();
//         router = new Router();
//         // router.addModule(address(sentry));
//         router.addModule(address(erc20));
//     }

    // function testERC20Init() public {
    //     assertEq(router.module(EL.CLONE), address(erc20), "ERC20Test: Clone not set");
    //     assertEq(router.module(EL.NAME), address(erc20), "ERC20Test: Name not set");
    //     assertEq(router.module(EL.SYMBOL), address(erc20), "ERC20Test: Symbol not set");
    //     assertEq(router.module(EL.DECIMALS), address(erc20), "ERC20Test: Decimals not set");
    //     assertEq(router.module(EL.TOTAL_SUPPLY), address(erc20), "ERC20Test: TotalSupply not set");
    //     assertEq(router.module(EL.BALANCE_OF), address(erc20), "ERC20Test: BalanceOf not set");
    //     assertEq(router.module(EL.TRANSFER), address(erc20), "ERC20Test: Transfer not set");
    //     assertEq(router.module(EL.TRANSFER_FROM), address(erc20), "ERC20Test: TransferFrom not set");
    //     assertEq(router.module(EL.APPROVE), address(erc20), "ERC20Test: Approve not set");
    //     assertEq(router.module(EL.ALLOWANCE), address(erc20), "ERC20Test: Allowance not set");
    //     assertEq(router.module(EL.INCREASE_ALLOWANCE), address(erc20), "ERC20Test: IncreaseAllowance not set");
    //     assertEq(router.module(EL.DECREASE_ALLOWANCE), address(erc20), "ERC20Test: DecreaseAllowance not set");
    // }

    // function testERC20Clone() public {
    //     vm.startPrank(alice);

    //     emit log("Clone");
    //     (success, data) = address(erc20).call(abi.encodeWithSignature("clone(string,string,uint8,uint256)", "Clone", "CLONE", 18, 1000));
    //     require(success, "ERC20Test: Clone failed");
    //     address clone = abi.decode(data, (address));

    //     emit log_named_address("clone", clone);

    //     emit log("Name");
    //     (success, data) = address(clone).call(abi.encodePacked(EL.NAME));
    //     require(success, "ERC20Test: Name failed");
    //     assertEq(abi.decode(data, (string)), "Clone");

    //     emit log("Symbol");
    //     (success, data) = address(clone).call(abi.encodePacked(EL.SYMBOL));
    //     require(success, "ERC20Test: Symbol failed");
    //     assertEq(abi.decode(data, (string)), "CLONE");

    //     emit log("Decimals");
    //     (success, data) = address(clone).call(abi.encodePacked(EL.DECIMALS));
    //     require(success, "ERC20Test: Decimals failed");
    //     assertEq(abi.decode(data, (uint256)), 18);

    //     emit log("TotalSupply");
    //     (success, data) = address(clone).call(abi.encodePacked(EL.TOTAL_SUPPLY));
    //     require(success, "ERC20Test: TotalSupply failed");
    //     assertEq(abi.decode(data, (uint256)), 1000);

    //     emit log("BalanceOf");
    //     (success, data) = address(clone).call(abi.encodePacked(EL.BALANCE_OF, alice));
    //     require(success, "ERC20Test: BalanceOf failed");
    //     assertEq(abi.decode(data, (uint256)), 1000);
    // }
// }
