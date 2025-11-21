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
    int128 constant SIGNIFICANT_DIGITS = 19;
    int256 constant NORMALIZED_MANTISSA_MAX = int256(10 ** uint256(int256(SIGNIFICANT_DIGITS)) - 1);
    int256 constant NORMALIZED_MANTISSA_MIN = int256(10 ** uint256(int256(SIGNIFICANT_DIGITS - 1)));
    int256 constant MANTISSA_MASK = int256(uint256(type(uint128).max));

    int128 constant ONE_MANTISSA = int128(uint128(10) ** uint128(SIGNIFICANT_DIGITS - 1));
    int128 constant ONE_EXPONENT = -int128(SIGNIFICANT_DIGITS - 1);

    int128 constant LOG10_WAD = 2302585092994045684;
    Float constant LOG10 = Float.wrap((int256(-18) << 128) | int256(LOG10_WAD));

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
    // Needed for exponential function
    function toInt(Float a_, uint8 decimals_) internal pure returns (int256) {
        (int128 _m, int128 _e) = components(a_);
        _e += int128(uint128(decimals_));
        if (_e >= 0) {
            return int256(_m) * int256(10 ** uint256(uint128(_e)));
        } else {
            return int256(_m) / int256(10 ** uint256(uint128(-_e)));
        }
    }

    function toInt(Float a_) internal pure returns (int256) {
        return toInt(a_, 18);
    }

    //------------
    //   toUInt
    //------------
    function toUInt(Float a_, uint8 decimals_) internal pure returns (uint256) {
        (int128 _m, int128 _e) = components(a_);
        require(_m >= 0, "Value must be non-negative");
        _e += int128(uint128(decimals_));
        if (_e >= 0) {
            return uint256(int256(_m)) * 10 ** uint256(int256(_e));
        } else {
            return uint256(int256(_m)) / 10 ** uint256(int256(-_e));
        }
    }

    function toUInt(Float a_) internal pure returns (uint256) {
        return toUInt(a_, 18);
    }

    //--------------
    //   toFloat
    //--------------
    function toFloat(uint256 a_, uint8 decimals_) internal pure returns (Float) {
        int128 _exp = -int128(uint128(decimals_));
        uint256 _amax = uint256(int256(type(int128).max));
        while (a_ > _amax) {
            a_ /= 10;
            _exp += 1;
        }
        return normalize(int128(uint128(a_)), _exp);
    }

    function toFloat(uint256 a_) internal pure returns (Float) {
        return toFloat(a_, 18);
    }

    //-------------------
    //   toFloatArray
    //-------------------

    // function toFloatArray(int256[] memory a_, uint8[] memory decimals_) internal pure returns (Float[] memory) {
    //     Float[] memory _result = new Float[](a_.length);
    //     for (uint256 _i = 0; _i < a_.length; _i++) {
    //         _result[_i] = toFloat(a_[_i], decimals_[_i]);
    //     }
    //     return _result;
    // }

    // function toFloatArray(int256[] memory a_) internal pure returns (Float[] memory) {
    //     Float[] memory _result = new Float[](a_.length);
    //     for (uint256 _i = 0; _i < a_.length; _i++) {
    //         _result[_i] = toFloat(a_[_i]);
    //     }
    //     return _result;
    // }

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
            require(_shift <= int256(SIGNIFICANT_DIGITS), "shift: |i| too large");
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

    // function normalize(int256 mantissa_, int256 exponent_) internal pure returns (Float) {
    //     if (mantissa_ == 0) return ZERO;

    //     int256 _mag = mantissa_ >= 0 ? mantissa_ : -mantissa_;

    //     if (_mag > NORMALIZED_MANTISSA_MAX) {
    //         while (_mag > NORMALIZED_MANTISSA_MAX) {
    //             mantissa_ /= 10;
    //             exponent_ += 1;
    //             _mag /= 10;
    //         }
    //         return from(mantissa_, exponent_);
    //     }

    //     if (_mag < NORMALIZED_MANTISSA_MIN) {
    //         while (_mag < NORMALIZED_MANTISSA_MIN) {
    //             mantissa_ *= 10;
    //             exponent_ -= 1;
    //             _mag *= 10;
    //         }
    //         return from(mantissa_, exponent_);
    //     }

    //     return from(mantissa_, exponent_);
    // }

    function normalize(int128 mantissa_, int128 exponent_) internal pure returns (Float) {
        if (mantissa_ == 0) return ZERO;

        int128 _mag = mantissa_ >= 0 ? mantissa_ : -mantissa_;

        if (_mag > NORMALIZED_MANTISSA_MAX) {
            while (_mag > NORMALIZED_MANTISSA_MAX) {
                mantissa_ /= 10;
                exponent_ += 1;
                _mag /= 10;
            }
            return from(mantissa_, exponent_);
        }

        if (_mag < NORMALIZED_MANTISSA_MIN) {
            while (_mag < NORMALIZED_MANTISSA_MIN) {
                mantissa_ *= 10;
                exponent_ -= 1;
                _mag *= 10;
            }
            return from(mantissa_, exponent_);
        }

        return from(mantissa_, exponent_);
    }

    function normalize(Float a_) internal pure returns (Float) {
        (int128 _mantissa, int128 _exponent) = components(a_);
        return normalize(_mantissa, _exponent);
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
            if (_delta > SIGNIFICANT_DIGITS) {
                return (_normA, from(0, _aExponent));
            }
            return (_normA, shift(_normB, _delta));
        } else {
            if (-_delta > SIGNIFICANT_DIGITS) {
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
        return normalize(mantissa(_alignedA) + mantissa(_alignedB), exponent(_alignedA));
    }

    function minus(Float a_) internal pure returns (Float) {
        return from(-mantissa(a_), exponent(a_));
    }

    function minus(Float a_, Float b_) internal pure returns (Float) {
        (Float _alignedA, Float _alignedB) = align(a_, b_);
        return normalize(mantissa(_alignedA) - mantissa(_alignedB), exponent(_alignedA));
    }

    function times(Float a_, Float b_) internal pure returns (Float) {
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        int128 _ma = mantissa(_normA);
        int128 _mb = mantissa(_normB);
        return normalize(
            (_ma * _mb) / int128(uint128(10) ** uint128(SIGNIFICANT_DIGITS)),
            SIGNIFICANT_DIGITS + exponent(_normA) + exponent(_normB)
        );
    }

    function divide(Float a_, Float b_) internal pure returns (Float) {
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        int128 _ma = mantissa(_normA);
        int128 _mb = mantissa(_normB);
        return normalize(
            (_ma * int128(uint128(10) ** uint128(SIGNIFICANT_DIGITS))) / _mb,
            exponent(_normA) - exponent(_normB) - SIGNIFICANT_DIGITS
        );
    }

    //=======================
    //   Special functions
    //=======================
    function round(Float a_, uint128 digits_) internal pure returns (Float) {
        if (mantissa(a_) == 0) return ZERO;
        if (digits_ >= uint128(SIGNIFICANT_DIGITS)) return normalize(a_);
        Float _norm = normalize(a_);
        int256 _factor = int256(10 ** (uint128(SIGNIFICANT_DIGITS) - digits_));
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

    function parts(Float number_) internal pure returns (Float _integerPart, Float _fractionalPart) {
        Float _norm = normalize(number_);
        (int128 _m, int128 _e) = components(_norm);

        if (_m == 0) return (ZERO, ZERO);
        if (_e >= 0) return (_norm, ZERO);
        if (SIGNIFICANT_DIGITS + _e < 0) return (ZERO, _norm); // too small, integer part is 0

        int128 _div = int128(uint128(10) ** uint128(-_e)); // shift ≤ SIGNIFICANT_DIGITS
        _integerPart = normalize(_m / _div, 0); // truncates toward zero
        _fractionalPart = _norm.minus(_integerPart);
    }

    function exp(Float x_) internal pure returns (Float) {
        Float _y = x_.divide(LOG10);
        (Float _yInt, Float _yFrac) = _y.parts();
        int256 _wad = _yFrac.times(LOG10).toInt(); // 18-decimal wad
        int128 _m = int128(_wad.expWad()); // still 18-decimal wad
        int256 _eInt = _yInt.toInt(0) - 18; // adjust for wad scale
        return normalize(_m, int128(_eInt));
    }

    function log(Float x_) internal pure returns (Float) {
        Float _x = normalize(x_);
        (int128 _m, int128 _e) = components(_x);
        require(_m > 0, "log non-positive");

        int256 _lnWad = (int256(_m) * 1e18).lnWad() + int256(_e) * LOG10_WAD;
        require(_lnWad >= int256(type(int128).min) && _lnWad <= int256(type(int128).max), "log overflow");

        return normalize(int128(_lnWad), -18);
    }

    function fullMulDiv(Float a_, Float b_, Float c_) internal pure returns (Float) {
        int128 _sign = 1;
        if (mantissa(a_) < 0) {
            a_ = minus(a_);
            _sign = -_sign;
        }
        if (mantissa(b_) < 0) {
            b_ = minus(b_);
            _sign = -_sign;
        }
        if (mantissa(c_) < 0) {
            c_ = minus(c_);
            _sign = -_sign;
        }
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        Float _normC = normalize(c_);
        uint256 _ma = uint256(uint128(mantissa(_normA)));
        uint256 _mb = uint256(uint128(mantissa(_normB)));
        uint256 _mc = uint256(uint128(mantissa(_normC)));
        int256 _mant = _sign * int128(int256(_ma.fullMulDiv(_mb, _mc)));
        int256 _exp = int256(exponent(_normA)) + int256(exponent(_normB)) - int256(exponent(_normC));
        return normalize(int128(_mant), int128(_exp));
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
