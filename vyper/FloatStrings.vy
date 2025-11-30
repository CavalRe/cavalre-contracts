# -------------------------------------------------------------------
# Scientific-notation printer for a packed Float (int256)
#  - 21 significant digits in mantissa
#  - drop trailing zeros in fractional part
#  - val interpreted as m * 10^e
# -------------------------------------------------------------------

import FloatLib as FloatLib

DIGITS: constant(Bytes[10]) = b"0123456789"

@internal
@pure
def int_to_bytes(val: int256) -> Bytes[78]:
    """
    Convert signed int256 to base-10 bytes.
    """
    if val == 0:
        return b"0"

    negative: bool = False
    v: uint256 = 0

    if val < 0:
        negative = True
        v = convert(-val, uint256)
    else:
        v = convert(val, uint256)

    # build digits
    digits: Bytes[78] = b""

    for i: uint256 in range(78):
        if v == 0:
            break
        digit: uint256 = v % 10
        v = v // 10
        digit_byte: Bytes[1] = slice(DIGITS, digit, 1)
        digits = convert(concat(digit_byte, digits), Bytes[78])

    if negative:
        digits = convert(concat(b"-", digits), Bytes[78])

    return digits

@internal
@pure
def int_to_string(val: int256) -> String[78]:
    """
    Convert signed int256 to base-10 string.
    """
    b: Bytes[78] = self.int_to_bytes(val)
    return convert(b, String[78])

@internal  # used via internal library calls in Vyper tests/contracts; not pure because of debug logs
def float_to_string(a: int256) -> String[128]:
    """
    Unpack packed Float(int256) -> scientific notation string
    with up to 21 significant digits in mantissa.
    Simpler safe formatting to avoid overflows/reverts.
    """
    # print("float_to_string", hardhat_compat=True)
    norm: int256 = FloatLib.normalize(a)
    parts: FloatLib.FloatParts = FloatLib.unpack(norm)
    m: int256 = parts.mantissa
    e: int256 = parts.exponent
    # print("mantissa", m, hardhat_compat=True)
    # print("exponent", e, hardhat_compat=True)
    if m == 0:
        return "0e0"

    negative: bool = False
    if m < 0:
        negative = True
        m = -m

    m_str: String[78] = self.int_to_string(m)
    # print("mantissa string", m_str, hardhat_compat=True)
    m_bytes: Bytes[78] = self.int_to_bytes(m)
    m_len: uint256 = len(m_bytes)
    # print("mantissa length", m_len, hardhat_compat=True)

    # leading digit
    ld: Bytes[1] = slice(m_bytes, 0, 1)
    # print("leading digit", convert(ld, String[1]), hardhat_compat=True)

    # fractional digits (trim trailing zeros)
    zero_byte: Bytes[1] = slice(DIGITS, 0, 1)
    frac: Bytes[78] = b""
    if m_len > 1:
        frac = slice(m_bytes, 1, m_len - 1)
        # print("fraction before trim", convert(frac, String[78]), hardhat_compat=True)
        frac_len: uint256 = len(frac)
        # print("fraction length before trim", frac_len, hardhat_compat=True)
        trimmed: uint256 = 0
        for i: uint256 in range(78):
            if i >= frac_len:
                break
            idx: uint256 = frac_len - 1 - i
            if slice(frac, idx, 1) != zero_byte:
                trimmed = idx + 1
                break
        frac = slice(frac, 0, trimmed)

    # print("fraction after trim", convert(frac, String[78]), hardhat_compat=True)
    exp_val: int256 = e + convert(m_len, int256) - 1
    # print("exponent value", exp_val, hardhat_compat=True)
    exp_bytes: Bytes[80] = self.int_to_bytes(exp_val)

    out: Bytes[128] = b""
    if negative:
        out = convert(concat(out, b"-"), Bytes[128])
    out = convert(concat(out, ld), Bytes[128])
    if len(frac) > 0:
        out = convert(concat(out, b"."), Bytes[128])
        out = convert(concat(out, frac), Bytes[128])
    out = convert(concat(out, b"e"), Bytes[128])
    out = convert(concat(out, exp_bytes), Bytes[128])

    # print("final output", convert(out, String[128]), hardhat_compat=True)

    return convert(out, String[128])
