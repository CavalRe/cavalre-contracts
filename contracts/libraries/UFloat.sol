// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {UFloatStrings} from "./UFloatStrings.sol";

import {console} from "forge-std/src/Test.sol";

struct UFloat {
    uint256 mantissa;
    int256 exponent;
}

library UFloatLib {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;
    using UFloatStrings for UFloat;

    /****************
     *   Constants   *
     ****************/
    uint256 constant SIGNIFICANT_DIGITS = 18;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);

    int256 constant _LOG10 = 2302585092994045684;

    /*******************
     *   Conversions   *
     ******************/

    function toInt(uint256 a) internal pure returns (int256) {
        require(a <= uint256(type(int256).max), "Value out of int256 range");
        return int256(a);
    }

    function toUInt(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Value must be non-negative");
        return uint256(a);
    }

    function toUInt(
        UFloat memory a,
        uint256 decimals
    ) internal pure returns (uint256) {
        if (a.exponent + toInt(decimals) >= 0) {
            return a.mantissa * 10 ** toUInt(a.exponent + toInt(decimals));
        } else {
            return a.mantissa / 10 ** toUInt(-(a.exponent + toInt(decimals)));
        }
    }

    function toUInt(UFloat memory a) internal pure returns (uint256) {
        return toUInt(a, 18);
    }

    //--------------
    //   toUFloat
    //--------------

    function toUFloat(
        uint256 a,
        uint256 decimals
    ) internal pure returns (UFloat memory) {
        return normalize(a, -toInt(decimals));
    }

    function toUFloat(uint256 a) internal pure returns (UFloat memory) {
        return toUFloat(a, SIGNIFICANT_DIGITS);
    }

    //-------------------
    //   toUFloatArray
    //-------------------
    function toUFloatArray(
        uint256[] memory a,
        uint256[] memory decimals
    ) internal pure returns (UFloat[] memory) {
        UFloat[] memory result = new UFloat[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = toUFloat(a[i], decimals[i]);
        }
        return result;
    }

    function toUFloatArray(
        uint256[] memory a
    ) internal pure returns (UFloat[] memory) {
        UFloat[] memory result = new UFloat[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = toUFloat(a[i]);
        }
        return result;
    }

    /*******************
     *   Comparisons   *
     *******************/

    //-------------
    //   isEqual
    //-------------
    function isEqual(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (bool) {
        (a, b) = align(a, b);
        return a.mantissa == b.mantissa;
    }

    /**********************
     *   Transformations   *
     **********************/

    // Must return a UFloat with non-negative exponent
    function integerPart(
        UFloat memory number
    ) internal pure returns (UFloat memory) {
        if (number.exponent < 0) {
            uint256 temp = number.mantissa;
            for (uint256 i; i < toUInt(-number.exponent); i++) {
                temp /= 10;
                if (temp == 0) return UFloat(0, 0);
            }
            return UFloat(temp, 0);
        } else {
            return number;
        }
    }

    //-----------
    //   Shift
    //-----------
    /*
    - shift should be unopinionated. 
    - If the shift is too large, it will overflow.
    - If the shift is too small, it will underflow.
     */
    function shift(
        UFloat memory a,
        int256 i
    ) internal pure returns (UFloat memory) {
        uint256 mantissa = a.mantissa;
        if (i > 0) {
            mantissa /= 10 ** toUInt(i);
        } else if (i < 0) {
            mantissa *= 10 ** toUInt(-i);
        }
        return UFloat(mantissa, a.exponent + i);
    }

    //---------------
    //   normalize
    //---------------
    function normalize(
        uint256 mantissa,
        int256 exponent
    ) internal pure returns (UFloat memory) {
        bool isLarge = mantissa > NORMALIZED_MANTISSA_MAX;
        bool isSmall = mantissa < NORMALIZED_MANTISSA_MIN;
        if (!isLarge && !isSmall) {
            return UFloat(mantissa, exponent);
        } else if (isLarge) {
            while (mantissa > NORMALIZED_MANTISSA_MAX) {
                mantissa /= 10;
                exponent++;
            }
            return UFloat(mantissa, exponent);
        } else if (mantissa == 0) {
            return UFloat(0, 0);
        } else {
            // if (isSmall) {
            while (mantissa < NORMALIZED_MANTISSA_MIN) {
                mantissa *= 10;
                exponent--;
            }
            return UFloat(mantissa, exponent);
        }
    }

    //-----------
    //   align
    //-----------

    /*
    a and b should be normalized before shifting because shifting shifts the mantissa downward
    */
    function align(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory, UFloat memory) {
        if (a.mantissa == 0 && b.mantissa == 0) {
            return (UFloat(0, 0), UFloat(0, 0));
        } else if (a.mantissa == 0) {
            return (UFloat(0, b.exponent), UFloat(b.mantissa, b.exponent));
        } else if (b.mantissa == 0) {
            return (UFloat(a.mantissa, a.exponent), UFloat(0, a.exponent));
        }

        a = normalize(a.mantissa, a.exponent);
        b = normalize(b.mantissa, b.exponent);

        int256 delta = a.exponent - b.exponent;
        if (delta >= 0) {
            if (uint256(delta) > SIGNIFICANT_DIGITS) {
                return (UFloat(a.mantissa, a.exponent), UFloat(0, a.exponent));
            }
            return (UFloat(a.mantissa, a.exponent), shift(b, delta));
        } else {
            if (uint256(-delta) > SIGNIFICANT_DIGITS) {
                return (UFloat(0, b.exponent), UFloat(b.mantissa, b.exponent));
            }
            return (shift(a, -delta), UFloat(b.mantissa, b.exponent));
        }
    }

    /*****************
     *   Arithmetic   *
     *****************/

    //----------
    //   plus
    //----------
    function plus(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory) {
        a = normalize(a.mantissa, a.exponent);
        b = normalize(b.mantissa, b.exponent);

        (a, b) = align(a, b);
        return normalize(a.mantissa + b.mantissa, a.exponent);
    }

    //-----------
    //   minus
    //-----------
    function minus(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory) {
        a = normalize(a.mantissa, a.exponent);
        b = normalize(b.mantissa, b.exponent);

        (a, b) = align(a, b);
        return normalize(a.mantissa - b.mantissa, a.exponent);
    }

    //-----------
    //   times
    //-----------
    function times(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory) {
        // if (a.mantissa == 0 || b.mantissa == 0) return UFloat(0, 0);
        a = normalize(a.mantissa, a.exponent);
        b = normalize(b.mantissa, b.exponent);

        // return
        //     normalize(UFloat(a.mantissa * b.mantissa, a.exponent + b.exponent));
        return
            normalize(
                (a.mantissa * b.mantissa) / 10 ** SIGNIFICANT_DIGITS,
                toInt(SIGNIFICANT_DIGITS) + a.exponent + b.exponent
            );
        // return UFloat(a.mantissa * b.mantissa, a.exponent + b.exponent);
    }

    //------------
    //   divide
    //------------
    function divide(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory) {
        // if (a.mantissa == 0) return UFloat(0, 0);
        a = normalize(a.mantissa, a.exponent);
        b = normalize(b.mantissa, b.exponent);

        return
            normalize(
                (a.mantissa * 10 ** SIGNIFICANT_DIGITS) / b.mantissa,
                a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
            );
    }

    /****************
    Special functions
    ****************/

    function exp(int256 a) internal pure returns (UFloat memory) {
        int256 k = a / _LOG10;
        int256 aprime = a - k * _LOG10;
        return normalize(uint256(aprime.expWad()), k - 18);
    }

    function log(UFloat memory a) internal pure returns (int256) {
        return int256(a.mantissa).lnWad() + a.exponent * _LOG10;
    }

    function fullMulDiv(
        UFloat memory a,
        UFloat memory b,
        UFloat memory c
    ) internal pure returns (UFloat memory) {
        a = normalize(a.mantissa, a.exponent);
        b = normalize(b.mantissa, b.exponent);
        c = normalize(c.mantissa, c.exponent);
        return
            normalize(
                a.mantissa.fullMulDiv(b.mantissa, c.mantissa),
                a.exponent + b.exponent - c.exponent
            );
    }
}
