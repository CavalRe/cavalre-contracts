// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DispatcherLib} from "./DispatcherLib.sol";
import {Dispatchable} from "./Dispatchable.sol";
import {IDispatcher} from "./IDispatcher.sol";

interface INativeHandler {
    function handleNative() external payable;
}

/*
 * Dispatcher is the immutable entrypoint for a modular, delegatecall-based contract system.
 *
 * Routing model:
 * - Calls whose selectors are not declared directly by Dispatcher reach `fallback`.
 * - Dispatcher resolves the selector to an installed module, then delegatecalls that module.
 * - Module code executes against Dispatcher storage and preserves the Dispatcher address for users.
 * - The Dispatcher owner can add or remove modules. Inspect `owner(address(this))` before trusting
 *   the current routing configuration.
 *
 * Explorer verification procedure:
 * 1. Verify this Dispatcher source at the deployed Router address.
 * 2. Read `modules()` to enumerate installed module addresses.
 * 3. Verify the source code for every returned module address.
 * 4. Read `commands()` for all modules, or `commands(modules_)` in module batches when needed.
 *    Each command reports its module address, canonical Solidity signature, and selector.
 * 5. For every command, confirm `module(command.selector)` equals `command.module`.
 * 6. Inspect `verifyModule(module_)` to independently validate that a module's signatures hash to
 *    its selectors. `signatures(module_)` and `selectors(module_)` expose the same validated data.
 *
 * These read functions are declared directly on Dispatcher so they are available in a verified
 * block explorer ABI without requiring the caller to know a module ABI in advance.
 */
contract Dispatcher is IDispatcher {
    // -- Init --

    // Initial owner authorized to add and remove modules.
    constructor(address owner_) {
        DispatcherLib.store().owners[address(this)] = owner_;
        emit DispatcherCreated(address(this));
    }

    // -- Dispatch --

    // Routes an undeclared selector to its installed module with delegatecall.
    fallback() external payable {
        address module_ = DispatcherLib.module(msg.sig);
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

    // Routes native value to the installed `handleNative()` command.
    receive() external payable {
        INativeHandler(address(this)).handleNative{value: msg.value}();
    }

    // -- Module Management --

    // Installs a verified module and all commands in its manifest.
    function addModule(address module_) external override {
        DispatcherLib.addModule(module_);
    }

    // Removes an installed module and all commands in its manifest.
    function removeModule(address module_) external override {
        DispatcherLib.removeModule(module_);
    }

    // -- Inspection --

    // Returns the owner authorized to manage a module or Dispatcher itself.
    function owner(address module_) external view override returns (address) {
        return DispatcherLib.owner(module_);
    }

    // Returns the installed module currently responsible for a command selector.
    function module(bytes4 selector_) external view override returns (address) {
        return DispatcherLib.module(selector_);
    }

    // Returns every installed module address.
    function modules() public view override returns (address[] memory) {
        return DispatcherLib.modules();
    }

    // Validates a module's selector/signature manifest and returns both arrays.
    function verifyModule(address module_)
        external
        pure
        override
        returns (bytes4[] memory selectors_, string[] memory signatures_)
    {
        return DispatcherLib.verifyModule(module_);
    }

    // Returns a module's validated canonical Solidity signatures.
    function signatures(address module_) external pure override returns (string[] memory) {
        return DispatcherLib.signatures(module_);
    }

    // Returns a module's validated command selectors.
    function selectors(address module_) external pure override returns (bytes4[] memory) {
        return DispatcherLib.selectors(module_);
    }

    // Returns command metadata for every installed module.
    function commands() external view override returns (DispatcherLib.Command[] memory) {
        return DispatcherLib.commands();
    }

    // Returns command metadata for a caller-selected module batch.
    function commands(address[] calldata modules_) external pure override returns (DispatcherLib.Command[] memory) {
        return DispatcherLib.commands(modules_);
    }
}
