# Package

version       = "1.1.3"
author        = "Daniil Yarancev"
description   = "MathExpr - tiny mathematical expression evaluator library"
license       = "MIT"
skipFiles     = @["tests.nim", "example.nim"]
# Dependencies

requires "nim >= 0.18.0"

task test, "Runs the test suite":
  exec "nim c -r tests.nim"
