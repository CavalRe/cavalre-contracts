// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DispatchableLib} from "../libraries/DispatchableLib.sol";

abstract contract Dispatchable {
    address internal immutable __self = address(this);

    // Errors
    error OwnableUnauthorizedAccount(address account);
    error NotDelegated();
    error IsDelegated();
    error InvalidCommandsLength(uint256 n);

    // Commands
    function selectors() external pure virtual returns (bytes4[] memory _selectors);

    function enforceIsOwner() internal view returns (DispatchableLib.Store storage s) {
        s = DispatchableLib.store();
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
