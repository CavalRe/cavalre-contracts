# FloatLib

`FloatLib` is a critical math library designed to enable safe and precise computations across extremely large and small numeric ranges using a custom floating-point representation. It plays a foundational role in Multiswap's internal logic, where value preservation, numerical stability, and scale invariance are essential.

## Overview

At its core, `FloatLib` defines a `Float` struct:

```solidity
struct Float {
    int256 mantissa;
    int256 exponent;
}
````

This structure enables values to be represented as:

```
value = mantissa × 10^exponent
```

By working in base-10 scientific notation, `FloatLib` maintains high precision while gracefully handling overflows and underflows that would occur with fixed-point math alone.

## Key Features

* **Custom base-10 float representation**: Enables consistent rounding and human-readable scale.
* **Normalization**: Ensures mantissas are kept within a consistent range for comparison and arithmetic.
* **Safe conversions**: Between integers, fixed-point values, and floats with safeguards against overflow.
* **Arithmetic operations**: Addition, subtraction, multiplication, and division of floats with automatic normalization.
* **Advanced utilities**:

  * Logarithmic operations
  * Exponent scaling
  * Comparison functions (`min`, `max`, `eq`, `gt`, etc.)
* **Solady-backed performance**: Integrates `FixedPointMathLib` from Solady for efficient low-level math operations.

## Use Cases

* **Value-preserving AMM mechanics**: Used extensively in Multiswap to handle swaps, allocations, and rebalancing over arbitrary asset scales.
* **Fee and price calculations**: Avoids rounding errors and inconsistent behavior across asset pairs with different decimal precisions.
* **Protocol safety**: Prevents critical bugs stemming from overflow or precision loss in multi-asset systems.

## Example

```solidity
import {FloatLib, Float} from "path/to/FloatLib.sol";

Float memory a = FloatLib.toFloat(123456789, 6); // represents 123.456789
Float memory b = FloatLib.toFloat(1000, 0);      // represents 1000

Float memory c = FloatLib.mul(a, b);             // precise multiplication
int256 asInt = FloatLib.toInt(c, 18);            // convert back to int with 18 decimals
```

## Limitations

* Not compatible with Solidity's native operators (`+`, `*`, etc.) — must use library functions.
* Requires careful normalization and rounding when used outside the library to avoid subtle bugs.

## License

MIT