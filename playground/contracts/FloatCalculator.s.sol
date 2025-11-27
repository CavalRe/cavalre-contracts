// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib} from "../../libraries/FloatLib.sol";
import {FloatStrings} from "../../libraries/FloatStrings.sol";

contract FloatCalculator {
    using FloatLib for Float;
    using FloatLib for int256;
    using FloatLib for uint256;
    using FloatStrings for Float;

    // ==================
    //     Arithmetic
    // ==================

    function add(int256 a, int256 b, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.plus(fb).toString();
    }

    function subtract(int256 a, int256 b, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.minus(fb).toString();
    }

    function multiply(int256 a, int256 b, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.times(fb).toString();
    }

    function divide(int256 a, int256 b, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.divide(fb).toString();
    }

    function negate(int256 a, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        return fa.minus().toString();
    }

    // ==================
    //    Comparisons
    // ==================

    function isEqual(int256 a, int256 b, uint256 decimals) external pure returns (bool) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.isEQ(fb);
    }

    function isGreaterThan(int256 a, int256 b, uint256 decimals) external pure returns (bool) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.isGT(fb);
    }

    function isLessThan(int256 a, int256 b, uint256 decimals) external pure returns (bool) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.isLT(fb);
    }

    function isGreaterOrEqual(int256 a, int256 b, uint256 decimals) external pure returns (bool) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.isGEQ(fb);
    }

    function isLessOrEqual(int256 a, int256 b, uint256 decimals) external pure returns (bool) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        return fa.isLEQ(fb);
    }

    // ==================
    //  Transformations
    // ==================

    function absoluteValue(int256 a, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        return fa.abs().toString();
    }

    function getIntegerPart(int256 a, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        return fa.integerPart().toString();
    }

    function shift(int256 a, uint256 decimals, int256 places) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        return fa.shift(places).toString();
    }

    function roundTo(int256 a, uint256 decimals, uint256 digits) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        return fa.round(digits).toString();
    }

    // ==================
    //  Special Functions
    // ==================

    function exponential(int256 a) external pure returns (string memory) {
        // exp takes raw int256 (18 decimal fixed point)
        return FloatLib.exp(a).toString();
    }

    function naturalLog(int256 a, uint256 decimals) external pure returns (int256) {
        Float fa = a.toFloat(decimals);
        return fa.log();
    }

    function cubicSolve(int256 b, int256 c, int256 d, uint256 decimals) external pure returns (string memory) {
        Float fb = b.toFloat(decimals);
        Float fc = c.toFloat(decimals);
        Float fd = d.toFloat(decimals);
        return FloatLib.cubicsolve(fb, fc, fd).toString();
    }

    function fullMulDiv(int256 a, int256 b, int256 c, uint256 decimals) external pure returns (string memory) {
        Float fa = a.toFloat(decimals);
        Float fb = b.toFloat(decimals);
        Float fc = c.toFloat(decimals);
        return FloatLib.fullMulDiv(fa, fb, fc).toString();
    }

    // ==================
    //     Utilities
    // ==================

    function toFloatString(int256 value, uint256 decimals) external pure returns (string memory) {
        return value.toFloat(decimals).toString();
    }

    function getComponents(int256 value, uint256 decimals) external pure returns (int256 mantissa, int256 exponent) {
        Float f = value.toFloat(decimals);
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
}
