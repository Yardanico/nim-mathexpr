## This library is a relatively small (<500 cloc) mathematical expression 
## evaluator library written in Nim.
## 
## The implementation is a simple recursive-descent evaluator.
## 
## It only depends on the stdlib (mostly on the `math` module), 
## and works on all official Nim backends including JavaScript and in the VM
## 
## There's a lot of predefined math functions and some constants, 
## and of course you can define custom ones.
## 
## Most of the library usage can be shown in this code example:
## 
## .. code-block:: nim
## 
##   import mathexpr
##   # Create a new evaluator instance
##   # All custom variables and math functions are bound to this evaluator
##   # so you could have different evaluators with different vars/functions
##   let e = newEvaluator()
##   
##   echo e.eval("((4 - 2^3 + 1) * -sqrt(3*3+4*4)) / 2") # 7.5
##   # Add some variables to our Evaluator object
##   e.addVars({"a": 5.0})
##   echo e.eval("+5^+3+1.1 + a") # 131.1
##   # Variables with the same name overwrite the old ones
##   e.addVars({"a": 1.0, "b": 2.0})
##   echo e.eval("a + b") # 3
##   
##   # Define our custom function which returns 
##   # 25 multiplied by all arguments it got
##   proc myFunc(args: seq[float]): float =
##     result = 25
##     for arg in args:
##       result *= arg
##   
##   e.addFunc("work", myFunc)
##   echo e.eval("work(1, 2, 3) + 5") # 25*1*2*3 + 5 = 155
##   
##   # Define a custom function which only accepts two arguments
##   proc test(a: seq[float]): float = 
##     a[0] + a[1]
##   
##   e.addFunc("test", test, 2)
##   echo e.eval("test(1, 5)") # 6
##   
##   # In some places parentheses and commas are optional:
##   echo e.eval("work(1 2 3) + 5") # 155
##   echo e.eval("sqrt 100 + 5") # 15
## 
## `eval` can return `NaN` or `Inf` for some inputs, such as `0/0`, or `1/0`, 
## see `src/tests.nim` for more info

## What is supported?
## ------------------
## Supported operators include `+`, `-`, `/`, `*`, `%`, `^`
##
## Implemented mathematical functions:
## * `abs(x)` - the absolute value of `x`
## * `acos(x)` or `arccos(x)` - the arccosine (in radians) of `x`
## * `asin(x)` or `arcsin(x)` - the arcsine (in radians) of `x`
## * `atan(x)` or `arctan(x)` or `arctg(x)` - the arctangent (in radians) of `x`
## * `atan2(x, y)` or `arctan2(x, y)` - the arctangent of the \
## quotient from provided `x` and `y`
## * `ceil(x)` - the smallest integer greater than or equal to `x`
## * `cos(x)` - the cosine of `x`
## * `cosh(x)` - the hyperbolic cosine of `x`
## * `deg(x)` - converts `x` in radians to degrees
## * `exp(x)` - the exponential function of `x`
## * `sgn(x)` - the sign of `x`
## * `sqrt(x)` - the square root of `x`
## * `sum(x, y, z, ...)` - sum of all passed arguments
## * `fac(x)` - the factorial of `x`
## * `floor(x)` - the largest integer not greater than `x`
## * `ln(x)` - the natural log of `x`
## * `log(x)` or `log10(x)` - the common logarithm (base 10) of `x`
## * `log2(x)` - the binary logarithm (base 2) of `x`
## * `max(x, y, z, ...)` - biggest argument from any number of arguments
## * `min(x, y, z, ...)` - smallest argument from any number of arguments
## * `ncr(x, y)` or `binom(x, y)` - the the number of ways a sample of \
## `y` elements can be obtained from a larger set of `x` distinguishable \
## objects where order does not matter and repetitions are not allowed
## * `npr(x, y)` - the number of ways of obtaining an ordered subset of `y` \
## elements from a set of `x` elements
## * `rad(x)` - converts `x` in degrees to radians
## * `pow(x, y)` - the `x` to the `y` power
## * `sin(x)` - the sine of `x`
## * `sinh(x)` - the hyperbolic sine of `x`
## * `tg(x)` or `tan(x)` - the tangent of `x`
## * `tanh(x)` - the hyperbolic tangent of `x`
## Predefined constants
## ---------------------
## * `pi` - The circle constant (Ludolph's number)
## * `tau` - The circle constant, equals to `2 * pi`
## * `e` - Euler's number

import math, strutils, parseutils, tables, strformat

type
  MathFunction* = proc(args: seq[float]): float ## \
  ## Type of the procedure definition for custom math functions

  MathCustomFun = object
    # Number of arguments this function is allowed to be called with
    argCount: int
    # The function itself
    fun: MathFunction

  MathExpression = object
    eval: Evaluator
    input: string
    len: int
    ch: char
    pos: int

  Evaluator* = ref object
    ## Main instance of the math evaluator
    funcs: Table[string, MathCustomFun]
    vars: Table[string, float]

proc atEnd(expr: var MathExpression): bool =
  expr.pos >= expr.len

proc incPos(expr: var MathExpression, addPos = 1): char {.discardable.} =
  # Increments current pos by `addPos` characters
  expr.pos += addPos
  expr.ch = if expr.atEnd(): '\0' else: expr.input[expr.pos]

proc nextOp(expr: var MathExpression, opList: set[char]): char =
  # Checks if the next character is an op from the `opList`
  # If yes, returns that character, otherwise returns `\0`
  expr.incPos(skipWhitespace(expr.input, expr.pos))
  if expr.ch in opList:
    result = expr.ch
    expr.incPos()
  else:
    result = '\0'

proc eat(expr: var MathExpression, toEat: char): bool =
  # Skips all whitespace characters and checks if
  # current character is `toEat`. If so, gets the next char
  # and returns true
  expr.incPos(skipWhitespace(expr.input, expr.pos))
  if expr.ch == toEat:
    expr.incPos()
    true
  else: false

template swallow(expr: var MathExpression, toEat: char) =
  # Same as eat, but raise unexpected char when toEat does not match
  if not expr.eat(toEat): expr.unexpectedChar() 
  

# Forward declaration because of recursive dependency
proc parseExpression(expr: var MathExpression): float
proc parseFactor(expr: var MathExpression): float

proc expectedParen(expr: var MathExpression) =
  raise newException(ValueError, &"Expected `)`, found `{expr.ch}`")

proc unknownIdent(funcName: string) =
  raise newException(ValueError, &"Ident `{funcName}` is not defined")

proc unexpectedChar(expr: var MathExpression) =
  raise newException(ValueError, &"Unexpected character `{expr.ch}`")

proc getArgs(expr: var MathExpression, zeroArg = true): seq[float] =
  # Gets argument list for a function call
  result = @[]
  if expr.eat('('):
    # Empty function call like a()
    if expr.eat(')'): return
    # Until it's the end of the argument list
    while expr.ch != ')':
      result.add expr.parseExpression()
      # `,` is not mandatory, since we allow things like max(1 2 3 4 5)
      if expr.ch == ',': expr.incPos()
    # We didn't find the closing paren
    if not expr.eat(')'):
      expr.expectedParen()
  else:
    # Parse a factor. It can't be an expression because this
    # would provide wrong results: sqrt 100 * 70
    result.add expr.parseFactor()

proc checkArgLen(expected, actual: int, funcName: string) =
  if expected == -1 and actual < 1:
    raise newException(ValueError,
      &"Expected at least one argument for '{funcName}', got 0"
    )
  elif expected != -1 and actual != expected:
    raise newException(ValueError,
      &"Expected {expected} arguments for '{funcName}', got {actual}"
    )

proc parseFactor(expr: var MathExpression): float =
  # Unary `+` and `-`
  if expr.eat('+'): return expr.parseFactor()
  elif expr.eat('-'): return -expr.parseFactor()

  if expr.eat('('):
    result = expr.parseExpression()
    if not expr.eat(')'):
      expr.expectedParen()

  elif expr.ch in IdentStartChars:
    var funcName: string
    expr.incPos(parseIdent(expr.input, funcName, expr.pos))

    # Code below uses withValue because it allows us to only
    # have 1 lookup to check if a variable exists without
    # having to define an arbitrary default value which might
    # conflict with a variable declared by the user

    # Check for a defined variable
    expr.eval.vars.withValue(funcName, val):
      return val[]
    
    # Check for a defined function
    expr.eval.funcs.withValue(funcName, fnc):
      let args = expr.getArgs()
      checkArgLen(fnc.argCount, args.len, funcName)
      return fnc.fun(args)

    # Built-in constants
    result = case funcName
    of "pi": PI
    of "tau": TAU
    of "e": E
    else: 0
    # If this is a constant, immediately return
    if result != 0: return

    # We are *kinda* sure that we're handling a function now
    let args = expr.getArgs()

    template callArgs(fnCall: untyped, argCount = 1): float =
      # Check that the number of passed arguments is `argCount`
      # and then does `fnCall`
      checkArgLen(argCount, args.len, funcName)
      fnCall

    result = case funcName
    of "abs":
      callArgs abs(args[0])
    of "acos", "arccos":
      callArgs arccos(args[0])
    of "asin", "arcsin":
      callArgs arcsin(args[0])
    of "atan", "arctan", "arctg":
      callArgs arctan(args[0])
    of "atan2", "arctan2":
      callArgs arctan2(args[0], args[1]), 2
    of "ceil":
      callArgs ceil(args[0])
    of "cos":
      callArgs cos(args[0])
    of "cosh":
      callArgs cosh(args[0])
    of "deg":
      callArgs radToDeg(args[0])
    of "exp":
      callArgs exp(args[0])
    of "sgn":
      callArgs float(sgn(args[0]))
    of "sqrt":
      callArgs sqrt(args[0])
    of "sum":
      callArgs sum(args), -1
    of "fac":
      callArgs float(fac(int(args[0])))
    of "floor":
      callArgs floor(args[0])
    of "ln":
      callArgs ln(args[0])
    of "log", "log10":
      callArgs log10(args[0])
    of "log2":
      callArgs log2(args[0])
    of "max":
      callArgs max(args), -1
    of "min":
      callArgs min(args), -1
    of "ncr", "binom":
      callArgs float(binom(int args[0], int args[1])), 2
    of "npr":
      callArgs float(binom(int args[0], int args[1]) * fac(int args[1])), 2
    of "rad":
      callArgs degToRad(args[0])
    of "pow":
      callArgs pow(args[0], args[1]), 2
    of "sin":
      callArgs sin(args[0])
    of "sinh":
      callArgs sinh(args[0])
    of "tg", "tan":
      callArgs tan(args[0])
    of "tanh":
      callArgs tanh(args[0])
    else:
      unknownIdent(funcname)
      NaN

  # Numbers (`.` is for numbers like `.5`)
  elif expr.ch in {'0'..'9', '.'}:
    let cnt = parseFloat(expr.input, result, expr.pos)
    if cnt == 0:
      expr.unexpectedChar()
    expr.incPos(cnt)

  else:
    expr.unexpectedChar()

proc parsePow(expr: var MathExpression): float =
  result = expr.parseFactor()
  while not expr.atEnd():
    case expr.nextOp({'^'})
    of '^':
      result = result.pow(expr.parseFactor())
    else: break

proc parseTerm(expr: var MathExpression): float =
  result = expr.parsePow()
  while not expr.atEnd():
    case expr.nextOp({'*', '/', '%'})
    of '*': result *= expr.parsePow()
    of '/': result /= expr.parsePow()
    of '%': result = result.mod(expr.parsePow())
    else: break

proc parseAddition(expr: var MathExpression): float =
  result = expr.parseTerm()
  while not expr.atEnd():
    case expr.nextOp({'+', '-'})
    of '+': result += expr.parseTerm()
    of '-': result -= expr.parseTerm()
    else: break

proc parseRelative(expr: var MathExpression): float =
  result = expr.parseAddition()
  while not expr.atEnd():
    let op = expr.nextOp({'<', '>'})
    case op
    of '<', '>':
      if expr.eat('='):
        result = case op
        of '<':
          if result <= expr.parseAddition(): 1.0
          else: 0.0
        of '>':
          if result >= expr.parseAddition(): 1.0
          else: 0.0
        else: NaN # unreachable
      else:
        result = case op
        of '<':
          if result < expr.parseAddition(): 1.0
          else: 0.0
        of '>':
          if result > expr.parseAddition(): 1.0
          else: 0.0
        else: NaN # unreachable
    else: break

proc `~=`(a, b: float): bool =
  ## Checks if difference between two floats is less than 0.0001
  abs(a - b) < 1e-4

proc parseExpression(expr: var MathExpression): float =
  result = expr.parseRelative()
  while not expr.atEnd():
    let op = expr.nextOp({'=', '!'})
    case op
    of '=', '!':
      expr.swallow('=')
      result = case op
      of '=':
        if result ~= expr.parseExpression(): 1.0
        else: 0.0
      of '!':
        if not (result ~= expr.parseExpression()): 1.0
        else: 0.0
      else: NaN # unreachable
    else: break

proc parse(expr: var MathExpression): float =
  result = expr.parseExpression()
  # We should parse the whole input, otherwise we skipped something
  # and that's certainly not good
  if not expr.atEnd(): expr.unexpectedChar()

proc newEvaluator*: Evaluator =
  ## Creates a new evaluator instance for evaluating math expressions
  ##
  ## There's no limit on the number of evaluator instances,
  ## and all functions and math procedures are local to the current instance
  Evaluator()

proc addFunc*(e: Evaluator, name: string, fun: MathFunction, argCount = -1) =
  ## Adds custom function `fun` with the name `name` to the evaluator `e`
  ## which will then be available inside of all following `e.eval()` calls.
  ##
  ## `argCount` specifies the number of arguments this function is allowed
  ## to be called with. If it is `-1`, the function will be able to be called
  ## with one or more arguments, otherwise - only with `argCount` arguments.
  e.funcs[name] = MathCustomFun(fun: fun, argCount: argCount)

proc removeFunc*(e: Evaluator, name: string) =
  ## Removes function with the name `name` from the evaluator `e`
  e.funcs.del(name)

proc addVar*(e: Evaluator, name: string, val: float) =
  ## Adds a constant with the name `name` to the evaluator `e`
  e.vars[name] = val

proc addVars*(e: Evaluator, vars: openArray[(string, float)]) =
  ## Adds all constants from the `vars` openArray to the evaluator `e`
  runnableExamples:
    let e = newEvaluator()
    e.addVars({"a": 3.0, "b": 5.5})
    assert e.eval("a ^ a + b") == 32.5

  for (name, val) in vars:
    e.addVar(name, val)

proc removeVar*(e: Evaluator, name: string) =
  ## Removes the specified constant with the name `name` from the evaluator `e`
  e.vars.del(name)

proc eval*(e: Evaluator, input: string): float =
  ## Evaluates a math expression from `input` and returns result as `float`
  ##
  ## Can raise an exception if `input` is invalid or an overflow occured
  if input.len == 0:
    raise newException(ValueError, "The line is empty!")

  var expr = MathExpression(
    eval: e,
    len: input.len,
    ch: input[0],
    input: input,
    pos: 0
  )

  expr.parse()
