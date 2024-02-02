// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    // Events
    event CommandSet(bytes4 indexed command, address indexed module);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    // Errors
    error CommandAlreadySet(bytes4 _command, address _module);
    error CommandNotFound(bytes4 _command);
    error ModuleNotFound(address _module);

    // Commands
    function getCommands(address _module) external returns (bytes4[] memory);
    
    function setCommand(bytes4 _command, address _module) external;

    function addModule(address _module) external;

    function removeModule(address _module) external;

    function owner(address _module) external view returns (address);

    function module(bytes4 _selector) external view returns (address);
}