// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {FloatLib, Float} from "../../libraries/FloatLib.sol";
import {FloatStrings} from "../../libraries/FloatStrings.sol";
import {Test} from "forge-std/src/Test.sol";

contract FloatTest is Test {
    using FloatLib for uint256;
    using FloatLib for int256;
    using FloatLib for Float;
    using FloatStrings for uint256;
    using FloatStrings for int256;
    using FloatStrings for Float;

    Float internal ZERO;
    Float internal HALF;
    Float internal ONE;
    Float internal TWO;
    Float internal THREE;
    Float internal FOUR;
    Float internal FIVE;
    Float internal SIX;
    Float internal SEVEN;
    Float internal EIGHT;
    Float internal NINE;
    Float internal TEN;

    Float internal ONEnHALF;
    Float internal TWOnHALF;
    Float internal THREEnHALF;
    Float internal FOURnHALF;
    Float internal FIVEnHALF;
    Float internal SIXnHALF;
    Float internal SEVENnHALF;
    Float internal EIGHTnHALF;
    Float internal NINEnHALF;

    Float internal a;
    Float internal b;
    Float internal c;

    Float internal ZERO_unnormalized;
    Float internal HALF_unnormalized;
    Float internal ONE_unnormalized;
    Float internal TWO_unnormalized;

    int256 internal mantissaZERO;
    int256 internal exponentZERO;
    int256 internal mantissaHALF;
    int256 internal exponentHALF;
    int256 internal mantissaONE;
    int256 internal exponentONE;
    int256 internal mantissaTWO;
    int256 internal exponentTWO;

    int256 internal mantissaZERO_unnormalized;
    int256 internal exponentZERO_unnormalized;
    int256 internal mantissaHALF_unnormalized;
    int256 internal exponentHALF_unnormalized;
    int256 internal mantissaONE_unnormalized;
    int256 internal exponentONE_unnormalized;
    int256 internal mantissaTWO_unnormalized;
    int256 internal exponentTWO_unnormalized;

    function assertEq(Float x, Float y) internal pure {
        x = FloatLib.normalize(x);
        y = FloatLib.normalize(y);
        assertEq(x.mantissa(), y.mantissa(), "mantissa");
        assertEq(x.exponent(), y.exponent(), "exponent");
    }

    function setUp() public {
        ZERO = FloatLib.normalize(0, 0);
        ONE = FloatLib.normalize(1, 0);
        TWO = FloatLib.normalize(2, 0);
        THREE = FloatLib.normalize(3, 0);
        FOUR = FloatLib.normalize(4, 0);
        FIVE = FloatLib.normalize(5, 0);
        SIX = FloatLib.normalize(6, 0);
        SEVEN = FloatLib.normalize(7, 0);
        EIGHT = FloatLib.normalize(8, 0);
        NINE = FloatLib.normalize(9, 0);
        TEN = FloatLib.normalize(10, 0);

        HALF = FloatLib.normalize(5, -1);
        ONEnHALF = FloatLib.normalize(15, -1);
        TWOnHALF = FloatLib.normalize(25, -1);
        THREEnHALF = FloatLib.normalize(35, -1);
        FOURnHALF = FloatLib.normalize(45, -1);
        FIVEnHALF = FloatLib.normalize(55, -1);
        SIXnHALF = FloatLib.normalize(65, -1);
        SEVENnHALF = FloatLib.normalize(75, -1);
        EIGHTnHALF = FloatLib.normalize(85, -1);
        NINEnHALF = FloatLib.normalize(95, -1);

        ZERO_unnormalized = FloatLib.from(0, 0);
        HALF_unnormalized = FloatLib.from(1, -1);
        ONE_unnormalized = FloatLib.from(1, 0);
        TWO_unnormalized = FloatLib.from(2, 0);

        mantissaZERO = ZERO.mantissa();
        exponentZERO = ZERO.exponent();
        mantissaHALF = HALF.mantissa();
        exponentHALF = HALF.exponent();
        mantissaONE = ONE.mantissa();
        exponentONE = ONE.exponent();
        mantissaTWO = TWO.mantissa();
        exponentTWO = TWO.exponent();

        mantissaZERO_unnormalized = ZERO_unnormalized.mantissa();
        exponentZERO_unnormalized = ZERO_unnormalized.exponent();
        mantissaHALF_unnormalized = HALF_unnormalized.mantissa();
        exponentHALF_unnormalized = HALF_unnormalized.exponent();
        mantissaONE_unnormalized = ONE_unnormalized.mantissa();
        exponentONE_unnormalized = ONE_unnormalized.exponent();
        mantissaTWO_unnormalized = TWO_unnormalized.mantissa();
        exponentTWO_unnormalized = TWO_unnormalized.exponent();
    }

    function getFloats() public view returns (Float[] memory) {
        Float[] memory _floats = new Float[](41);
        _floats[0] = TEN.minus();
        _floats[1] = NINEnHALF.minus();
        _floats[2] = NINE.minus();
        _floats[3] = EIGHTnHALF.minus();
        _floats[4] = EIGHT.minus();
        _floats[5] = SEVENnHALF.minus();
        _floats[6] = SEVEN.minus();
        _floats[7] = SIXnHALF.minus();
        _floats[8] = SIX.minus();
        _floats[9] = FIVEnHALF.minus();
        _floats[10] = FIVE.minus();
        _floats[11] = FOURnHALF.minus();
        _floats[12] = FOUR.minus();
        _floats[13] = THREEnHALF.minus();
        _floats[14] = THREE.minus();
        _floats[15] = TWOnHALF.minus();
        _floats[16] = TWO.minus();
        _floats[17] = ONEnHALF.minus();
        _floats[18] = ONE.minus();
        _floats[19] = HALF.minus();
        _floats[20] = ZERO;
        // _floats[20] = ONE;
        _floats[21] = HALF;
        _floats[22] = ONE;
        _floats[23] = ONEnHALF;
        _floats[24] = TWO;
        _floats[25] = TWOnHALF;
        _floats[26] = THREE;
        _floats[27] = THREEnHALF;
        _floats[28] = FOUR;
        _floats[29] = FOURnHALF;
        _floats[30] = FIVE;
        _floats[31] = FIVEnHALF;
        _floats[32] = SIX;
        _floats[33] = SIXnHALF;
        _floats[34] = SEVEN;
        _floats[35] = SEVENnHALF;
        _floats[36] = EIGHT;
        _floats[37] = EIGHTnHALF;
        _floats[38] = NINE;
        _floats[39] = NINEnHALF;
        _floats[40] = TEN;
        return _floats;
    }

    function testFloatToString() public {
        Float _float;
        Float _integerPartFloat;
        Float _fractionPartFloat;
        _float = FloatLib.from(12, -1);
        _integerPartFloat = _float.integerPart();
        _fractionPartFloat = _float.minus(_integerPartFloat);
        emit log_named_string("1.2", _float.toString());
        // emit log_named_uint("1.2.mantissa", float.mantissa);
        // emit log_named_int("1.2.exponent", float.exponent);
        emit log_named_string("Integer part of 1.2", _integerPartFloat.toString());
        // emit log_named_uint("Integer part of 1.2.mantissa", intergerPartFloat.mantissa);
        // emit log_named_int("Integer part of 1.2.exponent", intergerPartFloat.exponent);
        emit log_named_string("Fraction part of 1.2", _fractionPartFloat.toString());
        // emit log_named_uint("Fraction part of 1.2.mantissa", fractionPartFloat.mantissa);
        // emit log_named_int("Fraction part of 1.2.exponent", fractionPartFloat.exponent);

        // float = Float(12, -1).normalize();
        // intergerPartFloat = float.integerPart().normalize();
        // fractionPartFloat = float.minus(intergerPartFloat);
        // emit log_named_string("1.2", toString(float));
        // emit log_named_uint("1.2.mantissa", float.mantissa);
        // emit log_named_int("1.2.exponent", float.exponent);
        // emit log_named_string("Integer part of 1.2", toString(intergerPartFloat));
        // emit log_named_uint("Integer part of 1.2.mantissa", intergerPartFloat.mantissa);
        // emit log_named_int("Integer part of 1.2.exponent", intergerPartFloat.exponent);
        // emit log_named_string("Fraction part of 1.2", toString(fractionPartFloat));
        // emit log_named_uint("Fraction part of 1.2.mantissa", fractionPartFloat.mantissa);
        // emit log_named_int("Fraction part of 1.2.exponent", fractionPartFloat.exponent);

        emit log_named_string("1.15 x 10^-6", FloatLib.from(115, -8).toString());

        emit log("Round number");
        emit log_named_string("1.23456789 x 10^-6", FloatLib.from(123456789, -14).round(5).toString());
        emit log_named_string("-1.23456789 x 10^-6", FloatLib.from(-123456789, -14).round(5).toString());

        Float _bigNumber = FloatLib.normalize(115, 63);
        emit log("Write big number");
        emit log_named_int("bigNumber.mantissa", _bigNumber.mantissa());
        emit log_named_string("1.15 x 10^65", _bigNumber.toString());

        Float _bigNumberPlus = _bigNumber.plus(_bigNumber);
        emit log("Plus big number");
        emit log_named_string("2.30 x 10^65", _bigNumberPlus.toString());

        Float _reallyBigNumber = _bigNumber.times(_bigNumber);
        emit log("Write really big number");
        emit log_named_string("1.3225 x 10^130", _reallyBigNumber.toString());

        Float _smallNumber = FloatLib.normalize(115, -44);
        emit log("Write small number");
        emit log_named_string("1.15 x 10^-42", _smallNumber.toString());

        Float _reallySmallNumber = _smallNumber.times(_smallNumber);
        emit log("Write really small number");
        emit log_named_string("1.3225 x 10^-84", _reallySmallNumber.toString());

        // Float[] memory floats = getFloats();
        // emit log("Half integers");
        // for (uint256 i = 0; i < floats.length; i++) {
        //     emit log_named_string("Float to string", floats[i].toString());
        // }
        // int256 exponent = 19;
        // float = ONE.divide(FloatLib.from(9, exponent));
        // for (uint256 i; i < uint256(2 * int256(exponent)); i++) {
        //     emit log_named_string("Float to string", float.toString());
        //     float = float.times(TEN);
        // }
        // float = FloatLib.from(1, exponent).divide(FloatLib.from(9, 0));
        // for (uint256 i; i < uint256(2 * int256(exponent)); i++) {
        //     emit log_named_string("Float to string", float.toString());
        //     float = float.divide(TEN);
        // }
    }

    function testFloatGasBlank() public pure {}

    function testFloatGasNormalize() public view {
        FloatLib.normalize(ONE_unnormalized);
    }

    function testFloatGasNormalizeNormalized() public view {
        FloatLib.normalize(ONE);
    }

    function testFloatGasAlign() public view {
        FloatLib.align(ONE, TWO_unnormalized);
    }

    function testFloatGasAdd() public view {
        ONE.plus(TWO);
    }

    function testFloatGasSub() public view {
        TWO.minus(ONE);
    }

    function testFloatGasMul() public view {
        ONE.times(TWO);
    }

    function testFloatGasDiv() public view {
        ONE.divide(TWO);
    }

    // function testFloatGasMulDiv() public view {
    //     ONE.mulDiv(TWO, THREE);
    // }

    // function testFloatGasMulDivFull() public view {
    //     ONE.times(TWO).divide(THREE);
    // }

    // function testFloatGasMulDivAdd() public view {
    //     ONE.mulDivAdd(TWO, THREE);
    // }

    // function testFloatGasMulDivAddFull() public view {
    //     ONE.times(THREE).divide(TWO.plus(THREE));
    // }

    // function testFloatMSB() public view {
    //     assertEq(FloatLib.msb(0), 0, "0");
    //     assertEq(FloatLib.msb(1), 1, "1");
    //     assertEq(FloatLib.msb(2), 2, "2");
    //     assertEq(FloatLib.msb(3), 2, "3");
    //     assertEq(FloatLib.msb(4), 3, "4");
    //     assertEq(FloatLib.msb(5), 3, "5");
    //     assertEq(FloatLib.msb(6), 3, "6");
    //     assertEq(FloatLib.msb(7), 3, "7");
    //     assertEq(FloatLib.msb(8), 4, "8");
    //     assertEq(FloatLib.msb(9), 4, "9");
    //     assertEq(FloatLib.msb(10), 4, "10");
    //     assertEq(FloatLib.msb(11), 4, "11");
    //     assertEq(FloatLib.msb(12), 4, "12");
    //     assertEq(FloatLib.msb(13), 4, "13");
    //     assertEq(FloatLib.msb(14), 4, "14");
    //     assertEq(FloatLib.msb(15), 4, "15");
    //     assertEq(FloatLib.msb(16), 5, "16");
    //     assertEq(FloatLib.msb(17), 5, "17");
    //     assertEq(FloatLib.msb(18), 5, "18");
    //     assertEq(FloatLib.msb(19), 5, "19");
    //     assertEq(FloatLib.msb(20), 5, "20");
    //     assertEq(FloatLib.msb(21), 5, "21");
    //     assertEq(FloatLib.msb(22), 5, "22");
    //     assertEq(FloatLib.msb(23), 5, "23");
    //     assertEq(FloatLib.msb(24), 5, "24");
    //     assertEq(FloatLib.msb(25), 5, "25");
    //     assertEq(FloatLib.msb(26), 5, "26");
    //     assertEq(FloatLib.msb(27), 5, "27");
    //     assertEq(FloatLib.msb(28), 5, "28");
    //     assertEq(FloatLib.msb(29), 5, "29");
    //     assertEq(FloatLib.msb(30), 5, "30");
    // }

    function testFloatNormalize() public view {
        assertEq(
            FloatLib.normalize(ONE_unnormalized).mantissa().msb(),
            FloatLib.SIGNIFICANT_DIGITS,
            "mantissa (from unnormalized)"
        );
        assertEq(ONE.mantissa().msb(), FloatLib.SIGNIFICANT_DIGITS, "mantissa (from normalized)");
        assertEq(ONE.exponent(), FloatLib.normalize(ONE_unnormalized).exponent(), "exponent");
    }

    function testFloatAlign() public {
        (a, b) = FloatLib.align(ONE, TWO_unnormalized);
        assertEq(a, ONE);
        assertEq(b, TWO_unnormalized);
        assertEq(a.exponent(), b.exponent(), "exponent");
    }

    function testFloatONE() public {
        a = FloatLib.from(1, 0);
        a = FloatLib.normalize(a);
        assertEq(a.mantissa().msb(), FloatLib.SIGNIFICANT_DIGITS, "msb");
    }

    function testFloatAdd() public {
        Float[] memory _floats = getFloats();
        uint256 _nFloats = _floats.length;
        int256 _floatMax = int256((_nFloats - 1) / 2);
        int256 _iFloat;
        int256 _jFloat;
        for (uint256 _i; _i < _nFloats; _i++) {
            _iFloat = int256(_i) - _floatMax;
            for (uint256 _j; _j < _nFloats; _j++) {
                _jFloat = int256(_j) - _floatMax;
                a = _floats[_i];
                b = _floats[_j];
                c = a.plus(b);
                assertTrue(
                    c.isEQ(FloatLib.from(5 * (_iFloat + _jFloat), -1)),
                    string(abi.encodePacked(a.toString(), "+", b.toString(), "=", c.toString()))
                );
            }
        }
    }

    function testFloatSubtract() public {
        Float[] memory _floats = getFloats();
        uint256 _nFloats = _floats.length;
        int256 _floatMax = int256((_nFloats - 1) / 2);
        int256 _iFloat;
        int256 _jFloat;
        for (uint256 _i; _i < _nFloats; _i++) {
            _iFloat = int256(_i) - _floatMax;
            for (uint256 _j; _j < _nFloats; _j++) {
                _jFloat = int256(_j) - _floatMax;
                a = _floats[_i];
                b = _floats[_j];
                c = a.minus(b);
                assertTrue(
                    c.isEQ(FloatLib.from(5 * (_iFloat - _jFloat), -1)),
                    string(abi.encodePacked(a.toString(), "-", b.toString(), "=", c.toString()))
                );
            }
        }
    }

    function testFloatMultiply() public {
        Float[] memory _floats = getFloats();
        uint256 _nFloats = _floats.length;
        int256 _floatMax = int256((_nFloats - 1) / 2);
        int256 _iFloat;
        int256 _jFloat;
        for (uint256 _i; _i < _nFloats; _i++) {
            _iFloat = int256(_i) - _floatMax;
            for (uint256 _j; _j < _nFloats; _j++) {
                _jFloat = int256(_j) - _floatMax;
                a = _floats[_i];
                b = _floats[_j];
                c = a.times(b);
                assertTrue(
                    c.isEQ(FloatLib.from(25 * (_iFloat * _jFloat), -2)),
                    string(abi.encodePacked(a.toString(), "*", b.toString(), "=", c.toString()))
                );
            }
        }
    }

    function testFloatDivide() public {
        Float[] memory _floats = getFloats();
        uint256 _nFloats = _floats.length;
        int256 _floatMax = int256((_nFloats - 1) / 2);
        int256 _iFloat;
        int256 _jFloat;
        for (uint256 _i; _i < _nFloats; _i++) {
            _iFloat = int256(_i) - _floatMax;
            for (uint256 _j; _j < _nFloats; _j++) {
                _jFloat = int256(_j) - _floatMax;
                a = _floats[_i];
                b = _floats[_j];
                if (b.isEQ(ZERO)) {
                    continue;
                }
                c = a.divide(b).times(b);
                assertTrue(
                    c.round(10).isEQ(FloatLib.from(5 * _iFloat, -1)),
                    string(abi.encodePacked(a.toString(), "=", c.toString()))
                );
            }
        }
    }

    function testFloatExp() public {
        emit log("testExp");

        // emit log_named_string("exp(200)", FloatLib.exp(int256(200e18)).toString());
        // emit log_named_string("exp(0)", FloatLib.exp(int256(0)).toString());
        // emit log_named_string("exp(-200)", FloatLib.exp(int256(-200e18)).toString());

        // emit log_named_string("exp(1e3)", FloatLib.exp(int256(1e21)).toString());
        // emit log_named_string("exp(1e4)", FloatLib.exp(int256(1e22)).toString());
        // emit log_named_string("exp(1e5)", FloatLib.exp(int256(1e23)).toString());
        emit log_named_string("exp(1e6)", FloatLib.exp(int256(1e24)).toString());
        emit log_named_string("exp(1e-18)", FloatLib.exp(int256(1)).toString());
        emit log_named_string("exp(1e-17)", FloatLib.exp(int256(1e1)).toString());
        emit log_named_string("exp(1e-16)", FloatLib.exp(int256(1e2)).toString());
        emit log_named_string("exp(1e-15)", FloatLib.exp(int256(1e3)).toString());
        emit log_named_string("exp(1e-5)", FloatLib.exp(int256(1e13)).toString());
        emit log_named_string("exp(-1e6)", FloatLib.exp(int256(-1e24)).toString());

        emit log_named_string("exp(log(4e18)/2)", FloatLib.exp(FloatLib.log(FloatLib.from(4, 0)) / 2).toString());
        // emit log_named_int("exp(1e6)", FloatLib.exp(int256(1e24)).mantissa);
        // emit log_named_int("exp(-1e6)", FloatLib.exp(int256(-1e24)).mantissa);
        // emit log_named_string("exp(1e7)", FloatLib.exp(int256(1e25)).toString());
        // emit log_named_string("exp(1e8)", FloatLib.exp(int256(1e26)).toString());
        // emit log_named_string("exp(1e9)", FloatLib.exp(int256(1e27)).toString());
        // emit log_named_string("exp(1e10)", FloatLib.exp(int256(1e28)).toString());
        // emit log_named_string("exp(1e11)", FloatLib.exp(int256(1e29)).toString());
    }

    function testFloatCubic() public {
        Float x = FloatLib.cubicsolve(FloatLib.from(-5, 0), FloatLib.from(1, 0), FloatLib.from(-5, 0));
        emit log_named_string("x", x.toString());
    }

    // function testFloatMulDiv() public {
    //     Float[] memory floats = getFloats();
    //     for (uint256 i; i < floats.length; i++) {
    //         for (uint256 j; j < floats.length; j++) {
    //             for (uint256 k = 1; k < floats.length; k++) {
    //                 a = floats[i];
    //                 b = floats[j];
    //                 c = floats[k];
    //                 assertEq(
    //                     FloatLib.mulDiv(a, b, c),
    //                     a.times(b).divide(c),
    //                     "muDiv(a,b,c)!=(a*b)/c"
    //                 );
    //             }
    //         }
    //     }
    // }

    // function testFloatMulDivAdd() public {
    //     Float[] memory floats = getFloats();
    //     for (uint256 i; i < floats.length; i++) {
    //         for (uint256 j; j < floats.length; j++) {
    //             for (uint256 k = 1; k < floats.length; k++) {
    //                 a = floats[i];
    //                 b = floats[j];
    //                 c = floats[k];
    //                 assertEq(
    //                     FloatLib.mulDivAdd(a, b, c),
    //                     a.times(c).divide(b.plus(c)),
    //                     "muDivAdd(a,b,c)!=(a*b)/(c+b)"
    //                 );
    //             }
    //         }
    //     }
    // }

    // function testFloatEncode() public {
    //     uint256 x = FloatLib.encode(1, 1);
    //     uint256 m;
    //     uint256 e;
    //     (m, e) = FloatLib.decode(x);
    //     assertEq(
    //         x,
    //         0x0000000000000000000000000000000000000000000000000000000000000081,
    //         "encode"
    //     );
    //     assertEq(m, 1, "mantissa");
    //     assertEq(e, 1, "exponent");
    // }

    // uint256 private protocolFee = 5e17;
    // address private feeRecipient = vm.envAddress("FEE_RECIPIENT");
    // uint256 private tokensPerShare = 1e18;
    // uint256 private tau = 1e16;

    // TestPool private pool;

    // function setUp() public {
    //     pool = new TestPool(
    //         "Pool",
    //         "P",
    //         protocolFee,
    //         feeRecipient,
    //         tokensPerShare,
    //         tau
    //     );
    // }

    // function testFloatSquareRoot() public {
    //     uint256 x = 16e18;
    //     uint256 y = x.sqrt();
    //     assertEq(y, 4e9, "sqrt(16e18) = 4e9");
    //     assertApproxEqRel(
    //         uint256(int256(x).powWad(int256(HALF))),
    //         4e18,
    //         1e6,
    //         "16e18^(1/2) = 4e18"
    //     );
    // }

    // function testFloatGeometricMeanFuzz(uint256 amount) public {
    //     vm.assume(amount > 0 && amount < 1000000000000000 * ONE);

    //     assertEq(pool.geometricMean(0, 0, amount, 0), amount, "delta = 0");

    //     assertEq(
    //         pool.geometricMean(amount, amount, amount, 1),
    //         amount,
    //         "delta = 1"
    //     );
    // }

    // function testFloatGeometricMeanVerbose() public {
    //     uint256 lastMean = 12345678 * ONE;
    //     uint256 lastValue = 2 * lastMean;
    //     uint256 newValue = 2 * lastValue;

    //     emit log_named_uint("lastMean", lastMean);
    //     emit log_named_uint("lastValue", lastValue);
    //     emit log_named_uint("newValue", newValue);
    //     emit log_named_uint("tau", tau);
    //     emit log_named_uint(
    //         "mean (delta=0)",
    //         pool.geometricMean(newValue, lastValue, lastMean, 0)
    //     );
    //     emit log_named_uint(
    //         "mean (delta=1)",
    //         pool.geometricMean(newValue, lastValue, lastMean, 1)
    //     );
    //     emit log_named_uint(
    //         "mean (delta=10)",
    //         pool.geometricMean(newValue, lastValue, lastMean, 10)
    //     );
    // }
}
