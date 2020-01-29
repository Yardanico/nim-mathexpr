import mathexpr


let e = newEvaluator()

while true:
  stdout.write("mathexpr>>> ")
  let data = stdin.readLine()
  if data == "exit": break
  try:
    echo data, " = ", e.eval(data)
  except Exception as ex:
    echo "Exception: ", ex.msg