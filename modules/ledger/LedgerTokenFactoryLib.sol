// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Wrapper} from "./ERC20Wrapper.sol";
import {ILedger} from "./ILedger.sol";
import {LedgerLib} from "./LedgerLib.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

library LedgerTokenFactoryLib {
    function tokenSalt(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(name_, symbol_, decimals_, version_));
    }

    function predictToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        internal
        view
        returns (address _token)
    {
        bytes memory _creationCode = abi.encodePacked(
            type(ERC20Wrapper).creationCode, abi.encode(address(this), name_, symbol_, decimals_)
        );
        _token = Create2.computeAddress(tokenSalt(name_, symbol_, decimals_, version_), keccak256(_creationCode));
    }

    function createInternalToken(string memory name_, string memory symbol_, uint8 decimals_, string memory version_)
        internal
        returns (address _token, uint256 _flags)
    {
        if (!LedgerLib.isValidString(name_) || !LedgerLib.isValidString(symbol_)) {
            revert ILedger.InvalidToken(address(0), name_, symbol_, decimals_);
        }

        _token = predictToken(name_, symbol_, decimals_, version_);

        if (LedgerLib.root(_token) == _token) {
            _flags = LedgerLib.flags(address(0), LedgerLib.AccountKind.DebitGroup, LedgerLib.TokenKind.Internal, 1);
            bool _sameFlags = _flags == LedgerLib.flags(_token);
            bool _sameWrapper = LedgerLib.wrapper(_token) == _token;
            if (_sameFlags && _sameWrapper) return (_token, _flags);
            revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);
        }

        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);

        // Internal roots remain self-wrapped so the root address is immediately usable as an ERC20 surface.
        _token = address(
            new ERC20Wrapper{salt: tokenSalt(name_, symbol_, decimals_, version_)}(
                address(this), name_, symbol_, decimals_
            )
        );
        _flags = LedgerLib.addLedger(_token, name_, symbol_, decimals_, LedgerLib.TokenKind.Internal, address(0));

        LedgerLib.Store storage s = LedgerLib.store();
        s.wrapper[_token] = _token;
    }

    function createClaimToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address root_,
        address holderParent_,
        address relative_,
        string memory version_
    ) internal returns (address _token, uint256 _flags) {
        if (!LedgerLib.isValidString(name_) || !LedgerLib.isValidString(symbol_)) {
            revert ILedger.InvalidToken(address(0), name_, symbol_, decimals_);
        }
        address _claimAccount = LedgerLib.checkClaimAccount(address(0), root_, holderParent_, relative_);

        _token = predictToken(name_, symbol_, decimals_, version_);

        if (LedgerLib.root(_token) == _token) {
            _flags = LedgerLib.flags(_claimAccount, LedgerLib.AccountKind.DebitGroup, LedgerLib.TokenKind.Claim, 1);
            if (_flags == LedgerLib.flags(_token) && LedgerLib.wrapper(_token) == _token) return (_token, _flags);
            revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);
        }

        if (_token.code.length != 0) revert ILedger.InvalidToken(_token, name_, symbol_, decimals_);

        _token = address(
            new ERC20Wrapper{salt: tokenSalt(name_, symbol_, decimals_, version_)}(
                address(this), name_, symbol_, decimals_
            )
        );
        if (LedgerLib.root(_claimAccount) == _token) revert ILedger.InvalidLedgerAccount(_claimAccount);
        _flags = LedgerLib.addLedger(_token, name_, symbol_, decimals_, LedgerLib.TokenKind.Claim, _claimAccount);

        LedgerLib.Store storage s = LedgerLib.store();
        s.wrapper[_token] = _token;
    }
}
