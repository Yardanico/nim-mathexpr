## An example REPL for Mathexpr
import strutils, rdstdin, mathexpr
while true:
  let expr = readLineFromStdin("> ")
  if expr in ["exit", "quit", "quit()", "exit()"]:
    quit(0)
  try:
    # Try to evaluate it
    let result = eval(expr)
    echo("$1 = $2" % [expr, $result])
  except:
    echo getCurrentExceptionMsg()
    continue