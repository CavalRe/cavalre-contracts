# FloatLib
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/b96f8602f431eb4f1948c1233246d58b344ea36f/src/libraries/FloatLib/FloatLib.sol)


## State Variables
### SIGNIFICANT_DIGITS
Constants   *


```solidity
uint256 constant SIGNIFICANT_DIGITS = 18;
```


### NORMALIZED_MANTISSA_MAX

```solidity
uint256 constant NORMALIZED_MANTISSA_MAX = 10 ** SIGNIFICANT_DIGITS - 1;
```


### NORMALIZED_MANTISSA_MIN

```solidity
uint256 constant NORMALIZED_MANTISSA_MIN = 10 ** (SIGNIFICANT_DIGITS - 1);
```


### _LOG10

```solidity
int256 constant _LOG10 = 2302585092994045684;
```


## Functions
### toInt

Conversions   *


```solidity
function toInt(uint256 a) internal pure returns (int256);
```

### toInt


```solidity
function toInt(Float memory a, uint256 decimals) internal pure returns (int256);
```

### toInt


```solidity
function toInt(Float memory a) internal pure returns (int256);
```

### toUInt


```solidity
function toUInt(int256 a) internal pure returns (uint256);
```

### toUInt


```solidity
function toUInt(Float memory a, uint256 decimals) internal pure returns (uint256);
```

### toUInt


```solidity
function toUInt(Float memory a) internal pure returns (uint256);
```

### toFloat


```solidity
function toFloat(int256 a, uint256 decimals) internal pure returns (Float memory);
```

### toFloat


```solidity
function toFloat(int256 a) internal pure returns (Float memory);
```

### toFloatArray


```solidity
function toFloatArray(int256[] memory a, uint256[] memory decimals) internal pure returns (Float[] memory);
```

### toFloatArray


```solidity
function toFloatArray(int256[] memory a) internal pure returns (Float[] memory);
```

### isEQ

Comparisons   *


```solidity
function isEQ(Float memory a, Float memory b) internal pure returns (bool);
```

### isGT


```solidity
function isGT(Float memory a, Float memory b) internal pure returns (bool);
```

### isGEQ


```solidity
function isGEQ(Float memory a, Float memory b) internal pure returns (bool);
```

### isLT


```solidity
function isLT(Float memory a, Float memory b) internal pure returns (bool);
```

### isLEQ


```solidity
function isLEQ(Float memory a, Float memory b) internal pure returns (bool);
```

### abs

Transformations   *


```solidity
function abs(Float memory a) internal pure returns (Float memory);
```

### integerPart


```solidity
function integerPart(Float memory number) internal pure returns (Float memory);
```

### shift


```solidity
function shift(Float memory a, int256 i) internal pure returns (Float memory);
```

### normalize


```solidity
function normalize(int256 mantissa, int256 exponent) internal pure returns (Float memory);
```

### normalize


```solidity
function normalize(Float memory a) internal pure returns (Float memory);
```

### align


```solidity
function align(Float memory a, Float memory b) internal pure returns (Float memory, Float memory);
```

### plus

Arithmetic   *


```solidity
function plus(Float memory a, Float memory b) internal pure returns (Float memory);
```

### minus


```solidity
function minus(Float memory a) internal pure returns (Float memory);
```

### minus


```solidity
function minus(Float memory a, Float memory b) internal pure returns (Float memory);
```

### times


```solidity
function times(Float memory a, Float memory b) internal pure returns (Float memory);
```

### divide


```solidity
function divide(Float memory a, Float memory b) internal pure returns (Float memory);
```

### round

Special functions


```solidity
function round(Float memory a, uint256 digits) internal pure returns (Float memory);
```

### exp


```solidity
function exp(int256 a) internal pure returns (Float memory);
```

### log


```solidity
function log(Float memory a) internal pure returns (int256);
```

### cubicsolve


```solidity
function cubicsolve(Float memory b, Float memory c, Float memory d) internal pure returns (Float memory x);
```

### fullMulDiv


```solidity
function fullMulDiv(Float memory a, Float memory b, Float memory c) internal pure returns (Float memory);
```

## Errors
### NoSolution

```solidity
error NoSolution();
```

## Structs
### Cubic

```solidity
struct Cubic {
    Float p;
    Float q;
    Float rad;
    Float u;
    Float w;
}
```

