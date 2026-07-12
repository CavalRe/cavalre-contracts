// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {IDispatcher} from "../dispatcher/IDispatcher.sol";

library DispatcherLib {
    struct Command {
        address module;
        string signature;
        bytes4 selector;
    }

    // -- Storage --

    struct Store {
        mapping(address => address) owners;
        mapping(bytes4 => address) modules;
        address[] moduleList;
        mapping(address => uint256) moduleListIndexes;
    }

    bytes32 private constant STORE_POSITION =
        keccak256(abi.encode(uint256(keccak256("cavalre.storage.Dispatcher")) - 1)) & ~bytes32(uint256(0xff));

    function store() internal pure returns (Store storage s) {
        bytes32 position = STORE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // -- Module Management --

    function addModule(address module_) internal {
        (Store storage s,, bytes4[] memory _selectors) = enforceModuleUpdate(module_);
        if (_selectors.length == 0) revert IDispatcher.ModuleNotFound(module_);
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 _selector = _selectors[i];
            if (s.modules[_selector] != address(0)) {
                revert IDispatcher.CommandAlreadySet(_selector, module_);
            }
            s.modules[_selector] = module_;
            emit IDispatcher.CommandSet(_selector, module_);
        }
        s.moduleListIndexes[module_] = s.moduleList.length + 1;
        s.moduleList.push(module_);
        s.owners[module_] = msg.sender;
        emit IDispatcher.ModuleAdded(module_);
    }

    function removeModule(address module_) internal {
        (Store storage s,, bytes4[] memory _selectors) = enforceModuleUpdate(module_);
        if (_selectors.length == 0) revert IDispatcher.ModuleNotFound(module_);
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 _selector = _selectors[i];
            address _actualModule = s.modules[_selector];
            if (_actualModule != module_) {
                revert IDispatcher.CommandInWrongModule(_selector, module_, _actualModule);
            }
            s.modules[_selector] = address(0);
            emit IDispatcher.CommandSet(_selector, address(0));
        }
        uint256 _moduleIndex = s.moduleListIndexes[module_] - 1;
        uint256 _lastModuleIndex = s.moduleList.length - 1;
        if (_moduleIndex != _lastModuleIndex) {
            address _lastModule = s.moduleList[_lastModuleIndex];
            s.moduleList[_moduleIndex] = _lastModule;
            s.moduleListIndexes[_lastModule] = _moduleIndex + 1;
        }
        s.moduleList.pop();
        delete s.moduleListIndexes[module_];
        delete s.owners[module_];
        emit IDispatcher.ModuleRemoved(module_);
    }

    // -- Inspection --

    function owner(address module_) internal view returns (address) {
        return store().owners[module_];
    }

    function module(bytes4 selector_) internal view returns (address) {
        return store().modules[selector_];
    }

    function modules() internal view returns (address[] memory) {
        return store().moduleList;
    }

    function verifyModule(address module_)
        internal
        pure
        returns (bytes4[] memory _selectors, string[] memory _signatures)
    {
        _selectors = Dispatchable(module_).selectors();
        _signatures = Dispatchable(module_).signatures();
        if (_selectors.length != _signatures.length) {
            revert IDispatcher.InvalidSignaturesLength(_selectors.length, _signatures.length);
        }
        for (uint256 i = 0; i < _selectors.length; i++) {
            if (bytes4(keccak256(bytes(_signatures[i]))) != _selectors[i]) {
                revert IDispatcher.InvalidSignature(_selectors[i], _signatures[i]);
            }
        }
    }

    function signatures(address module_) internal pure returns (string[] memory _signatures) {
        (, _signatures) = verifyModule(module_);
    }

    function selectors(address module_) internal pure returns (bytes4[] memory _selectors) {
        (_selectors,) = verifyModule(module_);
    }

    function commands() internal view returns (Command[] memory _commands) {
        return commands(modules());
    }

    function commands(address[] memory modules_) internal pure returns (Command[] memory _commands) {
        uint256 n;
        for (uint256 i = 0; i < modules_.length; i++) {
            (bytes4[] memory _selectors,) = verifyModule(modules_[i]);
            n += _selectors.length;
        }
        _commands = new Command[](n);
        uint256 k;
        for (uint256 i = 0; i < modules_.length; i++) {
            address _module = modules_[i];
            (bytes4[] memory _selectors, string[] memory _signatures) = verifyModule(_module);
            for (uint256 j = 0; j < _selectors.length; j++) {
                _commands[k++] = Command({module: _module, signature: _signatures[j], selector: _selectors[j]});
            }
        }
    }

    function enforceModuleUpdate(address module_)
        private
        view
        returns (Store storage s, string[] memory _signatures, bytes4[] memory _selectors)
    {
        s = store();
        if (s.owners[address(this)] != msg.sender) {
            revert IDispatcher.OwnableUnauthorizedAccount(msg.sender);
        }
        (_selectors, _signatures) = verifyModule(module_);
    }
}
