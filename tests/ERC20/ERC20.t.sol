// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Router} from "../../contracts/router/Router.sol";
import {ERC20, ERC20Lib} from "../../contracts/ERC20/ERC20.sol";
import {Module, ModuleLib as ML} from "../../contracts/router/Module.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/src/Test.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC20Test is Test {
    Router router;
    ERC20 erc20;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    function setUp() public {
        vm.startPrank(alice);
        erc20 = new ERC20(18);
        router = new Router(alice);
        router.addModule(address(erc20));
        erc20 = ERC20(payable(router));
    }

    function testERC20Initialize() public {
        vm.startPrank(alice);

        erc20.initializeERC20("Clone", "CLONE");

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        erc20.initializeERC20("Clone", "CLONE");

        assertEq(erc20.name(), "Clone");

        assertEq(erc20.symbol(), "CLONE");

        assertEq(erc20.decimals(), 18);

        assertEq(erc20.totalSupply(), 0);

        assertEq(erc20.balanceOf(alice), 0);
    }
}
