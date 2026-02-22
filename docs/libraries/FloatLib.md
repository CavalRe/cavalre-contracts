# FloatLib

`libraries/FloatLib.sol` provides CavalRe’s custom decimal floating representation and arithmetic helpers.

## Overview

`Float` is a user-defined value type over `int256`:

```solidity
type Float is int256;
```

The packed format stores:

- signed exponent in high 128 bits
- signed mantissa in low 128 bits

Library helpers provide conversions, normalization, comparisons, and arithmetic over that representation.

## Key Capabilities

- conversion between integer amounts and `Float` with decimal-aware helpers
- normalization to keep mantissa/exponent within canonical bounds
- arithmetic (`add`, `subtract`, `multiply`, `divide`, `fullMulDiv`)
- comparisons and sign helpers (`isZero`, `isPositive`, `isNegative`, etc.)
- exponentials/log helpers used by protocol math

## Source Of Truth

For exact function signatures and semantics, use generated API docs:

- `docs/api/src/libraries/FloatLib.sol/library.FloatLib.md`
- `docs/api/src/libraries/FloatLib.sol/type.Float.md`
