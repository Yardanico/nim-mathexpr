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

proc expectedParen(expr: var MathExpression) = 
  raise newException(UnexpectedCharacter, &"Expected ')', found {expr.ch}")

proc unknownIdent(funcName: string) = 
  raise newException(UnknownIdent, &"Ident {funcName} is not defined")

proc unexpectedChar(expr: var MathExpression) = 
  raise newException(UnexpectedCharacter,
    &"Unexpected character ${expr.ch}"
  )

proc getArgs(expr: var MathExpression, zeroArg = true): seq[float] =
  ## Gets argument list for a function call
  result = @[]
  if expr.eat('('):
    # Empty function call like a()
    if expr.eat(')'): return 
    # Until it's the end of the argument list
    while expr.ch != ')':
      result.add expr.parseExpression()
      # ',' is not mandatory, since we allow things like max(1 2 3 4 5)
      if expr.ch == ',': expr.incPos()
    # We didn't find closing paren
    if not expr.eat(')'):
      expr.expectedParen()
  else:
    # Parse a factor. It can't be an expression because this
    # would provide wrong results: sqrt 100 * 70
    result.add expr.parseFactor()

proc checkArgLen(expected, actual: int, funcName: string) = 
  if expected == -1 and actual < 1:
    raise newException(ValueError, 
      &"Expected at least one argument for {funcName}, got 0"
    )
  elif expected != -1 and actual != expected:
    raise newException(ValueError,
      &"Expected {expected} arguments for {funcName}, got {actual}"
    )

template checkArgs(expected = 1) {.dirty.} = 
  checkArgLen(expected, args.len, funcName)

proc parseFactor(expr: var MathExpression): float =
  # Unary + and -
  if expr.eat('+'): return expr.parseFactor()
  elif expr.eat('-'): return -expr.parseFactor()

  if expr.eat('('):
    result = expr.parseExpression()
    if not expr.eat(')'):
      expr.expectedParen()

  elif expr.ch in IdentStartChars:
    var funcName: string
    expr.incPos(parseIdent(expr.input, funcName, expr.pos))

    if expr.eval.hasVars and funcName in expr.eval.vars:
      return expr.eval.vars[funcName]

    if expr.eval.hasFuncs:
      let data = expr.eval.funcs.getOrDefault(funcName)
      if not data.isNil(): return data(expr.getArgs())
    
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

    result = case funcName
    of "abs": checkArgs(); abs(args[0])
    of "acos", "arccos": checkArgs(); arccos(args[0])
    of "asin", "arcsin": checkArgs(); arcsin(args[0])
    of "atan", "arctan", "arctg": checkArgs(); arctan(args[0])
    of "atan2", "arctan2": checkArgs(2); arctan2(args[0], args[1])
    of "ceil": checkArgs(); ceil(args[0])
    of "cos": checkArgs(); cos(args[0])
    of "cosh": checkArgs(); cosh(args[0])
    of "deg": checkArgs(); radToDeg(args[0])
    of "exp": checkArgs(); exp(args[0])
    of "sqrt": checkArgs(); sqrt(args[0])
    of "sum": checkArgs(-1); sum(args)
    of "fac": checkArgs(); float fac(int(args[0]))
    of "floor": checkArgs(); floor(args[0])
    of "ln": checkArgs(); ln(args[0])
    of "log", "log10": checkArgs(); log10(args[0])
    of "log2": checkArgs(); log2(args[0])
    of "max": checkArgs(-1); max(args)
    of "min": checkArgs(-1); min(args)
    of "ncr", "binom": 
      checkArgs(2)
      float binom(int args[0], int args[1])
    of "npr": 
      checkArgs(2)
      float binom(int args[0], int args[1]) * fac(int args[1])
    of "rad": checkArgs(); degToRad(args[0])
    of "pow": checkArgs(2); pow(args[0], args[1])
    of "sin": checkArgs(); sin(args[0])
    of "sinh": checkArgs(); sinh(args[0])
    of "tg", "tan": checkArgs(); tan(args[0])
    of "tanh": checkArgs(); tanh(args[0])
    else:
      unknownIdent(funcname)
      NaN

  # Numbers ('.' is for numbers like '.5')
  elif expr.ch in {'0'..'9', '.'}:
    expr.incPos(parseFloat(expr.input, result, expr.pos))
  
  else:
    expr.unexpectedChar()

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
    of '+': result += expr.parseTerm()
    of '-': result -= expr.parseTerm()
    else: return
