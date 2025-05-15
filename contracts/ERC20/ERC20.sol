// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module} from "@cavalre/contracts/router/Module.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

library ERC20Lib {
    // Selectors
    bytes4 internal constant INITIALIZE_ERC20 =
        bytes4(keccak256("initializeERC20(string,string)"));
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

    // Stores
    bytes32 private constant STORE_POSITION =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function store()
        internal
        pure
        returns (ERC20Upgradeable.ERC20Storage storage s)
    {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract ERC20 is Module, ERC20Upgradeable {
    uint8 private immutable _decimals;

    bytes32 private constant INITIALIZABLE_STORAGE =
        keccak256(
            abi.encode(
                uint256(keccak256("cavalre.storage.ERC20.Initializable")) - 1
            )
        ) & ~bytes32(uint256(0xff));

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function _initializableStorageSlot()
        internal
        pure
        override
        returns (bytes32)
    {
        return INITIALIZABLE_STORAGE;
    }

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](10);
        _commands[0] = ERC20Lib.INITIALIZE_ERC20;
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

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function initializeERC20(
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC20_init(name_, symbol_);
    }
}
