# -------------------------------------------------------------------
# Scientific-notation printer for a packed Float (int256)
#  - 21 significant digits in mantissa
#  - drop trailing zeros in fractional part
#  - val interpreted as m * 10^e
# -------------------------------------------------------------------

import libraries.FloatLib as FloatLib

DIGITS: constant(Bytes[10]) = b"0123456789"


@internal
@pure
def int_to_string(val: int256) -> String[80]:
    """
    Convert signed int256 to base-10 string.
    """
    if val == 0:
        return "0"

    negative: bool = False
    v: uint256 = 0

    if val < 0:
        negative = True
        v = convert(-val, uint256)
    else:
        v = convert(val, uint256)

    # build digits in reverse
    reversed_digits: Bytes[79] = b""

    for _: uint256 in range(78):
        if v == 0:
            break
        digit: uint256 = v % 10
        v = v // 10
        reversed_digits = slice(
            concat(
                reversed_digits,
                slice(DIGITS, digit, 1)
            ),
            0,
            79
        )

    out_bytes: Bytes[79] = b""
    l: int128 = convert(len(reversed_digits), int128)
    l_u: uint256 = convert(l, uint256)

    for i: uint256 in range(78):
        if i >= l_u:
            break
        out_bytes = slice(
            concat(
                out_bytes,
                slice(reversed_digits, convert(l - 1 - convert(i, int128), uint256), 1)
            ),
            0,
            79
        )

    if negative:
        out_bytes = slice(concat(b"-", out_bytes), 0, 79)

    return convert(out_bytes, String[80])


@internal
@pure
def float_to_string(a: int256) -> String[128]:
    """
    Unpack packed Float(int256) -> scientific notation string
    with up to 21 significant digits in mantissa.
    Simpler safe formatting to avoid overflows/reverts.
    """
    norm: int256 = FloatLib.normalize(a)
    parts: FloatLib.FloatParts = FloatLib.unpack(norm)
    m: int256 = parts.mantissa
    e: int256 = parts.exponent
    if m == 0:
        return "0e0"

    negative: bool = False
    if m < 0:
        negative = True
        m = 0 - m

    m_str: String[80] = self.int_to_string(m)
    m_bytes: Bytes[80] = convert(m_str, Bytes[80])
    m_len: uint256 = len(m_bytes)

    # leading digit
    ld: Bytes[1] = slice(m_bytes, 0, 1)

    # fractional digits (trim trailing zeros)
    frac: Bytes[80] = b""
    if m_len > 1:
        frac = slice(m_bytes, 1, m_len - 1)
        fb_len: uint256 = len(frac)
        trimmed: uint256 = 0
        zero_byte: Bytes[1] = slice(DIGITS, 0, 1)
        for i: uint256 in range(80):
            if i >= fb_len:
                break
            idx: uint256 = fb_len - 1 - i
            if slice(frac, idx, 1) != zero_byte:
                trimmed = idx + 1
                break
        frac = slice(frac, 0, trimmed)

    exp_val: int256 = e + convert(m_len, int256) - 1
    exp_str: String[80] = self.int_to_string(exp_val)
    exp_bytes: Bytes[80] = convert(exp_str, Bytes[80])

    out: Bytes[128] = b""
    if negative:
        out = slice(concat(out, b"-"), 0, 128)
    out = slice(concat(out, ld), 0, 128)
    if len(frac) > 0:
        out = slice(concat(out, b"."), 0, 128)
        out = slice(concat(out, frac), 0, 128)
    out = slice(concat(out, b"e"), 0, 128)
    out = slice(concat(out, exp_bytes), 0, 128)

    return convert(out, String[128])
