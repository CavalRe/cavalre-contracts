// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReceiptTokenLib} from "../receipt/ReceiptTokenLib.sol";
import {ReceiptWrapper} from "../receipt/ReceiptWrapper.sol";
import {ERC20Wrapper} from "./ERC20Wrapper.sol";
import {ILedger} from "./ILedger.sol";
import {ILedgerTokenFactory} from "./ILedgerTokenFactory.sol";
import {LedgerLib} from "./LedgerLib.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

library LedgerTokenFactoryLib {
    function tokenSalt(ILedgerTokenFactory.TokenMetadata memory token_) internal pure returns (bytes32) {
        return keccak256(abi.encode(token_.name, token_.symbol, token_.decimals, token_.version));
    }

    /// @notice Predict an ordinary internal ERC20Wrapper; receipts use different creation bytecode.
    function predictToken(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address _token) {
        bytes memory _creationCode = abi.encodePacked(
            type(ERC20Wrapper).creationCode, abi.encode(address(this), token_.name, token_.symbol, token_.decimals)
        );
        _token = Create2.computeAddress(tokenSalt(token_), keccak256(_creationCode));
    }

    /// @notice Predict a ReceiptWrapper using shared metadata identity and dedicated creation bytecode.
    /// @dev Backing is not part of the salt. Reusing metadata with different backing must fail registration.
    function predictReceiptToken(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address) {
        bytes memory creationCode_ = abi.encodePacked(
            type(ReceiptWrapper).creationCode, abi.encode(address(this), token_.name, token_.symbol, token_.decimals)
        );
        return Create2.computeAddress(tokenSalt(token_), keccak256(creationCode_));
    }

    function createInternalToken(ILedgerTokenFactory.TokenMetadata memory token_)
        internal
        returns (address _token, uint256 _flags)
    {
        if (!LedgerLib.isValidString(token_.name) || !LedgerLib.isValidString(token_.symbol)) {
            revert ILedger.InvalidToken(address(0), token_.name, token_.symbol, token_.decimals);
        }

        _token = predictToken(token_);

        // Idempotent path: the predicted wrapper is already registered as the intended internal root.
        if (LedgerLib.ledger(_token) == _token) {
            _flags = LedgerLib.flags(
                LedgerLib.ROOT_ADDRESS, LedgerLib.AccountKind.DebitGroup, LedgerLib.TokenKind.Internal, 2
            );
            bool _sameFlags = _flags == LedgerLib.flags(_token);
            bool _sameWrapper = LedgerLib.wrapper(_token) == _token;
            if (_sameFlags && _sameWrapper) return (_token, _flags);
            revert ILedger.InvalidToken(_token, token_.name, token_.symbol, token_.decimals);
        }

        // The CREATE2 address is occupied, but not registered as the expected Ledger root.
        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, token_.name, token_.symbol, token_.decimals);

        // Internal roots remain self-wrapped so the root address is immediately usable as an ERC20 surface.
        _token = address(
            new ERC20Wrapper{salt: tokenSalt(token_)}(address(this), token_.name, token_.symbol, token_.decimals)
        );
        _flags = LedgerLib.addLedger(
            _token, token_.name, token_.symbol, token_.decimals, LedgerLib.TokenKind.Internal, address(0)
        );

        LedgerLib.Store storage s = LedgerLib.store();
        s.wrapper[_token] = _token;
    }

    /// @notice Deploy or replay a receipt wrapper and register its immutable backing through receipt code.
    /// @dev Trusted internal composition: the consuming module must authorize token creation.
    function createReceiptToken(address absoluteReceiptAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
        internal
        returns (address _token, uint256 _flags)
    {
        if (!LedgerLib.isValidString(token_.name) || !LedgerLib.isValidString(token_.symbol)) {
            revert ILedger.InvalidToken(address(0), token_.name, token_.symbol, token_.decimals);
        }

        _token = predictReceiptToken(token_);
        ReceiptTokenLib.checkReceiptAccount(_token, absoluteReceiptAccount_);

        if (LedgerLib.ledger(_token) == _token) {
            if (LedgerLib.wrapper(_token) != _token) {
                revert ILedger.InvalidToken(_token, token_.name, token_.symbol, token_.decimals);
            }
            // Registration compares the full flags and metadata, including the packed backing reference.
            return (_token, ReceiptTokenLib.register(_token, absoluteReceiptAccount_, token_));
        }

        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, token_.name, token_.symbol, token_.decimals);

        _token = address(
            new ReceiptWrapper{salt: tokenSalt(token_)}(address(this), token_.name, token_.symbol, token_.decimals)
        );
        _flags = ReceiptTokenLib.register(_token, absoluteReceiptAccount_, token_);
    }
}
