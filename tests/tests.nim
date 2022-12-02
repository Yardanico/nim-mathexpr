import mathexpr, unittest, math, strformat
const
  TestCases = [
    ("1", 1.0),
    ("1 ", 1.0),
    ("pi", 3.14159),
    ("e", 2.71828),

    ("atan(1)*4 - pi", 0.0),
    ("2+1", 2+1.0),
    ("(((2+(1))))", 2 + 1.0),

    ("3+2", 3+2.0),
    ("3+2+4", 3+2+4.0),
    ("(3+2)+4", 3+2+4.0),
    ("3+(2+4)", 3+2+4.0),
    ("(3+2+4)", 3+2+4.0),

    ("3*2*4", 3*2*4.0),
    ("(3*2)*4", 3*2*4.0),
    ("3*(2*4)", 3*2*4.0),
    ("(3*2*4)", 3*2*4.0),

    ("3-2-4", 3-2-4.0),
    ("(3-2)-4", (3-2)-4.0),
    ("3-(2-4)", 3-(2-4.0)),
    ("(3-2-4)", 3-2-4.0),

    ("3/2/4", 3.0/2.0/4.0),
    ("(3/2)/4", (3.0/2.0)/4.0),
    ("3/(2/4)", 3.0/(2.0/4.0)),
    ("(3/2/4)", 3.0/2.0/4.0),

    ("(3*2/4)", 3.0*2.0/4.0),
    ("(3/2*4)", 3.0/2.0*4.0),
    ("3*(2/4)", 3.0*(2.0/4.0)),

    ("asin sin .5", 0.5),
    ("sin asin .5", 0.5),
    ("ln exp .5", 0.5),
    ("exp ln .5", 0.5),

    ("asin sin-.5", -0.5),
    ("asin sin-0.5", -0.5),
    ("asin sin -0.5", -0.5),
    ("asin (sin -0.5)", -0.5),
    ("asin (sin (-0.5))", -0.5),
    ("asin sin (-0.5)", -0.5),
    ("(asin sin (-0.5))", -0.5),

    ("log10 1000", 3.0),
    ("log10 1e3", 3.0),
    ("log10(1000)", 3.0),
    ("log10(1e3)", 3.0),
    ("log10 1.0e3", 3.0),
    ("10^5*5e-5", 5.0),

    ("log 1000", 3.0),

    ("ln (e^10)", 10.0),
    ("100^.5+1", 11.0),
    ("100 ^.5+1", 11.0),
    ("100^+.5+1", 11.0),
    ("100^--.5+1", 11.0),
    ("100^---+-++---++-+-+-.5+1", 11.0),
    ("100^-.5+1", 1.1),
    ("100^---.5+1", 1.1),
    ("100^+---.5+1", 1.1),
    ("1e2^+---.5e0+1e0", 1.1),
    ("--(1e2^(+(-(-(-.5e0))))+1e0)", 1.1),

    ("sqrt 100 + 7", 17.0),
    ("sqrt 100 * 7", 70.0),
    ("sqrt (100 * 100)", 100.0),

    ("2^2", 4.0),
    ("pow(2,2)", 4.0),

    ("atan2(1,1)", 0.78539),
    ("atan2(1,2)", 0.463647),
    ("atan2(2,1)", 1.10711487),
    ("atan2(3,4)", 0.643501),
    ("atan2(3+3,4*2)", 0.6435),
    ("atan2(3+3,(4*2))", 0.6435),
    ("atan2((3+3),4*2)", 0.6435),
    ("atan2((3+3),(4*2))", 0.6435),
  ]

  Infs = [
    "1/0",
    "log(0)",
    "pow(2,10000000)"
  ]

  Pows = [
    ("2^3^4", "(2^3)^4"),
    ("-2^2", "-(2^2)"),
    ("--2^2", "2^2"),
    ("---2^2", "-(2^2)"),
    ("-2^2", "-4"),
    ("2^1.1^1.2^1.3", "((2^1.1)^1.2)^1.3"),
    ("2*3^4", "2*(3^4)"),
    ("2*-10^2", "2*-(10^2)")
  ]

  NaNs = [
    "0/0",
    "1%0",
    "1%(1%0)",
    "(1%0)%1",
  ]

  Combinatorics = [
    ("fac(0)", 1.0),
    ("fac(0.2)", 1.0),
    ("fac(1)", 1.0),
    ("fac(2)", 2.0),
    ("fac(3)", 6.0),
    ("fac(4.8)", 24.0),
    ("fac(10)", 3628800.0),

    ("ncr(0,0)", 1.0),
    ("ncr(10,1)", 10.0),
    ("ncr(10,0)", 1.0),
    ("ncr(10,10)", 1.0),
    ("ncr(16,7)", 11440.0),
    ("ncr(16,9)", 11440.0),
    ("ncr(100,95)", 75287520.0),

    ("npr(0,0)", 1.0),
    ("npr(10,1)", 10.0),
    ("npr(10,0)", 1.0),
    ("npr(10,10)", 3628800.0),
    ("npr(20,5)", 1860480.0),
    ("npr(100,4)", 94109400.0),
  ]

proc `~=`(a, b: float): bool =
  ## Checks if difference between two floats is less than 0.0001
  abs(a - b) < 1e-4

suite "Mathexpr tests":
  setup:
    let e = newEvaluator()
  for data in TestCases:
    let (expr, expected) = data
    test(&"{expr} == {expected}"):
      check e.eval(expr) ~= expected

  for expr in Infs:
    test(&"{expr} == Inf"):
      check abs(e.eval(expr)) == Inf

  for data in Pows:
    let (first, second) = data
    test(&"{first} == {second}"):
      let (a, b) = (e.eval(first), e.eval(second))
      check a == b

  for expr in NaNs:
    test(&"{expr} == NaN"):
      check(e.eval(expr).classify == fcNan)

  for data in Combinatorics:
    let (expr, expected) = data
    test(&"{expr} == {expected}"):
      check e.eval(expr) ~= expected

  test "Custom function":
    proc myData(args: seq[float]): float =
      for arg in args: result += arg * 2

    e.addFunc("test", myData)
    check e.eval(
      "test(1, 2, 3, 4, 5) + 35 - 27"
    ) == (myData(@[1.0, 2, 3, 4, 5]) + 35 - 27)

  test "Custom variables":
    e.addVars({"x": 5.0, "y": 36511.0, "z": 5.0})
    check e.eval("x + y - fac(z)") == (5.0 + 36511 - 120)

  test "README example":
    check e.eval("((4 - 2^3 + 1) * -sqrt(3*3+4*4)) / 2") ~= 7.5
    # Add some variables to our Evaluator object
    e.addVars({"a": 5.0})
    check e.eval("+5^+3+1.1 + a") ~= 131.1
    # Variables with the same name overwrite the old ones
    e.addVars({"a": 1.0, "b": 2.0})
    check e.eval("a + b") ~= 3
    
    # Define our custom function which returns 
    # 25 multiplied by all arguments it got
    proc myFunc(args: seq[float]): float =
      result = 25
      for arg in args:
        result *= arg
    
    e.addFunc("work", myFunc)
    check e.eval("work(1, 2, 3) + 5") ~= 155
    
    # Define a custom function which only accepts two arguments
    proc test(a: seq[float]): float = 
      a[0] + a[1]
    
    e.addFunc("test", test, 2)
    check e.eval("test(1, 5)") ~= 6
    
    # In some places parentheses and commas are optional:
    check e.eval("work(1 2 3) + 5") ~= 155
    check e.eval("sqrt 100 + 5") ~= 15