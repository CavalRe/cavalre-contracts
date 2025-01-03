// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module} from "@cavalre/contracts/router/Module.sol";

struct Store {
    mapping(address module => uint64) version;
    mapping(address module => bool) isInitializing;
}

library Lib {
    bytes32 private constant STORE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("cavalre.storage.Initializable")) - 1)
        ) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

abstract contract Initializable is Module {
    // Events
    event Initialized(address module, uint64 version);

    // Errors
    error InvalidInitialization(address module);
    error NotInitializing(address module);

    modifier initializer() {
        Store storage s = Lib.store();

        bool isTopLevelCall = !s.isInitializing[__self];
        uint64 initialized = s.version[__self];

        bool initialSetup = initialized == 0 && isTopLevelCall;

        if (!initialSetup) {
            revert InvalidInitialization(__self);
        }
        s.version[__self] = 1;
        if (isTopLevelCall) {
            s.isInitializing[__self] = true;
        }
        _;
        if (isTopLevelCall) {
            s.isInitializing[__self] = false;
            emit Initialized(__self, 1);
        }
    }

    modifier reinitializer(uint64 _version) {
        Store storage s = Lib.store();

        if (s.isInitializing[__self] || s.version[__self] >= _version) {
            revert InvalidInitialization(__self);
        }
        s.version[__self] = _version;
        s.isInitializing[__self] = true;
        _;
        s.isInitializing[__self] = false;
        emit Initialized(__self, _version);
    }

    modifier onlyInitializing() {
        Store storage s = Lib.store();

        if (!s.isInitializing[__self]) {
            revert NotInitializing(__self);
        }
        _;
    }
}
