import unittest, strutils

import ../src/latexdsl

## NOTE: Because `MathDelim` is a {.compileTime.} variable, assigning to it at CT
## is done without static.
when (NimMajor, NimMinor, NimPatch) > (1, 7, 0):
  MathDelim = "$$"
else:
  static: MathDelim = "$$"

suite "MathDelim changed in static context":
  test "`math` delimiter can be adjusted in `static` context":
    let b = latex:
      math:
        e^{\pi i} = -1
    echo $b.strip
    check $b.strip == r"$$e^{\pi i}=-1$$"
    echo $b
