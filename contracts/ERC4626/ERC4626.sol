// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module} from "@cavalre/contracts/router/Module.sol";
import {ERC20Lib} from "@cavalre/contracts/ERC20/ERC20.sol";

import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ERC4626Lib {
    // Selectors
    bytes4 internal constant INITIALIZE_ERC4626 =
        bytes4(keccak256("initializeERC4626(IERC20,string,string)"));
    bytes4 internal constant ASSET = bytes4(keccak256("asset()"));
    bytes4 internal constant TOTAL_ASSETS = bytes4(keccak256("totalAssets()"));
    bytes4 internal constant CONVERT_TO_SHARES =
        bytes4(keccak256("convertToShares(uint256)"));
    bytes4 internal constant CONVERT_TO_ASSETS =
        bytes4(keccak256("convertToAssets(uint256)"));
    bytes4 internal constant MAX_DEPOSIT = bytes4(keccak256("maxDeposit()"));
    bytes4 internal constant PREVIEW_DEPOSIT =
        bytes4(keccak256("previewDeposit(uint256)"));
    bytes4 internal constant DEPOSIT = bytes4(keccak256("deposit(uint256)"));
    bytes4 internal constant MAX_MINT = bytes4(keccak256("maxMint()"));
    bytes4 internal constant PREVIEW_MINT =
        bytes4(keccak256("previewMint(uint256)"));
    bytes4 internal constant MINT = bytes4(keccak256("mint(uint256)"));
    bytes4 internal constant MAX_WITHDRAW = bytes4(keccak256("maxWithdraw()"));
    bytes4 internal constant PREVIEW_WITHDRAW =
        bytes4(keccak256("previewWithdraw(uint256)"));
    bytes4 internal constant WITHDRAW = bytes4(keccak256("withdraw(uint256)"));
    bytes4 internal constant MAX_REDEEM = bytes4(keccak256("maxRedeem()"));
    bytes4 internal constant PREVIEW_REDEEM =
        bytes4(keccak256("previewRedeem(uint256)"));
    bytes4 internal constant REDEEM = bytes4(keccak256("redeem(uint256)"));

    // Stores
    bytes32 private constant STORE_POSITION =
        0x0773e532dfede91f04b12a73d3d2acd361424f41f76b4fb79f090161e36b4e00;

    function store()
        internal
        pure
        returns (ERC4626Upgradeable.ERC4626Storage storage s)
    {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

contract ERC4626 is Module, ERC4626Upgradeable {
    uint8 immutable private _decimals;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function commands()
        public
        pure
        virtual
        override
        returns (bytes4[] memory _commands)
    {
        _commands = new bytes4[](26);
        _commands[0] = ERC4626Lib.INITIALIZE_ERC4626;
        _commands[1] = ERC20Lib.NAME;
        _commands[2] = ERC20Lib.SYMBOL;
        _commands[3] = ERC20Lib.DECIMALS;
        _commands[4] = ERC20Lib.TOTAL_SUPPLY;
        _commands[5] = ERC20Lib.BALANCE_OF;
        _commands[6] = ERC20Lib.TRANSFER;
        _commands[7] = ERC20Lib.ALLOWANCE;
        _commands[8] = ERC20Lib.APPROVE;
        _commands[9] = ERC20Lib.TRANSFER_FROM;
        _commands[10] = ERC4626Lib.ASSET;
        _commands[11] = ERC4626Lib.TOTAL_ASSETS;
        _commands[12] = ERC4626Lib.CONVERT_TO_SHARES;
        _commands[13] = ERC4626Lib.CONVERT_TO_ASSETS;
        _commands[14] = ERC4626Lib.MAX_DEPOSIT;
        _commands[15] = ERC4626Lib.PREVIEW_DEPOSIT;
        _commands[16] = ERC4626Lib.DEPOSIT;
        _commands[17] = ERC4626Lib.MAX_MINT;
        _commands[18] = ERC4626Lib.PREVIEW_MINT;
        _commands[19] = ERC4626Lib.MINT;
        _commands[20] = ERC4626Lib.MAX_WITHDRAW;
        _commands[21] = ERC4626Lib.PREVIEW_WITHDRAW;
        _commands[22] = ERC4626Lib.WITHDRAW;
        _commands[23] = ERC4626Lib.MAX_REDEEM;
        _commands[24] = ERC4626Lib.PREVIEW_REDEEM;
        _commands[25] = ERC4626Lib.REDEEM;

    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function initialize4626(
        IERC20 _token,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __ERC4626_init(_token);
    }
}
