# mathexpr, a math expression evaluator library in Nim [![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)
[![Build Status](https://travis-ci.org/Yardanico/nim-mathexpr.svg?branch=master)](https://travis-ci.org/Yardanico/nim-mathexpr)
Mathexpr is a relatively small mathematical expression evaluator library written in Nim without any third-party dependencies. 
It has a lot of predefined math functions and some constants, and you can also define your own.

## Installation
To install mathexpr, simply run:
```
$ nimble install mathexpr
```

## Documentation
Mathexpr has a main Evaluator type, which you should use for evaluating math expressions:

```nim
import mathexpr
let e = newEvaluator()

echo e.eval("((4 - 2^3 + 1) * -sqrt(3*3+4*4)) / 2") # 7.5
echo e.eval("+5^+3+1.1 + a", {"a": 5.0}) # 131.1
# Add some variables to our Evaluator object
e.addVars({"a": 1.0, "b": 2.0})
echo e.eval("a + b") # 3

# Define our custom function which returns 
# 25 multiplied by all arguments it got
proc myFunc(args: seq[float]): float =
  result = 25
  for arg in args:
    result *= arg


e.addFunc("work", myFunc)
echo e.eval("work(1, 2, 3) + 5") # 25*1*2*3 + 5 = 155

# In some places parenthesis and commas are optional:
echo e.eval("work(1 2 3) + 5") # 155
echo e.eval("sqrt 100 + 5") 
```

`eval` can raise an exception. All possible exceptions:
- `EmptyInput` - raised when the input line is empty
- `UnbalancedParenthesis` - raised when the number of opening/closing parenthesis is not the same
- `UnexpectedCharacter` - raised when the evaluator encounters an unknown character
- `UnknownIdent` - raised when the parsed ident (function or variable name) is not defined
- `OverflowError` - happens when an overflow occured

`eval` can return `NaN` or `Inf` for some inputs, such as `0/0`, or `1/0`, see src/tests.nim

## What is supported?
#### Supported operators: `+`, `-`, `/`, `*`, `%`, `^`
### Implemented mathematical functions:
- `abs(x)` - the absolute value of `x`
- `acos(x)` or `arccos(x)` - the arccosine (in radians) of `x`
- `asin(x)` or `arcsin(x)` - the arcsine (in radians) of `x`
- `atan(x)` or `arctan(x)` or `arctg(x)` - the arctangent (in radians) of `x`
- `atan2(x, y)` or `arctan2(x, y)` - the arctangent of the quotient from provided `x` and `y`
- `ceil(x)` - the smallest integer greater than or equal to `x`
- `cos(x)` - the cosine of `x`
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
### Predefined constants:
- `pi` - The circle constant (Ludolph's number)
- `tau` - The circle constant, equals to `2 * pi`
- `e` - Euler's number