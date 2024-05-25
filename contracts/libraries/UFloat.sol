// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {UFloatStrings} from "./UFloatStrings.sol";

import {console} from "forge-std/src/Test.sol";

struct UFloat {
    uint64 mantissa;
    int8 exponent;
}

library UFloatLib {
    using FixedPointMathLib for int256;
    using UFloatStrings for UFloat;

    /****************
     *   Constants   *
     ****************/
    uint8 constant SIGNIFICANT_DIGITS = 18;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);

    int64 constant _LOG10 = 2302585092994045684;

    /*******************
     *   Conversions   *
     ******************/

    function toInt(int256 a) internal pure returns (int8) {
        require(a <= int256(type(int8).max), "Value out of int8 range");
        require(a >= int256(type(int8).min), "Value out of int8 range");
        return int8(a);
    }

    function toInt(uint256 a) internal pure returns (int8) {
        require(a <= uint256(uint8(type(int8).max)), "Value out of int8 range");
        return int8(int256(a));
    }

    function toUInt(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Value must be non-negative");
        return uint256(a);
    }

    function toUInt(
        UFloat memory a,
        uint8 decimals
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
        uint8 decimals
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
        uint64[] memory a,
        uint8[] memory decimals
    ) internal pure returns (UFloat[] memory) {
        UFloat[] memory result = new UFloat[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = toUFloat(a[i], decimals[i]);
        }
        return result;
    }

    function toUFloatArray(
        uint64[] memory a
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
            uint64 temp = number.mantissa;
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
        int8 i
    ) internal pure returns (UFloat memory) {
        uint64 mantissa = a.mantissa;
        if (i > 0) {
            mantissa /= uint64(10 ** toUInt(i));
        } else if (i < 0) {
            mantissa *= uint64(10 ** toUInt(-i));
        }
        return UFloat(mantissa, a.exponent + i);
    }

    //---------------
    //   normalize
    //---------------
    function normalize(
        uint256 mantissa,
        int8 exponent
    ) internal pure returns (UFloat memory) {
        bool isLarge = mantissa > NORMALIZED_MANTISSA_MAX;
        bool isSmall = mantissa < NORMALIZED_MANTISSA_MIN;
        if (!isLarge && !isSmall) {
            return UFloat(uint64(mantissa), exponent);
        } else if (isLarge) {
            while (mantissa > NORMALIZED_MANTISSA_MAX) {
                mantissa /= 10;
                exponent++;
            }
            return UFloat(uint64(mantissa), exponent);
        } else if (mantissa == 0) {
            return UFloat(0, 0);
        } else {
            // if (isSmall) {
            while (mantissa < NORMALIZED_MANTISSA_MIN) {
                mantissa *= 10;
                exponent--;
            }
            return UFloat(uint64(mantissa), exponent);
        }
    }

    // function normalize(UFloat memory a) internal pure returns (UFloat memory) {
    //     uint64 mantissa = a.mantissa;
    //     int8 exponent = a.exponent;
    //     bool isLarge = mantissa > NORMALIZED_MANTISSA_MAX;
    //     bool isSmall = mantissa < NORMALIZED_MANTISSA_MIN;
    //     if (!isLarge && !isSmall) {
    //         return UFloat(mantissa, exponent);
    //     } else if (isLarge) {
    //         while (mantissa > NORMALIZED_MANTISSA_MAX) {
    //             mantissa /= 10;
    //             exponent++;
    //         }
    //         return UFloat(mantissa, exponent);
    //     } else if (mantissa == 0) {
    //         return UFloat(0, 0);
    //     } else {
    //         // if (isSmall) {
    //         while (mantissa < NORMALIZED_MANTISSA_MIN) {
    //             mantissa *= 10;
    //             exponent--;
    //         }
    //         return UFloat(mantissa, exponent);
    //     }
    // }

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

        int8 delta = a.exponent - b.exponent;
        if (delta >= 0) {
            if (delta > int8(SIGNIFICANT_DIGITS)) {
                return (UFloat(a.mantissa, a.exponent), UFloat(0, a.exponent));
            }
            return (UFloat(a.mantissa, a.exponent), shift(b, delta));
        } else {
            if (-delta > int8(SIGNIFICANT_DIGITS)) {
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
                (uint256(a.mantissa) * uint256(b.mantissa)) /
                    10 ** SIGNIFICANT_DIGITS,
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
                (uint256(a.mantissa) * 10 ** SIGNIFICANT_DIGITS) /
                    uint256(b.mantissa),
                a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
            );
    }

    // // // Special functions
    // function exp(UFloat memory a) internal view returns (UFloat memory) {
    //     UFloat memory _LOG10 = UFloat(LOG10, -int8(18));
    //     console.log("LOG10", _LOG10.toString());
    //     UFloat memory k = integerPart(divide(a, _LOG10));
    //     console.log("k", k.toString());
    //     UFloat memory _aprime = minus(a, times(k, _LOG10));
    //     console.log("aprime", _aprime.toString());
    //     console.log("toUInt(aprime)", toUInt(_aprime));
    //     UFloat memory _exp = toUFloat(
    //         toUInt(int256(toUInt(minus(a, times(k, _LOG10)))).expWad())
    //     );

    //     return
    //         UFloat(
    //             _exp.mantissa,
    //             _exp.exponent + int8(int64(integerPart(k).mantissa))
    //         );
    // }

    // function exp(uint256 a) internal pure returns (UFloat memory) {
    //     uint256 k = a / LOG10;
    //     uint256 aprime = a - k * LOG10;
    //     return normalize(uint256(int256(aprime).expWad()), toInt(k) - 18);
    // }



    function exp(int256 a) internal pure returns (UFloat memory) {
        int256 k = a / _LOG10;
        int256 aprime = a - k * _LOG10;
        return normalize(uint256(aprime.expWad()), toInt(k - 18));
    }



}
