// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Module, ModuleLib as ML, Store} from "./Module.sol";
import {IRouter} from "./IRouter.sol";

library RouterLib {
    // Stores
    bytes32 private constant STORE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("cavalre.storage.Router")) - 1)
        ) & ~bytes32(uint256(0xff));

    // Events
    event CommandSet(bytes4 indexed command, address indexed module);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event RouterCreated(address indexed router);

    // Errors
    error CommandAlreadySet(bytes4 _command, address _module);
    error CommandNotFound(bytes4 _command);
    error ModuleNotFound(address _module);

    // Selectors
    bytes4 internal constant ROUTER = bytes4(keccak256(bytes("Router()")));

    // Commands
    function getCommands(address _module) internal returns (bytes4[] memory) {
        (bool success, bytes memory data) = _module.call(
            abi.encodeWithSignature("commands()")
        );
        require(success, "Command: _getCommands failed");
        return abi.decode(data, (bytes4[]));
    }

    // To remove a command, set the module to address(0)
    function setCommand(bytes4 _command, address _module) internal {
        Store storage s = ML.store();
        ML.enforceIsOwner(s.modules[ROUTER]);
        if (s.modules[_command] == _module)
            revert CommandAlreadySet(_command, _module);
        s.modules[_command] = _module;
        emit CommandSet(_command, _module);
    }

    function addModule(address _module) internal {
        bytes4[] memory _commands = getCommands(_module);
        if (_commands.length == 0) revert ModuleNotFound(_module);
        for (uint256 i = 0; i < _commands.length; i++) {
            setCommand(_commands[i], _module); // Access is controlled here
        }
        ML.store().owners[_module] = msg.sender;
        emit ModuleAdded(_module);
    }

    function removeModule(address _module) internal {
        bytes4[] memory _commands = getCommands(_module);
        if (_commands.length == 0) revert ModuleNotFound(_module);
        for (uint256 i = 0; i < _commands.length; i++) {
            setCommand(_commands[i], address(0)); // Access is controlled here
        }
        emit ModuleRemoved(_module);
    }

    function owner(address _module) internal view returns (address) {
        return ML.store().owners[_module];
    }

    function module(bytes4 selector) internal view returns (address) {
        return ML.store().modules[selector];
    }
}

contract Router is IRouter, Module {
    address private immutable __self = address(this);

    constructor() {
        Store storage s = ML.store();
        s.owners[__self] = msg.sender;
        s.modules[RouterLib.ROUTER] = __self;
        emit RouterLib.RouterCreated(__self);
    }

    function commands() public pure override returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    fallback() external payable {
        address module_ = ML.store().modules[msg.sig];
        if (module_ == address(0)) revert RouterLib.CommandNotFound(msg.sig);

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

    function getCommands(address _module) external returns (bytes4[] memory) {
        return RouterLib.getCommands(_module);
    }

    function setCommand(bytes4 _command, address _module) external {
        RouterLib.setCommand(_command, _module);
    }

    function addModule(address _module) external {
        RouterLib.addModule(_module);
    }

    function removeModule(address _module) external {
        RouterLib.removeModule(_module);
    }

    function owner(address _module) public view returns (address) {
        return RouterLib.owner(_module);
    }

    function module(bytes4 _selector)
        public
        view
        returns (address)
    {
        return RouterLib.module(_selector);
    }
}
