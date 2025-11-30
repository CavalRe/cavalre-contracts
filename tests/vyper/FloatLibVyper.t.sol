// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Test} from "forge-std/src/Test.sol";

interface IFloatLibVyper {
    function normalize_checks() external;
    function align_check() external;
    function add_checks() external;
    function subtract_checks() external;
    function multiply_checks() external;
    function divide_checks() external;
    function log_exp_checks() external;
    function exp_checks() external;
}

contract FloatLibVyperHarness is Test {
    IFloatLibVyper internal t;

    function setUp() public {
        address addr = deployCode("vyper/FloatLib.t.vy");
        t = IFloatLibVyper(addr);
    }

    function testFloatVyperNormalize() public {
        t.normalize_checks();
    }

    function testFloatVyperAlign() public {
        t.align_check();
    }

    function testFloatVyperAdd() public {
        t.add_checks();
    }

    function testFloatVyperSubtract() public {
        t.subtract_checks();
    }

    function testFloatVyperMultiply() public {
        t.multiply_checks();
    }

    function testFloatVyperDivide() public {
        t.divide_checks();
    }

    function testFloatVyperLogExp() public {
        t.log_exp_checks();
    }

    function testFloatVyperExp() public {
        t.exp_checks();
    }
}
