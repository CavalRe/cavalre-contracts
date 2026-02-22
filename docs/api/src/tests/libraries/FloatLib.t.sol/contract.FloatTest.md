# FloatTest
[Git Source](https://github.com/CavalRe/cavalre-contracts/blob/4beb1bb5ec51300e77fe11434272324aa08bfb7c/tests/libraries/FloatLib.t.sol)

**Inherits:**
[Test](/node_modules/forge-std/src/Test.sol/abstract.Test.md)


## State Variables
### ZERO

```solidity
Float internal ZERO
```


### HALF

```solidity
Float internal HALF
```


### ONE

```solidity
Float internal ONE
```


### TWO

```solidity
Float internal TWO
```


### THREE

```solidity
Float internal THREE
```


### FOUR

```solidity
Float internal FOUR
```


### FIVE

```solidity
Float internal FIVE
```


### SIX

```solidity
Float internal SIX
```


### SEVEN

```solidity
Float internal SEVEN
```


### EIGHT

```solidity
Float internal EIGHT
```


### NINE

```solidity
Float internal NINE
```


### TEN

```solidity
Float internal TEN
```


### ONEnHALF

```solidity
Float internal ONEnHALF
```


### TWOnHALF

```solidity
Float internal TWOnHALF
```


### THREEnHALF

```solidity
Float internal THREEnHALF
```


### FOURnHALF

```solidity
Float internal FOURnHALF
```


### FIVEnHALF

```solidity
Float internal FIVEnHALF
```


### SIXnHALF

```solidity
Float internal SIXnHALF
```


### SEVENnHALF

```solidity
Float internal SEVENnHALF
```


### EIGHTnHALF

```solidity
Float internal EIGHTnHALF
```


### NINEnHALF

```solidity
Float internal NINEnHALF
```


### a

```solidity
Float internal a
```


### b

```solidity
Float internal b
```


### c

```solidity
Float internal c
```


### ZERO_unnormalized

```solidity
Float internal ZERO_unnormalized
```


### HALF_unnormalized

```solidity
Float internal HALF_unnormalized
```


### ONE_unnormalized

```solidity
Float internal ONE_unnormalized
```


### TWO_unnormalized

```solidity
Float internal TWO_unnormalized
```


### mantissaZERO

```solidity
int256 internal mantissaZERO
```


### exponentZERO

```solidity
int256 internal exponentZERO
```


### mantissaHALF

```solidity
int256 internal mantissaHALF
```


### exponentHALF

```solidity
int256 internal exponentHALF
```


### mantissaONE

```solidity
int256 internal mantissaONE
```


### exponentONE

```solidity
int256 internal exponentONE
```


### mantissaTWO

```solidity
int256 internal mantissaTWO
```


### exponentTWO

```solidity
int256 internal exponentTWO
```


### mantissaZERO_unnormalized

```solidity
int256 internal mantissaZERO_unnormalized
```


### exponentZERO_unnormalized

```solidity
int256 internal exponentZERO_unnormalized
```


### mantissaHALF_unnormalized

```solidity
int256 internal mantissaHALF_unnormalized
```


### exponentHALF_unnormalized

```solidity
int256 internal exponentHALF_unnormalized
```


### mantissaONE_unnormalized

```solidity
int256 internal mantissaONE_unnormalized
```


### exponentONE_unnormalized

```solidity
int256 internal exponentONE_unnormalized
```


### mantissaTWO_unnormalized

```solidity
int256 internal mantissaTWO_unnormalized
```


### exponentTWO_unnormalized

```solidity
int256 internal exponentTWO_unnormalized
```


## Functions
### assertEq


```solidity
function assertEq(Float x, Float y) internal pure;
```

### setUp


```solidity
function setUp() public;
```

### getFloats


```solidity
function getFloats() public view returns (Float[] memory);
```

### testFloatToString


```solidity
function testFloatToString() public;
```

### testFloatGasBlank


```solidity
function testFloatGasBlank() public pure;
```

### testFloatGasNormalize


```solidity
function testFloatGasNormalize() public view;
```

### testFloatGasNormalizeNormalized


```solidity
function testFloatGasNormalizeNormalized() public view;
```

### testFloatGasAlign


```solidity
function testFloatGasAlign() public view;
```

### testFloatGasAdd


```solidity
function testFloatGasAdd() public view;
```

### testFloatGasSub


```solidity
function testFloatGasSub() public view;
```

### testFloatGasMul


```solidity
function testFloatGasMul() public view;
```

### testFloatGasDiv


```solidity
function testFloatGasDiv() public view;
```

### testFloatNormalize


```solidity
function testFloatNormalize() public view;
```

### testFloatAlign


```solidity
function testFloatAlign() public;
```

### testFloatONE


```solidity
function testFloatONE() public;
```

### testFloatAdd


```solidity
function testFloatAdd() public;
```

### testFloatSubtract


```solidity
function testFloatSubtract() public;
```

### testFloatMultiply


```solidity
function testFloatMultiply() public;
```

### testFloatDivide


```solidity
function testFloatDivide() public;
```

### testFloatLogExp


```solidity
function testFloatLogExp() public view;
```

### testFloatExp


```solidity
function testFloatExp() public;
```

