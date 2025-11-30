// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Test} from "forge-std/src/Test.sol";

interface IFloatStringsVyper {
    function string_one_point_two() external;
    function string_one_point_onefive_e6_neg() external;
    function string_neg_one_point_two3e_neg6() external;
    function string_pi() external;
    function string_zero() external;
    function string_round5() external;
}

contract FloatStringsVyperHarness is Test {
    IFloatStringsVyper internal t;

    function setUp() public {
        address addr = deployCode("vyper/FloatStrings.t.vy");
        t = IFloatStringsVyper(addr);
    }

    function testFloatStringsVyperEmitAll() public {
        t.string_one_point_two();
        t.string_one_point_onefive_e6_neg();
        t.string_neg_one_point_two3e_neg6();
        t.string_pi();
        t.string_zero();
        t.string_round5();
    }
}
