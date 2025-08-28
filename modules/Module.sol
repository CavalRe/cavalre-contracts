// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ModuleLib as Lib} from "../libraries/ModuleLib.sol";

abstract contract Module {
    address internal immutable __self = address(this);

    // Errors
    error OwnableUnauthorizedAccount(address account);
    error NotDelegated();
    error IsDelegated();
    error InvalidCommandsLength(uint256 n);

    // Commands
    function commands() external pure virtual returns (bytes4[] memory _commands);

    function enforceIsOwner() internal view returns (Lib.Store storage s) {
        s = Lib.store();
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
