// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module, RouterStore} from "./Module.sol";

contract Router is Module {
    // Events
    event CommandSet(bytes4 indexed command, address indexed module);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    // Errors
    error CommandAlreadySet(bytes4 _command, address _module);
    error CommandNotFound(bytes4 _command);
    error ModuleNotFound(address _module);

    constructor() {
        routerStore().owner = msg.sender;
    }

    function _getCommands(address _module) internal returns (bytes4[] memory) {
        (bool success, bytes memory data) = _module.call(abi.encodeWithSignature("commands()"));
        require(success, "Command: _getCommands failed");
        return abi.decode(data, (bytes4[]));
    }

    function _setCommand(bytes4 _command, address _module) internal {
        RouterStore storage s = enforceIsOwner();
        if (s.modules[_command] == _module) revert CommandAlreadySet(_command, _module);
        s.modules[_command] = _module;
        emit CommandSet(_command, _module);
    }

    function addModule(address _module) external {
        bytes4[] memory _commands = _getCommands(_module);
        if (_commands.length == 0) revert ModuleNotFound(_module);
        for (uint256 i = 0; i < _commands.length; i++) {
            _setCommand(_commands[i], _module); // Access is controlled here
        }
        emit ModuleAdded(_module);
    }

    function removeModule(address _module) external {
        bytes4[] memory _commands = _getCommands(_module);
        for (uint256 i = 0; i < _commands.length; i++) {
            _setCommand(_commands[i], address(0)); // Access is controlled here
        }
        emit ModuleRemoved(_module);
    }

    fallback() external payable {
        address module_ = routerStore().modules[msg.sig];
        if (module_ == address(0)) revert CommandNotFound(msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), module_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
