import math, strutils

const
  ArgsErrorMsg = "Incorrect number of arguments at pos $1 in function `$2`"
  CharErrorMsg = "Unexpected char `$1` at pos $2"

proc eval*(data: string): float = 
  ## Evaluates math expression from string *data* and returns result as a float
  var data = data.toLowerAscii()

  var
    pos = 0 ## Current position
    ch = data[0]
  
  template nextChar = 
    ## Gets next char
    inc pos
    ch = data[pos]
  
  proc eat(charToEat: char): bool {.inline.} = 
    ## Skips all whitespace characters, 
    ## checks if current character is *charToEat* and skips it
    while ch in Whitespace: nextChar()
    if ch == charToEat: 
      nextChar()
      result = true
  
  # We forward-declare these two procs because we have a recursive dependency
  proc parseExpression: float
  proc parseFactor: float
  
  proc parseArgumentsAux(argsNum: int): seq[float] = 
    ## Parses any number of arguments (except 1)
    if argsNum != -1:
      result = newSeqOfCap[float](argsNum)
    else:
      result = newSeq[float]()
    # No arguments at all
    if ch != ',': return
    while ch == ',':
      nextChar()
      result.add parseExpression()
    nextChar()
    if argsNum != -1 and argsNum != result.len:
      # Return nothing
      result = nil
    
  template getArgs(argsNum = 0, allowZeroArgs = false): untyped {.dirty.} = 
    ## Gets all arguments for current function
    var data = @[parseFactor()]
    # If we need to parse more than 1 argument
    if argsNum != 1: data.add parseArgumentsAux(argsNum - 1)
    
    # If number of given/needed arguments is wrong:
    if data.isNil or (not allowZeroArgs and data.len == 0):
      raise newException(ValueError, ArgsErrorMsg % [$pos, $funcName])
    data
  
  template getArg(): untyped = 
    getArgs(1)[0]

  proc parseFactor: float = 
    # Unary + and -
    if eat('+'): return parseFactor()
    elif eat('-'): return -parseFactor()
    
    let startPos = pos

    # Parentheses
    if eat('('):
      # We allow zero number of arguments by checking for ')' here
      if ch != ')': result = parseExpression()
      discard eat(')')
    
    # First char in function name should be in latin alphabet
    
    elif ch in {'a'..'z'}:
      # Other chars can also be numerical
      while ch in {'a'..'z', '0'..'9'}: nextChar()
      let funcName = data[startPos..<pos]
      case funcName
      # Functions
      of "abs": result = abs(getArg())
      of "acos", "arccos": result = arccos(getArg())
      of "asin", "arcsin": result = arcsin(getArg())
      of "atan", "arctan", "arctg": result = arctan(getArg())
      of "atan2", "arctan2":
        let args = getArgs(2)
        result = arctan2(args[0], args[1])
      of "ceil": result = ceil(getArg())
      of "cos": result = cos(getArg())
      of "cosh": result = cosh(getArg())
      of "exp": result = exp(getArg())
      of "sqrt": result = sqrt(getArg())
      of "fac": result = float fac(int(getArg()))
      of "floor": result = floor(getArg())
      of "ln": result = ln(getArg())
      of "log", "log10": result = log10(getArg())
      of "log2": result = log2(getArg())
      of "max": result = max(getArgs())
      of "min": result = min(getArgs())
      of "ncr", "binom": 
        let args = getArgs(2)
        result = float binom(int args[0], int args[1])
      of "npr":
        let args = getArgs(2)
        result = float binom(int args[0], int args[1]) * fac(int args[1])
      of "pow":
        let args = getArgs(2)
        result = pow(args[0], args[1])
      of "sin": result = sin(getArg())
      of "sinh": result = sinh(getArg())
      of "tan": result = tan(getArg())
      of "tanh": result = tanh(getArg())
      # Constants
      of "pi": result = PI
      of "tau": result = TAU
      of "e": result = E
      else: 
        raise newException(ValueError, "Unknown function: " & funcName)
    # Numbers (we allow things like .5)
    elif ch in {'0'..'9', '.'}:
      # Ugly checks to allow expressions like 10^5*5e-5
      # Maybe there's a better way?
      while ch in {'0'..'9', '.', 'e'} or 
        (ch == 'e' and data[pos+1] == '-') or 
        (data[pos-1] == 'e' and ch == '-' and data[pos+1] in {'0'..'9'}): 
        nextChar()
      result = 
        if ch == '.': parseFloat("0" & data[startPos..<pos])
        else: parseFloat(data[startPos..<pos])
    else:
      raise newException(ValueError, CharErrorMsg % [$ch, $pos])
  
  proc parseTerm: float = 
    result = parseFactor()
    while true:
      if eat('*'): result *= parseFactor()
      elif eat('/'): result /= parseFactor()
      elif eat('%'): result = result.fmod(parseFactor())
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
    result = Inf
  except:
    result = NaN