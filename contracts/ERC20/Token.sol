// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, ModuleLib as ML} from "@cavalre/contracts/router/Module.sol";
import {ERC20} from "@cavalre/contracts/ERC20/ERC20.sol";
import {ERC20Lib} from "@cavalre/contracts/ERC20/ERC20Upgradeable.sol";

library TokenLib {
    // Selectors
    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));
}

contract TokenFactory is Module {
    bytes4 internal constant CREATE_TOKEN = bytes4(keccak256("createToken(string,string,uint8,uint256)"));

    event TokenCreated(
        address indexed _token,
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    );

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

    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) external returns (address) {
        enforceIsOwner();
        Token token = new Token();
        token.initialize(_name, _symbol);

        emit TokenCreated(address(token), _name, _symbol, _decimals, _totalSupply);
        return address(token);
    }
}

contract Token is ERC20 {
    address private immutable __self = address(this);
    address private immutable __owner = msg.sender;

    bytes4 internal constant MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(address,uint256)"));

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](12);
        _commands[0] = INITIALIZE;
        _commands[1] = NAME;
        _commands[2] = SYMBOL;
        _commands[3] = DECIMALS;
        _commands[4] = TOTAL_SUPPLY;
        _commands[5] = BALANCE_OF;
        _commands[6] = TRANSFER;
        _commands[7] = ALLOWANCE;
        _commands[7] = APPROVE;
        _commands[9] = TRANSFER_FROM;
        _commands[10] = MINT;
        _commands[11] = BURN;
    }

    // Commands
    function deployer() external view returns (address) {
        return __owner;
    }

    function mint(address _account, uint256 _amount) external {
        if (msg.sender != __owner)
            revert ML.OwnableUnauthorizedAccount(msg.sender);
        ERC20Lib.mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        if (msg.sender != __owner)
            revert ML.OwnableUnauthorizedAccount(msg.sender);
        ERC20Lib.burn(_account, _amount);
    }
}
