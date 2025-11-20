// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Float, FloatLib} from "./FloatLib.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

library FloatStrings {
    using FixedPointMathLib for int256;
    using FloatLib for Float;

    // Most significant bit
    function msb(int256 value_) internal pure returns (uint256) {
        if (value_ == 0) {
            return 0;
        }

        return toStringBytes(value_.abs()).length;
    }

    function shiftStringBytesLeft(bytes memory strBytes_, uint256 numChars_) public pure returns (bytes memory) {
        bytes memory _result = new bytes(strBytes_.length + numChars_);

        for (uint256 _i = 0; _i < _result.length; _i++) {
            if (_i < strBytes_.length) {
                _result[_i] = strBytes_[_i];
            } else {
                _result[_i] = "0";
            }
        }

        return _result;
    }

    function shiftStringLeft(string memory str_, uint256 numChars_) public pure returns (string memory) {
        return string(shiftStringBytesLeft(bytes(str_), numChars_));
    }

    function shiftStringBytesRight(bytes memory strBytes_, uint256 numChars_)
        public
        pure
        returns (bytes memory _result, bytes memory _remainder)
    {
        uint256 _resultChars;
        uint256 _remainderChars;
        uint256 _excessChars;
        if (numChars_ > strBytes_.length) {
            _resultChars = 0;
            _excessChars = numChars_ - strBytes_.length;
            _result = new bytes(1);
        } else {
            _resultChars = strBytes_.length - numChars_;
            _result = new bytes(_resultChars);
        }
        _remainderChars = numChars_;
        _remainder = new bytes(_remainderChars);

        for (uint256 _i = 0; _i < strBytes_.length; _i++) {
            if (_i < _resultChars) {
                _result[_i] = strBytes_[_i];
            } else {
                _remainder[_remainderChars - 1 + _resultChars - _i] =
                    strBytes_[strBytes_.length - 1 + _resultChars - _i];
            }
        }

        return (_result, _remainder);
    }

    function shiftStringRight(string memory str_, uint256 numChars_)
        public
        pure
        returns (string memory _result, string memory _remainder)
    {
        bytes memory _strBytes = bytes(str_);
        bytes memory _resultBytes;
        bytes memory _remainderBytes;
        (_resultBytes, _remainderBytes) = shiftStringBytesRight(_strBytes, numChars_);
        _result = string(_resultBytes);
        _remainder = string(_remainderBytes);
    }

    function toStringBytes(uint256 value_) public pure returns (bytes memory) {
        // Handle the special case of zero.
        if (value_ == 0) {
            return bytes("0");
        }

        // Determine the length of the decimal number.
        uint256 _digits = digits(value_);

        // Create a temporary byte array to fill with the digits of the number.
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) {
            _digits -= 1;
            _buffer[_digits] = bytes1(uint8(48 + (value_ % 10)));
            value_ /= 10;
        }

        // Convert the byte array to a string and return it.
        return _buffer;
    }

    function toStringBytes(Float value_) internal pure returns (bytes memory, bytes memory) {
        (int128 _mantissa, ) = FloatLib.components(value_);
        int256 _mant = int256(_mantissa);
        if (_mant == 0) {
            return (bytes("0"), bytes("0"));
        }

        Float _integerPartFloat = FloatLib.integerPart(value_);
        bytes memory _integerPartBytes;

        (int128 _intMantissa, int128 _intExponent) = FloatLib.components(_integerPartFloat);
        if (_intMantissa == 0) {
            _integerPartBytes = bytes("0");
        } else {
            bytes memory _integerPartMantissaBytes =
                toStringBytes(uint256(int256(_intMantissa >= 0 ? _intMantissa : -_intMantissa)));

            _integerPartBytes = new bytes(_integerPartMantissaBytes.length + uint256(int256(_intExponent)));

            for (uint256 _i = 0; _i < _integerPartBytes.length; _i++) {
                if (_i < _integerPartMantissaBytes.length) {
                    _integerPartBytes[_i] = _integerPartMantissaBytes[_i];
                } else {
                    _integerPartBytes[_i] = bytes1("0");
                }
            }
        }

        Float _fractionalPartFloat;
        if (_intMantissa == 0) {
            _fractionalPartFloat = value_;
        } else {
            _fractionalPartFloat = FloatLib.minus(value_, _integerPartFloat);
        }

        bytes memory _fractionalPartBytes;
        (int128 _fracMantissa, int128 _fracExponent) = FloatLib.components(_fractionalPartFloat);
        if (_fracMantissa == 0) {
            _fractionalPartBytes = bytes("0");
        } else {
            bytes memory _fractionalPartMantissaBytes =
                toStringBytes(uint256(int256(_fracMantissa >= 0 ? _fracMantissa : -_fracMantissa)));

            _fractionalPartBytes = new bytes(uint256(-int256(_fracExponent)));

            for (uint256 _i = 0; _i < _fractionalPartBytes.length; _i++) {
                if (_i < _fractionalPartMantissaBytes.length) {
                    _fractionalPartBytes[_fractionalPartBytes.length - 1 - _i] =
                        _fractionalPartMantissaBytes[_fractionalPartMantissaBytes.length - 1 - _i];
                } else {
                    _fractionalPartBytes[_fractionalPartBytes.length - 1 - _i] = bytes1("0");
                }
            }
        }

        return (_integerPartBytes, _fractionalPartBytes);
    }

    function toString(uint256 value_) public pure returns (string memory) {
        return string(toStringBytes(value_));
    }

    function toString(int256 value_) public pure returns (string memory) {
        return string(abi.encodePacked(value_ < 0 ? "-" : "", toStringBytes(value_.abs())));
    }

    function trimStringBytesRight(bytes memory strBytes_) public pure returns (bytes memory) {
        uint256 _i = strBytes_.length - 1;
        while (_i > 0 && strBytes_[_i] == "0") {
            _i--;
        }
        bytes memory _result = new bytes(_i + 1);
        for (uint256 _j = 0; _j < _i + 1; _j++) {
            _result[_j] = strBytes_[_j];
        }
        return _result;
    }

    function trimStringRight(string memory str_) public pure returns (string memory) {
        return string(trimStringBytesRight(bytes(str_)));
    }

    function toString(Float number_) internal pure returns (string memory) {
        bytes memory _integerPartBytes;
        bytes memory _fractionalPartBytes;

        number_ = FloatLib.normalize(number_);

        Float _max = FloatLib.normalize(int256(uint256(FloatLib.NORMALIZED_MANTISSA_MAX)), 0);

        uint256 _ushift = FloatLib.SIGNIFICANT_DIGITS - 1;
        int256 _ishift = int256(_ushift);

        (int128 _mantissa, int128 _exponent) = FloatLib.components(number_);
        int256 _mant = int256(_mantissa);
        int256 _exp = int256(_exponent);
        if (FloatLib.abs(number_).isLT(_max) && _exp >= -_ishift) {
            (_integerPartBytes, _fractionalPartBytes) = toStringBytes(number_);
            return string(
                abi.encodePacked(
                    _mant < 0 ? "-" : "",
                    string(_integerPartBytes),
                    ".",
                    string(trimStringBytesRight(_fractionalPartBytes))
                )
            );
        } else {
            (_integerPartBytes, _fractionalPartBytes) = toStringBytes(FloatLib.normalize(_mant, -_ishift));
            return string(
                abi.encodePacked(
                    _mant < 0 ? "-" : "",
                    string(_integerPartBytes),
                    ".",
                    string(trimStringBytesRight(_fractionalPartBytes)),
                    "e",
                    toString(_exp + _ishift)
                )
            );
        }
    }

    function digits(uint256 number_) public pure returns (uint8) {
        if (number_ == 0) {
            return 1; // Zero has 1 significant digit
        }

        uint8 count = 0;
        while (number_ != 0) {
            count++;
            number_ /= 10; // Remove the least significant digit
        }
        return count;
    }
}
