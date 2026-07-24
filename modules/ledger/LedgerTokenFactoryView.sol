// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedgerTokenFactory} from "./ILedgerTokenFactory.sol";
import {LedgerTokenFactoryLib} from "./LedgerTokenFactoryLib.sol";

contract LedgerTokenFactoryView is Dispatchable {
    function signatures() external pure override returns (string[] memory _signatures) {
        _signatures = new string[](2);
        _signatures[0] = "tokenSalt(string,string,uint8,string)";
        _signatures[1] = "predictToken(string,string,uint8,string)";
    }

    function selectors() external pure override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](2);
        _selectors[n++] = bytes4(keccak256("tokenSalt(string,string,uint8,string)"));
        _selectors[n++] = bytes4(keccak256("predictToken(string,string,uint8,string)"));
        if (n != 2) revert InvalidCommandsLength(n);
    }

    function tokenSalt(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        external
        pure
        returns (bytes32)
    {
        return LedgerTokenFactoryLib.tokenSalt(_tokenMetadata(name_, symbol_, decimals_, version_));
    }

    function predictToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        external
        view
        returns (address)
    {
        return LedgerTokenFactoryLib.predictToken(_tokenMetadata(name_, symbol_, decimals_, version_));
    }

    function _tokenMetadata(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        private
        pure
        returns (ILedgerTokenFactory.TokenMetadata memory _token)
    {
        _token = ILedgerTokenFactory.TokenMetadata({
            name: name_, symbol: symbol_, decimals: decimals_, version: version_
        });
    }
}
