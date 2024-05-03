// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FloatingPoint, UFloat} from "./FloatingPoint.sol";

library FloatingPointStrings {
    using FloatingPoint for uint256;
    using FloatingPoint for int256;
    using FloatingPoint for UFloat;

    // Most significant bit
    function msb(uint256 value) internal pure returns (uint256) {
        if (value == 0) {
            return 0;
        }
        return toStringBytes(value).length;
    }

    function shiftStringBytesLeft(
        bytes memory strBytes,
        uint256 numChars
    ) public pure returns (bytes memory) {
        bytes memory result = new bytes(strBytes.length + numChars);

        for (uint256 i = 0; i < result.length; i++) {
            if (i < strBytes.length) {
                result[i] = strBytes[i];
            } else {
                result[i] = "0";
            }
        }

        return result;
    }

    function shiftStringLeft(
        string memory str,
        uint256 numChars
    ) public pure returns (string memory) {
        return string(shiftStringBytesLeft(bytes(str), numChars));
    }

    function shiftStringBytesRight(
        bytes memory strBytes,
        uint256 numChars
    ) public pure returns (bytes memory result, bytes memory remainder) {
        uint256 resultChars;
        uint256 remainderChars;
        uint256 excessChars;
        if (numChars > strBytes.length) {
            resultChars = 0;
            excessChars = numChars - strBytes.length;
            result = new bytes(1);
        } else {
            resultChars = strBytes.length - numChars;
            result = new bytes(resultChars);
        }
        remainderChars = numChars;
        remainder = new bytes(remainderChars);

        for (uint256 i = 0; i < strBytes.length; i++) {
            if (i < resultChars) {
                result[i] = strBytes[i];
            } else {
                remainder[remainderChars - 1 + resultChars - i] = strBytes[
                    strBytes.length - 1 + resultChars - i
                ];
            }
        }

        return (result, remainder);
    }

    function shiftStringRight(
        string memory str,
        uint256 numChars
    ) public pure returns (string memory result, string memory remainder) {
        bytes memory strBytes = bytes(str);
        bytes memory resultBytes;
        bytes memory remainderBytes;
        (resultBytes, remainderBytes) = shiftStringBytesRight(
            strBytes,
            numChars
        );
        result = string(resultBytes);
        remainder = string(remainderBytes);
    }

    function toStringBytes(uint256 value) public pure returns (bytes memory) {
        // Handle the special case of zero.
        if (value == 0) {
            return bytes("0");
        }

        // Determine the length of the decimal number.
        // uint256 temp = value;
        uint256 digits_ = digits(value);
        // while (temp != 0) {
        //     digits_++;
        //     temp /= 10;
        // }

        // Create a temporary byte array to fill with the digits of the number.
        bytes memory buffer = new bytes(digits_);
        while (value != 0) {
            digits_ -= 1;
            buffer[digits_] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }

        // Convert the byte array to a string and return it.
        return buffer;
    }

    function toStringBytes(
        UFloat memory value
    ) public pure returns (bytes memory, bytes memory) {
        // Handle the special case of zero.
        if (value.mantissa == 0) {
            return (bytes("0"), bytes("0"));
        }

        UFloat memory integerPartFloat = value.integerPart();

        bytes memory integerPartBytes;
        if (integerPartFloat.mantissa == 0) {
            integerPartBytes = bytes("0");
        } else {
            bytes memory integerPartMantissaBytes = toStringBytes(
                integerPartFloat.mantissa
            );

            integerPartBytes = new bytes(
                integerPartMantissaBytes.length +
                    integerPartFloat.exponent.toUInt()
            );

            for (uint256 i = 0; i < integerPartBytes.length; i++) {
                if (i < integerPartMantissaBytes.length) {
                    integerPartBytes[i] = integerPartMantissaBytes[i];
                } else {
                    integerPartBytes[i] = bytes1("0");
                }
            }
        }

        UFloat memory fractionalPartFloat;
        if (integerPartFloat.mantissa == 0) {
            fractionalPartFloat = value;
        } else {
            fractionalPartFloat = value.minus(integerPartFloat);
        }

        bytes memory fractionalPartBytes;
        if (fractionalPartFloat.mantissa == 0) {
            fractionalPartBytes = bytes("0");
        } else {
            bytes memory fractionalPartMantissaBytes = toStringBytes(
                fractionalPartFloat.mantissa
            );

            fractionalPartBytes = new bytes(
                (-fractionalPartFloat.exponent).toUInt()
            );

            for (uint256 i = 0; i < fractionalPartBytes.length; i++) {
                if (i < fractionalPartMantissaBytes.length) {
                    fractionalPartBytes[
                        fractionalPartBytes.length - 1 - i
                    ] = fractionalPartMantissaBytes[
                        fractionalPartMantissaBytes.length - 1 - i
                    ];
                } else {
                    fractionalPartBytes[
                        fractionalPartBytes.length - 1 - i
                    ] = bytes1("0");
                }
            }
        }

        return (integerPartBytes, fractionalPartBytes);
    }

    function toString(uint256 value) public pure returns (string memory) {
        return string(toStringBytes(value));
    }

    function trimStringBytesRight(
        bytes memory strBytes
    ) public pure returns (bytes memory) {
        uint256 i = strBytes.length - 1;
        while (i > 0 && strBytes[i] == "0") {
            i--;
        }
        bytes memory result = new bytes(i + 1);
        for (uint256 j = 0; j < i + 1; j++) {
            result[j] = strBytes[j];
        }
        return result;
    }

    function trimStringRight(
        string memory str
    ) public pure returns (string memory) {
        return string(trimStringBytesRight(bytes(str)));
    }

    function toString(
        UFloat memory number
    ) public pure returns (string memory) {
        bytes memory integerPartBytes;
        bytes memory fractionalPartBytes;

        (integerPartBytes, fractionalPartBytes) = toStringBytes(number);
        return
            string(
                abi.encodePacked(
                    string(integerPartBytes),
                    ".",
                    string(trimStringBytesRight(fractionalPartBytes))
                )
            );
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
