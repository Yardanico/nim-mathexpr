## An example REPL for Mathexpr
import strutils, rdstdin, ./mathexpr, tables

# Our variables (they will be available in the REPL)
var ourVars = {"x": 5.0, "y": 6.0, "z": 75.0}.newTable()

# Procedure should have this type:
# proc(args: seq[float]): float
proc mySum(args: seq[float]): float = 
  for arg in args: result += arg

# Add our custom `sum` function
mathexpr.functions["sum"] = mySum

while true:
  var expr: string
  try:
    expr = readLineFromStdin("> ")
  except IOError:
    echo "Goodbye!"
    quit()
  
  if expr in ["exit", "quit", "quit()", "exit()"]:
    quit(0)
  try:
    let result = eval(expr, ourVars)
    echo "$1 = $2" % [expr, $result]
  except:
    echo getCurrentExceptionMsg()
    continue