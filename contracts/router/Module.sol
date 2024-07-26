// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Store {
    mapping(address => address) owners;
    mapping(bytes4 => address) modules;
}

library ModuleLib {
    // Stores
    bytes32 private constant STORE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("cavalre.storage.Module")) - 1)
        ) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

abstract contract Module {
    address internal immutable __self = address(this);

    // Errors
    error IsDelegated();
    error NotDelegated();
    error OwnableUnauthorizedAccount(address account);

    // Commands
    function commands() public pure virtual returns (bytes4[] memory _commands);

    function enforceIsOwner() internal view returns (Store storage s) {
        s = ModuleLib.store();
        if (s.owners[__self] != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

    function enforceIsDelegated() internal view {
        if (address(this) == __self) revert NotDelegated();
    }

    function enforceNotDelegated() internal view {
        if (address(this) != __self) revert IsDelegated();
    }
}
