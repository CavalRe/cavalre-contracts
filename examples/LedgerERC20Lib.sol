// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library ERC20Lib {
    struct Store {
        mapping(address => mapping(address => uint256)) allowances;
    }

    bytes4 internal constant INITIALIZE_ERC20 = bytes4(keccak256("initializeERC20()"));
    bytes4 internal constant NAME = bytes4(keccak256("name()"));
    bytes4 internal constant SYMBOL = bytes4(keccak256("symbol()"));
    bytes4 internal constant DECIMALS = bytes4(keccak256("decimals()"));
    bytes4 internal constant TOTAL_SUPPLY = bytes4(keccak256("totalSupply()"));
    bytes4 internal constant BALANCE_OF = bytes4(keccak256("balanceOf(address)"));
    bytes4 internal constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"));
    bytes4 internal constant APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 internal constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 internal constant INCREASE_ALLOWANCE = bytes4(keccak256("increaseAllowance(address,uint256)"));
    bytes4 internal constant DECREASE_ALLOWANCE = bytes4(keccak256("decreaseAllowance(address,uint256)"));
    bytes4 internal constant FORCE_APPROVE = bytes4(keccak256("forceApprove(address,uint256)"));

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position_ = STORE_POSITION;
        assembly {
            s.slot := position_
        }
    }
}
