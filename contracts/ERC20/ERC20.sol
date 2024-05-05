// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, ModuleLib as ML} from "@cavalre/contracts/router/Module.sol";
// import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20Upgradeable, ERC20Lib} from "./ERC20Upgradeable.sol";

contract ERC20 is ERC20Upgradeable, Module {
    // Selectors
    bytes4 internal constant INITIALIZE =
        bytes4(keccak256("initialize(string,string)"));
    bytes4 internal constant NAME = bytes4(keccak256("name()"));
    bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"));
    bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
    bytes4 internal constant BALANCE_OF =
        bytes4(keccak256("balanceOf(address)"));
    bytes4 internal constant TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant ALLOWANCE =
        bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant APPROVE =
        bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,uint256)"));

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](10);
        _commands[0] = INITIALIZE;
        _commands[1] = NAME;
        _commands[2] = SYMBOL;
        _commands[3] = DECIMALS;
        _commands[4] = TOTAL_SUPPLY;
        _commands[5] = BALANCE_OF;
        _commands[6] = TRANSFER;
        _commands[7] = ALLOWANCE;
        _commands[8] = APPROVE;
        _commands[9] = TRANSFER_FROM;
    }

    function initialize(
        string calldata name,
        string calldata symbol
    ) public initializer {
        __ERC20_init(name, symbol);
    }
}
