// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DispatcherLib} from "../dispatcher/DispatcherLib.sol";

interface IDispatcher {
    event CommandSet(bytes4 indexed command, address indexed module);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event DispatcherCreated(address indexed dispatcher);

    error CommandAlreadySet(bytes4 command, address module);
    error CommandNotFound(bytes4 command);
    error CommandInWrongModule(bytes4 command, address expectedModule, address actualModule);
    error ModuleNotFound(address module);
    error OwnableUnauthorizedAccount(address account);
    error InvalidSignaturesLength(uint256 expectedLength, uint256 actualLength);
    error InvalidSignature(bytes4 selector, string signature);

    function addModule(address module_) external;

    function removeModule(address module_) external;

    function modules() external view returns (address[] memory);

    function owner(address module_) external view returns (address);

    function module(bytes4 selector_) external view returns (address);

    function verifyModule(address module_)
        external
        pure
        returns (bytes4[] memory selectors_, string[] memory signatures_);

    function signatures(address module_) external view returns (string[] memory);

    function selectors(address module_) external view returns (bytes4[] memory);

    function commands() external view returns (DispatcherLib.Command[] memory);

    function commands(address[] calldata modules_) external view returns (DispatcherLib.Command[] memory);
}
