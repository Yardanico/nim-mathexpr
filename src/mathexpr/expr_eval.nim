import math, strutils, parseutils, tables, strformat
import types

proc incPos(expr: var MathExpression, addPos = 1): char {.discardable.} =
  ## Increments current pos by 'addPos' characters
  expr.pos += addPos
  expr.ch = if expr.len == expr.pos: '\0' else: expr.input[expr.pos]

proc nextOp(expr: var MathExpression, opList: string): char =
  ## Checks if the next character is an op from the 'opList'
  ##
  ## If yes, returns that character, otherwise returns '\0'
  expr.incPos(skipWhitespace(expr.input, expr.pos))
  if expr.ch in opList:
    result = expr.ch
    expr.incPos()
  else:
    result = '\0'

proc eat(expr: var MathExpression, toEat: char): bool =
  ## Skips all whitespace characters and checks if
  ## current character is 'toEat'. If so, gets the next char
  ## and returns true
  expr.incPos(skipWhitespace(expr.input, expr.pos))
  if expr.ch == toEat:
    expr.incPos()
    true
  else: false

# Forward declaration because of recursive dependency
proc parseExpression*(expr: var MathExpression): float
proc parseFactor(expr: var MathExpression): float

proc getArgs(expr: var MathExpression, args = 0, funcName: string,
    zeroArgs = false): seq[float] =
  ## Gets argument list for a function call
  result = @[]
  if expr.eat('('):
    # Until it's the end of the argument list
    while expr.ch != ')':
      result.add expr.parseExpression()
      # ',' is not mandatory, since we allow things like max(1 2 3 4 5)
      if expr.ch == ',': expr.incPos()
    # We didn't find closing paren
    if not expr.eat(')'):
      raise newException(
        UnbalancedParenthesis, &"Expected ')', found ${expr.ch}"
      )
  else:
    # Parse a factor. It can't be an expression because this
    # would provide wrong results: sqrt 100 * 70
    result.add expr.parseFactor()
  if (args != 0 and result.len != args):
    raise newException(
      ValueError,
      &"Expected ${args} arguments for ${funcName}, got ${result.len}"
    )
  elif (not zeroArgs and result.len == 0):
    raise newException(
      ValueError,
      &"Expected one or more arguments for ${funcName}, got 0"
    )

template getArgs(argsNum = 0, zeroArgs = false): untyped {.dirty.} =
  expr.getArgs(argsNum, funcName, zeroArgs)

template getArg(): untyped {.dirty.} =
  expr.getArgs(1, funcName)[0]

proc parseFactor(expr: var MathExpression): float =
  # Unary + and -
  if expr.eat('+'): return expr.parseFactor()
  elif expr.eat('-'): return -expr.parseFactor()

  if expr.eat('('):
    result = expr.parseExpression()
    if not expr.eat(')'):
      raise newException(UnexpectedCharacter, &"Expected ')', found ${expr.ch}")

  elif expr.ch in IdentStartChars:
    var funcName: string
    expr.incPos(parseIdent(expr.input, funcName, expr.pos))
    if expr.eval.hasVars:
      let data = expr.eval.vars.getOrDefault(funcName)
      if data != 0.0: return data

    if expr.eval.hasFuncs:
      let data = expr.eval.funcs.getOrDefault(funcName)
      if not data.isNil(): return data(getArgs())

    result = case funcName:
    of "abs": abs(getArg())
    of "acos", "arccos": arccos(getArg())
    of "asin", "arcsin": arcsin(getArg())
    of "atan", "arctan", "arctg": arctan(getArg())
    of "atan2", "arctan2":
      let args = getArgs(2)
      arctan2(args[0], args[1])
    of "ceil": ceil(getArg())
    of "cos": cos(getArg())
    of "cosh": cosh(getArg())
    of "deg": radToDeg(getArg())
    of "exp": exp(getArg())
    of "sqrt": sqrt(getArg())
    of "sum": sum(getArgs())
    of "fac": float fac(int(getArg()))
    of "floor": floor(getArg())
    of "ln": ln(getArg())
    of "log", "log10": log10(getArg())
    of "log2": log2(getArg())
    of "max": max(getArgs())
    of "min": min(getArgs())
    of "ncr", "binom":
      let args = getArgs(2)
      float binom(int args[0], int args[1])
    of "npr":
      let args = getArgs(2)
      float binom(int args[0], int args[1]) * fac(int args[1])
    of "rad": degToRad(getArg())
    of "pow":
      let args = getArgs(2)
      pow(args[0], args[1])
    of "sin": sin(getArg())
    of "sinh": sinh(getArg())
    of "tan": tan(getArg())
    of "tanh": tanh(getArg())
    # Built-in constants
    of "pi": PI
    of "tau": TAU
    of "e": E
    else:
      raise newException(UnknownIdent, &"Ident ${funcName} is not defined")

  # Numbers ('.' is for numbers like '.5')
  elif expr.ch in {'0'..'9', '.'}:
    expr.incPos(parseFloat(expr.input, result, expr.pos))
  else:
    raise newException(UnexpectedCharacter,
        &"Unexpected character ${expr.ch}")

proc parseTerm(expr: var MathExpression): float =
  result = expr.parseFactor()
  while true:
    case expr.nextOp("*/%^")
    of '*': result *= expr.parseFactor()
    of '/': result /= expr.parseFactor()
    of '%': result = result.mod(expr.parseFactor())
    of '^': result = result.pow(expr.parseFactor())
    else: return

proc parseExpression*(expr: var MathExpression): float =
  result = expr.parseTerm()
  while true:
    case expr.nextOp("+-")
    of '+':
      result += expr.parseTerm()
    of '-': result -= expr.parseTerm()
    else: return
