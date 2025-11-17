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
    uint256 constant SIGNIFICANT_DIGITS = 18;
    uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
    uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);

    int256 constant ONE_MANTISSA = int256(10 ** (SIGNIFICANT_DIGITS - 1));
    int256 constant ONE_EXPONENT = -int256(SIGNIFICANT_DIGITS - 1);

    int256 constant LOG10 = 2302585092994045684;

    uint256 constant MANTISSA_MASK = (uint256(1) << 128) - 1;

    //=================
    //   Conversions
    //=================

    function one() internal pure returns (Float) {
        return from(ONE_MANTISSA, ONE_EXPONENT);
    }

    function oneMinus(Float a_) internal pure returns (Float) {
        return one().minus(a_);
    }

    //-----------
    //   toInt
    //-----------
    function toInt(uint256 a_) internal pure returns (int256) {
        require(a_ <= uint256(type(int256).max), "Value out of int256 range");
        return int256(a_);
    }

    function toInt(Float a_, uint256 decimals_) internal pure returns (int256) {
        (int256 _mantissa, int256 _exponent) = components(a_);
        int256 _exp = _exponent + toInt(decimals_);
        if (_exp >= 0) {
            return _mantissa * int256(10 ** toUInt(_exp));
        } else {
            return _mantissa / int256(10 ** toUInt(-_exp));
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
        (int256 _mantissa, int256 _exponent) = components(a_);
        require(_mantissa >= 0, "Value must be non-negative");
        int256 _exp = _exponent + toInt(decimals_);
        if (_exp >= 0) {
            return uint256(_mantissa) * 10 ** toUInt(_exp);
        } else {
            return uint256(_mantissa) / 10 ** toUInt(-_exp);
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
        require(a_ <= uint256(type(int256).max), "Value out of int256 range");
        return normalize(int256(a_), -toInt(decimals_));
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
        return from(int256(mantissa(a_).abs()), exponent(a_));
    }

    function integerPart(Float number_) internal pure returns (Float) {
        (int256 _mantissa, int256 _exponent) = components(number_);
        if (_exponent < 0) {
            int256 _temp = _mantissa;
            for (uint256 _i; _i < toUInt(-_exponent); _i++) {
                _temp /= 10;
                if (_temp == 0) return from(0, 0);
            }
            return from(_temp, 0);
        } else {
            return number_;
        }
    }

    //-----------
    //   Shift
    //-----------
    function shift(Float a_, int256 i_) internal pure returns (Float) {
        int256 _mantissa = mantissa(a_);
        if (i_ == 0 || _mantissa == 0) return a_;

        uint256 _k = i_ > 0 ? uint256(i_) : uint256(-i_);

        int256 _m = _mantissa;
        int256 _e = exponent(a_) + i_;

        if (i_ > 0) {
            while (_k >= 16) {
                _m /= 1e16;
                _k -= 16;
            }
            if (_k >= 8) {
                _m /= 1e8;
                _k -= 8;
            }
            if (_k >= 4) {
                _m /= 1e4;
                _k -= 4;
            }
            if (_k >= 2) {
                _m /= 1e2;
                _k -= 2;
            }
            if (_k >= 1) _m /= 10;
        } else {
            require(_k <= SIGNIFICANT_DIGITS, "shift: |i| too large");
            while (_k >= 16) {
                _m *= 1e16;
                _k -= 16;
            }
            if (_k >= 8) {
                _m *= 1e8;
                _k -= 8;
            }
            if (_k >= 4) {
                _m *= 1e4;
                _k -= 4;
            }
            if (_k >= 2) {
                _m *= 1e2;
                _k -= 2;
            }
            if (_k >= 1) _m *= 10;
        }

        return from(_m, _e);
    }

    //---------------
    //   normalize
    //---------------
    function normalize(int256 mantissa_, int256 exponent_) internal pure returns (Float) {
        if (mantissa_ == 0) return from(0, 0);

        int256 _m = mantissa_;
        int256 _e = exponent_;

        uint256 _mag = abs256(_m);

        if (_mag > NORMALIZED_MANTISSA_MAX) {
            while (_mag > NORMALIZED_MANTISSA_MAX) {
                _m /= 10;
                _e += 1;
                _mag /= 10;
            }
            return from(_m, _e);
        }

        if (_mag < NORMALIZED_MANTISSA_MIN) {
            while (_mag < NORMALIZED_MANTISSA_MIN) {
                _m *= 10;
                _e -= 1;
                _mag *= 10;
            }
            return from(_m, _e);
        }

        return from(_m, _e);
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
            Float _zero = from(0, 0);
            return (_zero, _zero);
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
            if (uint256(_delta) > SIGNIFICANT_DIGITS) {
                return (_normA, from(0, _aExponent));
            }
            return (_normA, shift(_normB, _delta));
        } else {
            if (uint256(-_delta) > SIGNIFICANT_DIGITS) {
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
        return normalize(
            (mantissa(_normA) * mantissa(_normB)) / int256(10 ** SIGNIFICANT_DIGITS),
            toInt(SIGNIFICANT_DIGITS) + exponent(_normA) + exponent(_normB)
        );
    }

    function divide(Float a_, Float b_) internal pure returns (Float) {
        Float _normA = normalize(a_);
        Float _normB = normalize(b_);
        return normalize(
            (mantissa(_normA) * int256(10 ** SIGNIFICANT_DIGITS)) / mantissa(_normB),
            exponent(_normA) - exponent(_normB) - toInt(SIGNIFICANT_DIGITS)
        );
    }

    //=======================
    //   Special functions
    //=======================
    function round(Float a_, uint256 digits_) internal pure returns (Float) {
        if (mantissa(a_) == 0) return from(0, 0);
        Float _norm = normalize(a_);
        int256 _factor = int256(10 ** (SIGNIFICANT_DIGITS - digits_));
        int256 _scaled = mantissa(_norm) / _factor;
        int256 _remainder = mantissa(_norm) % _factor;
        if (_remainder * 2 >= _factor) {
            _scaled++;
        }
        if (_remainder * 2 <= -_factor) {
            _scaled--;
        }
        return from(_scaled * _factor, exponent(_norm));
    }

    function exp(int256 a_) internal pure returns (Float) {
        int256 _k = a_ / LOG10;
        int256 _aprime = a_ - _k * LOG10;
        return normalize(_aprime.expWad(), _k - 18);
    }

    function log(Float a_) internal pure returns (int256) {
        Float _norm = normalize(a_);
        return int256(mantissa(_norm)).lnWad() + (exponent(_norm) + 18) * LOG10;
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

        _cubic.p = minus(c_, divide(times(b_, b_), from(3, 0)));
        _cubic.q =
            minus(plus(d_, divide(times(b_, times(b_, b_)), from(135, -1))), divide(times(b_, c_), from(3e17, -17)));
        _cubic.rad = plus(
            divide(times(_cubic.q, _cubic.q), from(4, 0)),
            divide(times(_cubic.p, times(_cubic.p, _cubic.p)), from(27, 0))
        );
        if (isLT(_cubic.rad, from(0, 0))) revert NoSolution();
        _cubic.u = minus(exp(log(_cubic.rad) / 2), divide(_cubic.q, from(2, 0)));
        _cubic.w = mantissa(_cubic.u) > 0 ? exp(log(_cubic.u) / 3) : minus(exp(log(minus(_cubic.u)) / 3));

        _x = minus(minus(_cubic.w, divide(_cubic.p, times(from(3, 0), _cubic.w))), divide(b_, from(3, 0)));
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
        return normalize(
            _sign * int256(mantissa(_normA).abs().fullMulDiv(mantissa(_normB).abs(), mantissa(_normC).abs())),
            exponent(_normA) + exponent(_normB) - exponent(_normC)
        );
    }

    //====================
    //   Helper methods
    //====================
    function from(int256 mantissa_, int256 exponent_) internal pure returns (Float) {
        require(mantissa_ >= type(int128).min && mantissa_ <= type(int128).max, "Mantissa overflow");
        require(exponent_ >= type(int128).min && exponent_ <= type(int128).max, "Exponent overflow");
        int256 _packed = (exponent_ << 128) | (mantissa_ & int256(MANTISSA_MASK));
        return Float.wrap(_packed);
    }

    function components(Float a_) internal pure returns (int256 _mantissa, int256 _exponent) {
        int256 _raw = Float.unwrap(a_);
        _mantissa = int256(int128(_raw));
        _exponent = int256(int128(_raw >> 128));
    }

    function mantissa(Float a_) internal pure returns (int256) {
        return int256(int128(Float.unwrap(a_)));
    }

    function exponent(Float a_) internal pure returns (int256) {
        return int256(int128(Float.unwrap(a_) >> 128));
    }

    function abs256(int256 x_) internal pure returns (uint256) {
        if (x_ >= 0) return uint256(x_);
        unchecked {
            return uint256(~x_) + 1;
        }
    }
}
