// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib} from "../../libraries/FloatLib.sol";
import {FloatStrings} from "../../libraries/FloatStrings.sol";

contract FloatCalculator {
    using FloatLib for Float;
    using FloatLib for uint256;
    using FloatStrings for Float;

    // Helper to convert signed value to Float
    function _toFloat(int256 a, uint8 decimals) internal pure returns (Float) {
        if (a >= 0) {
            return uint256(a).toFloat(decimals);
        } else {
            return uint256(-a).toFloat(decimals).minus();
        }
    }

    // ==================
    //     Arithmetic
    // ==================

    function add(int256 a, int256 b, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.plus(fb).toString();
    }

    function subtract(int256 a, int256 b, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.minus(fb).toString();
    }

    function multiply(int256 a, int256 b, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.times(fb).toString();
    }

    function divide(int256 a, int256 b, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.divide(fb).toString();
    }

    function negate(int256 a, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.minus().toString();
    }

    // ==================
    //    Comparisons
    // ==================

    function isEqual(int256 a, int256 b, uint8 decimals) external pure returns (bool) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.isEQ(fb);
    }

    function isGreaterThan(int256 a, int256 b, uint8 decimals) external pure returns (bool) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.isGT(fb);
    }

    function isLessThan(int256 a, int256 b, uint8 decimals) external pure returns (bool) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.isLT(fb);
    }

    function isGreaterOrEqual(int256 a, int256 b, uint8 decimals) external pure returns (bool) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.isGEQ(fb);
    }

    function isLessOrEqual(int256 a, int256 b, uint8 decimals) external pure returns (bool) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        return fa.isLEQ(fb);
    }

    function isZero(int256 a, uint8 decimals) external pure returns (bool) {
        Float fa = _toFloat(a, decimals);
        return fa.isZero();
    }

    // ==================
    //  Transformations
    // ==================

    function absoluteValue(int256 a, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.abs().toString();
    }

    function getParts(int256 a, uint8 decimals) external pure returns (string memory intPart, string memory fracPart) {
        Float fa = _toFloat(a, decimals);
        (Float intFloat, Float fracFloat) = fa.parts();
        return (intFloat.toString(), fracFloat.toString());
    }

    function shift(int256 a, uint8 decimals, int256 places) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.shift(places).toString();
    }

    function roundTo(int256 a, uint8 decimals, uint256 digits) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.round(digits).toString();
    }

    // ==================
    //  Special Functions
    // ==================

    function exponential(int256 a, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.exp().toString();
    }

    function naturalLog(int256 a, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.log().toString();
    }

    function power(int256 base, int256 exp, uint8 decimals) external pure returns (string memory) {
        Float fb = _toFloat(base, decimals);
        Float fe = _toFloat(exp, decimals);
        return fb.pow(fe).toString();
    }

    function squareRoot(int256 a, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        return fa.sqrt().toString();
    }

    function fullMulDiv(int256 a, int256 b, int256 c, uint8 decimals) external pure returns (string memory) {
        Float fa = _toFloat(a, decimals);
        Float fb = _toFloat(b, decimals);
        Float fc = _toFloat(c, decimals);
        return FloatLib.fullMulDiv(fa, fb, fc).toString();
    }

    // ==================
    //     Utilities
    // ==================

    function toFloatString(int256 value, uint8 decimals) external pure returns (string memory) {
        return _toFloat(value, decimals).toString();
    }

    function getComponents(int256 value, uint8 decimals) external pure returns (int256 mantissa, int256 exponent) {
        Float f = _toFloat(value, decimals);
        return FloatLib.components(f);
    }

    function fromComponents(int256 mantissa, int256 exponent) external pure returns (string memory) {
        return FloatLib.from(mantissa, exponent).toString();
    }

    function normalize(int256 mantissa, int256 exponent) external pure returns (string memory) {
        return FloatLib.normalize(mantissa, exponent).toString();
    }

    // ==================
    //     Constants
    // ==================

    function zero() external pure returns (string memory) {
        return FloatLib.ZERO.toString();
    }

    function one() external pure returns (string memory) {
        return FloatLib.ONE.toString();
    }

    function two() external pure returns (string memory) {
        return FloatLib.TWO.toString();
    }

    function ten() external pure returns (string memory) {
        return FloatLib.TEN.toString();
    }

    function pi() external pure returns (string memory) {
        return FloatLib.PI.toString();
    }
}
