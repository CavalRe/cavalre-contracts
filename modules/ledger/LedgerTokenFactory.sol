// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Dispatchable} from "../dispatcher/Dispatchable.sol";
import {ILedgerTokenFactory} from "./ILedgerTokenFactory.sol";
import {LedgerTokenFactoryLib} from "./LedgerTokenFactoryLib.sol";

contract LedgerTokenFactory is Dispatchable {
    function signatures() external pure virtual override returns (string[] memory _signatures) {
        _signatures = new string[](2);
        _signatures[0] = "createInternalTokens((string,string,uint8,string)[])";
        _signatures[1] = "createShareTokens((address,(string,string,uint8,string))[])";
    }

    function selectors() external pure virtual override returns (bytes4[] memory _selectors) {
        uint256 n;
        _selectors = new bytes4[](2);
        _selectors[n++] = bytes4(keccak256("createInternalTokens((string,string,uint8,string)[])"));
        _selectors[n++] = bytes4(keccak256("createShareTokens((address,(string,string,uint8,string))[])"));
        if (n != 2) revert InvalidCommandsLength(n);
    }

    function createInternalTokens(ILedgerTokenFactory.TokenMetadata[] memory tokens_)
        external
        returns (address[] memory _tokenAddresses, uint256[] memory _flags)
    {
        enforceIsOwner();
        _tokenAddresses = new address[](tokens_.length);
        _flags = new uint256[](tokens_.length);

        for (uint256 i; i < tokens_.length; i++) {
            (_tokenAddresses[i], _flags[i]) = LedgerTokenFactoryLib.createInternalToken(tokens_[i]);
        }
    }

    /// @notice Create share tokens in input order; any failed item reverts the entire batch.
    function createShareTokens(ILedgerTokenFactory.ShareTokenConfig[] memory tokens_)
        external
        returns (address[] memory _tokenAddresses, uint256[] memory _flags)
    {
        enforceIsOwner();
        _tokenAddresses = new address[](tokens_.length);
        _flags = new uint256[](tokens_.length);

        for (uint256 i_; i_ < tokens_.length; i_++) {
            (_tokenAddresses[i_], _flags[i_]) =
                LedgerTokenFactoryLib.createShareToken(tokens_[i_].backingAccount, tokens_[i_].metadata);
        }
    }
}
