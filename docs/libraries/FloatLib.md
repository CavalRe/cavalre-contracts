# FloatLib

`libraries/FloatLib.sol` provides CavalRe’s custom decimal floating representation and arithmetic helpers.

## Overview

`Float` is a user-defined value type over `int256`:

```solidity
type Float is int256;
```

The packed format stores:

- signed base-10 exponent in the high bits
- signed mantissa in the low 72 bits

Library helpers provide conversions, normalization, comparisons, and arithmetic over that representation.

## Key Capabilities

- conversion between integer amounts and `Float` with decimal-aware helpers
- normalization to keep mantissa/exponent within canonical bounds
- arithmetic (`add`, `subtract`, `multiply`, `divide`, `fullMulDiv`)
- comparisons and sign helpers (`isZero`, `isPositive`, `isNegative`, etc.)
- exponentials/log helpers used by protocol math

Current constants target 21 significant digits (`SIGNIFICANT_DIGITS = 21`).

## Source Of Truth

For exact function signatures and semantics, use generated API docs:

- `docs/api/src/libraries/FloatLib.sol/library.FloatLib.md`
- `docs/api/src/libraries/FloatLib.sol/type.Float.md`
