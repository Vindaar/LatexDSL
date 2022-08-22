import unittest, strutils

import ../src/latexdsl

static: MathDelim = "$$"

suite "MathDelim changed in static context":
  test "`math` delimiter can be adjusted in `static` context":
    let b = latex:
      math:
        e^{\pi i} = -1
    check $b.strip == r"$$e^{\pi i}=-1$$"
    echo $b
