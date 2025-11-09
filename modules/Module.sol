// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ModuleLib} from "../libraries/ModuleLib.sol";

abstract contract Module {
    address internal immutable __self = address(this);

    // Errors
    error OwnableUnauthorizedAccount(address account);
    error NotDelegated();
    error IsDelegated();
    error InvalidCommandsLength(uint256 n);

    // Commands
    function selectors() external pure virtual returns (bytes4[] memory _selectors);

    function enforceIsOwner() internal view returns (ModuleLib.Store storage s) {
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
