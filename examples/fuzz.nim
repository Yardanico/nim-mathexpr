import os, mathexpr
let data = readFile(paramStr(1))

try:
  let e = newEvaluator()
  echo e.eval(data)
except ValueError:
  echo "error"