// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module, ModuleLib as ML} from "@cavalre/router/Module.sol";
import {IERC20, ERC20, ERC20Lib} from "@cavalre/erc20/ERC20.sol";

library TokenLib {
    // Selectors
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

interface IToken is IERC20 {   
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

contract Token is IToken, ERC20 {
    address private immutable __self = address(this);

    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](15);
        _commands[0] = CLONE;
        _commands[1] = INITIALIZE;
        _commands[2] = NAME;
        _commands[3] = SYMBOL;
        _commands[4] = DECIMALS;
        _commands[5] = TOTAL_SUPPLY;
        _commands[6] = BALANCE_OF;
        _commands[7] = TRANSFER;
        _commands[8] = ALLOWANCE;
        _commands[9] = APPROVE;
        _commands[10] = TRANSFER_FROM;
        _commands[11] = INCREASE_ALLOWANCE;
        _commands[12] = DECREASE_ALLOWANCE;
        _commands[13] = MINT;
        _commands[14] = BURN;
    }

    // Commands
    function mint(address _account, uint256 _amount) external {
        enforceIsOwner();
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        enforceIsOwner();
        _burn(_account, _amount);
    }
}
