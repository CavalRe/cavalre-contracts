// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Router} from "../modules/Router.sol";
import {ERC20, ERC20Lib} from "./ERC20.sol";
import {ModuleLib} from "../modules/Module.sol";

import {Test, console} from "forge-std/src/Test.sol";

library TokenLib {
    // Selectors
    bytes4 internal constant INITIALIZE_TOKEN = bytes4(keccak256("initializeTestToken(string,string)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(uint256)"));
    bytes4 internal constant BURN = bytes4(keccak256("burn(uint256)"));
}

contract TestToken is ERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(uint8 _decimals) ERC20(_decimals) {}

    function selectors() public pure virtual override returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](12);
        _selectors[0] = TokenLib.INITIALIZE_TOKEN;
        _selectors[1] = ERC20Lib.NAME;
        _selectors[2] = ERC20Lib.SYMBOL;
        _selectors[3] = ERC20Lib.DECIMALS;
        _selectors[4] = ERC20Lib.TOTAL_SUPPLY;
        _selectors[5] = ERC20Lib.BALANCE_OF;
        _selectors[6] = ERC20Lib.TRANSFER;
        _selectors[7] = ERC20Lib.ALLOWANCE;
        _selectors[7] = ERC20Lib.APPROVE;
        _selectors[9] = ERC20Lib.TRANSFER_FROM;
        _selectors[10] = TokenLib.MINT;
        _selectors[11] = TokenLib.BURN;
    }

    // Commands
    function initializeTestToken(string memory _name, string memory _symbol) public initializer {
        __ERC20_init(_name, _symbol);
    }

    function mint(uint256 _amount) public {
        super._mint(msg.sender, _amount);
    }

    function burn(uint256 _amount) public {
        super._burn(msg.sender, _amount);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        mint(msg.value);
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(_msgSender()) >= wad);
        burn(wad);
        (bool success,) = payable(_msgSender()).call{value: wad}("");
        require(success, "Transfer failed");
        emit Withdrawal(_msgSender(), wad);
    }
}
