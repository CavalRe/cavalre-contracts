// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

struct Float {
    int256 mantissa;
    int256 exponent;
}

library FloatLib {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    // Errors
    error NoSolution();

    //===============
    //   Constants
    //===============
    uint256 constant SIGNIFICANT_DIGITS = 18;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);

    int256 constant _LOG10 = 2302585092994045684;

    //=================
    //   Conversions
    //=================
    //-----------
    //   toInt
    //-----------
    function toInt(uint256 a) internal pure returns (int256) {
        require(a <= uint256(type(int256).max), "Value out of int256 range");
        return int256(a);
    }

    function toInt(Float memory a, uint256 decimals) internal pure returns (int256) {
        if (a.exponent + toInt(decimals) >= 0) {
            return a.mantissa * int256(10 ** toUInt(a.exponent + toInt(decimals)));
        } else {
            return a.mantissa / int256(10 ** toUInt(-(a.exponent + toInt(decimals))));
        }
    }

    function toInt(Float memory a) internal pure returns (int256) {
        return toInt(a, 18);
    }

    //------------
    //   toUInt
    //------------
    function toUInt(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Value must be non-negative");
        return uint256(a);
    }

    function toUInt(Float memory a, uint256 decimals) internal pure returns (uint256) {
        require(a.mantissa >= 0, "Value must be non-negative");
        if (a.exponent + toInt(decimals) >= 0) {
            return uint256(a.mantissa) * 10 ** toUInt(a.exponent + toInt(decimals));
        } else {
            return uint256(a.mantissa) / 10 ** toUInt(-(a.exponent + toInt(decimals)));
        }
    }

    function toUInt(Float memory a) internal pure returns (uint256) {
        return toUInt(a, 18);
    }

    //--------------
    //   toFloat
    //--------------

    function toFloat(int256 a, uint256 decimals) internal pure returns (Float memory) {
        return normalize(a, -toInt(decimals));
    }

    function toFloat(int256 a) internal pure returns (Float memory) {
        return toFloat(a, 18);
    }

    function toFloat(uint256 a, uint256 decimals) internal pure returns (Float memory) {
        require(a <= uint256(type(int256).max), "Value out of int256 range");
        return normalize(int256(a), -toInt(decimals));
    }

    function toFloat(uint256 a) internal pure returns (Float memory) {
        return toFloat(a, 18);
    }

    //-------------------
    //   toFloatArray
    //-------------------

    function toFloatArray(int256[] memory a, uint256[] memory decimals) internal pure returns (Float[] memory) {
        Float[] memory result = new Float[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = toFloat(a[i], decimals[i]);
        }
        return result;
    }

    function toFloatArray(int256[] memory a) internal pure returns (Float[] memory) {
        Float[] memory result = new Float[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = toFloat(a[i]);
        }
        return result;
    }

    //=================
    //   Comparisons
    //=================
    //----------
    //   isEQ
    //----------
    function isEQ(Float memory a, Float memory b) internal pure returns (bool) {
        (a, b) = align(a, b);
        return a.mantissa == b.mantissa;
    }

    function isGT(Float memory a, Float memory b) internal pure returns (bool) {
        (a, b) = align(a, b);
        return a.mantissa > b.mantissa;
    }

    function isGEQ(Float memory a, Float memory b) internal pure returns (bool) {
        (a, b) = align(a, b);
        return a.mantissa >= b.mantissa;
    }

    function isLT(Float memory a, Float memory b) internal pure returns (bool) {
        (a, b) = align(a, b);
        return a.mantissa < b.mantissa;
    }

    function isLEQ(Float memory a, Float memory b) internal pure returns (bool) {
        (a, b) = align(a, b);
        return a.mantissa <= b.mantissa;
    }

    //=====================
    //   Transformations
    //=====================
    function abs(Float memory a) internal pure returns (Float memory) {
        return Float(int256(a.mantissa.abs()), a.exponent);
    }

    function integerPart(Float memory number) internal pure returns (Float memory) {
        if (number.exponent < 0) {
            int256 temp = number.mantissa;
            for (uint256 i; i < toUInt(-number.exponent); i++) {
                temp /= 10;
                if (temp == 0) return Float(0, 0);
            }
            return Float(temp, 0);
        } else {
            return number;
        }
    }

    //-----------
    //   Shift
    //-----------
    function shift(Float memory a, int256 i) internal pure returns (Float memory) {
        if (i == 0 || a.mantissa == 0) return a;

        uint256 k = i > 0 ? uint256(i) : uint256(-i);

        int256 m = a.mantissa;
        int256 e = a.exponent + i;

        // chunked by powers of 10 to avoid 10**k
        if (i > 0) {
            while (k >= 16) {
                m /= 1e16;
                k -= 16;
            }
            if (k >= 8) {
                m /= 1e8;
                k -= 8;
            }
            if (k >= 4) {
                m /= 1e4;
                k -= 4;
            }
            if (k >= 2) {
                m /= 1e2;
                k -= 2;
            }
            if (k >= 1) m /= 10;
        } else {
            require(k <= SIGNIFICANT_DIGITS, "shift: |i| too large");
            while (k >= 16) {
                m *= 1e16;
                k -= 16;
            }
            if (k >= 8) {
                m *= 1e8;
                k -= 8;
            }
            if (k >= 4) {
                m *= 1e4;
                k -= 4;
            }
            if (k >= 2) {
                m *= 1e2;
                k -= 2;
            }
            if (k >= 1) m *= 10;
        }

        return Float(m, e);
    }

    //---------------
    //   normalize
    //---------------
    function normalize(int256 mantissa, int256 exponent) internal pure returns (Float memory) {
        // Fast path
        if (mantissa == 0) return Float(0, 0);

        int256 m = mantissa;
        int256 e = exponent;

        // Single abs computation (safe for -2^255)
        uint256 mag = _abs256(m);

        // Scale down by 10s until within bounds
        if (mag > NORMALIZED_MANTISSA_MAX) {
            while (mag > NORMALIZED_MANTISSA_MAX) {
                m /= 10;
                e += 1;
                mag /= 10;
            }
            return Float(m, e);
        }

        // Scale up by 10s until within bounds
        if (mag < NORMALIZED_MANTISSA_MIN) {
            while (mag < NORMALIZED_MANTISSA_MIN) {
                m *= 10;
                e -= 1;
                mag *= 10;
            }
            return Float(m, e);
        }

        return Float(m, e);
    }

    function _abs256(int256 x) private pure returns (uint256) {
        if (x >= 0) return uint256(x);
        unchecked {
            return uint256(~x) + 1;
        } // == uint256(-x)
    }

    function normalize(Float memory a) internal pure returns (Float memory) {
        return normalize(a.mantissa, a.exponent);
    }

    //-----------
    //   align
    //-----------
    // a and b should be normalized before shifting because shifting shifts the mantissa downward
    function align(Float memory a, Float memory b) internal pure returns (Float memory, Float memory) {
        if (a.mantissa == 0 && b.mantissa == 0) {
            return (Float(0, 0), Float(0, 0));
        } else if (a.mantissa == 0) {
            return (Float(0, b.exponent), Float(b.mantissa, b.exponent));
        } else if (b.mantissa == 0) {
            return (Float(a.mantissa, a.exponent), Float(0, a.exponent));
        }

        a = normalize(a);
        b = normalize(b);

        int256 delta = a.exponent - b.exponent;
        if (delta >= 0) {
            if (uint256(delta) > SIGNIFICANT_DIGITS) {
                return (Float(a.mantissa, a.exponent), Float(0, a.exponent));
            }
            return (Float(a.mantissa, a.exponent), shift(b, delta));
        } else {
            if (uint256(-delta) > SIGNIFICANT_DIGITS) {
                return (Float(0, b.exponent), Float(b.mantissa, b.exponent));
            }
            return (shift(a, -delta), Float(b.mantissa, b.exponent));
        }
    }

    //================
    //   Arithmetic
    //================
    //----------
    //   plus
    //----------
    function plus(Float memory a, Float memory b) internal pure returns (Float memory) {
        (a, b) = align(a, b);
        return normalize(a.mantissa + b.mantissa, a.exponent);
    }

    //-----------
    //   minus
    //-----------
    function minus(Float memory a) internal pure returns (Float memory) {
        return Float(-a.mantissa, a.exponent);
    }

    function minus(Float memory a, Float memory b) internal pure returns (Float memory) {
        (a, b) = align(a, b);
        return normalize(a.mantissa - b.mantissa, a.exponent);
    }

    //-----------
    //   times
    //-----------
    function times(Float memory a, Float memory b) internal pure returns (Float memory) {
        a = normalize(a);
        b = normalize(b);

        return normalize(
            (a.mantissa * b.mantissa) / int256(10 ** SIGNIFICANT_DIGITS),
            toInt(SIGNIFICANT_DIGITS) + a.exponent + b.exponent
        );
    }

    //------------
    //   divide
    //------------
    function divide(Float memory a, Float memory b) internal pure returns (Float memory) {
        a = normalize(a);
        b = normalize(b);

        return normalize(
            (a.mantissa * int256(10 ** SIGNIFICANT_DIGITS)) / b.mantissa,
            a.exponent - b.exponent - toInt(SIGNIFICANT_DIGITS)
        );
    }

    //=======================
    //   Special functions
    //=======================
    function round(Float memory a, uint256 digits) internal pure returns (Float memory) {
        if (a.mantissa == 0) return Float(0, 0);
        a = normalize(a);
        int256 factor = int256(10 ** (SIGNIFICANT_DIGITS - digits));
        int256 scaled = a.mantissa / factor;
        int256 remainder = a.mantissa % factor;
        if (remainder * 2 >= factor) {
            scaled++;
        }
        if (remainder * 2 <= -factor) {
            scaled--;
        }
        return Float(scaled * factor, a.exponent);
    }

    function exp(
        int256 a // 18 decimals
    ) internal pure returns (Float memory) {
        int256 k = a / _LOG10;
        int256 aprime = a - k * _LOG10;
        return normalize(aprime.expWad(), k - 18);
    }

    function log(Float memory a)
        internal
        pure
        returns (
            int256 // 18 decimals
        )
    {
        return int256(a.mantissa).lnWad() + (a.exponent + 18) * _LOG10;
    }

    struct Cubic {
        Float p;
        Float q;
        Float rad;
        Float u;
        Float w;
    }

    function cubicsolve(Float memory b, Float memory c, Float memory d) internal pure returns (Float memory x) {
        Cubic memory cubic;

        cubic.p = minus(c, divide(times(b, b), Float(3, 0)));
        cubic.q = minus(plus(d, divide(times(b, times(b, b)), Float(135, -1))), divide(times(b, c), Float(3e17, -17)));
        cubic.rad = plus(
            divide(times(cubic.q, cubic.q), Float(4, 0)), divide(times(cubic.p, times(cubic.p, cubic.p)), Float(27, 0))
        );
        if (isLT(cubic.rad, Float(0, 0))) revert NoSolution();
        cubic.u = minus(exp(log(cubic.rad) / 2), divide(cubic.q, Float(2, 0)));
        cubic.w = cubic.u.mantissa > 0 ? exp(log(cubic.u) / 3) : minus(exp(log(minus(cubic.u)) / 3));

        x = minus(minus(cubic.w, divide(cubic.p, times(Float(3, 0), cubic.w))), divide(b, Float(3, 0)));
    }

    function fullMulDiv(Float memory a, Float memory b, Float memory c) internal pure returns (Float memory) {
        int256 sign = 1;
        if (a.mantissa < 0) {
            sign *= -1;
        }
        if (b.mantissa < 0) {
            sign *= -1;
        }
        if (c.mantissa < 0) {
            sign *= -1;
        }
        a = normalize(a);
        b = normalize(b);
        c = normalize(c);
        return normalize(
            sign * int256(a.mantissa.abs().fullMulDiv(b.mantissa.abs(), c.mantissa.abs())),
            a.exponent + b.exponent - c.exponent
        );
    }
}
