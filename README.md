# mathexpr, a math expression evaluator library in Nim [![Build Status](https://travis-ci.org/Yardanico/nim-osureplay.svg?branch=master)](https://travis-ci.org/Yardanico/nim-osureplay)
This is a mathematic expression evaluation library in pure Nim (with no third-party dependencies) 

Mathexpr code is originally based on [this](https://stackoverflow.com/a/26227947/5476128) StackOverflow answer

## Installation
To install mathexpr, simply run:
```
$ nimble install mathexpr
```

## Documentation
Mathexpr has only one exported procedure: `proc eval(data: string): float`
```nim
import mathexpr
echo eval("((4 - 2^3 + 1) * -sqrt(3*3+4*4)) / 2") # 7.5
```
## Supported functions
### Mathexpr has these functions implemented:
- `abs(x)` - the absolute value of `x`
- `acos(x)` or `arccos(x)` - the arccosine (in radians) of `x`
- `asin(x)` or `arcsin(x)` - the arcsine (in radians) of `x`
- `atan(x)` or `arctan(x)` - the arctangent (in radians) of `x`
- `atan2(x, y)` or `arctan2(x, y)` - the arctangent of the quotient from provided `x` and `y`
- `ceil(x)` - the smallest integer greater than or equal to `x`
- `cos(x)` - the cosine of of `x`
- `cosh(x)` - the hyperbolic cosine of `x`
- `exp(x)` - the exponential function of `x`
- `sqrt(x)` - the square root of `x`
- `fac(x)` - the factorial of `x`
- `floor(x)` - the largest integer not greater than `x`
- `ln(x)` - the natural log of `x`
- `log(x)` or `log10(x)` - the common logarithm (base 10) of `x`
- `log2(x)` - the binary logarithm (base 2) of `x`
- `max(x, y, z, ...)` - biggest argument from any number of arguments
- `min(x, y, z, ...)` - smallest argument from any number of arguments
- `ncr(x, y)` or `binom(x, y)` - the the number of ways a sample of `y` elements can be obtained from a larger set of `x` distinguishable objects where order does not matter and repetitions are not allowed
- `npr(x, y)` - the number of ways of obtaining an ordered subset of `y` elements from a set of `x` elements
- `pow(x, y)` - the `x` to the `y` power
- `sin(x)` - the sine of `x`
- `sinh(x)` - the hyperbolic sine of `x`
- `tan(x)` - the tangent of `x`
- `tanh(x)` - the hyperbolic tangent of `x`
### These constants are available:
- `pi` - The circle constant (Ludolph's number)
- `tau` - The circle constant, equals to 2 * PI
- `e` - Euler's number