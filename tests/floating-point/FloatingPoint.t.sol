// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

// import {Pool, FixedPointMathLib} from "../contracts/Pool.sol";
import {FloatingPoint, UFloat} from "../../libraries/FloatingPoint.sol";
import {FloatingPointStrings} from "../../libraries/FloatingPointStrings.sol";
import {Test} from "forge-std/src/Test.sol";

contract FloatingPointTest is Test {
    using FloatingPoint for uint256;
    using FloatingPoint for int256;
    using FloatingPoint for UFloat;
    using FloatingPointStrings for uint256;
    using FloatingPointStrings for int256;
    using FloatingPointStrings for UFloat;

    UFloat internal ZERO;
    UFloat internal HALF;
    UFloat internal ONE;
    UFloat internal TWO;
    UFloat internal THREE;
    UFloat internal FOUR;
    UFloat internal FIVE;
    UFloat internal SIX;
    UFloat internal SEVEN;
    UFloat internal EIGHT;
    UFloat internal NINE;
    UFloat internal TEN;

    UFloat internal ONEnHALF;
    UFloat internal TWOnHALF;
    UFloat internal THREEnHALF;
    UFloat internal FOURnHALF;
    UFloat internal FIVEnHALF;
    UFloat internal SIXnHALF;
    UFloat internal SEVENnHALF;
    UFloat internal EIGHTnHALF;
    UFloat internal NINEnHALF;

    UFloat internal a;
    UFloat internal b;
    UFloat internal c;

    UFloat internal ZERO_unnormalized;
    UFloat internal HALF_unnormalized;
    UFloat internal ONE_unnormalized;
    UFloat internal TWO_unnormalized;

    uint256 internal mantissaZERO;
    int256 internal exponentZERO;
    uint256 internal mantissaHALF;
    int256 internal exponentHALF;
    uint256 internal mantissaONE;
    int256 internal exponentONE;
    uint256 internal mantissaTWO;
    int256 internal exponentTWO;

    uint256 internal mantissaZERO_unnormalized;
    int256 internal exponentZERO_unnormalized;
    uint256 internal mantissaHALF_unnormalized;
    int256 internal exponentHALF_unnormalized;
    uint256 internal mantissaONE_unnormalized;
    int256 internal exponentONE_unnormalized;
    uint256 internal mantissaTWO_unnormalized;
    int256 internal exponentTWO_unnormalized;

    function assertEq(
        UFloat memory x,
        UFloat memory y,
        string memory message
    ) internal {
        failed = failed;
        x = x.normalize();
        y = y.normalize();
        assertEq(x.mantissa, y.mantissa, "mantissa");
        assertEq(x.exponent, y.exponent, "exponent");
        if (failed) emit log(message);
    }

    function setUp() public {
        ZERO = FloatingPoint.normalize(UFloat(0, 0));
        ONE = FloatingPoint.normalize(UFloat(1, 0));
        TWO = FloatingPoint.normalize(UFloat(2, 0));
        THREE = FloatingPoint.normalize(UFloat(3, 0));
        FOUR = FloatingPoint.normalize(UFloat(4, 0));
        FIVE = FloatingPoint.normalize(UFloat(5, 0));
        SIX = FloatingPoint.normalize(UFloat(6, 0));
        SEVEN = FloatingPoint.normalize(UFloat(7, 0));
        EIGHT = FloatingPoint.normalize(UFloat(8, 0));
        NINE = FloatingPoint.normalize(UFloat(9, 0));
        TEN = FloatingPoint.normalize(UFloat(10, 0));

        HALF = FloatingPoint.normalize(UFloat(5, -1));
        ONEnHALF = FloatingPoint.normalize(UFloat(15, -1));
        TWOnHALF = FloatingPoint.normalize(UFloat(25, -1));
        THREEnHALF = FloatingPoint.normalize(UFloat(35, -1));
        FOURnHALF = FloatingPoint.normalize(UFloat(45, -1));
        FIVEnHALF = FloatingPoint.normalize(UFloat(55, -1));
        SIXnHALF = FloatingPoint.normalize(UFloat(65, -1));
        SEVENnHALF = FloatingPoint.normalize(UFloat(75, -1));
        EIGHTnHALF = FloatingPoint.normalize(UFloat(85, -1));
        NINEnHALF = FloatingPoint.normalize(UFloat(95, -1));

        ZERO_unnormalized = UFloat(0, 0);
        HALF_unnormalized = UFloat(1, -1);
        ONE_unnormalized = UFloat(1, 0);
        TWO_unnormalized = UFloat(2, 0);

        mantissaZERO = ZERO.mantissa;
        exponentZERO = ZERO.exponent;
        mantissaHALF = HALF.mantissa;
        exponentHALF = HALF.exponent;
        mantissaONE = ONE.mantissa;
        exponentONE = ONE.exponent;
        mantissaTWO = TWO.mantissa;
        exponentTWO = TWO.exponent;

        mantissaZERO_unnormalized = ZERO_unnormalized.mantissa;
        exponentZERO_unnormalized = ZERO_unnormalized.exponent;
        mantissaHALF_unnormalized = HALF_unnormalized.mantissa;
        exponentHALF_unnormalized = HALF_unnormalized.exponent;
        mantissaONE_unnormalized = ONE_unnormalized.mantissa;
        exponentONE_unnormalized = ONE_unnormalized.exponent;
        mantissaTWO_unnormalized = TWO_unnormalized.mantissa;
        exponentTWO_unnormalized = TWO_unnormalized.exponent;
    }

    function getFloats() public view returns (UFloat[] memory) {
        UFloat[] memory floats = new UFloat[](21);
        floats[0] = ZERO;
        floats[1] = HALF;
        floats[2] = ONE;
        floats[3] = ONEnHALF;
        floats[4] = TWO;
        floats[5] = TWOnHALF;
        floats[6] = THREE;
        floats[7] = THREEnHALF;
        floats[8] = FOUR;
        floats[9] = FOURnHALF;
        floats[10] = FIVE;
        floats[11] = FIVEnHALF;
        floats[12] = SIX;
        floats[13] = SIXnHALF;
        floats[14] = SEVEN;
        floats[15] = SEVENnHALF;
        floats[16] = EIGHT;
        floats[17] = EIGHTnHALF;
        floats[18] = NINE;
        floats[19] = NINEnHALF;
        floats[20] = TEN;
        return floats;
    }

    function testToString() public {
        UFloat memory float;
        UFloat memory intergerPartFloat;
        UFloat memory fractionPartFloat;
        float = UFloat(12, -1);
        intergerPartFloat = float.integerPart();
        fractionPartFloat = float.minus(intergerPartFloat);
        emit log_named_string("1.2", float.toString());
        // emit log_named_uint("1.2.mantissa", float.mantissa);
        // emit log_named_int("1.2.exponent", float.exponent);
        emit log_named_string(
            "Integer part of 1.2",
            intergerPartFloat.toString()
        );
        // emit log_named_uint("Integer part of 1.2.mantissa", intergerPartFloat.mantissa);
        // emit log_named_int("Integer part of 1.2.exponent", intergerPartFloat.exponent);
        emit log_named_string(
            "Fraction part of 1.2",
            fractionPartFloat.toString()
        );
        // emit log_named_uint("Fraction part of 1.2.mantissa", fractionPartFloat.mantissa);
        // emit log_named_int("Fraction part of 1.2.exponent", fractionPartFloat.exponent);

        // float = UFloat(12, -1).normalize();
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

        emit log_named_string("1.15 x 10^-6", UFloat(115, -8).toString());

        UFloat memory bigNumber = UFloat(115, 998).normalize();
        emit log("Write big number");
        emit log_named_uint("bigNumber.mantissa", bigNumber.mantissa);
        emit log_named_string("1.15 x 10^1000", bigNumber.toString());

        UFloat memory bigNumberPlus = bigNumber.plus(bigNumber);
        emit log("Plus big number");
        emit log_named_string("2.30 x 10^1000", bigNumberPlus.toString());

        UFloat memory reallyBigNumber = bigNumber.times(bigNumber);
        emit log("Write really big number");
        emit log_named_string("1.3225 x 10^2000", reallyBigNumber.toString());

        UFloat memory smallNumber = UFloat(115, -1002).normalize();
        emit log("Write small number");
        emit log_named_string("1.15 x 10^-1000", smallNumber.toString());

        UFloat memory reallySmallNumber = smallNumber.times(smallNumber);
        emit log("Write really small number");
        emit log_named_string("1.3225 x 10^-2000", reallySmallNumber.toString());

        UFloat[] memory floats = getFloats();
        emit log("Half integers");
        for (uint256 i = 0; i < floats.length; i++) {
            emit log_named_string("UFloat to string", floats[i].toString());
        }
        int256 exponent = 19;
        float = ONE.divide(UFloat(9, exponent)).normalize();
        for (uint256 i = 0; i < uint256(2 * exponent); i++) {
            emit log_named_string("UFloat to string", float.toString());
            float = float.times(TEN);
        }
        float = UFloat(1, exponent).divide(UFloat(9, 0)).normalize();
        for (uint256 i = 0; i < uint256(2 * exponent); i++) {
            emit log_named_string("UFloat to string", float.toString());
            float = float.divide(TEN);
        }
    }

    function testGasBlank() public pure {}

    function testGasNormalize() public view {
        FloatingPoint.normalize(ONE_unnormalized);
    }

    function testGasNormalizeNormalized() public view {
        FloatingPoint.normalize(ONE);
    }

    function testGasAlign() public view {
        FloatingPoint.align(ONE, TWO_unnormalized);
    }

    function testGasAdd() public view {
        ONE.plus(TWO);
    }

    function testGasSub() public view {
        TWO.minus(ONE);
    }

    function testGasMul() public view {
        ONE.times(TWO);
    }

    function testGasDiv() public view {
        ONE.divide(TWO);
    }

    // function testGasMulDiv() public view {
    //     ONE.mulDiv(TWO, THREE);
    // }

    // function testGasMulDivFull() public view {
    //     ONE.times(TWO).divide(THREE);
    // }

    // function testGasMulDivAdd() public view {
    //     ONE.mulDivAdd(TWO, THREE);
    // }

    // function testGasMulDivAddFull() public view {
    //     ONE.times(THREE).divide(TWO.plus(THREE));
    // }

    // function testMSB() public view {
    //     assertEq(FloatingPoint.msb(0), 0, "0");
    //     assertEq(FloatingPoint.msb(1), 1, "1");
    //     assertEq(FloatingPoint.msb(2), 2, "2");
    //     assertEq(FloatingPoint.msb(3), 2, "3");
    //     assertEq(FloatingPoint.msb(4), 3, "4");
    //     assertEq(FloatingPoint.msb(5), 3, "5");
    //     assertEq(FloatingPoint.msb(6), 3, "6");
    //     assertEq(FloatingPoint.msb(7), 3, "7");
    //     assertEq(FloatingPoint.msb(8), 4, "8");
    //     assertEq(FloatingPoint.msb(9), 4, "9");
    //     assertEq(FloatingPoint.msb(10), 4, "10");
    //     assertEq(FloatingPoint.msb(11), 4, "11");
    //     assertEq(FloatingPoint.msb(12), 4, "12");
    //     assertEq(FloatingPoint.msb(13), 4, "13");
    //     assertEq(FloatingPoint.msb(14), 4, "14");
    //     assertEq(FloatingPoint.msb(15), 4, "15");
    //     assertEq(FloatingPoint.msb(16), 5, "16");
    //     assertEq(FloatingPoint.msb(17), 5, "17");
    //     assertEq(FloatingPoint.msb(18), 5, "18");
    //     assertEq(FloatingPoint.msb(19), 5, "19");
    //     assertEq(FloatingPoint.msb(20), 5, "20");
    //     assertEq(FloatingPoint.msb(21), 5, "21");
    //     assertEq(FloatingPoint.msb(22), 5, "22");
    //     assertEq(FloatingPoint.msb(23), 5, "23");
    //     assertEq(FloatingPoint.msb(24), 5, "24");
    //     assertEq(FloatingPoint.msb(25), 5, "25");
    //     assertEq(FloatingPoint.msb(26), 5, "26");
    //     assertEq(FloatingPoint.msb(27), 5, "27");
    //     assertEq(FloatingPoint.msb(28), 5, "28");
    //     assertEq(FloatingPoint.msb(29), 5, "29");
    //     assertEq(FloatingPoint.msb(30), 5, "30");
    // }

    function testNormalize() public {
        assertEq(
            ONE_unnormalized.normalize().mantissa.msb(),
            FloatingPoint.SIGNIFICANT_DIGITS,
            "mantissa (from unnormalized)"
        );
        assertEq(
            ONE.mantissa.msb(),
            FloatingPoint.SIGNIFICANT_DIGITS,
            "mantissa (from normalized)"
        );
        assertEq(
            ONE.exponent,
            ONE_unnormalized.normalize().exponent,
            "exponent"
        );
    }

    function testAlign() public {
        (a, b) = FloatingPoint.align(ONE, TWO_unnormalized);
        assertEq(a, ONE, "a!=ONE");
        assertEq(b, TWO_unnormalized, "b!=TWO_unnormalized");
        assertEq(a.exponent, b.exponent, "exponent");
    }

    function testONE() public {
        a = UFloat(1, 0);
        a = FloatingPoint.normalize(a);
        assertEq(a.mantissa.msb(), 18, "msb");
        if (failed) {
            emit log_named_uint("ONE.mantissa", a.mantissa);
            emit log_named_int("ONE.exponent", a.exponent);
        }
    }

    function testAdd() public {
        assertEq(ZERO.plus(ZERO), ZERO, "0+0!=0");
        assertEq(ZERO.plus(HALF), HALF, "0+0.5!=0.5");
        assertEq(ZERO.plus(ONE), ONE, "0+1!=1");
        assertEq(ZERO.plus(ONEnHALF), ONEnHALF, "0+1.5!=1.5");
        assertEq(ZERO.plus(TWO), TWO, "0+2!=2");
        assertEq(ZERO.plus(TWOnHALF), TWOnHALF, "0+2.5!=2.5");
        assertEq(ZERO.plus(THREE), THREE, "0+3!=3");
        assertEq(ZERO.plus(THREEnHALF), THREEnHALF, "0+3.5!=3.5");
        assertEq(ZERO.plus(FOUR), FOUR, "0+4!=4");
        assertEq(ZERO.plus(FOURnHALF), FOURnHALF, "0+4.5!=4.5");
        assertEq(ZERO.plus(FIVE), FIVE, "0+5!=5");
        assertEq(ZERO.plus(FIVEnHALF), FIVEnHALF, "0+5.5!=5.5");
        assertEq(ZERO.plus(SIX), SIX, "0+6!=6");
        assertEq(ZERO.plus(SIXnHALF), SIXnHALF, "0+6.5!=6.5");
        assertEq(ZERO.plus(SEVEN), SEVEN, "0+7!=7");
        assertEq(ZERO.plus(SEVENnHALF), SEVENnHALF, "0+7.5!=7.5");
        assertEq(ZERO.plus(EIGHT), EIGHT, "0+8!=8");
        assertEq(ZERO.plus(EIGHTnHALF), EIGHTnHALF, "0+8.5!=8.5");
        assertEq(ZERO.plus(NINE), NINE, "0+9!=9");
        assertEq(ZERO.plus(NINEnHALF), NINEnHALF, "0+9.5!=9.5");
        assertEq(ZERO.plus(TEN), TEN, "0+10!=10");

        assertEq(HALF.plus(ZERO), HALF, "0.5+0!=0.5");
        assertEq(HALF.plus(HALF), ONE, "0.5+0.5!=1");
        assertEq(HALF.plus(ONE), ONEnHALF, "0.5+1!=1.5");
        assertEq(HALF.plus(ONEnHALF), TWO, "0.5+1.5!=2");
        assertEq(HALF.plus(TWO), TWOnHALF, "0.5+2!=2.5");
        assertEq(HALF.plus(TWOnHALF), THREE, "0.5+2.5!=3");
        assertEq(HALF.plus(THREE), THREEnHALF, "0.5+3!=3.5");
        assertEq(HALF.plus(THREEnHALF), FOUR, "0.5+3.5!=4");
        assertEq(HALF.plus(FOUR), FOURnHALF, "0.5+4!=4.5");
        assertEq(HALF.plus(FOURnHALF), FIVE, "0.5+4.5!=5");
        assertEq(HALF.plus(FIVE), FIVEnHALF, "0.5+5!=5.5");
        assertEq(HALF.plus(FIVEnHALF), SIX, "0.5+5.5!=6");
        assertEq(HALF.plus(SIX), SIXnHALF, "0.5+6!=6.5");
        assertEq(HALF.plus(SIXnHALF), SEVEN, "0.5+6.5!=7");
        assertEq(HALF.plus(SEVEN), SEVENnHALF, "0.5+7!=7.5");
        assertEq(HALF.plus(SEVENnHALF), EIGHT, "0.5+7.5!=8");
        assertEq(HALF.plus(EIGHT), EIGHTnHALF, "0.5+8!=8.5");
        assertEq(HALF.plus(EIGHTnHALF), NINE, "0.5+8.5!=9");
        assertEq(HALF.plus(NINE), NINEnHALF, "0.5+9!=9.5");
        assertEq(HALF.plus(NINEnHALF), TEN, "0.5+9.5!=10");

        assertEq(ONE.plus(ZERO), ONE, "1+0!=1");
        assertEq(ONE.plus(HALF), ONEnHALF, "1+0.5!=1.5");
        assertEq(ONE.plus(ONE), TWO, "1+1!=2");
        assertEq(ONE.plus(ONEnHALF), TWOnHALF, "1+1.5!=2.5");
        assertEq(ONE.plus(TWO), THREE, "1+2!=3");
        assertEq(ONE.plus(TWOnHALF), THREEnHALF, "1+2.5!=3.5");
        assertEq(ONE.plus(THREE), FOUR, "1+3!=4");
        assertEq(ONE.plus(THREEnHALF), FOURnHALF, "1+3.5!=4.5");
        assertEq(ONE.plus(FOUR), FIVE, "1+4!=5");
        assertEq(ONE.plus(FOURnHALF), FIVEnHALF, "1+4.5!=5.5");
        assertEq(ONE.plus(FIVE), SIX, "1+5!=6");
        assertEq(ONE.plus(FIVEnHALF), SIXnHALF, "1+5.5!=6.5");
        assertEq(ONE.plus(SIX), SEVEN, "1+6!=7");
        assertEq(ONE.plus(SIXnHALF), SEVENnHALF, "1+6.5!=7.5");
        assertEq(ONE.plus(SEVEN), EIGHT, "1+7!=8");
        assertEq(ONE.plus(SEVENnHALF), EIGHTnHALF, "1+7.5!=8.5");
        assertEq(ONE.plus(EIGHT), NINE, "1+8!=9");
        assertEq(ONE.plus(EIGHTnHALF), NINEnHALF, "1+8.5!=9.5");
        assertEq(ONE.plus(NINE), TEN, "1+9!=10");

        assertEq(ONEnHALF.plus(ZERO), ONEnHALF, "1.5+0!=1.5");
        assertEq(ONEnHALF.plus(HALF), TWO, "1.5+0.5!=2");
        assertEq(ONEnHALF.plus(ONE), TWOnHALF, "1.5+1!=2.5");
        assertEq(ONEnHALF.plus(ONEnHALF), THREE, "1.5+1.5!=3");
        assertEq(ONEnHALF.plus(TWO), THREEnHALF, "1.5+2!=3.5");
        assertEq(ONEnHALF.plus(TWOnHALF), FOUR, "1.5+2.5!=4");
        assertEq(ONEnHALF.plus(THREE), FOURnHALF, "1.5+3!=4.5");
        assertEq(ONEnHALF.plus(THREEnHALF), FIVE, "1.5+3.5!=5");
        assertEq(ONEnHALF.plus(FOUR), FIVEnHALF, "1.5+4!=5.5");
        assertEq(ONEnHALF.plus(FOURnHALF), SIX, "1.5+4.5!=6");
        assertEq(ONEnHALF.plus(FIVE), SIXnHALF, "1.5+5!=6.5");
        assertEq(ONEnHALF.plus(FIVEnHALF), SEVEN, "1.5+5.5!=7");
        assertEq(ONEnHALF.plus(SIX), SEVENnHALF, "1.5+6!=7.5");
        assertEq(ONEnHALF.plus(SIXnHALF), EIGHT, "1.5+6.5!=8");
        assertEq(ONEnHALF.plus(SEVEN), EIGHTnHALF, "1.5+7!=8.5");
        assertEq(ONEnHALF.plus(SEVENnHALF), NINE, "1.5+7.5!=9");
        assertEq(ONEnHALF.plus(EIGHT), NINEnHALF, "1.5+8!=9.5");
        assertEq(ONEnHALF.plus(EIGHTnHALF), TEN, "1.5+8.5!=10");

        assertEq(TWO.plus(ZERO), TWO, "2+0!=2");
        assertEq(TWO.plus(HALF), TWOnHALF, "2+0.5!=2.5");
        assertEq(TWO.plus(ONE), THREE, "2+1!=3");
        assertEq(TWO.plus(ONEnHALF), THREEnHALF, "2+1.5!=3.5");
        assertEq(TWO.plus(TWO), FOUR, "2+2!=4");
        assertEq(TWO.plus(TWOnHALF), FOURnHALF, "2+2.5!=4.5");
        assertEq(TWO.plus(THREE), FIVE, "2+3!=5");
        assertEq(TWO.plus(THREEnHALF), FIVEnHALF, "2+3.5!=5.5");
        assertEq(TWO.plus(FOUR), SIX, "2+4!=6");
        assertEq(TWO.plus(FOURnHALF), SIXnHALF, "2+4.5!=6.5");
        assertEq(TWO.plus(FIVE), SEVEN, "2+5!=7");
        assertEq(TWO.plus(FIVEnHALF), SEVENnHALF, "2+5.5!=7.5");
        assertEq(TWO.plus(SIX), EIGHT, "2+6!=8");
        assertEq(TWO.plus(SIXnHALF), EIGHTnHALF, "2+6.5!=8.5");
        assertEq(TWO.plus(SEVEN), NINE, "2+7!=9");
        assertEq(TWO.plus(SEVENnHALF), NINEnHALF, "2+7.5!=9.5");
        assertEq(TWO.plus(EIGHT), TEN, "2+8!=10");

        assertEq(TWOnHALF.plus(ZERO), TWOnHALF, "2.5+0!=2.5");
        assertEq(TWOnHALF.plus(HALF), THREE, "2.5+0.5!=3");
        assertEq(TWOnHALF.plus(ONE), THREEnHALF, "2.5+1!=3.5");
        assertEq(TWOnHALF.plus(ONEnHALF), FOUR, "2.5+1.5!=4");
        assertEq(TWOnHALF.plus(TWO), FOURnHALF, "2.5+2!=4.5");
        assertEq(TWOnHALF.plus(TWOnHALF), FIVE, "2.5+2.5!=5");
        assertEq(TWOnHALF.plus(THREE), FIVEnHALF, "2.5+3!=5.5");
        assertEq(TWOnHALF.plus(THREEnHALF), SIX, "2.5+3.5!=6");
        assertEq(TWOnHALF.plus(FOUR), SIXnHALF, "2.5+4!=6.5");
        assertEq(TWOnHALF.plus(FOURnHALF), SEVEN, "2.5+4.5!=7");
        assertEq(TWOnHALF.plus(FIVE), SEVENnHALF, "2.5+5!=7.5");
        assertEq(TWOnHALF.plus(FIVEnHALF), EIGHT, "2.5+5.5!=8");
        assertEq(TWOnHALF.plus(SIX), EIGHTnHALF, "2.5+6!=8.5");
        assertEq(TWOnHALF.plus(SIXnHALF), NINE, "2.5+6.5!=9");
        assertEq(TWOnHALF.plus(SEVEN), NINEnHALF, "2.5+7!=9.5");
        assertEq(TWOnHALF.plus(SEVENnHALF), TEN, "2.5+7.5!=10");

        assertEq(THREE.plus(ZERO), THREE, "3+0!=3");
        assertEq(THREE.plus(HALF), THREEnHALF, "3+0.5!=3.5");
        assertEq(THREE.plus(ONE), FOUR, "3+1!=4");
        assertEq(THREE.plus(ONEnHALF), FOURnHALF, "3+1.5!=4.5");
        assertEq(THREE.plus(TWO), FIVE, "3+2!=5");
        assertEq(THREE.plus(TWOnHALF), FIVEnHALF, "3+2.5!=5.5");
        assertEq(THREE.plus(THREE), SIX, "3+3!=6");
        assertEq(THREE.plus(THREEnHALF), SIXnHALF, "3+3.5!=6.5");
        assertEq(THREE.plus(FOUR), SEVEN, "3+4!=7");
        assertEq(THREE.plus(FOURnHALF), SEVENnHALF, "3+4.5!=7.5");
        assertEq(THREE.plus(FIVE), EIGHT, "3+5!=8");
        assertEq(THREE.plus(FIVEnHALF), EIGHTnHALF, "3+5.5!=8.5");
        assertEq(THREE.plus(SIX), NINE, "3+6!=9");
        assertEq(THREE.plus(SIXnHALF), NINEnHALF, "3+6.5!=9.5");
        assertEq(THREE.plus(SEVEN), TEN, "3+7!=10");

        assertEq(THREEnHALF.plus(ZERO), THREEnHALF, "3.5+0!=3.5");
        assertEq(THREEnHALF.plus(HALF), FOUR, "3.5+0.5!=4");
        assertEq(THREEnHALF.plus(ONE), FOURnHALF, "3.5+1!=4.5");
        assertEq(THREEnHALF.plus(ONEnHALF), FIVE, "3.5+1.5!=5");
        assertEq(THREEnHALF.plus(TWO), FIVEnHALF, "3.5+2!=5.5");
        assertEq(THREEnHALF.plus(TWOnHALF), SIX, "3.5+2.5!=6");
        assertEq(THREEnHALF.plus(THREE), SIXnHALF, "3.5+3!=6.5");
        assertEq(THREEnHALF.plus(THREEnHALF), SEVEN, "3.5+3.5!=7");
        assertEq(THREEnHALF.plus(FOUR), SEVENnHALF, "3.5+4!=7.5");
        assertEq(THREEnHALF.plus(FOURnHALF), EIGHT, "3.5+4.5!=8");
        assertEq(THREEnHALF.plus(FIVE), EIGHTnHALF, "3.5+5!=8.5");
        assertEq(THREEnHALF.plus(FIVEnHALF), NINE, "3.5+5.5!=9");
        assertEq(THREEnHALF.plus(SIX), NINEnHALF, "3.5+6!=9.5");
        assertEq(THREEnHALF.plus(SIXnHALF), TEN, "3.5+6.5!=10");

        assertEq(FOUR.plus(ZERO), FOUR, "4+0!=4");
        assertEq(FOUR.plus(HALF), FOURnHALF, "4+0.5!=4.5");
        assertEq(FOUR.plus(ONE), FIVE, "4+1!=5");
        assertEq(FOUR.plus(ONEnHALF), FIVEnHALF, "4+1.5!=5.5");
        assertEq(FOUR.plus(TWO), SIX, "4+2!=6");
        assertEq(FOUR.plus(TWOnHALF), SIXnHALF, "4+2.5!=6.5");
        assertEq(FOUR.plus(THREE), SEVEN, "4+3!=7");
        assertEq(FOUR.plus(THREEnHALF), SEVENnHALF, "4+3.5!=7.5");
        assertEq(FOUR.plus(FOUR), EIGHT, "4+4!=8");
        assertEq(FOUR.plus(FOURnHALF), EIGHTnHALF, "4+4.5!=8.5");
        assertEq(FOUR.plus(FIVE), NINE, "4+5!=9");
        assertEq(FOUR.plus(FIVEnHALF), NINEnHALF, "4+5.5!=9.5");
        assertEq(FOUR.plus(SIX), TEN, "4+6!=10");

        assertEq(FOURnHALF.plus(ZERO), FOURnHALF, "4.5+0!=4.5");
        assertEq(FOURnHALF.plus(HALF), FIVE, "4.5+0.5!=5");
        assertEq(FOURnHALF.plus(ONE), FIVEnHALF, "4.5+1!=5.5");
        assertEq(FOURnHALF.plus(ONEnHALF), SIX, "4.5+1.5!=6");
        assertEq(FOURnHALF.plus(TWO), SIXnHALF, "4.5+2!=6.5");
        assertEq(FOURnHALF.plus(TWOnHALF), SEVEN, "4.5+2.5!=7");
        assertEq(FOURnHALF.plus(THREE), SEVENnHALF, "4.5+3!=7.5");
        assertEq(FOURnHALF.plus(THREEnHALF), EIGHT, "4.5+3.5!=8");
        assertEq(FOURnHALF.plus(FOUR), EIGHTnHALF, "4.5+4!=8.5");
        assertEq(FOURnHALF.plus(FOURnHALF), NINE, "4.5+4.5!=9");
        assertEq(FOURnHALF.plus(FIVE), NINEnHALF, "4.5+5!=9.5");
        assertEq(FOURnHALF.plus(FIVEnHALF), TEN, "4.5+5.5!=10");

        assertEq(FIVE.plus(ZERO), FIVE, "5+0!=5");
        assertEq(FIVE.plus(HALF), FIVEnHALF, "5+0.5!=5.5");
        assertEq(FIVE.plus(ONE), SIX, "5+1!=6");
        assertEq(FIVE.plus(ONEnHALF), SIXnHALF, "5+1.5!=6.5");
        assertEq(FIVE.plus(TWO), SEVEN, "5+2!=7");
        assertEq(FIVE.plus(TWOnHALF), SEVENnHALF, "5+2.5!=7.5");
        assertEq(FIVE.plus(THREE), EIGHT, "5+3!=8");
        assertEq(FIVE.plus(THREEnHALF), EIGHTnHALF, "5+3.5!=8.5");
        assertEq(FIVE.plus(FOUR), NINE, "5+4!=9");
        assertEq(FIVE.plus(FOURnHALF), NINEnHALF, "5+4.5!=9.5");
        assertEq(FIVE.plus(FIVE), TEN, "5+5!=10");

        assertEq(FIVEnHALF.plus(ZERO), FIVEnHALF, "5.5+0!=5.5");
        assertEq(FIVEnHALF.plus(HALF), SIX, "5.5+0.5!=6");
        assertEq(FIVEnHALF.plus(ONE), SIXnHALF, "5.5+1!=6.5");
        assertEq(FIVEnHALF.plus(ONEnHALF), SEVEN, "5.5+1.5!=7");
        assertEq(FIVEnHALF.plus(TWO), SEVENnHALF, "5.5+2!=7.5");
        assertEq(FIVEnHALF.plus(TWOnHALF), EIGHT, "5.5+2.5!=8");
        assertEq(FIVEnHALF.plus(THREE), EIGHTnHALF, "5.5+3!=8.5");
        assertEq(FIVEnHALF.plus(THREEnHALF), NINE, "5.5+3.5!=9");
        assertEq(FIVEnHALF.plus(FOUR), NINEnHALF, "5.5+4!=9.5");
        assertEq(FIVEnHALF.plus(FOURnHALF), TEN, "5.5+4.5!=10");

        assertEq(SIX.plus(ZERO), SIX, "6+0!=6");
        assertEq(SIX.plus(HALF), SIXnHALF, "6+0.5!=6.5");
        assertEq(SIX.plus(ONE), SEVEN, "6+1!=7");
        assertEq(SIX.plus(ONEnHALF), SEVENnHALF, "6+1.5!=7.5");
        assertEq(SIX.plus(TWO), EIGHT, "6+2!=8");
        assertEq(SIX.plus(TWOnHALF), EIGHTnHALF, "6+2.5!=8.5");
        assertEq(SIX.plus(THREE), NINE, "6+3!=9");
        assertEq(SIX.plus(THREEnHALF), NINEnHALF, "6+3.5!=9.5");
        assertEq(SIX.plus(FOUR), TEN, "6+4!=10");

        assertEq(SIXnHALF.plus(ZERO), SIXnHALF, "6.5+0!=6.5");
        assertEq(SIXnHALF.plus(HALF), SEVEN, "6.5+0.5!=7");
        assertEq(SIXnHALF.plus(ONE), SEVENnHALF, "6.5+1!=7.5");
        assertEq(SIXnHALF.plus(ONEnHALF), EIGHT, "6.5+1.5!=8");
        assertEq(SIXnHALF.plus(TWO), EIGHTnHALF, "6.5+2!=8.5");
        assertEq(SIXnHALF.plus(TWOnHALF), NINE, "6.5+2.5!=9");
        assertEq(SIXnHALF.plus(THREE), NINEnHALF, "6.5+3!=9.5");
        assertEq(SIXnHALF.plus(THREEnHALF), TEN, "6.5+3.5!=10");

        assertEq(SEVEN.plus(ZERO), SEVEN, "7+0!=7");
        assertEq(SEVEN.plus(HALF), SEVENnHALF, "7+0.5!=7.5");
        assertEq(SEVEN.plus(ONE), EIGHT, "7+1!=8");
        assertEq(SEVEN.plus(ONEnHALF), EIGHTnHALF, "7+1.5!=8.5");
        assertEq(SEVEN.plus(TWO), NINE, "7+2!=9");
        assertEq(SEVEN.plus(TWOnHALF), NINEnHALF, "7+2.5!=9.5");
        assertEq(SEVEN.plus(THREE), TEN, "7+3!=10");

        assertEq(SEVENnHALF.plus(ZERO), SEVENnHALF, "7.5+0!=7.5");
        assertEq(SEVENnHALF.plus(HALF), EIGHT, "7.5+0.5!=8");
        assertEq(SEVENnHALF.plus(ONE), EIGHTnHALF, "7.5+1!=8.5");
        assertEq(SEVENnHALF.plus(ONEnHALF), NINE, "7.5+1.5!=9");
        assertEq(SEVENnHALF.plus(TWO), NINEnHALF, "7.5+2!=9.5");
        assertEq(SEVENnHALF.plus(TWOnHALF), TEN, "7.5+2.5!=10");

        assertEq(EIGHT.plus(ZERO), EIGHT, "8+0!=8");
        assertEq(EIGHT.plus(HALF), EIGHTnHALF, "8+0.5!=8.5");
        assertEq(EIGHT.plus(ONE), NINE, "8+1!=9");
        assertEq(EIGHT.plus(ONEnHALF), NINEnHALF, "8+1.5!=9.5");
        assertEq(EIGHT.plus(TWO), TEN, "8+2!=10");

        assertEq(EIGHTnHALF.plus(ZERO), EIGHTnHALF, "8.5+0!=8.5");
        assertEq(EIGHTnHALF.plus(HALF), NINE, "8.5+0.5!=9");
        assertEq(EIGHTnHALF.plus(ONE), NINEnHALF, "8.5+1!=9.5");
        assertEq(EIGHTnHALF.plus(ONEnHALF), TEN, "8.5+1.5!=10");

        assertEq(NINE.plus(ZERO), NINE, "9+0!=9");
        assertEq(NINE.plus(HALF), NINEnHALF, "9+0.5!=9.5");
        assertEq(NINE.plus(ONE), TEN, "9+1!=10");

        assertEq(NINEnHALF.plus(ZERO), NINEnHALF, "9.5+0!=9.5");
        assertEq(NINEnHALF.plus(HALF), TEN, "9.5+0.5!=10");

        assertEq(TEN.plus(ZERO), TEN, "10+0!=10");
    }

    function testSubtract() public {
        assertEq(ZERO.minus(ZERO), ZERO, "0-0!=0");

        assertEq(HALF.minus(ZERO), HALF, "0.5-0!=0.5");
        assertEq(HALF.minus(HALF), ZERO, "0.5-0.5!=0");

        assertEq(ONE.minus(ZERO), ONE, "1-0!=1");
        assertEq(ONE.minus(HALF), HALF, "1-0.5!=0.5");
        assertEq(ONE.minus(ONE), ZERO, "1-1!=0");

        assertEq(ONEnHALF.minus(ZERO), ONEnHALF, "1.5-0!=1.5");
        assertEq(ONEnHALF.minus(HALF), ONE, "1.5-0.5!=1");
        assertEq(ONEnHALF.minus(ONE), HALF, "1.5-1!=0.5");
        assertEq(ONEnHALF.minus(ONEnHALF), ZERO, "1.5-1.5!=0");

        assertEq(TWO.minus(ZERO), TWO, "2-0!=2");
        assertEq(TWO.minus(HALF), ONEnHALF, "2-0.5!=1.5");
        assertEq(TWO.minus(ONE), ONE, "2-1!=1");
        assertEq(TWO.minus(ONEnHALF), HALF, "2-1.5!=0.5");
        assertEq(TWO.minus(TWO), ZERO, "2-2!=0");

        assertEq(TWOnHALF.minus(ZERO), TWOnHALF, "2.5-0!=2.5");
        assertEq(TWOnHALF.minus(HALF), TWO, "2.5-0.5!=2");
        assertEq(TWOnHALF.minus(ONE), ONEnHALF, "2.5-1!=1.5");
        assertEq(TWOnHALF.minus(ONEnHALF), ONE, "2.5-1.5!=1");
        assertEq(TWOnHALF.minus(TWO), HALF, "2.5-2!=0.5");
        assertEq(TWOnHALF.minus(TWOnHALF), ZERO, "2.5-2.5!=0");

        assertEq(THREE.minus(ZERO), THREE, "3-0!=3");
        assertEq(THREE.minus(HALF), TWOnHALF, "3-0.5!=2.5");
        assertEq(THREE.minus(ONE), TWO, "3-1!=2");
        assertEq(THREE.minus(ONEnHALF), ONEnHALF, "3-1.5!=1.5");
        assertEq(THREE.minus(TWO), ONE, "3-2!=1");
        assertEq(THREE.minus(TWOnHALF), HALF, "3-2.5!=0.5");
        assertEq(THREE.minus(THREE), ZERO, "3-3!=0");

        assertEq(THREEnHALF.minus(ZERO), THREEnHALF, "3.5-0!=3.5");
        assertEq(THREEnHALF.minus(HALF), THREE, "3.5-0.5!=3");
        assertEq(THREEnHALF.minus(ONE), TWOnHALF, "3.5-1!=2.5");
        assertEq(THREEnHALF.minus(ONEnHALF), TWO, "3.5-1.5!=2");
        assertEq(THREEnHALF.minus(TWO), ONEnHALF, "3.5-2!=1.5");
        assertEq(THREEnHALF.minus(TWOnHALF), ONE, "3.5-2.5!=1");
        assertEq(THREEnHALF.minus(THREE), HALF, "3.5-3!=0.5");
        assertEq(THREEnHALF.minus(THREEnHALF), ZERO, "3.5-3.5!=0");

        assertEq(FOUR.minus(ZERO), FOUR, "4-0!=4");
        assertEq(FOUR.minus(HALF), THREEnHALF, "4-0.5!=3.5");
        assertEq(FOUR.minus(ONE), THREE, "4-1!=3");
        assertEq(FOUR.minus(ONEnHALF), TWOnHALF, "4-1.5!=2.5");
        assertEq(FOUR.minus(TWO), TWO, "4-2!=2");
        assertEq(FOUR.minus(TWOnHALF), ONEnHALF, "4-2.5!=1.5");
        assertEq(FOUR.minus(THREE), ONE, "4-3!=1");
        assertEq(FOUR.minus(THREEnHALF), HALF, "4-3.5!=0.5");
        assertEq(FOUR.minus(FOUR), ZERO, "4-4!=0");

        assertEq(FOURnHALF.minus(ZERO), FOURnHALF, "4.5-0!=4.5");
        assertEq(FOURnHALF.minus(HALF), FOUR, "4.5-0.5!=4");
        assertEq(FOURnHALF.minus(ONE), THREEnHALF, "4.5-1!=3.5");
        assertEq(FOURnHALF.minus(ONEnHALF), THREE, "4.5-1.5!=3");
        assertEq(FOURnHALF.minus(TWO), TWOnHALF, "4.5-2!=2.5");
        assertEq(FOURnHALF.minus(TWOnHALF), TWO, "4.5-2.5!=2");
        assertEq(FOURnHALF.minus(THREE), ONEnHALF, "4.5-3!=1.5");
        assertEq(FOURnHALF.minus(THREEnHALF), ONE, "4.5-3.5!=1");
        assertEq(FOURnHALF.minus(FOUR), HALF, "4.5-4!=0.5");
        assertEq(FOURnHALF.minus(FOURnHALF), ZERO, "4.5-4.5!=0");

        assertEq(FIVE.minus(ZERO), FIVE, "5-0!=5");
        assertEq(FIVE.minus(HALF), FOURnHALF, "5-0.5!=4.5");
        assertEq(FIVE.minus(ONE), FOUR, "5-1!=4");
        assertEq(FIVE.minus(ONEnHALF), THREEnHALF, "5-1.5!=3.5");
        assertEq(FIVE.minus(TWO), THREE, "5-2!=3");
        assertEq(FIVE.minus(TWOnHALF), TWOnHALF, "5-2.5!=2.5");
        assertEq(FIVE.minus(THREE), TWO, "5-3!=2");
        assertEq(FIVE.minus(THREEnHALF), ONEnHALF, "5-3.5!=1.5");
        assertEq(FIVE.minus(FOUR), ONE, "5-4!=1");
        assertEq(FIVE.minus(FOURnHALF), HALF, "5-4.5!=0.5");
        assertEq(FIVE.minus(FIVE), ZERO, "5-5!=0");

        assertEq(FIVEnHALF.minus(ZERO), FIVEnHALF, "5.5-0!=5.5");
        assertEq(FIVEnHALF.minus(HALF), FIVE, "5.5-0.5!=5");
        assertEq(FIVEnHALF.minus(ONE), FOURnHALF, "5.5-1!=4.5");
        assertEq(FIVEnHALF.minus(ONEnHALF), FOUR, "5.5-1.5!=4");
        assertEq(FIVEnHALF.minus(TWO), THREEnHALF, "5.5-2!=3.5");
        assertEq(FIVEnHALF.minus(TWOnHALF), THREE, "5.5-2.5!=3");
        assertEq(FIVEnHALF.minus(THREE), TWOnHALF, "5.5-3!=2.5");
        assertEq(FIVEnHALF.minus(THREEnHALF), TWO, "5.5-3.5!=2");
        assertEq(FIVEnHALF.minus(FOUR), ONEnHALF, "5.5-4!=1.5");
        assertEq(FIVEnHALF.minus(FOURnHALF), ONE, "5.5-4.5!=1");
        assertEq(FIVEnHALF.minus(FIVE), HALF, "5.5-5!=0.5");
        assertEq(FIVEnHALF.minus(FIVEnHALF), ZERO, "5.5-5.5!=0");

        assertEq(SIX.minus(ZERO), SIX, "6-0!=6");
        assertEq(SIX.minus(HALF), FIVEnHALF, "6-0.5!=5.5");
        assertEq(SIX.minus(ONE), FIVE, "6-1!=5");
        assertEq(SIX.minus(ONEnHALF), FOURnHALF, "6-1.5!=4.5");
        assertEq(SIX.minus(TWO), FOUR, "6-2!=4");
        assertEq(SIX.minus(TWOnHALF), THREEnHALF, "6-2.5!=3.5");
        assertEq(SIX.minus(THREE), THREE, "6-3!=3");
        assertEq(SIX.minus(THREEnHALF), TWOnHALF, "6-3.5!=2.5");
        assertEq(SIX.minus(FOUR), TWO, "6-4!=2");
        assertEq(SIX.minus(FOURnHALF), ONEnHALF, "6-4.5!=1.5");
        assertEq(SIX.minus(FIVE), ONE, "6-5!=1");
        assertEq(SIX.minus(FIVEnHALF), HALF, "6-5.5!=0.5");
        assertEq(SIX.minus(SIX), ZERO, "6-6!=0");

        assertEq(SIXnHALF.minus(ZERO), SIXnHALF, "6.5-0!=6.5");
        assertEq(SIXnHALF.minus(HALF), SIX, "6.5-0.5!=6");
        assertEq(SIXnHALF.minus(ONE), FIVEnHALF, "6.5-1!=5.5");
        assertEq(SIXnHALF.minus(ONEnHALF), FIVE, "6.5-1.5!=5");
        assertEq(SIXnHALF.minus(TWO), FOURnHALF, "6.5-2!=4.5");
        assertEq(SIXnHALF.minus(TWOnHALF), FOUR, "6.5-2.5!=4");
        assertEq(SIXnHALF.minus(THREE), THREEnHALF, "6.5-3!=3.5");
        assertEq(SIXnHALF.minus(THREEnHALF), THREE, "6.5-3.5!=3");
        assertEq(SIXnHALF.minus(FOUR), TWOnHALF, "6.5-4!=2.5");
        assertEq(SIXnHALF.minus(FOURnHALF), TWO, "6.5-4.5!=2");
        assertEq(SIXnHALF.minus(FIVE), ONEnHALF, "6.5-5!=1.5");
        assertEq(SIXnHALF.minus(FIVEnHALF), ONE, "6.5-5.5!=1");
        assertEq(SIXnHALF.minus(SIX), HALF, "6.5-6!=0.5");
        assertEq(SIXnHALF.minus(SIXnHALF), ZERO, "6.5-6.5!=0");

        assertEq(SEVEN.minus(ZERO), SEVEN, "7-0!=7");
        assertEq(SEVEN.minus(HALF), SIXnHALF, "7-0.5!=6.5");
        assertEq(SEVEN.minus(ONE), SIX, "7-1!=6");
        assertEq(SEVEN.minus(ONEnHALF), FIVEnHALF, "7-1.5!=5.5");
        assertEq(SEVEN.minus(TWO), FIVE, "7-2!=5");
        assertEq(SEVEN.minus(TWOnHALF), FOURnHALF, "7-2.5!=4.5");
        assertEq(SEVEN.minus(THREE), FOUR, "7-3!=4");
        assertEq(SEVEN.minus(THREEnHALF), THREEnHALF, "7-3.5!=3.5");
        assertEq(SEVEN.minus(FOUR), THREE, "7-4!=3");
        assertEq(SEVEN.minus(FOURnHALF), TWOnHALF, "7-4.5!=2.5");
        assertEq(SEVEN.minus(FIVE), TWO, "7-5!=2");
        assertEq(SEVEN.minus(FIVEnHALF), ONEnHALF, "7-5.5!=1.5");
        assertEq(SEVEN.minus(SIX), ONE, "7-6!=1");
        assertEq(SEVEN.minus(SIXnHALF), HALF, "7-6.5!=0.5");
        assertEq(SEVEN.minus(SEVEN), ZERO, "7-7!=0");

        assertEq(SEVENnHALF.minus(ZERO), SEVENnHALF, "7.5-0!=7.5");
        assertEq(SEVENnHALF.minus(HALF), SEVEN, "7.5-0.5!=7");
        assertEq(SEVENnHALF.minus(ONE), SIXnHALF, "7.5-1!=6.5");
        assertEq(SEVENnHALF.minus(ONEnHALF), SIX, "7.5-1.5!=6");
        assertEq(SEVENnHALF.minus(TWO), FIVEnHALF, "7.5-2!=5.5");
        assertEq(SEVENnHALF.minus(TWOnHALF), FIVE, "7.5-2.5!=5");
        assertEq(SEVENnHALF.minus(THREE), FOURnHALF, "7.5-3!=4.5");
        assertEq(SEVENnHALF.minus(THREEnHALF), FOUR, "7.5-3.5!=4");
        assertEq(SEVENnHALF.minus(FOUR), THREEnHALF, "7.5-4!=3.5");
        assertEq(SEVENnHALF.minus(FOURnHALF), THREE, "7.5-4.5!=3");
        assertEq(SEVENnHALF.minus(FIVE), TWOnHALF, "7.5-5!=2.5");
        assertEq(SEVENnHALF.minus(FIVEnHALF), TWO, "7.5-5.5!=2");
        assertEq(SEVENnHALF.minus(SIX), ONEnHALF, "7.5-6!=1.5");
        assertEq(SEVENnHALF.minus(SIXnHALF), ONE, "7.5-6.5!=1");
        assertEq(SEVENnHALF.minus(SEVEN), HALF, "7.5-7!=0.5");
        assertEq(SEVENnHALF.minus(SEVENnHALF), ZERO, "7.5-7.5!=0");

        assertEq(EIGHT.minus(ZERO), EIGHT, "8-0!=8");
        assertEq(EIGHT.minus(HALF), SEVENnHALF, "8-0.5!=7.5");
        assertEq(EIGHT.minus(ONE), SEVEN, "8-1!=7");
        assertEq(EIGHT.minus(ONEnHALF), SIXnHALF, "8-1.5!=6.5");
        assertEq(EIGHT.minus(TWO), SIX, "8-2!=6");
        assertEq(EIGHT.minus(TWOnHALF), FIVEnHALF, "8-2.5!=5.5");
        assertEq(EIGHT.minus(THREE), FIVE, "8-3!=5");
        assertEq(EIGHT.minus(THREEnHALF), FOURnHALF, "8-3.5!=4.5");
        assertEq(EIGHT.minus(FOUR), FOUR, "8-4!=4");
        assertEq(EIGHT.minus(FOURnHALF), THREEnHALF, "8-4.5!=3.5");
        assertEq(EIGHT.minus(FIVE), THREE, "8-5!=3");
        assertEq(EIGHT.minus(FIVEnHALF), TWOnHALF, "8-5.5!=2.5");
        assertEq(EIGHT.minus(SIX), TWO, "8-6!=2");
        assertEq(EIGHT.minus(SIXnHALF), ONEnHALF, "8-6.5!=1.5");
        assertEq(EIGHT.minus(SEVEN), ONE, "8-7!=1");
        assertEq(EIGHT.minus(SEVENnHALF), HALF, "8-7.5!=0.5");
        assertEq(EIGHT.minus(EIGHT), ZERO, "8-8!=0");

        assertEq(EIGHTnHALF.minus(ZERO), EIGHTnHALF, "8.5-0!=8.5");
        assertEq(EIGHTnHALF.minus(HALF), EIGHT, "8.5-0.5!=8");
        assertEq(EIGHTnHALF.minus(ONE), SEVENnHALF, "8.5-1!=7.5");
        assertEq(EIGHTnHALF.minus(ONEnHALF), SEVEN, "8.5-1.5!=7");
        assertEq(EIGHTnHALF.minus(TWO), SIXnHALF, "8.5-2!=6.5");
        assertEq(EIGHTnHALF.minus(TWOnHALF), SIX, "8.5-2.5!=6");
        assertEq(EIGHTnHALF.minus(THREE), FIVEnHALF, "8.5-3!=5.5");
        assertEq(EIGHTnHALF.minus(THREEnHALF), FIVE, "8.5-3.5!=5");
        assertEq(EIGHTnHALF.minus(FOUR), FOURnHALF, "8.5-4!=4.5");
        assertEq(EIGHTnHALF.minus(FOURnHALF), FOUR, "8.5-4.5!=4");
        assertEq(EIGHTnHALF.minus(FIVE), THREEnHALF, "8.5-5!=3.5");
        assertEq(EIGHTnHALF.minus(FIVEnHALF), THREE, "8.5-5.5!=3");
        assertEq(EIGHTnHALF.minus(SIX), TWOnHALF, "8.5-6!=2.5");
        assertEq(EIGHTnHALF.minus(SIXnHALF), TWO, "8.5-6.5!=2");
        assertEq(EIGHTnHALF.minus(SEVEN), ONEnHALF, "8.5-7!=1.5");
        assertEq(EIGHTnHALF.minus(SEVENnHALF), ONE, "8.5-7.5!=1");
        assertEq(EIGHTnHALF.minus(EIGHT), HALF, "8.5-8!=0.5");
        assertEq(EIGHTnHALF.minus(EIGHTnHALF), ZERO, "8.5-8.5!=0");

        assertEq(NINE.minus(ZERO), NINE, "9-0!=9");
        assertEq(NINE.minus(HALF), EIGHTnHALF, "9-0.5!=8.5");
        assertEq(NINE.minus(ONE), EIGHT, "9-1!=8");
        assertEq(NINE.minus(ONEnHALF), SEVENnHALF, "9-1.5!=7.5");
        assertEq(NINE.minus(TWO), SEVEN, "9-2!=7");
        assertEq(NINE.minus(TWOnHALF), SIXnHALF, "9-2.5!=6.5");
        assertEq(NINE.minus(THREE), SIX, "9-3!=6");
        assertEq(NINE.minus(THREEnHALF), FIVEnHALF, "9-3.5!=5.5");
        assertEq(NINE.minus(FOUR), FIVE, "9-4!=5");
        assertEq(NINE.minus(FOURnHALF), FOURnHALF, "9-4.5!=4.5");
        assertEq(NINE.minus(FIVE), FOUR, "9-5!=4");
        assertEq(NINE.minus(FIVEnHALF), THREEnHALF, "9-5.5!=3.5");
        assertEq(NINE.minus(SIX), THREE, "9-6!=3");
        assertEq(NINE.minus(SIXnHALF), TWOnHALF, "9-6.5!=2.5");
        assertEq(NINE.minus(SEVEN), TWO, "9-7!=2");
        assertEq(NINE.minus(SEVENnHALF), ONEnHALF, "9-7.5!=1.5");
        assertEq(NINE.minus(EIGHT), ONE, "9-8!=1");
        assertEq(NINE.minus(EIGHTnHALF), HALF, "9-8.5!=0.5");
        assertEq(NINE.minus(NINE), ZERO, "9-9!=0");

        assertEq(NINEnHALF.minus(ZERO), NINEnHALF, "9.5-0!=9.5");
        assertEq(NINEnHALF.minus(HALF), NINE, "9.5-0.5!=9");
        assertEq(NINEnHALF.minus(ONE), EIGHTnHALF, "9.5-1!=8.5");
        assertEq(NINEnHALF.minus(ONEnHALF), EIGHT, "9.5-1.5!=8");
        assertEq(NINEnHALF.minus(TWO), SEVENnHALF, "9.5-2!=7.5");
        assertEq(NINEnHALF.minus(TWOnHALF), SEVEN, "9.5-2.5!=7");
        assertEq(NINEnHALF.minus(THREE), SIXnHALF, "9.5-3!=6.5");
        assertEq(NINEnHALF.minus(THREEnHALF), SIX, "9.5-3.5!=6");
        assertEq(NINEnHALF.minus(FOUR), FIVEnHALF, "9.5-4!=5.5");
        assertEq(NINEnHALF.minus(FOURnHALF), FIVE, "9.5-4.5!=5");
        assertEq(NINEnHALF.minus(FIVE), FOURnHALF, "9.5-5!=4.5");
        assertEq(NINEnHALF.minus(FIVEnHALF), FOUR, "9.5-5.5!=4");
        assertEq(NINEnHALF.minus(SIX), THREEnHALF, "9.5-6!=3.5");
        assertEq(NINEnHALF.minus(SIXnHALF), THREE, "9.5-6.5!=3");
        assertEq(NINEnHALF.minus(SEVEN), TWOnHALF, "9.5-7!=2.5");
        assertEq(NINEnHALF.minus(SEVENnHALF), TWO, "9.5-7.5!=2");
        assertEq(NINEnHALF.minus(EIGHT), ONEnHALF, "9.5-8!=1.5");
        assertEq(NINEnHALF.minus(EIGHTnHALF), ONE, "9.5-8.5!=1");
        assertEq(NINEnHALF.minus(NINE), HALF, "9.5-9!=0.5");
        assertEq(NINEnHALF.minus(NINEnHALF), ZERO, "9.5-9.5!=0");

        assertEq(TEN.minus(ZERO), TEN, "10-0!=10");
        assertEq(TEN.minus(HALF), NINEnHALF, "10-0.5!=9.5");
        assertEq(TEN.minus(ONE), NINE, "10-1!=9");
        assertEq(TEN.minus(ONEnHALF), EIGHTnHALF, "10-1.5!=8.5");
        assertEq(TEN.minus(TWO), EIGHT, "10-2!=8");
        assertEq(TEN.minus(TWOnHALF), SEVENnHALF, "10-2.5!=7.5");
        assertEq(TEN.minus(THREE), SEVEN, "10-3!=7");
        assertEq(TEN.minus(THREEnHALF), SIXnHALF, "10-3.5!=6.5");
        assertEq(TEN.minus(FOUR), SIX, "10-4!=6");
        assertEq(TEN.minus(FOURnHALF), FIVEnHALF, "10-4.5!=5.5");
        assertEq(TEN.minus(FIVE), FIVE, "10-5!=5");
        assertEq(TEN.minus(FIVEnHALF), FOURnHALF, "10-5.5!=4.5");
        assertEq(TEN.minus(SIX), FOUR, "10-6!=4");
        assertEq(TEN.minus(SIXnHALF), THREEnHALF, "10-6.5!=3.5");
        assertEq(TEN.minus(SEVEN), THREE, "10-7!=3");
        assertEq(TEN.minus(SEVENnHALF), TWOnHALF, "10-7.5!=2.5");
        assertEq(TEN.minus(EIGHT), TWO, "10-8!=2");
        assertEq(TEN.minus(EIGHTnHALF), ONEnHALF, "10-8.5!=1.5");
        assertEq(TEN.minus(NINE), ONE, "10-9!=1");
        assertEq(TEN.minus(NINEnHALF), HALF, "10-9.5!=0.5");
        assertEq(TEN.minus(TEN), ZERO, "10-10!=0");
    }

    function testMultiply() public {
        assertEq(ZERO.times(ZERO), ZERO, "0*0!=0");
        assertEq(ZERO.times(HALF), ZERO, "0*0.5!=0");
        assertEq(ZERO.times(ONE), ZERO, "0*1!=0");
        assertEq(ZERO.times(ONEnHALF), ZERO, "0*1.5!=0");
        assertEq(ZERO.times(TWO), ZERO, "0*2!=0");
        assertEq(ZERO.times(TWOnHALF), ZERO, "0*2.5!=0");
        assertEq(ZERO.times(THREE), ZERO, "0*3!=0");
        assertEq(ZERO.times(THREEnHALF), ZERO, "0*3.5!=0");
        assertEq(ZERO.times(FOUR), ZERO, "0*4!=0");
        assertEq(ZERO.times(FOURnHALF), ZERO, "0*4.5!=0");
        assertEq(ZERO.times(FIVE), ZERO, "0*5!=0");
        assertEq(ZERO.times(FIVEnHALF), ZERO, "0*5.5!=0");
        assertEq(ZERO.times(SIX), ZERO, "0*6!=0");
        assertEq(ZERO.times(SIXnHALF), ZERO, "0*6.5!=0");
        assertEq(ZERO.times(SEVEN), ZERO, "0*7!=0");
        assertEq(ZERO.times(SEVENnHALF), ZERO, "0*7.5!=0");
        assertEq(ZERO.times(EIGHT), ZERO, "0*8!=0");
        assertEq(ZERO.times(EIGHTnHALF), ZERO, "0*8.5!=0");
        assertEq(ZERO.times(NINE), ZERO, "0*9!=0");
        assertEq(ZERO.times(NINEnHALF), ZERO, "0*9.5!=0");
        assertEq(ZERO.times(TEN), ZERO, "0*10!=0");

        assertEq(HALF.times(ZERO), ZERO, "0.5*0!=0");
        assertEq(HALF.times(ONE), HALF, "0.5*1!=0.5");
        assertEq(HALF.times(TWO), ONE, "0.5*2!=1");
        assertEq(HALF.times(THREE), ONEnHALF, "0.5*3!=1.5");
        assertEq(HALF.times(FOUR), TWO, "0.5*4!=2");
        assertEq(HALF.times(FIVE), TWOnHALF, "0.5*5!=2.5");
        assertEq(HALF.times(SIX), THREE, "0.5*6!=3");
        assertEq(HALF.times(SEVEN), THREEnHALF, "0.5*7!=3.5");
        assertEq(HALF.times(EIGHT), FOUR, "0.5*8!=4");
        assertEq(HALF.times(NINE), FOURnHALF, "0.5*9!=4.5");
        assertEq(HALF.times(TEN), FIVE, "0.5*10!=5");

        assertEq(ONE.times(ZERO), ZERO, "1*0!=0");
        assertEq(ONE.times(HALF), HALF, "1*0.5!=0.5");
        assertEq(ONE.times(ONE), ONE, "1*1!=1");
        assertEq(ONE.times(ONEnHALF), ONEnHALF, "1*1.5!=1.5");
        assertEq(ONE.times(TWO), TWO, "1*2!=2");
        assertEq(ONE.times(TWOnHALF), TWOnHALF, "1*2.5!=2.5");
        assertEq(ONE.times(THREE), THREE, "1*3!=3");
        assertEq(ONE.times(THREEnHALF), THREEnHALF, "1*3.5!=3.5");
        assertEq(ONE.times(FOUR), FOUR, "1*4!=4");
        assertEq(ONE.times(FOURnHALF), FOURnHALF, "1*4.5!=4.5");
        assertEq(ONE.times(FIVE), FIVE, "1*5!=5");
        assertEq(ONE.times(FIVEnHALF), FIVEnHALF, "1*5.5!=5.5");
        assertEq(ONE.times(SIX), SIX, "1*6!=6");
        assertEq(ONE.times(SIXnHALF), SIXnHALF, "1*6.5!=6.5");
        assertEq(ONE.times(SEVEN), SEVEN, "1*7!=7");
        assertEq(ONE.times(SEVENnHALF), SEVENnHALF, "1*7.5!=7.5");
        assertEq(ONE.times(EIGHT), EIGHT, "1*8!=8");
        assertEq(ONE.times(EIGHTnHALF), EIGHTnHALF, "1*8.5!=8.5");
        assertEq(ONE.times(NINE), NINE, "1*9!=9");
        assertEq(ONE.times(NINEnHALF), NINEnHALF, "1*9.5!=9.5");
        assertEq(ONE.times(TEN), TEN, "1*10!=10");

        assertEq(ONEnHALF.times(ZERO), ZERO, "1.5*0!=0");
        assertEq(ONEnHALF.times(ONE), ONEnHALF, "1.5*1!=1.5");
        assertEq(ONEnHALF.times(TWO), THREE, "1.5*2!=3");
        assertEq(ONEnHALF.times(THREE), FOURnHALF, "1.5*3!=4.5");
        assertEq(ONEnHALF.times(FOUR), SIX, "1.5*4!=6");
        assertEq(ONEnHALF.times(FIVE), SEVENnHALF, "1.5*5!=7.5");
        assertEq(ONEnHALF.times(SIX), NINE, "1.5*6!=9");

        assertEq(TWO.times(ZERO), ZERO, "2*0!=0");
        assertEq(TWO.times(HALF), ONE, "2*0.5!=1");
        assertEq(TWO.times(ONE), TWO, "2*1!=2");
        assertEq(TWO.times(ONEnHALF), THREE, "2*1.5!=3");
        assertEq(TWO.times(TWO), FOUR, "2*2!=4");
        assertEq(TWO.times(TWOnHALF), FIVE, "2*2.5!=5");
        assertEq(TWO.times(THREE), SIX, "2*3!=6");
        assertEq(TWO.times(THREEnHALF), SEVEN, "2*3.5!=7");
        assertEq(TWO.times(FOUR), EIGHT, "2*4!=8");
        assertEq(TWO.times(FOURnHALF), NINE, "2*4.5!=9");
        assertEq(TWO.times(FIVE), TEN, "2*5!=10");

        assertEq(TWOnHALF.times(ZERO), ZERO, "2.5*0!=0");
        assertEq(TWOnHALF.times(ONE), TWOnHALF, "2.5*1!=2.5");
        assertEq(TWOnHALF.times(TWO), FIVE, "2.5*2!=5");
        assertEq(TWOnHALF.times(THREE), SEVENnHALF, "2.5*3!=7.5");
        assertEq(TWOnHALF.times(FOUR), TEN, "2.5*4!=10");

        assertEq(THREE.times(ZERO), ZERO, "3*0!=0");
        assertEq(THREE.times(HALF), ONEnHALF, "3*0.5!=1.5");
        assertEq(THREE.times(ONE), THREE, "3*1!=3");
        assertEq(THREE.times(ONEnHALF), FOURnHALF, "3*1.5!=4.5");
        assertEq(THREE.times(TWO), SIX, "3*2!=6");
        assertEq(THREE.times(TWOnHALF), SEVENnHALF, "3*2.5!=7.5");
        assertEq(THREE.times(THREE), NINE, "3*3!=9");

        assertEq(THREEnHALF.times(ZERO), ZERO, "3.5*0!=0");
        assertEq(THREEnHALF.times(ONE), THREEnHALF, "3.5*1!=3.5");
        assertEq(THREEnHALF.times(TWO), SEVEN, "3.5*2!=7");

        assertEq(FOUR.times(ZERO), ZERO, "4*0!=0");
        assertEq(FOUR.times(HALF), TWO, "4*0.5!=2");
        assertEq(FOUR.times(ONE), FOUR, "4*1!=4");
        assertEq(FOUR.times(ONEnHALF), SIX, "4*1.5!=6");
        assertEq(FOUR.times(TWO), EIGHT, "4*2!=8");
        assertEq(FOUR.times(TWOnHALF), TEN, "4*2.5!=10");

        assertEq(FOURnHALF.times(ZERO), ZERO, "4.5*0!=0");
        assertEq(FOURnHALF.times(ONE), FOURnHALF, "4.5*1!=4.5");
        assertEq(FOURnHALF.times(TWO), NINE, "4.5*2!=9");

        assertEq(FIVE.times(ZERO), ZERO, "5*0!=0");
        assertEq(FIVE.times(HALF), TWOnHALF, "5*0.5!=2.5");
        assertEq(FIVE.times(ONE), FIVE, "5*1!=5");
        assertEq(FIVE.times(ONEnHALF), SEVENnHALF, "5*1.5!=7.5");
        assertEq(FIVE.times(TWO), TEN, "5*2!=10");

        assertEq(FIVEnHALF.times(ZERO), ZERO, "5.5*0!=0");
        assertEq(FIVEnHALF.times(ONE), FIVEnHALF, "5.5*1!=5.5");

        assertEq(SIX.times(ZERO), ZERO, "6*0!=0");
        assertEq(SIX.times(HALF), THREE, "6*0.5!=3");
        assertEq(SIX.times(ONE), SIX, "6*1!=6");
        assertEq(SIX.times(ONEnHALF), NINE, "6*1.5!=9");

        assertEq(SIXnHALF.times(ZERO), ZERO, "6.5*0!=0");
        assertEq(SIXnHALF.times(ONE), SIXnHALF, "6.5*1!=6.5");

        assertEq(SEVEN.times(ZERO), ZERO, "7*0!=0");
        assertEq(SEVEN.times(HALF), THREEnHALF, "7*0.5!=3.5");
        assertEq(SEVEN.times(ONE), SEVEN, "7*1!=7");

        assertEq(SEVENnHALF.times(ZERO), ZERO, "7.5*0!=0");
        assertEq(SEVENnHALF.times(ONE), SEVENnHALF, "7.5*1!=7.5");

        assertEq(EIGHT.times(ZERO), ZERO, "8*0!=0");
        assertEq(EIGHT.times(HALF), FOUR, "8*0.5!=4");
        assertEq(EIGHT.times(ONE), EIGHT, "8*1!=8");

        assertEq(EIGHTnHALF.times(ZERO), ZERO, "8.5*0!=0");
        assertEq(EIGHTnHALF.times(ONE), EIGHTnHALF, "8.5*1!=8.5");

        assertEq(NINE.times(ZERO), ZERO, "9*0!=0");
        assertEq(NINE.times(HALF), FOURnHALF, "9*0.5!=4.5");
        assertEq(NINE.times(ONE), NINE, "9*1!=9");

        assertEq(NINEnHALF.times(ZERO), ZERO, "9.5*0!=0");
        assertEq(NINEnHALF.times(ONE), NINEnHALF, "9.5*1!=9.5");

        assertEq(TEN.times(ZERO), ZERO, "10*0!=0");
        assertEq(TEN.times(HALF), FIVE, "10*0.5!=5");
        assertEq(TEN.times(ONE), TEN, "10*1!=10");
    }

    function testDivide() public {
        assertEq(ZERO.divide(HALF), ZERO, "0/0.5!=0");
        assertEq(ZERO.divide(ONE), ZERO, "0/1!=0");
        assertEq(ZERO.divide(ONEnHALF), ZERO, "0/1.5!=0");
        assertEq(ZERO.divide(TWO), ZERO, "0/2!=0");
        assertEq(ZERO.divide(TWOnHALF), ZERO, "0/2.5!=0");
        assertEq(ZERO.divide(THREE), ZERO, "0/3!=0");
        assertEq(ZERO.divide(THREEnHALF), ZERO, "0/3.5!=0");
        assertEq(ZERO.divide(FOUR), ZERO, "0/4!=0");
        assertEq(ZERO.divide(FOURnHALF), ZERO, "0/4.5!=0");
        assertEq(ZERO.divide(FIVE), ZERO, "0/5!=0");
        assertEq(ZERO.divide(FIVEnHALF), ZERO, "0/5.5!=0");
        assertEq(ZERO.divide(SIX), ZERO, "0/6!=0");
        assertEq(ZERO.divide(SIXnHALF), ZERO, "0/6.5!=0");
        assertEq(ZERO.divide(SEVEN), ZERO, "0/7!=0");
        assertEq(ZERO.divide(SEVENnHALF), ZERO, "0/7.5!=0");
        assertEq(ZERO.divide(EIGHT), ZERO, "0/8!=0");
        assertEq(ZERO.divide(EIGHTnHALF), ZERO, "0/8.5!=0");
        assertEq(ZERO.divide(NINE), ZERO, "0/9!=0");
        assertEq(ZERO.divide(NINEnHALF), ZERO, "0/9.5!=0");
        assertEq(ZERO.divide(TEN), ZERO, "0/10!=0");

        assertEq(HALF.divide(HALF), ONE, "0.5/0.5!=1");
        assertEq(HALF.divide(ONE), HALF, "0.5/1!=0.5");

        assertEq(ONE.divide(HALF), TWO, "1/0.5!=2");
        assertEq(ONE.divide(ONE), ONE, "1/1!=1");
        assertEq(ONE.divide(TWO), HALF, "1/2!=0.5");

        assertEq(ONEnHALF.divide(HALF), THREE, "1.5/0.5!=3");
        assertEq(ONEnHALF.divide(ONE), ONEnHALF, "1.5/1!=1.5");

        assertEq(TWO.divide(HALF), FOUR, "2/0.5!=4");
        assertEq(TWO.divide(ONE), TWO, "2/1!=2");
        assertEq(TWO.divide(TWO), ONE, "2/2!=1");
        assertEq(TWO.divide(FOUR), HALF, "2/4!=0.5");

        assertEq(TWOnHALF.divide(HALF), FIVE, "2.5/0.5!=5");
        assertEq(TWOnHALF.divide(ONE), TWOnHALF, "2.5/1!=2.5");
        assertEq(TWOnHALF.divide(TWOnHALF), ONE, "2.5/2.5!=1");

        assertEq(THREE.divide(HALF), SIX, "3/0.5!=6");
        assertEq(THREE.divide(ONE), THREE, "3/1!=3");
        assertEq(THREE.divide(ONEnHALF), TWO, "3/1.5!=2");
        assertEq(THREE.divide(TWO), ONEnHALF, "3/2!=1.5");
        assertEq(THREE.divide(THREE), ONE, "3/3!=1");
        assertEq(THREE.divide(SIX), HALF, "3/6!=0.5");

        assertEq(THREEnHALF.divide(HALF), SEVEN, "3.5/0.5!=7");
        assertEq(THREEnHALF.divide(ONE), THREEnHALF, "3.5/1!=3.5");
        assertEq(THREEnHALF.divide(THREEnHALF), ONE, "3.5/3.5!=1");

        assertEq(FOUR.divide(HALF), EIGHT, "4/0.5!=8");
        assertEq(FOUR.divide(ONE), FOUR, "4/1!=4");
        assertEq(FOUR.divide(TWO), TWO, "4/2!=2");
        assertEq(FOUR.divide(FOUR), ONE, "4/4!=1");
        assertEq(FOUR.divide(EIGHT), HALF, "4/8!=0.5");

        assertEq(FOURnHALF.divide(HALF), NINE, "4.5/0.5!=9");
        assertEq(FOURnHALF.divide(ONE), FOURnHALF, "4.5/1!=4.5");
        assertEq(FOURnHALF.divide(FOURnHALF), ONE, "4.5/4.5!=1");

        assertEq(FIVE.divide(HALF), TEN, "5/0.5!=10");
        assertEq(FIVE.divide(ONE), FIVE, "5/1!=5");
        assertEq(FIVE.divide(TWO), TWOnHALF, "5/2!=2.5");
        assertEq(FIVE.divide(FIVE), ONE, "5/5!=1");
        assertEq(FIVE.divide(TEN), HALF, "5/10!=0.5");

        assertEq(FIVEnHALF.divide(ONE), FIVEnHALF, "5.5/5.5!=1");
        assertEq(FIVEnHALF.divide(FIVEnHALF), ONE, "5.5/5.5!=1");

        assertEq(SIX.divide(ONE), SIX, "6/1!=6");
        assertEq(SIX.divide(TWO), THREE, "6/2!=3");
        assertEq(SIX.divide(THREE), TWO, "6/3!=2");
        assertEq(SIX.divide(FOUR), ONEnHALF, "6/4!=1.5");
        assertEq(SIX.divide(SIX), ONE, "6/6!=1");

        assertEq(SIXnHALF.divide(ONE), SIXnHALF, "6.5/1!=6.5");
        assertEq(SIXnHALF.divide(SIXnHALF), ONE, "6.5/6.5!=1");

        assertEq(SEVEN.divide(ONE), SEVEN, "7/1!=7");
        assertEq(SEVEN.divide(TWO), THREEnHALF, "7/2!=3.5");
        assertEq(SEVEN.divide(SEVEN), ONE, "7/7!=1");

        assertEq(SEVENnHALF.divide(ONE), SEVENnHALF, "7.5/1!=7.5");
        assertEq(SEVENnHALF.divide(SEVENnHALF), ONE, "7.5/7.5!=1");

        assertEq(EIGHT.divide(ONE), EIGHT, "8/1!=8");
        assertEq(EIGHT.divide(TWO), FOUR, "8/2!=4");
        assertEq(EIGHT.divide(FOUR), TWO, "8/4!=2");
        assertEq(EIGHT.divide(EIGHT), ONE, "8/8!=1");

        assertEq(EIGHTnHALF.divide(ONE), EIGHTnHALF, "8.5/1!=8.5");
        assertEq(EIGHTnHALF.divide(EIGHTnHALF), ONE, "8.5/8.5!=1");

        assertEq(NINE.divide(ONE), NINE, "9/1!=9");
        assertEq(NINE.divide(TWO), FOURnHALF, "9/2!=4.5");
        assertEq(NINE.divide(THREE), THREE, "9/3!=3");
        assertEq(NINE.divide(NINE), ONE, "9/9!=1");

        assertEq(NINEnHALF.divide(ONE), NINEnHALF, "9.5/1!=9.5");
        assertEq(NINEnHALF.divide(NINEnHALF), ONE, "9.5/9.5!=1");

        assertEq(TEN.divide(ONE), TEN, "10/1!=10");
        assertEq(TEN.divide(TWO), FIVE, "10/2!=5");
        assertEq(TEN.divide(FOUR), TWOnHALF, "10/4!=2.5");
        assertEq(TEN.divide(FIVE), TWO, "10/5!=2");
        assertEq(TEN.divide(TEN), ONE, "10/10!=1");
    }

    // function testMulDiv() public {
    //     UFloat[] memory floats = getFloats();
    //     for (uint256 i; i < floats.length; i++) {
    //         for (uint256 j; j < floats.length; j++) {
    //             for (uint256 k = 1; k < floats.length; k++) {
    //                 a = floats[i];
    //                 b = floats[j];
    //                 c = floats[k];
    //                 assertEq(
    //                     FloatingPoint.mulDiv(a, b, c),
    //                     a.times(b).divide(c),
    //                     "muDiv(a,b,c)!=(a*b)/c"
    //                 );
    //             }
    //         }
    //     }
    // }

    // function testMulDivAdd() public {
    //     UFloat[] memory floats = getFloats();
    //     for (uint256 i; i < floats.length; i++) {
    //         for (uint256 j; j < floats.length; j++) {
    //             for (uint256 k = 1; k < floats.length; k++) {
    //                 a = floats[i];
    //                 b = floats[j];
    //                 c = floats[k];
    //                 assertEq(
    //                     FloatingPoint.mulDivAdd(a, b, c),
    //                     a.times(c).divide(b.plus(c)),
    //                     "muDivAdd(a,b,c)!=(a*b)/(c+b)"
    //                 );
    //             }
    //         }
    //     }
    // }

    // function testEncode() public {
    //     uint256 x = FloatingPoint.encode(1, 1);
    //     uint256 m;
    //     uint256 e;
    //     (m, e) = FloatingPoint.decode(x);
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

    // function testSquareRoot() public {
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

    // function testGeometricMeanFuzz(uint256 amount) public {
    //     vm.assume(amount > 0 && amount < 1000000000000000 * ONE);

    //     assertEq(pool.geometricMean(0, 0, amount, 0), amount, "delta = 0");

    //     assertEq(
    //         pool.geometricMean(amount, amount, amount, 1),
    //         amount,
    //         "delta = 1"
    //     );
    // }

    // function testGeometricMeanVerbose() public {
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
