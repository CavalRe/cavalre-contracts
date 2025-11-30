# @version 0.4.3
"""
Vyper port of FloatLib.sol using packed int256 floats (exponent << 72 | mantissa).
All major ops present; pow/sqrt built on exp/ln approximations.
"""

struct FloatParts:
    mantissa: int256
    exponent: int256

SIGNIFICANT_DIGITS: constant(uint256) = 21
NORMALIZED_MANTISSA_MAX: constant(uint256) = 10 ** SIGNIFICANT_DIGITS - 1
NORMALIZED_MANTISSA_MIN: constant(uint256) = 10 ** (SIGNIFICANT_DIGITS - 1)
MANTISSA_BITS: constant(uint256) = 72
MANTISSA_MASK: constant(uint256) = (1 << MANTISSA_BITS) - 1

ONE_MANTISSA: constant(int256) = 100000000000000000000
ONE_EXPONENT: constant(int256) = 0 - 20

PI: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | 314159265358979323846

LOG10_WAD: constant(int256) = 2302585092994045684
LOG10: constant(int256) = ((-18) << MANTISSA_BITS) | LOG10_WAD
NEG_18: constant(int256) = 0 - 18

ZERO: constant(int256) = 0
ONE: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | ONE_MANTISSA
TWO: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (2 * ONE_MANTISSA)
THREE: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (3 * ONE_MANTISSA)
FOUR: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (4 * ONE_MANTISSA)
FIVE: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (5 * ONE_MANTISSA)
SIX: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (6 * ONE_MANTISSA)
SEVEN: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (7 * ONE_MANTISSA)
EIGHT: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (8 * ONE_MANTISSA)
NINE: constant(int256) = (ONE_EXPONENT << MANTISSA_BITS) | (9 * ONE_MANTISSA)
TEN: constant(int256) = ((ONE_EXPONENT + 1) << MANTISSA_BITS) | ONE_MANTISSA
HALF: constant(int256) = ((ONE_EXPONENT - 1) << MANTISSA_BITS) | (5 * ONE_MANTISSA)


@internal
@pure
def unpack(a: int256) -> FloatParts:
    # extract mantissa/exponent from packed int256 (mantissa stored in low 72 bits, sign preserved)
    raw: int256 = a
    shift_bits: uint256 = 256 - MANTISSA_BITS
    m: int256 = raw << shift_bits
    m = m >> shift_bits
    e: int256 = raw >> MANTISSA_BITS
    return FloatParts(mantissa=m, exponent=e)


@internal
@pure
def pack(parts: FloatParts) -> int256:
    packed: int256 = (parts.exponent << MANTISSA_BITS) | (parts.mantissa & convert(MANTISSA_MASK, int256))
    return packed


@internal
@pure
def to_int(a: int256, decimals: uint8) -> int256:
    m: int256 = self.mantissa(a)
    e: int256 = self.exponent(a) + convert(decimals, int256)
    if e >= 0:
        return m * convert(10 ** convert(e, uint256), int256)
    else:
        return m // convert(10 ** convert(0 - e, uint256), int256)


@internal
@pure
def to_int18(a: int256) -> int256:
    return self.to_int(a, 18)


@internal
@pure
def to_uint(a: int256, decimals: uint8) -> uint256:
    m: int256 = self.mantissa(a)
    assert m >= 0, "Value must be non-negative"
    e: int256 = self.exponent(a) + convert(decimals, int256)
    if e >= 0:
        return convert(m, uint256) * 10 ** convert(e, uint256)
    else:
        return convert(m, uint256) // 10 ** convert(0 - e, uint256)


@internal
@pure
def to_uint18(a: int256) -> uint256:
    return self.to_uint(a, 18)


@internal
@pure
def to_float(u: uint256, decimals: uint8) -> int256:
    return self.normalize_raw(convert(u, int256), 0 - convert(decimals, int256))


@internal
@pure
def to_float18(u: uint256) -> int256:
    return self.to_float(u, 18)


@internal
@pure
def is_eq(a: int256, b: int256) -> bool:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.mantissa(aa) == self.mantissa(bb)


@internal
@pure
def is_gt(a: int256, b: int256) -> bool:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.mantissa(aa) > self.mantissa(bb)


@internal
@pure
def is_geq(a: int256, b: int256) -> bool:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.mantissa(aa) >= self.mantissa(bb)


@internal
@pure
def is_lt(a: int256, b: int256) -> bool:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.mantissa(aa) < self.mantissa(bb)


@internal
@pure
def is_leq(a: int256, b: int256) -> bool:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.mantissa(aa) <= self.mantissa(bb)


@internal
@pure
def is_zero(a: int256) -> bool:
    return self.mantissa(a) == 0


@internal
@pure
def abs_val(a: int256) -> int256:
    parts: FloatParts = self.unpack(a)
    if parts.mantissa >= 0:
        return a
    return self.from_parts(0 - parts.mantissa, parts.exponent)


@internal
@pure
def decimal_shift(a: int256, i: int256) -> int256:
    m: int256 = self.mantissa(a)
    if i == 0 or m == 0:
        return a
    s: int256 = i
    e: int256 = self.exponent(a) + i
    if s > 0:
        m //= convert(10 ** convert(s, uint256), int256)
    else:
        s = 0 - s
        assert s <= convert(SIGNIFICANT_DIGITS, int256), "shift: |i| too large"
        m *= convert(10 ** convert(s, uint256), int256)
    return self.from_parts(m, e)


@internal
@pure
def normalize_raw(mantissa_: int256, exponent_: int256) -> int256:
    # rescale mantissa into [1e20, 1e21-1] while adjusting exponent
    if mantissa_ == 0:
        return ZERO
    mag: uint256 = convert(abs(mantissa_), uint256)
    for _i: uint256 in range(64):
        if mag > NORMALIZED_MANTISSA_MAX:
            mantissa_ //= 10
            exponent_ += 1
            mag //= 10
        else:
            break
    for _j: uint256 in range(64):
        if mag < NORMALIZED_MANTISSA_MIN:
            mantissa_ *= 10
            exponent_ -= 1
            mag *= 10
        else:
            break
    return self.from_parts(mantissa_, exponent_)


@internal
@pure
def normalize(a: int256) -> int256:
    parts: FloatParts = self.unpack(a)
    return self.normalize_raw(parts.mantissa, parts.exponent)


@internal
@pure
def align(a: int256, b: int256) -> (int256, int256):
    # align exponents for addition/subtraction; overflows to zero if gap exceeds SIGNIFICANT_DIGITS
    ap: FloatParts = self.unpack(a)
    bp: FloatParts = self.unpack(b)
    if ap.mantissa == 0 and bp.mantissa == 0:
        return (ZERO, ZERO)
    elif ap.mantissa == 0:
        return (self.from_parts(0, bp.exponent), self.from_parts(bp.mantissa, bp.exponent))
    elif bp.mantissa == 0:
        return (self.from_parts(ap.mantissa, ap.exponent), self.from_parts(0, ap.exponent))
    na: int256 = self.normalize(a)
    nb: int256 = self.normalize(b)
    na_parts: FloatParts = self.unpack(na)
    nb_parts: FloatParts = self.unpack(nb)
    delta: int256 = na_parts.exponent - nb_parts.exponent
    if delta >= 0:
        if delta > convert(SIGNIFICANT_DIGITS, int256):
            return (na, self.from_parts(0, na_parts.exponent))
        return (na, self.decimal_shift(nb, delta))
    else:
        if 0 - delta > convert(SIGNIFICANT_DIGITS, int256):
            return (self.from_parts(0, nb_parts.exponent), nb)
        return (self.decimal_shift(na, 0 - delta), nb)


@internal
@pure
def plus(a: int256, b: int256) -> int256:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.normalize_raw(self.mantissa(aa) + self.mantissa(bb), self.exponent(aa))


@internal
@pure
def minus_unary(a: int256) -> int256:
    return self.from_parts(0 - self.mantissa(a), self.exponent(a))


@internal
@pure
def minus(a: int256, b: int256) -> int256:
    aa: int256 = 0
    bb: int256 = 0
    aa, bb = self.align(a, b)
    return self.normalize_raw(self.mantissa(aa) - self.mantissa(bb), self.exponent(aa))


@internal
@pure
def times(a: int256, b: int256) -> int256:
    na: int256 = self.normalize(a)
    nb: int256 = self.normalize(b)
    ma: int256 = self.mantissa(na)
    mb: int256 = self.mantissa(nb)
    return self.normalize_raw(
        (ma * mb) // convert(10 ** SIGNIFICANT_DIGITS, int256),
        convert(SIGNIFICANT_DIGITS, int256) + self.exponent(na) + self.exponent(nb),
    )


@internal
@pure
def divide(a: int256, b: int256) -> int256:
    na: int256 = self.normalize(a)
    nb: int256 = self.normalize(b)
    ma: int256 = self.mantissa(na)
    mb: int256 = self.mantissa(nb)
    return self.normalize_raw(
        (ma * convert(10 ** SIGNIFICANT_DIGITS, int256)) // mb,
        self.exponent(na) - self.exponent(nb) - convert(SIGNIFICANT_DIGITS, int256),
    )


@internal
@pure
def round_digits(a: int256, digits: uint256) -> int256:
    if self.mantissa(a) == 0:
        return ZERO
    if digits >= SIGNIFICANT_DIGITS:
        return self.normalize(a)
    norm: int256 = self.normalize(a)
    factor: int256 = convert(10 ** (SIGNIFICANT_DIGITS - digits), int256)
    m: int256 = self.mantissa(norm)
    scaled: int256 = m // factor
    remainder: int256 = m % factor
    if remainder * 2 >= factor:
        scaled += 1
    if remainder * 2 <= 0 - factor:
        scaled -= 1
    return self.from_parts(scaled * factor, self.exponent(norm))


@internal
@pure
def parts(a: int256) -> (int256, int256):
    norm: int256 = self.normalize(a)
    np: FloatParts = self.unpack(norm)
    if np.mantissa == 0:
        return (ZERO, ZERO)
    if np.exponent >= 0:
        return (norm, ZERO)
    if convert(SIGNIFICANT_DIGITS, int256) + np.exponent < 0:
        return (ZERO, norm)
    div_: int256 = convert(10 ** convert(0 - np.exponent, uint256), int256)
    integer_part: int256 = self.normalize_raw(np.mantissa // div_, 0)
    return (integer_part, self.minus(norm, integer_part))


@internal
@pure
def exp(a: int256) -> int256:
    # exp(x) via base-10 decomposition: exp(x) = 10^(x / ln 10)
    y: int256 = self.divide(a, LOG10)
    y_int: int256 = 0
    y_frac: int256 = 0
    y_int, y_frac = self.parts(y)
    wad: int256 = self.to_int(self.times(y_frac, LOG10), 18)
    m: int256 = self.exp_wad(wad)
    e: int256 = self.to_int(y_int, 0) - 18
    return self.normalize_raw(m, e)


@internal
@pure
def exp_wad(x: int256) -> int256:
    # Credit: Solady FixedPointMathLib.expWad
    if x <= 0 - 41446531673892822313:
        return 0
    assert x < 135305999368893231589, "expWad overflow"

    x = (x << 78) // 5 ** 18

    k: int256 = ((x << 96) // 54916777467707473351141471128 + 2 ** 95) >> 96
    x -= k * 54916777467707473351141471128

    y: int256 = x + 1346386616545796478920950773328
    y = ((y * x) >> 96) + 57155421227552351082224309758442
    p: int256 = y + x - 94201549194550492254356042504812
    p = ((p * y) >> 96) + 28719021644029726153956944680412240
    p = p * x + (4385272521454847904659076985693276 << 96)

    q: int256 = x - 2855989394907223263936484059900
    q = ((q * x) >> 96) + 50020603652535783019961831881945
    q = ((q * x) >> 96) - 533845033583426703283633433725380
    q = ((q * x) >> 96) + 3604857256930695427073651918091429
    q = ((q * x) >> 96) - 14423608567350463180887372962807573
    q = ((q * x) >> 96) + 26449188498355588339934803723976023

    r: int256 = p // q
    r = convert(
        (convert(r, uint256) * 3822833074963236453042738258902158003155416615667)
        >> convert(195 - k, uint256),
        int256,
    )
    return r


@internal
@pure
def ln(a: int256) -> int256:
    # natural log via ln(m * 10^e) = ln(m) + e * ln(10)
    x: int256 = self.normalize(a)
    m: int256 = 0
    e: int256 = 0
    m, e = self.components(x)
    assert m > 0, "log non-positive"
    ln_wad_value: int256 = self.ln_wad(m * 10 ** 18) + e * LOG10_WAD
    return self.normalize_raw(ln_wad_value, NEG_18)


@internal
@pure
def ln_wad(x: int256) -> int256:
    assert x > 0, "lnWad undefined"

    u0: uint256 = convert(x, uint256)
    n: uint256 = u0
    l: uint256 = 0
    if n >= (1 << 128):
        n >>= 128
        l += 128
    if n >= (1 << 64):
        n >>= 64
        l += 64
    if n >= (1 << 32):
        n >>= 32
        l += 32
    if n >= (1 << 16):
        n >>= 16
        l += 16
    if n >= (1 << 8):
        n >>= 8
        l += 8
    if n >= (1 << 4):
        n >>= 4
        l += 4
    if n >= (1 << 2):
        n >>= 2
        l += 2
    if n >= (1 << 1):
        l += 1

    r: int256 = convert(255 - l, int256)
    x96: int256 = convert((u0 << convert(r, uint256)) >> 159, int256)

    p: int256 = x96 + 3273285459638523848632254066296
    p = ((p * x96) >> 96) + 24828157081833163892658089445524
    p = ((p * x96) >> 96) + 43456485725739037958740375743393
    p = (p * x96) >> 96
    p -= 11111509109440967052023855526967
    p = (p * x96) >> 96
    p -= 45023709667254063763336534515857
    p = (p * x96) >> 96
    p -= 14706773417378608786704636184526
    p = p * x96 - (795164235651350426258249787498 << 96)

    q: int256 = x96 + 5573035233440673466300451813936
    q = ((q * x96) >> 96) + 71694874799317883764090561454958
    q = ((q * x96) >> 96) + 283447036172924575727196451306956
    q = ((q * x96) >> 96) + 401686690394027663651624208769553
    q = ((q * x96) >> 96) + 204048457590392012362485061816622
    q = ((q * x96) >> 96) + 31853899698501571402653359427138
    q = ((q * x96) >> 96) + 909429971244387300277376558375

    p = p // q

    p = p * 1677202110996718588342820967067443963516166
    p += 16597577552685614221487285958193947469193820559219878177908093499208371 * (159 - r)
    p += 600920179829731861736702779321621459595472258049074101567377883020018308

    return p >> 174


@internal
@pure
def pow_uint(base: int256, e: uint256) -> int256:
    if e == 0:
        return ONE
    b: int256 = self.normalize(base)
    if e == 1:
        return b
    if self.mantissa(b) == 0:
        return ZERO
    if self.is_eq(b, ONE):
        return ONE
    result: int256 = ONE
    exp_: uint256 = e
    for _k: uint256 in range(256):
        if exp_ == 0:
            break
        if exp_ & 1 == 1:
            result = self.times(result, b)
        exp_ >>= 1
        if exp_ != 0:
            b = self.times(b, b)
    return result


@internal
@pure
def pow_int(base: int256, e: int256) -> int256:
    b: int256 = self.normalize(base)
    if e >= 0:
        return self.pow_uint(b, convert(e, uint256))
    assert self.mantissa(b) != 0, "pow: zero base"
    exp_abs: uint256 = convert(0 - e, uint256)
    pos: int256 = self.pow_uint(b, exp_abs)
    return self.divide(ONE, pos)


@internal
@pure
def pow(base: int256, e: int256) -> int256:
    b: int256 = self.normalize(base)
    if self.mantissa(e) == 0:
        return ONE
    if self.is_eq(b, ONE):
        return ONE
    assert self.mantissa(b) > 0, "pow: base must be positive"
    return self.exp(self.times(self.ln(b), e))


@internal
@pure
def sqrt(a: int256) -> int256:
    return self.exp(self.divide(self.ln(a), TWO))


@internal
@pure
def full_mul_div(a: int256, b: int256, c: int256) -> int256:
    neg: bool = False
    if self.mantissa(a) < 0:
        a = self.minus_unary(a)
        neg = not neg
    if self.mantissa(b) < 0:
        b = self.minus_unary(b)
        neg = not neg
    if self.mantissa(c) < 0:
        c = self.minus_unary(c)
        neg = not neg
    n: int256 = self.divide(self.times(a, b), c)
    if neg:
        return self.minus_unary(n)
    return n


@internal
@pure
def from_parts(mantissa_: int256, exponent_: int256) -> int256:
    return self.pack(FloatParts(mantissa=mantissa_, exponent=exponent_))


@internal
@pure
def components(a: int256) -> (int256, int256):
    p: FloatParts = self.unpack(a)
    return (p.mantissa, p.exponent)


@internal
@pure
def mantissa(a: int256) -> int256:
    return self.unpack(a).mantissa


@internal
@pure
def exponent(a: int256) -> int256:
    return self.unpack(a).exponent
