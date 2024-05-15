// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {RouterTestLib} from "../router/Router.t.sol";
import {ERC20, ERC20Lib} from "../../contracts/ERC20/ERC20.sol";
import {Module, ModuleLib as ML} from "../../contracts/router/Module.sol";
// import {Sentry, SentryLib as SL} from "@cavalre/contracts/sentry/Sentry.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/src/Test.sol";

library ERC20TestLib {
    using RouterTestLib for Router;

    function name(Router router_) internal returns (string memory) {
        return abi.decode(router_.call(ERC20Lib.NAME, ""), (string));
    }

    function symbol(Router router_) internal returns (string memory) {
        return abi.decode(router_.call(ERC20Lib.SYMBOL, ""), (string));
    }

    function decimals(Router router_) internal returns (uint8) {
        return abi.decode(router_.call(ERC20Lib.DECIMALS, ""), (uint8));
    }

    function totalSupply(Router router_) internal returns (uint256) {
        return abi.decode(router_.call(ERC20Lib.TOTAL_SUPPLY, ""), (uint256));
    }

    function balanceOf(Router router_, address _owner)
        internal
        returns (uint256)
    {
        return abi.decode(
            router_.call(ERC20Lib.BALANCE_OF, abi.encode(_owner)),
            (uint256)
        );
    }

    function transfer(
        Router router_,
        address _to,
        uint256 _value
    ) internal {
        router_.call(ERC20Lib.TRANSFER, abi.encode(_to, _value));
    }

    function transferFrom(
        Router router_,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        router_.call(
            ERC20Lib.TRANSFER_FROM,
            abi.encode(_from, _to, _value)
        );
    }

    function approve(
        Router router_,
        address _spender,
        uint256 _value
    ) internal {
        router_.call(ERC20Lib.APPROVE, abi.encode(_spender, _value));
    }

    function allowance(
        Router router_,
        address _owner,
        address _spender
    ) internal returns (uint256) {
        return abi.decode(
            router_.call(ERC20Lib.ALLOWANCE, abi.encode(_owner, _spender)),
            (uint256)
        );
    }
}

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
        assertEq(
            router.module(ERC20Lib.NAME),
            address(erc20),
            "ERC20Test: Name not set"
        );
        assertEq(
            router.module(ERC20Lib.SYMBOL),
            address(erc20),
            "ERC20Test: Symbol not set"
        );
        assertEq(
            router.module(ERC20Lib.DECIMALS),
            address(erc20),
            "ERC20Test: Decimals not set"
        );
        assertEq(
            router.module(ERC20Lib.TOTAL_SUPPLY),
            address(erc20),
            "ERC20Test: TotalSupply not set"
        );
        assertEq(
            router.module(ERC20Lib.BALANCE_OF),
            address(erc20),
            "ERC20Test: BalanceOf not set"
        );
        assertEq(
            router.module(ERC20Lib.TRANSFER),
            address(erc20),
            "ERC20Test: Transfer not set"
        );
        assertEq(
            router.module(ERC20Lib.TRANSFER_FROM),
            address(erc20),
            "ERC20Test: TransferFrom not set"
        );
        assertEq(
            router.module(ERC20Lib.APPROVE),
            address(erc20),
            "ERC20Test: Approve not set"
        );
        assertEq(
            router.module(ERC20Lib.ALLOWANCE),
            address(erc20),
            "ERC20Test: Allowance not set"
        );
    }

    function testERC20Initialize() public {
        vm.startPrank(alice);

        address clone = Clones.clone(address(erc20));
        ERC20(clone).initializeERC20("Clone", "CLONE");

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        ERC20(clone).initializeERC20("Clone", "CLONE");

        assertEq(ERC20(clone).name(), "Clone");

        assertEq(ERC20(clone).symbol(), "CLONE");

        assertEq(ERC20(clone).decimals(), 18);

        assertEq(ERC20(clone).totalSupply(), 0);

        assertEq(ERC20(clone).balanceOf(alice), 0);
    }
}
