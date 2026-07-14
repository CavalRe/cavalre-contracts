// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DispatcherLib} from "./DispatcherLib.sol";
import {IDispatcher} from "./IDispatcher.sol";

abstract contract Dispatchable {
    address internal immutable __self = address(this);

    // Errors
    error NotDelegated();
    error IsDelegated();
    error InvalidCommandsLength(uint256 n);

    // Commands
    function signatures() external pure virtual returns (string[] memory _signatures);

    function selectors() external pure virtual returns (bytes4[] memory _selectors);

    function enforceIsOwner() internal view {
        if (DispatcherLib.store().owners[__self] != msg.sender) {
            revert IDispatcher.OwnableUnauthorizedAccount(msg.sender);
        }
    }

    function enforceIsDelegated() internal view {
        if (address(this) == __self) revert NotDelegated();
    }

    function enforceNotDelegated() internal view {
        if (address(this) != __self) revert IsDelegated();
    }
}
