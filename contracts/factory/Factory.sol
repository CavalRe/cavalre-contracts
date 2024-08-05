// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Module} from "../router/Module.sol";

library FactoryLib {
    // Selectors
    bytes4 internal constant CLONE = bytes4(keccak256("clone(address)"));
    bytes4 internal constant CLONE_DETERMINISTIC =
        bytes4(keccak256("cloneDeterministic(address,bytes32)"));
    bytes4 internal constant PREDICT_DETERMINISTIC_ADDRESS_1 =
        bytes4(
            keccak256("predictDeterministicAddress(address,bytes32,address)")
        );
    bytes4 internal constant PREDICT_DETERMINISTIC_ADDRESS_2 =
        bytes4(
            keccak256(
                "predictDeterministicCreate2Address(address,bytes32)"
            )
        );
}

contract Factory is Module {
    function commands() public pure override returns (bytes4[] memory _commands) {
        _commands = new bytes4[](4);
        _commands[0] = FactoryLib.CLONE;
        _commands[1] = FactoryLib.CLONE_DETERMINISTIC;
        _commands[2] = FactoryLib.PREDICT_DETERMINISTIC_ADDRESS_1;
        _commands[3] = FactoryLib.PREDICT_DETERMINISTIC_ADDRESS_2;

        return _commands;
    }

    function clone() public returns (address instance) {
        return Clones.clone(address(this));
    }

    function cloneDeterministic(bytes32 salt) public returns (address instance) {
        return Clones.cloneDeterministic(address(this), salt);
    }

    function predictDeterministicAddress(
        bytes32 salt,
        address deployer
    ) public view returns (address predicted) {
        return Clones.predictDeterministicAddress(address(this), salt, deployer);
    }

    function predictDeterministicAddress(
        bytes32 salt
    ) public view returns (address predicted) {
        return Clones.predictDeterministicAddress(address(this), salt);
    }
}
