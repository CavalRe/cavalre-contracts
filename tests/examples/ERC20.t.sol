// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatcher} from "../../modules/dispatcher/Dispatcher.sol";
import {ERC20, ERC20Lib} from "../../examples/ERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Test} from "forge-std/src/Test.sol";

contract ERC20Test is Test {
    Dispatcher dispatcher;
    ERC20 erc20;

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    error InvalidInitialization();

    error NotInitializing();

    function setUp() public {
        vm.startPrank(alice);
        erc20 = new ERC20(18);
        dispatcher = new Dispatcher(alice);
        address[] memory modules_ = new address[](1);
        modules_[0] = address(erc20);
        dispatcher.addModule(modules_);
        erc20 = ERC20(payable(dispatcher));
    }

    function testERC20Initialize() public {
        vm.startPrank(alice);

        erc20.initializeERC20("Clone", "CLONE");

        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        erc20.initializeERC20("Clone", "CLONE");

        assertEq(erc20.name(), "Clone");

        assertEq(erc20.symbol(), "CLONE");

        assertEq(erc20.decimals(), 18);

        assertEq(erc20.totalSupply(), 0);

        assertEq(erc20.balanceOf(alice), 0);
    }
}
