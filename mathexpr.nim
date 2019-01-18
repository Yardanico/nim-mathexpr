import math, strformat, strutils, parseutils, tables

type
  MathFunction = proc(args: seq[float]): float

const
  ArgsErrorMsg = "Expected $1 arguments for function `$2`, got $3"
  AtLeastErrorMsg = "Function `$1` accepts at least one argument, got 0"
  CharErrorMsg = "Unexpected char $1 at pos $2"
  UnknownIdentMsg = "Unknown function, variable or constant `$1` at pos $2"

# TODO: Make a PR to Nim stdlib
when defined(JS):
  proc `mod`(a, b: float): float = 
    asm """`a` % `b`"""

var funcs = newTable[string, MathFunction]()

proc addFunc*(name: string, fun: MathFunction) = 
  ## Adds custom function *fun* named *name* which will be available inside of
  ## a mathematical expression passed to eval()
  ##
  ## You can use any valid Nim code inside of a custom function, but it must
  ## accept sequence of floats and return a single float
  runnableExamples:
    proc add2(args: seq[float]): float = 
      args[0] + 2

    addFunc("add2", add2)
    doAssert eval("add2(4)") == 6.0
  funcs[name] = fun

var defaultTable: Table[string, float]

proc eval*(data: string, vars = defaultTable): float = 
  ## Evaluates math expression from string *data* and returns result as a float
  ##
  ## Has optional *vars* argument - table of variables which can be used inside
  ## of a math expression
  runnableExamples:
    # You don't need `tables` module if you only use eval() template or you 
    # don't use custom variables at all
    import tables 

    # By default trigonometric functions in mathexpr operate on radians, like
    # in Nim's `math` stdlib module
    doAssert eval("cos(pi)*sin(pi)") == 0
    
    let vars = {"a": 5.0, "b": 7.0}.toTable()
    doAssert eval("a+b", vars) == 12.0
  
  let 
    hasVars = vars.len > 0
    hasFuncs = funcs.len > 0
    maxPos = data.len
  
  var
    pos = 0  ## Current position
    ch = data[0]  ## Current character
  
  template nextChar = 
    ## Increments current position and gets next char
    inc pos
    # Check if string ended
    if pos == maxPos: ch = '\0'
    else: ch = data[pos]
  
  template setChar = 
    ## Set ch to current position in string if it's not the last characters
    if pos < data.len: ch = data[pos]

  template charError = 
    raise newException(ValueError, CharErrorMsg % [$ch, $pos])

  template eat(charToEat: char): bool = 
    ## Skips all whitespace characters and checks if 
    ## current character is *charToEat*. If so, gets the next char 
    ## and returns true
    pos += skipWhitespace(data, pos)
    setChar()
    if ch == charToEat:
      nextChar()
      true
    else: false
  
  # We forward-declare these two procs because we have a recursive dependency
  proc parseExpression: float
  proc parseFactor: float

  proc getArgs(args = 0, funcName: string, zeroArgs = false): seq[float] = 
    result = @[]
    if eat('('):
      # While there are arguments left
      while ch != ')':
        result.add parseExpression()
        # Skip ',' if we have it. With this we allow things like
        # max(1 2 3 4) or atan2(3 5)
        if ch == ',': nextChar()
      if not eat(')'):
        charError()
    else:
      # Parse a factor. It can't be an expression because this
      # would provide wrong results: sqrt 100 * 70
      result.add parseFactor()
    # We check here if args count is provided and
    # it's the same as number of arguments
    # or we have 0 arguments but we don't allow zero arguments
    if (args != 0 and result.len != args):
      raise newException(
        ValueError, ArgsErrorMsg % [$args, funcName, $result.len]
      )
    elif (not zeroArgs and result.len == 0):
      raise newException(ValueError, AtLeastErrorMsg % [funcName])

  template getArgs(argsNum = 0, zeroArgs = false): untyped {.dirty.} = 
    getArgs(argsNum, funcName, zeroArgs)

  template getArg(): untyped {.dirty.} = 
    getArgs(1, funcName)[0]

  proc parseFactor: float = 
    # Unary + and -
    if eat('+'): return parseFactor()
    elif eat('-'): return -parseFactor()
    
    if eat('('):
      result = parseExpression()
      if not eat(')'):
        charError()

    elif ch in IdentStartChars:
      var funcName: string
      pos += parseIdent(data, funcName, pos)
      setChar()

      if hasVars:
        let data = vars.getOrDefault(funcName)
        if data != 0.0: return data
      
      if hasFuncs:
        let data = funcs.getOrDefault(funcName)
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
        raise newException(ValueError, UnknownIdentMsg % [$funcName, $pos])
      
    # Numbers ('.' is for numbers like '.5')
    elif ch in {'0'..'9', '.'}:
      let skipped = parseFloat(data, result, pos)
      if skipped == 0: charError()

      pos += skipped
      setChar()
    else:
      charError()

  proc parseTerm: float = 
    result = parseFactor()
    while true:
      if eat('*'): result *= parseFactor()
      elif eat('/'): result /= parseFactor()
      elif eat('%'): result = result.mod(parseFactor())
      elif eat('^'): result = result.pow(parseFactor())
      else: return

  proc parseExpression: float = 
    result = parseTerm()
    while true:
      if eat('+'): result += parseTerm()
      elif eat('-'): result -= parseTerm()
      else: return
  
  try:
    result = parseExpression()
  except OverflowError:
    return Inf
  # If we didn't process all characters in the string
  if pos < data.len:
    charError()

template eval*(data: string, vars: openArray[(string, float)]): float = 
  ## Template which automatically converts *vars* openarray to a Table
  ## so you don't need to import and use `tables` module yourself.
  runnableExamples:
    doAssert eval("a+b*2", {"a": 5.0, "b": 3.0}) == 11.0
  
  mixin toTable
  eval(data, vars.toTable())