// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ModuleLib {
    struct Store {
        mapping(address => address) owners;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Module")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
