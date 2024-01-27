// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct UFloat {
    uint256 mantissa;
    int256 exponent;
}

struct Float {
    int256 mantissa;
    int256 exponent;
}

library FloatingPoint {
    /****************
    *   Constants   *
    ****************/
    uint256 constant SIGNIFICANT_DIGITS = 18;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);

    /*******************
     *   Conversions   *
     ******************/

    function toUInt(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Value must be non-negative");
        return uint256(a);
    }

    function toInt(uint256 a) internal pure returns (int256) {
        require(a <= uint256(type(int256).max), "Value out of int256 range");
        return int256(a);
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
        return toUInt(a, SIGNIFICANT_DIGITS);
    }

    // function toInt(
    //     Float memory a,
    //     uint256 decimals
    // ) internal pure returns (int256) {
    //     if (a.exponent + toInt(decimals) >= 0) {
    //         return
    //             a.mantissa * int256(10 ** toUInt(a.exponent + toInt(decimals)));
    //     } else {
    //         return
    //             a.mantissa /
    //             int256(10 ** toUInt(-(a.exponent + toInt(decimals))));
    //     }
    // }

    // function toInt(Float memory a) internal pure returns (int256) {
    //     return toInt(a, SIGNIFICANT_DIGITS);
    // }

    //--------------
    //   toUFloat
    //--------------
    // function toUFloat(Float memory a) internal pure returns (UFloat memory) {
    //     return UFloat(toUInt(a.mantissa), a.exponent);
    // }

    function toUFloat(
        uint256 a,
        uint256 decimals
    ) internal pure returns (UFloat memory) {
        return normalize(UFloat(a, -toInt(decimals)));
    }

    function toUFloat(uint256 a) internal pure returns (UFloat memory) {
        return toUFloat(a, SIGNIFICANT_DIGITS);
    }

    //-------------
    //   toFloat
    //-------------
    // function toFloat(UFloat memory a) internal pure returns (Float memory) {
    //     return Float(toInt(a.mantissa), a.exponent);
    // }

    // function toFloat(
    //     uint256 a,
    //     uint256 decimals
    // ) internal pure returns (Float memory) {
    //     return normalize(Float(toInt(a), -toInt(decimals)));
    // }

    // function toFloat(uint256 a) internal pure returns (Float memory) {
    //     return toFloat(a, SIGNIFICANT_DIGITS);
    // }

    //-------------------
    //   toUFloatArray
    //-------------------
    function toUFloatArray(
        uint256[] memory a,
        uint8[] memory decimals
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

    // function isEqual(
    //     Float memory a,
    //     Float memory b
    // ) internal pure returns (bool) {
    //     (a, b) = align(a, b);
    //     return a.mantissa == b.mantissa;
    // }

    //--------
    //   gt
    //--------
    // function gt(UFloat memory a, UFloat memory b) internal pure returns (bool) {
    //     (a, b) = align(a, b);
    //     return a.mantissa > b.mantissa;
    // }

    // function gte(
    //     UFloat memory a,
    //     UFloat memory b
    // ) internal pure returns (bool) {
    //     (a, b) = align(a, b);
    //     return a.mantissa >= b.mantissa;
    // }

    // function lt(UFloat memory a, UFloat memory b) internal pure returns (bool) {
    //     (a, b) = align(a, b);
    //     return a.mantissa < b.mantissa;
    // }

    // function lte(
    //     UFloat memory a,
    //     UFloat memory b
    // ) internal pure returns (bool) {
    //     (a, b) = align(a, b);
    //     return a.mantissa <= b.mantissa;
    // }

    // function equal(uint256 a, uint256 b) internal pure returns (bool) {
    //     if (a == b) return true;
    //     (uint256 mantissaA, uint256 exponent) = decode(a);
    //     (uint256 mantissaB, uint256 exponentB) = decode(b);

    //     (mantissaA, mantissaB, exponent) = align(
    //         mantissaA,
    //         exponent,
    //         mantissaB,
    //         exponentB
    //     );

    //     return mantissaA == mantissaB;
    // }

    /**********************
     *   Transformations   *
     **********************/

    // Must return a UFloat with non-negative exponent
    function integerPart(
        UFloat memory number
    ) internal pure returns (UFloat memory) {
        if (number.exponent < 0) {
            uint256 temp = number.mantissa;
            for (uint256 i = 0; i < toUInt(-number.exponent); i++) {
                temp /= 10;
                if (temp == 0) return UFloat(0, 0);
            }
            return UFloat(temp, 0);
        } else {
            return number;
        }
    }

    // function integerPart(
    //     Float memory number
    // ) internal pure returns (Float memory) {
    //     if (number.exponent < 0) {
    //         return
    //             Float(
    //                 number.mantissa / toInt(10 ** toUInt(-number.exponent)),
    //                 0
    //             );
    //     } else {
    //         return number;
    //     }
    // }

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
    //   Normalize
    //---------------
    function normalize(UFloat memory a) internal pure returns (UFloat memory) {
        uint256 mantissa = a.mantissa;
        int256 exponent = a.exponent;
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
        
        int256 delta = a.exponent - b.exponent;
        if (delta >= 0) {
            if (delta > int256(SIGNIFICANT_DIGITS)) {
                return (UFloat(a.mantissa, a.exponent), UFloat(0, a.exponent));
            }
            return (UFloat(a.mantissa, a.exponent), shift(b, delta));
        } else {
            if (-delta > int256(SIGNIFICANT_DIGITS)) {
                return (UFloat(0, b.exponent), UFloat(b.mantissa, b.exponent));
            }
            return (shift(a, -delta), UFloat(b.mantissa, b.exponent));
        }
    }

    // function align(
    //     Float memory a,
    //     Float memory b
    // ) internal pure returns (Float memory, Float memory) {
    //     if (a.exponent > b.exponent) {
    //         a.mantissa *= toInt(10 ** toUInt(a.exponent - b.exponent));
    //         a.exponent = b.exponent;
    //     } else if (a.exponent < b.exponent) {
    //         b.mantissa *= toInt(10 ** toUInt(b.exponent - a.exponent));
    //         b.exponent = a.exponent;
    //     }
    //     return (a, b);
    // }

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

    // function plus(
    //     Float memory a,
    //     Float memory b
    // ) internal pure returns (Float memory) {
    //     (a, b) = align(a, b);
    //     return normalize(Float(a.mantissa + b.mantissa, a.exponent));
    // }

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

    // function minus(
    //     Float memory a,
    //     Float memory b
    // ) internal pure returns (Float memory) {
    //     (a, b) = align(a, b);
    //     return normalize(Float(a.mantissa - b.mantissa, a.exponent));
    // }

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
                    (a.mantissa * b.mantissa) / 10 ** SIGNIFICANT_DIGITS,
                    toInt(SIGNIFICANT_DIGITS) + a.exponent + b.exponent
                )
            );
        // return UFloat(a.mantissa * b.mantissa, a.exponent + b.exponent);
    }

    // function times(
    //     Float memory a,
    //     Float memory b
    // ) internal pure returns (Float memory) {
    //     return
    //         normalize(
    //             Float(
    //                 (a.mantissa * b.mantissa) / toInt(10 ** SIGNIFICANT_DIGITS),
    //                 toInt(SIGNIFICANT_DIGITS) + a.exponent + b.exponent
    //             )
    //         );
    // }

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
                    (a.mantissa * 10 ** SIGNIFICANT_DIGITS) / b.mantissa,
                    a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
                )
            );
        // return
        //     UFloat(
        //         (a.mantissa * 10 ** SIGNIFICANT_DIGITS) / b.mantissa,
        //         a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
        //     );
    }

    // function divide(
    //     Float memory a,
    //     Float memory b
    // ) internal pure returns (Float memory) {
    //     return
    //         normalize(
    //             Float(
    //                 (a.mantissa * toInt(10 ** SIGNIFICANT_DIGITS)) / b.mantissa,
    //                 a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
    //             )
    //         );
    // }

    // function mulDiv(
    //     UFloat memory a,
    //     UFloat memory b,
    //     UFloat memory c
    // ) internal pure returns (UFloat memory) {
    //     return
    //         normalize(
    //             UFloat(
    //                 (a.mantissa * b.mantissa * 10 ** SIGNIFICANT_DIGITS) /
    //                     c.mantissa,
    //                 a.exponent +
    //                     b.exponent -
    //                     c.exponent -
    //                     toInt(SIGNIFICANT_DIGITS)
    //             )
    //         );
    // }

    // function mulDivAdd(
    //     UFloat memory a,
    //     UFloat memory b,
    //     UFloat memory db
    // ) internal pure returns (UFloat memory) {
    //     (b, db) = align(b, db);

    //     // Normalize result
    //     return
    //         normalize(
    //             UFloat(
    //                 (a.mantissa * db.mantissa * 10 ** SIGNIFICANT_DIGITS) /
    //                     (b.mantissa + db.mantissa),
    //                 a.exponent - toInt(SIGNIFICANT_DIGITS)
    //             )
    //         );
    // }




}
