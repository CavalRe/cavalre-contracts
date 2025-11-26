// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";
import {FloatLib, Float} from "../../libraries/FloatLib.sol";
import {FloatStrings} from "../../libraries/FloatStrings.sol";
import {RandomLib} from "../../libraries/RandomLib.sol";

contract RandomLibTest is Test {
    using FloatLib for Float;
    using FloatStrings for Float;

    function setUp() public {}

    function testRandom() public {
        bool isVerbose = false;

        for (uint256 i = 0; i < 10000; i++) {
            // Float _float = RandomLib.random();
            // Float _float = RandomLib.randomPositive();
            // Float _float = RandomLib.randomUnit();
            // Float _float = RandomLib.randomInterval(FloatLib.TWO, FloatLib.FIVE);
            // Float _float = RandomLib.randomPositive().minus(FloatLib.ONE);
            // Float _float = RandomLib.randomUnitNormal();
            // Float _float = RandomLib.randomNormal(FloatLib.FIVE, FloatLib.FIVE);
            Float _float =
                RandomLib.randomLogNormal(FloatLib.HALF.times(FloatLib.HALF), FloatLib.HALF).minus(FloatLib.ONE);
            if (isVerbose) emit log_string(_float.toString());
            // emit log_named_int("  mantissa", _float.mantissa());
            // emit log_named_int("  exponent", _float.exponent());
        }
    }
}
