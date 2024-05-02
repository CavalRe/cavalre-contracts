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

    // Errors
    error IsDelegated();
    error NotDelegated();
    error OwnableUnauthorizedAccount(address account);

    function enforceIsOwner(
        address _module
    ) internal view returns (Store storage s) {
        s = store();
        if (s.owners[_module] != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
        return s;
    }

    function enforceIsDelegated(address _module) internal view {
        if (address(this) == _module) revert NotDelegated();
    }

    function enforceNotDelegated(address _module) internal view {
        if (address(this) != _module) revert IsDelegated();
    }

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

abstract contract Module {
    address private immutable __self = address(this);

    // Commands
    function commands() public pure virtual returns (bytes4[] memory _commands);

    function enforceIsOwner() internal view returns (Store storage) {
        return ModuleLib.enforceIsOwner(__self);
    }

    function enforceIsDelegated() internal view {
        ModuleLib.enforceIsDelegated(__self);
    }

    function enforceNotDelegated() internal view {
        ModuleLib.enforceNotDelegated(__self);
    }
}
