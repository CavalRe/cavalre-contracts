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

    function shiftStringBytesLeft(
        bytes memory strBytes_,
        uint256 numChars_
    ) public pure returns (bytes memory) {
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

    function shiftStringLeft(
        string memory str_,
        uint256 numChars_
    ) public pure returns (string memory) {
        return string(shiftStringBytesLeft(bytes(str_), numChars_));
    }

    function shiftStringBytesRight(
        bytes memory strBytes_,
        uint256 numChars_
    ) public pure returns (bytes memory _result, bytes memory _remainder) {
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
                _remainder[_remainderChars - 1 + _resultChars - _i] = strBytes_[
                    strBytes_.length - 1 + _resultChars - _i
                ];
            }
        }

        return (_result, _remainder);
    }

    function shiftStringRight(
        string memory str_,
        uint256 numChars_
    ) public pure returns (string memory _result, string memory _remainder) {
        bytes memory _strBytes = bytes(str_);
        bytes memory _resultBytes;
        bytes memory _remainderBytes;
        (_resultBytes, _remainderBytes) = shiftStringBytesRight(
            _strBytes,
            numChars_
        );
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

    function toStringBytes(
        Float value_
    ) internal pure returns (bytes memory, bytes memory) {
        Float _norm = FloatLib.normalize(value_);
        (Float _intPart, Float _fracPart) = FloatLib.parts(_norm);

        // Integer part
        bytes memory _integerPartBytes;
        Float _absInt = FloatLib.abs(_intPart);
        (int256 _intMantissa, ) = FloatLib.components(_absInt);
        if (_intMantissa == 0) {
            _integerPartBytes = bytes("0");
        } else {
            uint256 _intVal = FloatLib.toUInt(_absInt, 0);
            _integerPartBytes = toStringBytes(_intVal);
        }

        // Fractional part
        bytes memory _fractionalPartBytes;
        Float _absFrac = FloatLib.abs(_fracPart);
        (int256 _fracMantissa, int256 _fracExponent) = FloatLib.components(
            _absFrac
        );
        if (_fracMantissa == 0) {
            _fractionalPartBytes = bytes("0");
        } else {
            bytes memory _mantBytes = toStringBytes(
                uint256(
                    int256(_fracMantissa >= 0 ? _fracMantissa : -_fracMantissa)
                )
            );
            uint256 _digits = uint256(-_fracExponent); // exponent is negative for fractional part
            _fractionalPartBytes = new bytes(_digits);
            for (uint256 _i = 0; _i < _digits; _i++) {
                if (_i < _mantBytes.length) {
                    _fractionalPartBytes[_digits - 1 - _i] = _mantBytes[
                        _mantBytes.length - 1 - _i
                    ];
                } else {
                    _fractionalPartBytes[_digits - 1 - _i] = bytes1("0");
                }
            }
        }

        return (_integerPartBytes, _fractionalPartBytes);
    }

    function toString(uint256 value_) public pure returns (string memory) {
        return string(toStringBytes(value_));
    }

    function toString(int256 value_) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    value_ < 0 ? "-" : "",
                    toStringBytes(value_.abs())
                )
            );
    }

    function trimStringBytesRight(
        bytes memory strBytes_
    ) public pure returns (bytes memory) {
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

    function trimStringRight(
        string memory str_
    ) public pure returns (string memory) {
        return string(trimStringBytesRight(bytes(str_)));
    }

    function toString(Float number_) internal pure returns (string memory) {
        bytes memory _integerPartBytes;
        bytes memory _fractionalPartBytes;

        number_ = FloatLib.normalize(number_);

        Float _max = FloatLib.normalize(
            int256(FloatLib.NORMALIZED_MANTISSA_MAX),
            0
        );

        int256 _ushift = int256(FloatLib.SIGNIFICANT_DIGITS) - 1;
        int256 _ishift = _ushift;

        (int256 _mantissa, int256 _exponent) = FloatLib.components(number_);
        // int256 _mant = int256(_mantissa);
        // int256 _exp = int256(_exponent);
        if (FloatLib.abs(number_).isLT(_max) && _exponent >= -_ishift) {
            (_integerPartBytes, _fractionalPartBytes) = toStringBytes(number_);
            return
                string(
                    abi.encodePacked(
                        _mantissa < 0 ? "-" : "",
                        string(_integerPartBytes),
                        ".",
                        string(trimStringBytesRight(_fractionalPartBytes))
                    )
                );
        } else {
            (_integerPartBytes, _fractionalPartBytes) = toStringBytes(
                FloatLib.normalize(_mantissa, -_ishift)
            );
            return
                string(
                    abi.encodePacked(
                        _mantissa < 0 ? "-" : "",
                        string(_integerPartBytes),
                        ".",
                        string(trimStringBytesRight(_fractionalPartBytes)),
                        "e",
                        toString(_exponent + _ishift)
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
