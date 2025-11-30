# @version 0.4.3
# Simple Vyper test helper for FloatStrings.float_to_string

import FloatLib as FloatLib
import FloatStrings as FloatStrings


event LogStr:
    label: String[32]
    msg: String[128]


@external
def string_one_point_two():
    print("Float(12,-1):", FloatStrings.float_to_string(FloatLib.normalize_raw(12, -1)), hardhat_compat=True)


@external
def string_one_point_onefive_e6_neg():
    print("Float(115, -8):", FloatStrings.float_to_string(FloatLib.normalize_raw(115, -8)), hardhat_compat=True)


@external
def string_neg_one_point_two3e_neg6():
    print("Float(-123456789, -14):", FloatStrings.float_to_string(FloatLib.normalize_raw(-123456789, -14)), hardhat_compat=True)


@external
def string_pi():
    print("Float(PI):", FloatStrings.float_to_string(FloatLib.PI), hardhat_compat=True)


@external
def string_zero():
    print("Float(ZERO):", FloatStrings.float_to_string(FloatLib.ZERO), hardhat_compat=True)


@external
def string_round5():
    f: int256 = FloatLib.round_digits(FloatLib.normalize_raw(123456789, -14), 5)
    print("round(Float(123456789, -14), 5)):", FloatStrings.float_to_string(f), hardhat_compat=True)
