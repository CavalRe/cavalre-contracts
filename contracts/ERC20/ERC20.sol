// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, ModuleLib as ML} from "@cavalre/contracts/router/Module.sol";
// import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20Upgradeable, ERC20Lib} from "./ERC20Upgradeable.sol";

contract ERC20 is ERC20Upgradeable, Module {
    // // Selectors
    // bytes4 internal constant NAME = bytes4(keccak256("name()"));
    // bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"));
    // bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"));
    // bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
    // bytes4 internal constant BALANCE_OF =
    //     bytes4(keccak256("balanceOf(address)"));
    // bytes4 internal constant TRANSFER =
    //     bytes4(keccak256("transfer(address,uint256)"));
    // bytes4 internal constant ALLOWANCE =
    //     bytes4(keccak256("allowance(address,address)"));
    // bytes4 internal constant APPROVE =
    //     bytes4(keccak256("approve(address,uint256)"));
    // bytes4 internal constant TRANSFER_FROM =
    //     bytes4(keccak256("transferFrom(address,address,uint256)"));

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](10);
        _commands[0] = ERC20Lib.INITIALIZE;
        _commands[1] = ERC20Lib.NAME;
        _commands[2] = ERC20Lib.SYMBOL;
        _commands[3] = ERC20Lib.DECIMALS;
        _commands[4] = ERC20Lib.TOTAL_SUPPLY;
        _commands[5] = ERC20Lib.BALANCE_OF;
        _commands[6] = ERC20Lib.TRANSFER;
        _commands[7] = ERC20Lib.ALLOWANCE;
        _commands[8] = ERC20Lib.APPROVE;
        _commands[9] = ERC20Lib.TRANSFER_FROM;
    }

    function initialize(
        string calldata name,
        string calldata symbol
    ) public virtual initializer {
        __ERC20_init(name, symbol);
    }
}
