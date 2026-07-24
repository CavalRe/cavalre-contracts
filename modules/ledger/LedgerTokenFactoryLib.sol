// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Wrapper} from "./ERC20Wrapper.sol";
import {ILedger} from "./ILedger.sol";
import {ILedgerTokenFactory} from "./ILedgerTokenFactory.sol";
import {LedgerLib} from "./LedgerLib.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

library LedgerTokenFactoryLib {
    function tokenSalt(ILedgerTokenFactory.TokenMetadata memory token_) internal pure returns (bytes32) {
        return keccak256(abi.encode(token_.name, token_.symbol, token_.decimals, token_.version));
    }

    function predictToken(ILedgerTokenFactory.TokenMetadata memory token_) internal view returns (address _token) {
        bytes memory _creationCode = abi.encodePacked(
            type(ERC20Wrapper).creationCode, abi.encode(address(this), token_.name, token_.symbol, token_.decimals)
        );
        _token = Create2.computeAddress(tokenSalt(token_), keccak256(_creationCode));
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
        if (LedgerLib.root(_token) == _token) {
            _flags = LedgerLib.flags(address(0), LedgerLib.AccountKind.DebitGroup, LedgerLib.TokenKind.Internal, 1);
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

    function createClaimToken(address absoluteClaimAccount_, ILedgerTokenFactory.TokenMetadata memory token_)
        internal
        returns (address _token, uint256 _flags)
    {
        if (!LedgerLib.isValidString(token_.name) || !LedgerLib.isValidString(token_.symbol)) {
            revert ILedger.InvalidToken(address(0), token_.name, token_.symbol, token_.decimals);
        }

        _token = predictToken(token_);
        LedgerLib.checkClaimAccount(_token, absoluteClaimAccount_);

        if (LedgerLib.root(_token) == _token) {
            _flags =
                LedgerLib.flags(absoluteClaimAccount_, LedgerLib.AccountKind.DebitGroup, LedgerLib.TokenKind.Claim, 1);
            if (_flags == LedgerLib.flags(_token) && LedgerLib.wrapper(_token) == _token) return (_token, _flags);
            revert ILedger.InvalidToken(_token, token_.name, token_.symbol, token_.decimals);
        }

        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, token_.name, token_.symbol, token_.decimals);

        _token = address(
            new ERC20Wrapper{salt: tokenSalt(token_)}(address(this), token_.name, token_.symbol, token_.decimals)
        );
        _flags = LedgerLib.addLedger(
            _token, token_.name, token_.symbol, token_.decimals, LedgerLib.TokenKind.Claim, absoluteClaimAccount_
        );

        LedgerLib.Store storage s = LedgerLib.store();
        s.wrapper[_token] = _token;
    }
}
