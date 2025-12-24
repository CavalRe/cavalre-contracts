// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedger} from "../interfaces/ILedger.sol";
import {Float, FloatLib} from "./FloatLib.sol";
import {LedgerLib} from "./LedgerLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LedgerValuationLib {
    using FloatLib for uint256;
    using FloatLib for Float;

    function price(address token_) external view returns (Float) {
        Float _reserve = LedgerLib.reserve(token_).toFloat(LedgerLib.decimals(token_));
        if (_reserve.mantissa() == 0) revert ILedger.ZeroReserve(token_);
        Float _scale = LedgerLib.scale(token_).toFloat();
        return _scale.divide(_reserve);
    }

    function totalValue(address token_) external view returns (Float) {
        uint8 _decimals = LedgerLib.decimals(token_);
        Float _reserve = LedgerLib.reserve(token_).toFloat(_decimals);
        if (_reserve.mantissa() == 0) revert ILedger.ZeroReserve(token_);
        Float _scale = LedgerLib.scale(token_).toFloat();
        Float _totalSupply = LedgerLib.isInternal(token_)
            ? LedgerLib
                .balanceOf(LedgerLib.toLedgerAddress(LedgerLib.parent(address(this), LedgerLib.isCredit(token_)), token_))
                .toFloat(_decimals)
            : IERC20(token_).totalSupply().toFloat(_decimals);
        return _totalSupply.fullMulDiv(_scale, _reserve);
    }
}
