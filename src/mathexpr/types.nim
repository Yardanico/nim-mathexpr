import tables

type
  MathFunction* = proc(args: seq[float]): float

  MathExpression* = object
    eval*: Evaluator
    input*: string
    len*: int
    ch*: char
    pos*: int

  Evaluator* = ref object
    hasFuncs*: bool
    hasVars*: bool
    funcs*: TableRef[string, MathFunction]
    vars*: TableRef[string, float]

  EmptyInput* = object of Exception
  UnbalancedParenthesis* = object of Exception
  UnexpectedCharacter* = object of Exception
  UnknownIdent* = object of Exception
