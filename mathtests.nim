import unittest, mathexpr, math

suite "Testing calculations":
  test "1 + 1 == 2.0":
    check teInterp("1 + 1") == 2.0
  
  test "log(10) == 1.0":
    check teInterp("log(10)") == 1.0
  
  test "5*351 == 1755.0":
    check teInterp("5*351") == 1755.0
  
