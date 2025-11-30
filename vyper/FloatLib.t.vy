# @version 0.4.3
# Vyper harness mirroring FloatLib.t.sol arithmetic/log-exp checks

import FloatLib as FloatLib
import FloatStrings as FloatStrings

MAX_FLOATS: constant(uint256) = 41
FLOAT_MAX_INDEX: constant(int256) = 20
ROUND_DIGITS: constant(uint256) = 10
LOG_DIGITS: constant(uint256) = 12


@internal
@pure
def float_value(idx: uint256) -> (int256, int256):
    offset: int256 = convert(idx, int256) - FLOAT_MAX_INDEX
    return FloatLib.normalize_raw(5 * offset, -1), offset


@external
@pure
def normalize_checks():
    norm: int256 = FloatLib.normalize_raw(1, 0)
    assert FloatLib.mantissa(norm) == 10 ** 20
    assert FloatLib.exponent(norm) == -20


@external
@pure
def align_check():
    a: int256 = FloatLib.normalize_raw(1, 0)
    b: int256 = FloatLib.normalize_raw(20000000000, -10)
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = FloatLib.align(a, b)
    assert FloatLib.is_eq(aa, a)
    assert FloatLib.is_eq(bb, b)
    assert FloatLib.exponent(aa) == FloatLib.exponent(bb)


@external
@pure
def add_checks():
    for i: uint256 in range(MAX_FLOATS):
        a: int256 = 0
        i_val: int256 = 0
        a, i_val = self.float_value(i)
        for j: uint256 in range(MAX_FLOATS):
            b: int256 = 0
            j_val: int256 = 0
            b, j_val = self.float_value(j)
            c: int256 = FloatLib.plus(a, b)
            expected: int256 = FloatLib.normalize_raw(5 * (i_val + j_val), -1)
            assert FloatLib.is_eq(c, expected), "add"


@external
@pure
def subtract_checks():
    for i: uint256 in range(MAX_FLOATS):
        a: int256 = 0
        i_val: int256 = 0
        a, i_val = self.float_value(i)
        for j: uint256 in range(MAX_FLOATS):
            b: int256 = 0
            j_val: int256 = 0
            b, j_val = self.float_value(j)
            c: int256 = FloatLib.minus(a, b)
            expected: int256 = FloatLib.normalize_raw(5 * (i_val - j_val), -1)
            assert FloatLib.is_eq(c, expected), "sub"


@external
@pure
def multiply_checks():
    for i: uint256 in range(MAX_FLOATS):
        a: int256 = 0
        i_val: int256 = 0
        a, i_val = self.float_value(i)
        for j: uint256 in range(MAX_FLOATS):
            b: int256 = 0
            j_val: int256 = 0
            b, j_val = self.float_value(j)
            c: int256 = FloatLib.times(a, b)
            expected: int256 = FloatLib.normalize_raw(25 * (i_val * j_val), -2)
            assert FloatLib.is_eq(c, expected), "mul"


@external
@pure
def divide_checks():
    for i: uint256 in range(MAX_FLOATS):
        a: int256 = 0
        i_val: int256 = 0
        a, i_val = self.float_value(i)
        for j: uint256 in range(MAX_FLOATS):
            b: int256 = 0
            _j_val: int256 = 0
            b, _j_val = self.float_value(j)
            if FloatLib.is_zero(b):
                continue
            c: int256 = FloatLib.times(FloatLib.divide(a, b), b)
            expected: int256 = FloatLib.normalize_raw(5 * i_val, -1)
            assert FloatLib.is_eq(FloatLib.round_digits(c, ROUND_DIGITS), FloatLib.round_digits(expected, ROUND_DIGITS)), "div"


@external
@pure
def log_exp_checks():
    for i: uint256 in range(MAX_FLOATS):
        f: int256 = 0
        _i_val: int256 = 0
        f, _i_val = self.float_value(i)
        if FloatLib.is_leq(f, FloatLib.ZERO):
            continue
        l: int256 = FloatLib.ln(f)
        e: int256 = FloatLib.exp(l)
        assert FloatLib.is_eq(
            FloatLib.round_digits(e, LOG_DIGITS),
            FloatLib.round_digits(f, LOG_DIGITS),
        ), "log/exp"


@external
def exp_checks():
    print("exp(1e6):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(1, 6))), hardhat_compat=True)
    print("exp(1e-18):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(1, -18))), hardhat_compat=True)
    print("exp(1e-17):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(1, -17))), hardhat_compat=True)
    print("exp(1e-16):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(1, -16))), hardhat_compat=True)
    print("exp(1e-15):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(1, -15))), hardhat_compat=True)
    print("exp(1e-5):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(1, -5))), hardhat_compat=True)
    print("exp(-1e6):", FloatStrings.float_to_string(FloatLib.exp(FloatLib.normalize_raw(-1, 6))), hardhat_compat=True)