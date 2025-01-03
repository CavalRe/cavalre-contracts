// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@cavalre/contracts/Initializable/Initializable.sol";

struct Store {
    uint256 status;
}

library Lib {
    bytes32 private constant STORE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("cavalre.storage.ReentrancyGuard")) - 1)
        ) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

abstract contract ReentrancyGuard is Initializable {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    // Errors
    error Reentrancy();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        Store storage s = Lib.store();
        s.status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        Store storage s = Lib.store();
        if (s.status == ENTERED) {
            revert Reentrancy();
        }
        s.status = ENTERED;
        _;
        s.status = NOT_ENTERED;
    }
}