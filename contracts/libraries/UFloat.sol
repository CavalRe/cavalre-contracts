// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct UFloat {
    uint64 mantissa;
    int8 exponent;
}

library UFloatLib {
    /****************
     *   Constants   *
     ****************/
    uint8 constant SIGNIFICANT_DIGITS = 18;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);

    /*******************
     *   Conversions   *
     ******************/

    function toUInt(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Value must be non-negative");
        return uint256(a);
    }

    function toInt(uint8 a) internal pure returns (int8) {
        require(a <= uint8(type(int8).max), "Value out of int8 range");
        return int8(a);
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
        return toUInt(a, SIGNIFICANT_DIGITS);
    }

    //--------------
    //   toUFloat
    //--------------

    function toUFloat(
        uint64 a,
        uint8 decimals
    ) internal pure returns (UFloat memory) {
        return normalize(UFloat(a, -toInt(decimals)));
    }

    function toUFloat(uint64 a) internal pure returns (UFloat memory) {
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
    //   Normalize
    //---------------
    function normalize(UFloat memory a) internal pure returns (UFloat memory) {
        uint64 mantissa = a.mantissa;
        int8 exponent = a.exponent;
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

        a = normalize(a);
        b = normalize(b);

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
        a = normalize(a);
        b = normalize(b);

        (a, b) = align(a, b);
        return normalize(UFloat(a.mantissa + b.mantissa, a.exponent));
    }

    //-----------
    //   minus
    //-----------
    function minus(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory) {
        a = normalize(a);
        b = normalize(b);

        (a, b) = align(a, b);
        return normalize(UFloat(a.mantissa - b.mantissa, a.exponent));
    }

    //-----------
    //   times
    //-----------
    function times(
        UFloat memory a,
        UFloat memory b
    ) internal pure returns (UFloat memory) {
        // if (a.mantissa == 0 || b.mantissa == 0) return UFloat(0, 0);
        a = normalize(a);
        b = normalize(b);

        // return
        //     normalize(UFloat(a.mantissa * b.mantissa, a.exponent + b.exponent));
        return
            normalize(
                UFloat(
                    uint64((uint256(a.mantissa) * uint256(b.mantissa)) / 10 ** SIGNIFICANT_DIGITS),
                    toInt(SIGNIFICANT_DIGITS) + a.exponent + b.exponent
                )
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
        a = normalize(a);
        b = normalize(b);

        return
            normalize(
                UFloat(
                    uint64((uint256(a.mantissa) * 10 ** SIGNIFICANT_DIGITS) / uint256(b.mantissa)),
                    a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
                )
            );
    }
}
