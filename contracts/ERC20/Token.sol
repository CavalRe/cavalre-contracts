// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, ModuleLib as ML} from "@cavalre/contracts/router/Module.sol";
import {ERC20, ERC20Lib} from "@cavalre/contracts/ERC20/ERC20.sol";

library TokenLib {
    // Selectors
    bytes4 internal constant INITIALIZE_TOKEN =
        bytes4(keccak256("initializeToken(string,string)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

contract TokenFactory is Module {
    bytes4 internal constant CREATE_TOKEN =
        bytes4(keccak256("createToken(string,string,uint8,uint256)"));

    // event TokenCreated(
    //     address indexed _token,
    //     string _name,
    //     string _symbol,
    //     uint8 _decimals,
    //     uint256 _totalSupply
    // );

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](1);
        _commands[0] = CREATE_TOKEN;
    }

    // function createToken(
    //     string memory _name,
    //     string memory _symbol,
    //     uint8 _decimals,
    //     uint256 _totalSupply
    // ) external returns (address) {
    //     enforceIsOwner();
    //     Token token = new Token();
    //     token.initializeToken(_name, _symbol);

    //     emit TokenCreated(address(token), _name, _symbol, _decimals, _totalSupply);
    //     return address(token);
    // }
}

contract Token is ERC20 {
    address private immutable __self = address(this);
    address private immutable __owner = msg.sender;

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](12);
        _commands[0] = TokenLib.INITIALIZE_TOKEN;
        _commands[1] = ERC20Lib.NAME;
        _commands[2] = ERC20Lib.SYMBOL;
        _commands[3] = ERC20Lib.DECIMALS;
        _commands[4] = ERC20Lib.TOTAL_SUPPLY;
        _commands[5] = ERC20Lib.BALANCE_OF;
        _commands[6] = ERC20Lib.TRANSFER;
        _commands[7] = ERC20Lib.ALLOWANCE;
        _commands[7] = ERC20Lib.APPROVE;
        _commands[9] = ERC20Lib.TRANSFER_FROM;
        _commands[10] = TokenLib.MINT;
        _commands[11] = TokenLib.BURN;
    }

    // Commands
    function initializeToken(
        string memory _name,
        string memory _symbol
    ) external initializer {
        enforceIsOwner();
        __ERC20_init(_name, _symbol);
    }

    function mint(address _account, uint256 _amount) external {
        enforceIsOwner();
        ERC20Lib.mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        enforceIsOwner();
        ERC20Lib.burn(_account, _amount);
    }
}
