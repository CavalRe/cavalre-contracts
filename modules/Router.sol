// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, Lib as ML} from "./Module.sol";
import {RouterLib as Lib} from "../libraries/RouterLib.sol";

interface INativeHandler {
    function handleNative() external payable;
}

contract Router is Module {
    // Events
    event CommandSet(bytes4 indexed command, address indexed module);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event RouterCreated(address indexed router);

    // Errors
    error CommandAlreadySet(bytes4 _command, address _module);
    error CommandNotFound(bytes4 _command);
    error ModuleNotFound(address _module);

    constructor(address owner_) {
        ML.Store storage s = ML.store();
        s.owners[__self] = owner_;
        emit RouterCreated(__self);
    }

    function commands() public pure override returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    fallback() external payable {
        address module_ = Lib.store().modules[msg.sig];
        if (module_ == address(0)) revert CommandNotFound(msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), module_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {
        INativeHandler(address(this)).handleNative{value: msg.value}();
    }

    function getCommands(address module_) public returns (bytes4[] memory) {
        (bool _success, bytes memory _data) = module_.call(abi.encodeWithSignature("commands()"));
        require(_success, "Command: getCommands failed");
        return abi.decode(_data, (bytes4[]));
    }

    function addModule(address module_) external {
        enforceIsOwner();
        bytes4[] memory _commands = getCommands(module_);
        if (_commands.length == 0) revert ModuleNotFound(module_);
        Lib.Store storage s = Lib.store();
        for (uint256 i = 0; i < _commands.length; i++) {
            if (s.modules[_commands[i]] != address(0)) {
                revert CommandAlreadySet(_commands[i], module_);
            }
            s.modules[_commands[i]] = module_;
            emit CommandSet(_commands[i], module_);
        }
        ML.store().owners[module_] = msg.sender;
        emit ModuleAdded(module_);
    }

    function removeModule(address module_) external {
        enforceIsOwner();
        bytes4[] memory _commands = getCommands(module_);
        if (_commands.length == 0) revert ModuleNotFound(module_);
        Lib.Store storage s = Lib.store();
        for (uint256 i = 0; i < _commands.length; i++) {
            s.modules[_commands[i]] = address(0);
            emit CommandSet(_commands[i], address(0));
        }
        delete ML.store().owners[module_];
        emit ModuleRemoved(module_);
    }

    function owner(address module_) public view returns (address) {
        return ML.store().owners[module_];
    }

    function module(bytes4 selector_) public view returns (address) {
        return Lib.store().modules[selector_];
    }
}
