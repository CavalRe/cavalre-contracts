// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {LedgerTokenFactoryLib} from "./LedgerTokenFactoryLib.sol";

contract LedgerTokenFactory is Dispatchable {
    function signatures() external pure virtual override returns (string[] memory _signatures) {
        _signatures = new string[](2);
        _signatures[0] = "createInternalToken(string,string,uint8,string)";
        _signatures[1] = "createClaimToken(string,string,uint8,address,address,address,string)";
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](2);
        _selectors[n++] = bytes4(keccak256("createInternalToken(string,string,uint8,string)"));
        _selectors[n++] = bytes4(keccak256("createClaimToken(string,string,uint8,address,address,address,string)"));
        if (n != 2) revert InvalidCommandsLength(n);
    }

    function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        external
        returns (address _token, uint256 _flags)
    {
        enforceIsOwner();
        return LedgerTokenFactoryLib.createInternalToken(name_, symbol_, decimals_, version_);
    }

    function createClaimToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address root_,
        address holderParent_,
        address relative_,
        string memory version_
    ) external returns (address _token, uint256 _flags) {
        enforceIsOwner();
        return
            LedgerTokenFactoryLib.createClaimToken(name_, symbol_, decimals_, root_, holderParent_, relative_, version_);
    }
}
