// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

type Float is int256;

library FloatLib {
    using FloatLib for Float;
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    // Errors
    error NoSolution();

    //===============
    //   Constants
    //===============
    uint128 constant SIGNIFICANT_DIGITS = 18;
    uint128 constant NORMALIZED_MANTISSA_MAX = uint128(10) ** SIGNIFICANT_DIGITS - 1;
    uint128 constant NORMALIZED_MANTISSA_MIN = uint128(10) ** (SIGNIFICANT_DIGITS - 1);
    int256 constant MANTISSA_MASK = int256(uint256(type(uint128).max));

    int128 constant ONE_MANTISSA = int128(10) ** (SIGNIFICANT_DIGITS - 1);
    int128 constant ONE_EXPONENT = -int128(SIGNIFICANT_DIGITS - 1);

    int256 constant LOG10 = 2302585092994045684;

    Float constant ZERO = Float.wrap(0);
    Float constant ONE = Float.wrap((int256(ONE_EXPONENT) << 128) | ONE_MANTISSA);
    Float constant TWO = Float.wrap((int256(ONE_EXPONENT) << 128) | (2 * ONE_MANTISSA));
    Float constant THREE = Float.wrap((int256(ONE_EXPONENT) << 128) | (3 * ONE_MANTISSA));
    Float constant FOUR = Float.wrap((int256(ONE_EXPONENT) << 128) | (4 * ONE_MANTISSA));
    Float constant FIVE = Float.wrap((int256(ONE_EXPONENT) << 128) | (5 * ONE_MANTISSA));
    Float constant SIX = Float.wrap((int256(ONE_EXPONENT) << 128) | (6 * ONE_MANTISSA));
    Float constant SEVEN = Float.wrap((int256(ONE_EXPONENT) << 128) | (7 * ONE_MANTISSA));
    Float constant EIGHT = Float.wrap((int256(ONE_EXPONENT) << 128) | (8 * ONE_MANTISSA));
    Float constant NINE = Float.wrap((int256(ONE_EXPONENT) << 128) | (9 * ONE_MANTISSA));
    Float constant TEN = Float.wrap(((int256(ONE_EXPONENT) + 1) << 128) | ONE_MANTISSA);

    //=================
    //   Conversions
    //=================

    //-----------
    //   toInt
    //-----------
    function toInt(uint256 a_) internal pure returns (int256) {
        require(a_ <= uint256(type(int256).max), "Value out of int256 range");
        return int256(a_);
    }

    function toInt(Float a_, uint256 decimals_) internal pure returns (int256) {
        (int128 _mantissa, int128 _exponent) = components(a_);
        int256 _m = int256(_mantissa);
        int256 _exp = int256(_exponent) + toInt(decimals_);
        if (_exp >= 0) {
            return _m * int256(10 ** toUInt(_exp));
        } else {
            return _m / int256(10 ** toUInt(-_exp));
        }
    }

    function toInt(Float a_) internal pure returns (int256) {
        return toInt(a_, 18);
    }

    //------------
    //   toUInt
    //------------
    function toUInt(int256 a_) internal pure returns (uint256) {
        require(a_ >= 0, "Value must be non-negative");
        return uint256(a_);
    }

    function toUInt(Float a_, uint256 decimals_) internal pure returns (uint256) {
        (int128 _mantissa, int128 _exponent) = components(a_);
        require(_mantissa >= 0, "Value must be non-negative");
        int256 _m = int256(_mantissa);
        int256 _exp = int256(_exponent) + toInt(decimals_);
        if (_exp >= 0) {
            return uint256(_m) * 10 ** toUInt(_exp);
        } else {
            return uint256(_m) / 10 ** toUInt(-_exp);
        }
    }

    function toUInt(Float a_) internal pure returns (uint256) {
        return toUInt(a_, 18);
    }

    //--------------
    //   toFloat
    //--------------

    function toFloat(int256 a_, uint256 decimals_) internal pure returns (Float) {
        return normalize(a_, -toInt(decimals_));
    }

    function toFloat(int256 a_) internal pure returns (Float) {
        return toFloat(a_, 18);
    }

    function toFloat(uint256 a_, uint256 decimals_) internal pure returns (Float) {
        int256 _exp = -toInt(decimals_);
        if (a_ > uint256(type(int256).max)) {
            a_ /= 10;
            _exp += 1;
        }
        return normalize(int256(a_), _exp);
    }

    function toFloat(uint256 a_) internal pure returns (Float) {
        return toFloat(a_, 18);
    }

    //-------------------
    //   toFloatArray
    //-------------------

    function toFloatArray(int256[] memory a_, uint256[] memory decimals_) internal pure returns (Float[] memory) {
        Float[] memory _result = new Float[](a_.length);
        for (uint256 _i = 0; _i < a_.length; _i++) {
            _result[_i] = toFloat(a_[_i], decimals_[_i]);
        }
        return _result;
    }

    function toFloatArray(int256[] memory a_) internal pure returns (Float[] memory) {
        Float[] memory _result = new Float[](a_.length);
        for (uint256 _i = 0; _i < a_.length; _i++) {
            _result[_i] = toFloat(a_[_i]);
        }
        return _result;
    }

    //=================
    //   Comparisons
    //=================
    //----------
    //   isEQ
    //----------
    function isEQ(Float a_, Float b_) internal pure returns (bool) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        return mantissa(_alignedA) == mantissa(_alignedB);
    }

    function isGT(Float a_, Float b_) internal pure returns (bool) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        return mantissa(_alignedA) > mantissa(_alignedB);
    }

    function isGEQ(Float a_, Float b_) internal pure returns (bool) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        return mantissa(_alignedA) >= mantissa(_alignedB);
    }

    function isLT(Float a_, Float b_) internal pure returns (bool) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        return mantissa(_alignedA) < mantissa(_alignedB);
    }

    function isLEQ(Float a_, Float b_) internal pure returns (bool) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        return mantissa(_alignedA) <= mantissa(_alignedB);
    }

    //=====================
    //   Transformations
    //=====================
    function abs(Float a_) internal pure returns (Float) {
        (int128 _m, int128 _e) = components(a_);
        if (_m >= 0) return a_;
        return from(-_m, _e);
    }

    function integerPart(Float number_) internal pure returns (Float) {
        (int128 _m, int128 _e) = components(normalize(number_));
        if (_e >= 0 || _m == 0) return from(_m, _e); // already an integer or zero

        uint128 _shift = uint128(-_e);
        if (_shift > SIGNIFICANT_DIGITS) return ZERO; // too small, integer part is 0

        int256 _div = int256(10 ** _shift); // fits because shift ≤ SIGNIFICANT_DIGITS
        int128 _intPart = int128(int256(_m) / _div); // truncates toward zero
        return from(_intPart, 0);
    }

    //-----------
    //   Shift
    //-----------
    function shift(Float a_, int128 i_) internal pure returns (Float) {
        int128 _mantissa = mantissa(a_);
        if (i_ == 0 || _mantissa == 0) return a_;

        int256 _shift = i_;
        int128 _m = _mantissa;
        int128 _e = exponent(a_) + i_;

        if (_shift > 0) {
            while (_shift >= 16) {
                _m /= 1e16;
                _shift -= 16;
            }
            if (_shift >= 8) {
                _m /= 1e8;
                _shift -= 8;
            }
            if (_shift >= 4) {
                _m /= 1e4;
                _shift -= 4;
            }
            if (_shift >= 2) {
                _m /= 1e2;
                _shift -= 2;
            }
            if (_shift >= 1) {
                _m /= 10;
                _shift -= 1;
            }
        } else {
            _shift = -_shift;
            require(_shift <= int256(uint256(SIGNIFICANT_DIGITS)), "shift: |i| too large");
            while (_shift >= 16) {
                _m *= 1e16;
                _shift -= 16;
            }
            if (_shift >= 8) {
                _m *= 1e8;
                _shift -= 8;
            }
            if (_shift >= 4) {
                _m *= 1e4;
                _shift -= 4;
            }
            if (_shift >= 2) {
                _m *= 1e2;
                _shift -= 2;
            }
            if (_shift >= 1) {
                _m *= 10;
                _shift -= 1;
            }
        }

        return from(_m, _e);
    }

    //---------------
    //   normalize
    //---------------
    function normalize(int256 mantissa_, int256 exponent_) internal pure returns (Float) {
        if (mantissa_ == 0) return ZERO;

        int256 _m = mantissa_;
        int256 _e = exponent_;

        uint256 _mag = abs256(_m);

        if (_mag > NORMALIZED_MANTISSA_MAX) {
            while (_mag > NORMALIZED_MANTISSA_MAX) {
                _m /= 10;
                _e += 1;
                _mag /= 10;
            }
            return from(int128(_m), int128(_e));
        }

        if (_mag < NORMALIZED_MANTISSA_MIN) {
            while (_mag < NORMALIZED_MANTISSA_MIN) {
                _m *= 10;
                _e -= 1;
                _mag *= 10;
            }
            return from(int128(_m), int128(_e));
        }

        return from(int128(_m), int128(_e));
    }

    function normalize(Float a_) internal pure returns (Float) {
        (int128 _mantissa, int128 _exponent) = components(a_);
        return normalize(int256(_mantissa), int256(_exponent));
    }

    //-----------
    //   align
    //-----------
    function align(Float a_, Float b_) internal pure returns (Float, Float) {
        (int128 _aMantissa, int128 _aExponent) = components(a_);
        (int128 _bMantissa, int128 _bExponent) = components(b_);
        if (_aMantissa == 0 && _bMantissa == 0) {
            return (ZERO, ZERO);
        } else if (_aMantissa == 0) {
            return (from(0, _bExponent), from(_bMantissa, _bExponent));
        } else if (_bMantissa == 0) {
            return (from(_aMantissa, _aExponent), from(0, _aExponent));
        }

        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        _aMantissa = mantissa(_normA);
        _aExponent = exponent(_normA);
        _bMantissa = mantissa(_normB);
        _bExponent = exponent(_normB);

        int128 _delta = _aExponent - _bExponent;
        if (_delta >= 0) {
            if (uint128(_delta) > SIGNIFICANT_DIGITS) {
                return (_normA, from(0, _aExponent));
            }
            return (_normA, shift(_normB, _delta));
        } else {
            if (uint128(-_delta) > SIGNIFICANT_DIGITS) {
                return (from(0, _bExponent), _normB);
            }
            return (shift(_normA, -_delta), _normB);
        }
    }

    //================
    //   Arithmetic
    //================
    function plus(Float a_, Float b_) internal pure returns (Float) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        int256 _sum = int256(mantissa(_alignedA)) + int256(mantissa(_alignedB));
        return normalize(_sum, int256(exponent(_alignedA)));
    }

    function minus(Float a_) internal pure returns (Float) {
        int128 _m = mantissa(a_);
        int128 _e = exponent(a_);
        return from(-_m, _e);
    }

    function minus(Float a_, Float b_) internal pure returns (Float) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        int256 _diff = int256(mantissa(_alignedA)) - int256(mantissa(_alignedB));
        return normalize(_diff, int256(exponent(_alignedA)));
    }

    function times(Float a_, Float b_) internal pure returns (Float) {
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        int256 _ma = int256(mantissa(_normA));
        int256 _mb = int256(mantissa(_normB));
        return normalize(
            (_ma * _mb) / int256(10 ** SIGNIFICANT_DIGITS),
            toInt(SIGNIFICANT_DIGITS) + int256(exponent(_normA)) + int256(exponent(_normB))
        );
    }

    function divide(Float a_, Float b_) internal pure returns (Float) {
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        int256 _ma = int256(mantissa(_normA));
        int256 _mb = int256(mantissa(_normB));
        return normalize(
            (_ma * int256(10 ** SIGNIFICANT_DIGITS)) / _mb,
            int256(exponent(_normA)) - int256(exponent(_normB)) - toInt(SIGNIFICANT_DIGITS)
        );
    }

    //=======================
    //   Special functions
    //=======================
    function round(Float a_, uint256 digits_) internal pure returns (Float) {
        if (mantissa(a_) == 0) return ZERO;
        if (digits_ >= SIGNIFICANT_DIGITS) return normalize(a_);
        Float _norm = normalize(a_);
        int256 _factor = int256(10 ** (SIGNIFICANT_DIGITS - digits_));
        int256 _mant = int256(mantissa(_norm));
        int256 _scaled = _mant / _factor;
        int256 _remainder = _mant % _factor;
        if (_remainder * 2 >= _factor) {
            _scaled++;
        }
        if (_remainder * 2 <= -_factor) {
            _scaled--;
        }
        int256 _resultMant = _scaled * _factor;
        return from(int128(_resultMant), exponent(_norm));
    }

    function exp(int256 a_) internal pure returns (Float) {
        int256 _k = a_ / LOG10;
        int256 _aprime = a_ - _k * LOG10;
        return normalize(_aprime.expWad(), _k - 18);
    }

    function log(Float a_) internal pure returns (int256) {
        Float _norm = normalize(a_);
        return int256(mantissa(_norm)).lnWad() + (int256(exponent(_norm)) + 18) * LOG10;
    }

    struct Cubic {
        Float p;
        Float q;
        Float rad;
        Float u;
        Float w;
    }

    function cubicsolve(Float b_, Float c_, Float d_) internal pure returns (Float _x) {
        Cubic memory _cubic;

        _cubic.p = minus(c_, divide(times(b_, b_), THREE));
        _cubic.q =
            minus(plus(d_, divide(times(b_, times(b_, b_)), from(135, -1))), divide(times(b_, c_), from(3e17, -17)));
        _cubic.rad = plus(
            divide(times(_cubic.q, _cubic.q), FOUR), divide(times(_cubic.p, times(_cubic.p, _cubic.p)), from(27, 0))
        );
        if (isLT(_cubic.rad, ZERO)) revert NoSolution();
        _cubic.u = minus(exp(log(_cubic.rad) / 2), divide(_cubic.q, TWO));
        _cubic.w = mantissa(_cubic.u) > 0 ? exp(log(_cubic.u) / 3) : minus(exp(log(minus(_cubic.u)) / 3));

        _x = minus(minus(_cubic.w, divide(_cubic.p, times(THREE, _cubic.w))), divide(b_, THREE));
    }

    function fullMulDiv(Float a_, Float b_, Float c_) internal pure returns (Float) {
        int256 _sign = 1;
        if (mantissa(a_) < 0) {
            _sign *= -1;
        }
        if (mantissa(b_) < 0) {
            _sign *= -1;
        }
        if (mantissa(c_) < 0) {
            _sign *= -1;
        }
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        Float _normC = normalize(c_);
        uint256 _ma = uint256(int256(mantissa(_normA)).abs());
        uint256 _mb = uint256(int256(mantissa(_normB)).abs());
        uint256 _mc = uint256(int256(mantissa(_normC)).abs());
        int256 _mant = _sign * int256(_ma.fullMulDiv(_mb, _mc));
        int256 _exp = int256(exponent(_normA)) + int256(exponent(_normB)) - int256(exponent(_normC));
        return normalize(_mant, _exp);
    }

    //====================
    //   Helper methods
    //====================
    function from(int128 mantissa_, int128 exponent_) internal pure returns (Float) {
        int256 _packed = (int256(exponent_) << 128) | (int256(mantissa_) & MANTISSA_MASK);
        return Float.wrap(_packed);
    }

    function components(Float a_) internal pure returns (int128 _mantissa, int128 _exponent) {
        int256 _raw = Float.unwrap(a_);
        _mantissa = int128(_raw);
        _exponent = int128(_raw >> 128);
    }

    function mantissa(Float a_) internal pure returns (int128) {
        return int128(Float.unwrap(a_));
    }

    function exponent(Float a_) internal pure returns (int128) {
        return int128(Float.unwrap(a_) >> 128);
    }

    function abs256(int256 x_) internal pure returns (uint256) {
        if (x_ >= 0) return uint256(x_);
        unchecked {
            return uint256(~x_) + 1;
        }
    }
}
