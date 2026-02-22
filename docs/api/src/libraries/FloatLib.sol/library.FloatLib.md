# FloatLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/27a8b6bea99c34fd7ef12952ab488aa1d4998a37/libraries/FloatLib.sol)


## State Variables
### SIGNIFICANT_DIGITS

```solidity
uint256 constant SIGNIFICANT_DIGITS = 21
```


### NORMALIZED_MANTISSA_MAX

```solidity
uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1
```


### NORMALIZED_MANTISSA_MIN

```solidity
uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1)
```


### MANTISSA_BITS

```solidity
uint256 constant MANTISSA_BITS = 72
```


### MANTISSA_MASK

```solidity
uint256 constant MANTISSA_MASK = (uint256(1) << MANTISSA_BITS) - 1
```


### ONE_MANTISSA

```solidity
int256 constant ONE_MANTISSA = int256(10 ** (SIGNIFICANT_DIGITS - 1))
```


### ONE_EXPONENT

```solidity
int256 constant ONE_EXPONENT = -int256(SIGNIFICANT_DIGITS - 1)
```


### PI

```solidity
Float constant PI = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | 314159265358979323846)
```


### LOG10_WAD

```solidity
int256 constant LOG10_WAD = 2302585092994045684
```


### LOG10

```solidity
Float constant LOG10 = Float.wrap((int256(-18) << MANTISSA_BITS) | LOG10_WAD)
```


### ZERO

```solidity
Float constant ZERO = Float.wrap(0)
```


### ONE

```solidity
Float constant ONE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | ONE_MANTISSA)
```


### TWO

```solidity
Float constant TWO = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (2 * ONE_MANTISSA))
```


### THREE

```solidity
Float constant THREE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (3 * ONE_MANTISSA))
```


### FOUR

```solidity
Float constant FOUR = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (4 * ONE_MANTISSA))
```


### FIVE

```solidity
Float constant FIVE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (5 * ONE_MANTISSA))
```


### SIX

```solidity
Float constant SIX = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (6 * ONE_MANTISSA))
```


### SEVEN

```solidity
Float constant SEVEN = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (7 * ONE_MANTISSA))
```


### EIGHT

```solidity
Float constant EIGHT = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (8 * ONE_MANTISSA))
```


### NINE

```solidity
Float constant NINE = Float.wrap((ONE_EXPONENT << MANTISSA_BITS) | (9 * ONE_MANTISSA))
```


### TEN

```solidity
Float constant TEN = Float.wrap(((ONE_EXPONENT + 1) << MANTISSA_BITS) | ONE_MANTISSA)
```


### HALF

```solidity
Float constant HALF = Float.wrap(((ONE_EXPONENT - 1) << MANTISSA_BITS) | (5 * ONE_MANTISSA))
```


## Functions
### toInt


```solidity
function toInt(Float a_, uint8 decimals_) internal pure returns (int256);
```

### toInt


```solidity
function toInt(Float a_) internal pure returns (int256);
```

### toUInt


```solidity
function toUInt(Float a_, uint8 decimals_) internal pure returns (uint256);
```

### toUInt


```solidity
function toUInt(Float a_) internal pure returns (uint256);
```

### toFloat


```solidity
function toFloat(uint256 a_, uint8 decimals_) internal pure returns (Float);
```

### toFloat


```solidity
function toFloat(uint256 a_) internal pure returns (Float);
```

### isEQ


```solidity
function isEQ(Float a_, Float b_) internal pure returns (bool);
```

### isGT


```solidity
function isGT(Float a_, Float b_) internal pure returns (bool);
```

### isGEQ


```solidity
function isGEQ(Float a_, Float b_) internal pure returns (bool);
```

### isLT


```solidity
function isLT(Float a_, Float b_) internal pure returns (bool);
```

### isLEQ


```solidity
function isLEQ(Float a_, Float b_) internal pure returns (bool);
```

### isZero


```solidity
function isZero(Float a_) internal pure returns (bool);
```

### abs


```solidity
function abs(Float a_) internal pure returns (Float);
```

### shift


```solidity
function shift(Float a_, int256 i_) internal pure returns (Float);
```

### normalize


```solidity
function normalize(int256 mantissa_, int256 exponent_) internal pure returns (Float);
```

### normalize


```solidity
function normalize(Float a_) internal pure returns (Float);
```

### align


```solidity
function align(Float a_, Float b_) internal pure returns (Float, Float);
```

### plus


```solidity
function plus(Float a_, Float b_) internal pure returns (Float);
```

### minus


```solidity
function minus(Float a_) internal pure returns (Float);
```

### minus


```solidity
function minus(Float a_, Float b_) internal pure returns (Float);
```

### times


```solidity
function times(Float a_, Float b_) internal pure returns (Float);
```

### divide


```solidity
function divide(Float a_, Float b_) internal pure returns (Float);
```

### round


```solidity
function round(Float a_, uint256 digits_) internal pure returns (Float);
```

### parts


```solidity
function parts(Float number_) internal pure returns (Float _integerPart, Float _fractionalPart);
```

### exp


```solidity
function exp(Float x_) internal pure returns (Float);
```

### log


```solidity
function log(Float x_) internal pure returns (Float);
```

### powUint


```solidity
function powUint(Float base_, uint256 e_) internal pure returns (Float result_);
```

### powInt


```solidity
function powInt(Float base_, int256 e_) internal pure returns (Float);
```

### pow


```solidity
function pow(Float base_, Float e_) internal pure returns (Float);
```

### sqrt


```solidity
function sqrt(Float x_) internal pure returns (Float);
```

### fullMulDiv


```solidity
function fullMulDiv(Float a_, Float b_, Float c_) internal pure returns (Float);
```

### from


```solidity
function from(int256 mantissa_, int256 exponent_) internal pure returns (Float);
```

### components


```solidity
function components(Float a_) internal pure returns (int256 _mantissa, int256 _exponent);
```

### mantissa


```solidity
function mantissa(Float a_) internal pure returns (int256);
```

### exponent


```solidity
function exponent(Float a_) internal pure returns (int256);
```

## Errors
### NoSolution

```solidity
error NoSolution();
```

