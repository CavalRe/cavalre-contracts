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
    uint256 constant SIGNIFICANT_DIGITS = 21;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);
    uint256 constant MANTISSA_BITS = 72;
    uint256 constant MANTISSA_MASK = (uint256(1) << MANTISSA_BITS) - 1;

    int256 constant ONE_MANTISSA = int256(10 ** (SIGNIFICANT_DIGITS - 1));
    int256 constant ONE_EXPONENT = -int256(SIGNIFICANT_DIGITS - 1);

    Float constant PI = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | 314159265358979323846);

    int256 constant LOG10_WAD = 2302585092994045684;
    Float constant LOG10 = Float.wrap((int256(-18) << MANTISSA_BITS) | LOG10_WAD);

    Float constant ZERO = Float.wrap(0);
    Float constant ONE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | ONE_MANTISSA);
    Float constant TWO = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (2 * ONE_MANTISSA));
    Float constant THREE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (3 * ONE_MANTISSA));
    Float constant FOUR = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (4 * ONE_MANTISSA));
    Float constant FIVE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (5 * ONE_MANTISSA));
    Float constant SIX = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (6 * ONE_MANTISSA));
    Float constant SEVEN = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (7 * ONE_MANTISSA));
    Float constant EIGHT = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (8 * ONE_MANTISSA));
    Float constant NINE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (9 * ONE_MANTISSA));
    Float constant TEN = Float.wrap(((ONE_EXPONENT + 1) << MANTISSA_BITS) | ONE_MANTISSA);
    Float constant HALF = Float.wrap(((ONE_EXPONENT - 1) << MANTISSA_BITS) | (5 * ONE_MANTISSA));

    //=================
    //   Conversions
    //=================

    //-----------
    //   toInt
    //-----------
    // Needed for exponential function
    function toInt(Float a_, uint8 decimals_) internal pure returns (int256) {
        (int256 _m, int256 _e) = components(a_);
        _e += int256(uint256(decimals_));
        if (_e >= 0) {
            return _m * int256(10 ** uint256(_e));
        } else {
            return _m / int256(10 ** uint256(-_e));
        }
    }

    function toInt(Float a_) internal pure returns (int256) {
        return toInt(a_, 18);
    }

    //------------
    //   toUInt
    //------------
    function toUInt(Float a_, uint8 decimals_) internal pure returns (uint256) {
        (int256 _m, int256 _e) = components(a_);
        require(_m >= 0, "Value must be non-negative");
        _e += int256(uint256(decimals_));
        if (_e >= 0) {
            return uint256(_m) * 10 ** uint256(_e);
        } else {
            return uint256(_m) / 10 ** uint256(-_e);
        }
    }

    function toUInt(Float a_) internal pure returns (uint256) {
        return toUInt(a_, 18);
    }

    //--------------
    //   toFloat
    //--------------
    function toFloat(uint256 a_, uint8 decimals_) internal pure returns (Float) {
        return normalize(int256(a_), -int256(uint256(decimals_)));
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

    function isZero(Float a_) internal pure returns (bool) {
        return mantissa(a_) == 0;
    }

    //=====================
    //   Transformations
    //=====================
    function abs(Float a_) internal pure returns (Float) {
        (int256 _m, int256 _e) = components(a_);
        if (_m >= 0) return a_;
        return from(-_m, _e);
    }

    //-----------
    //   Shift
    //-----------
    function shift(Float a_, int256 i_) internal pure returns (Float) {
        int256 _mantissa = mantissa(a_);
        if (i_ == 0 || _mantissa == 0) return a_;

        int256 _shift = i_;
        int256 _m = _mantissa;
        int256 _e = exponent(a_) + i_;

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

    function normalize(int256 mantissa_, int256 exponent_) internal pure returns (Float) {
        if (mantissa_ == 0) return ZERO;

        uint256 _mag = mantissa_ >= 0 ? uint256(mantissa_) : uint256(-mantissa_);

        while (_mag > NORMALIZED_MANTISSA_MAX) {
            mantissa_ /= 10;
            exponent_ += 1;
            _mag /= 10;
        }

        while (_mag < NORMALIZED_MANTISSA_MIN) {
            mantissa_ *= 10;
            exponent_ -= 1;
            _mag *= 10;
        }

        return from(mantissa_, exponent_);
    }

    function normalize(Float a_) internal pure returns (Float) {
        (int256 _mantissa, int256 _exponent) = components(a_);
        return normalize(_mantissa, _exponent);
    }

    //-----------
    //   align
    //-----------
    function align(Float a_, Float b_) internal pure returns (Float, Float) {
        (int256 _aMantissa, int256 _aExponent) = components(a_);
        (int256 _bMantissa, int256 _bExponent) = components(b_);
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

        int256 _delta = _aExponent - _bExponent;
        if (_delta >= 0) {
            if (_delta > int256(SIGNIFICANT_DIGITS)) {
                return (_normA, from(0, _aExponent));
            }
            return (_normA, shift(_normB, _delta));
        } else {
            if (-_delta > int256(SIGNIFICANT_DIGITS)) {
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
        int256 _ma = mantissa(_normA);
        int256 _mb = mantissa(_normB);
        return normalize(
            (_ma * _mb) / int256(10 ** SIGNIFICANT_DIGITS),
            int256(SIGNIFICANT_DIGITS) + exponent(_normA) + exponent(_normB)
        );
    }

    function divide(Float a_, Float b_) internal pure returns (Float) {
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        int256 _ma = mantissa(_normA);
        int256 _mb = mantissa(_normB);
        return normalize(
            (_ma * int256(10 ** SIGNIFICANT_DIGITS)) / _mb,
            exponent(_normA) - exponent(_normB) - int256(SIGNIFICANT_DIGITS)
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
        return from(_resultMant, exponent(_norm));
    }

    function parts(Float number_) internal pure returns (Float _integerPart, Float _fractionalPart) {
        Float _norm = normalize(number_);
        (int256 _m, int256 _e) = components(_norm);

        if (_m == 0) return (ZERO, ZERO);
        if (_e >= 0) return (_norm, ZERO);
        if (int256(SIGNIFICANT_DIGITS) + _e < 0) return (ZERO, _norm); // too small, integer part is 0

        int256 _div = int256(10 ** uint256(-_e)); // shift ≤ SIGNIFICANT_DIGITS
        _integerPart = normalize(_m / _div, 0); // truncates toward zero
        _fractionalPart = _norm.minus(_integerPart);
    }

    function exp(Float x_) internal pure returns (Float) {
        Float _y = x_.divide(LOG10);
        (Float _yInt, Float _yFrac) = _y.parts();
        int256 _wad = _yFrac.times(LOG10).toInt(); // 18-decimal wad
        int256 _m = _wad.expWad(); // still 18-decimal wad
        int256 _e = _yInt.toInt(0) - 18; // adjust for wad scale
        return normalize(_m, _e);
    }

    function log(Float x_) internal pure returns (Float) {
        Float _x = normalize(x_);
        (int256 _m, int256 _e) = components(_x);
        require(_m > 0, "log non-positive");

        int256 _lnWad = (_m * 1e18).lnWad() + _e * LOG10_WAD;

        return normalize(_lnWad, -18);
    }

    //-------------
    //   Pow
    //-------------
    // Exponentiation by squaring for integer exponents; faster and avoids the rounding stack-up of exp(log(x) * n).
    function powUint(Float base_, uint256 e_) internal pure returns (Float result_) {
        if (e_ == 0) return ONE;
        Float _base = normalize(base_);
        if (e_ == 1) return _base;
        if (mantissa(_base) == 0) return ZERO;
        if (_base.isEQ(ONE)) return ONE;

        result_ = ONE;
        uint256 _exp = e_;
        while (_exp != 0) {
            if (_exp & 1 == 1) {
                result_ = result_.times(_base);
            }
            _exp >>= 1;
            if (_exp != 0) {
                _base = _base.times(_base);
            }
        }
    }

    function powInt(Float base_, int256 e_) internal pure returns (Float) {
        Float _base = normalize(base_);
        if (e_ >= 0) return powUint(_base, uint256(e_));
        require(mantissa(_base) != 0, "pow: zero base");
        require(e_ != type(int256).min, "pow: exponent too small");
        Float _pos = powUint(_base, uint256(-e_));
        return ONE.divide(_pos);
    }

    // Real-exponent power via exp(log(base) * exponent); base must be positive to keep log defined.
    function pow(Float base_, Float e_) internal pure returns (Float) {
        Float _base = normalize(base_);
        if (mantissa(e_) == 0) return ONE;
        if (_base.isEQ(ONE)) return ONE;
        require(mantissa(_base) > 0, "pow: base must be positive");
        return exp(log(_base).times(e_));
    }

    function sqrt(Float x_) internal pure returns (Float) {
        return exp(log(x_).divide(TWO));
    }

    function fullMulDiv(Float a_, Float b_, Float c_) internal pure returns (Float) {
        bool _isNegative = false;
        if (mantissa(a_) < 0) {
            a_ = minus(a_);
            _isNegative = !_isNegative;
        }
        if (mantissa(b_) < 0) {
            b_ = minus(b_);
            _isNegative = !_isNegative;
        }
        if (mantissa(c_) < 0) {
            c_ = minus(c_);
            _isNegative = !_isNegative;
        }
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        Float _normC = normalize(c_);
        uint256 _ma = uint256(mantissa(_normA));
        uint256 _mb = uint256(mantissa(_normB));
        uint256 _mc = uint256(mantissa(_normC));
        int256 _m = _isNegative ? -int256(_ma.fullMulDiv(_mb, _mc)) : int256(_ma.fullMulDiv(_mb, _mc));
        int256 _e = exponent(_normA) + exponent(_normB) - exponent(_normC);
        return normalize(_m, _e);
    }

    //====================
    //   Helper methods
    //====================
    function from(int256 mantissa_, int256 exponent_) internal pure returns (Float) {
        int256 _packed = (exponent_ << MANTISSA_BITS) | (mantissa_ & int256(MANTISSA_MASK));
        return Float.wrap(_packed);
    }

    function components(Float a_) internal pure returns (int256 _mantissa, int256 _exponent) {
        int256 _raw = Float.unwrap(a_);
        _mantissa = int256(int72(_raw));
        _exponent = _raw >> MANTISSA_BITS;
    }

    function mantissa(Float a_) internal pure returns (int256) {
        return int256(int72(Float.unwrap(a_)));
    }

    function exponent(Float a_) internal pure returns (int256) {
        return int256(Float.unwrap(a_) >> MANTISSA_BITS);
    }
}
