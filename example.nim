## An example REPL for Mathexpr
import strutils, rdstdin, ./mathexpr, tables

# Our variables (they will be available in the REPL)
var ourVars = {"x": 5.0, "y": 6.0, "z": 75.0, "fooBar_123": 1337.0}.newTable()

#[
  You can define custom procedures, which will be available to any
  expression passed to mathexpr
  Procedure should have this type:
    proc (args: seq[float]): float
  If you want to, you can use "func" instead of "proc", 
  but be aware that they're different things
  Try to call this "work" function like this:
  work(fooBar_123, x, y, z, 1234)
]#


proc myFunc(args: seq[float]): float =
  result = 25
  for arg in args:
    echo result, " *= ", arg
    result *= arg

# Add our custom `work` function
mathexpr.functions["work"] = myFunc

while true:
  var expr: string
  try:
    expr = readLineFromStdin("> ")
  except IOError:
    echo "Goodbye!"
    quit()
  
  if expr in ["exit", "quit", "quit()", "exit()"]:
    quit()
  try:
    let result = eval(expr, ourVars)
    echo "$1 = $2" % [expr, $result]
  except:
    echo "Error: ", getCurrentExceptionMsg()
    continue