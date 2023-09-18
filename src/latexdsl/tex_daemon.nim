import std / [osproc, streams, strutils, strscans]

type
  TeXDaemon* = object
    pid*: Process
    stdin*: Stream
    stdout*: Stream

proc initTexDaemon*(): TeXDaemon =
  const cmd = "xelatex"
  const args = ["-shell-escape"]
  const defaultProcessOptions: set[ProcessOption] = {poStdErrToStdOut, poDaemon, poUsePath}
  let pid = startProcess(cmd, args = args, options = defaultProcessOptions)
  echo "Pid: ", pid.repr
  result = TeXDaemon(pid: pid,
                     stdin: pid.inputStream,
                     stdout: pid.peekableOutputStream)

proc write*(d: TeXDaemon, line: string) =
  if d.pid.running:
    d.stdin.write(line & "\n")
    d.stdin.flush()
  else:
    raise newException(IOError, "The TeXDaemon is not running anymore. Write failed.")

proc read*(d: TeXDaemon): string =
  ## Reads until it encounters a `*`, which indicates the prompt of the TeX
  ## interpreter (the first time it is two `**`). Returns all read data.
  if d.pid.running:
    var data = newStringOfCap(1000)
    var c: char
    while c != '*':
      c = d.stdout.readChar()
      data.add c
    result = data
  else:
    raise newException(IOError, "The TeXDaemon is not running anymore. Reading failed.")

proc setupForInput*(t: TeXDaemon) =
  let d = t.read()
  echo "TeXDaemon ready for input."
  echo d
  doAssert d[^1] == '*'

proc process*(d: TeXDaemon, data: string) =
  ## Processes the user data. Can be used to bring the
  ## TeXDaemon into initial processing mode by passing
  ## an initial setup.
  ## This simply discards all read data.
  for line in data.strip.splitLines:
    echo "Writing: ", line
    d.write(line) # write one line
    echo "---------read"
    echo d.read() # read back data
    echo "-------------"

const sizeCommands = """
\typeout{\the\wd\mybox} % Width
\typeout{\the\ht\mybox} % Height
\typeout{\the\dp\mybox} % Depth
"""

proc checkSize(td: TeXDaemon, style, arg: string): (float, float, float) =
  ## Checks the of the given argument if formatted by LaTeX
  let boxArg = """$#
\sbox{\mybox}{$#}
""" % [style, arg]
  td.process(boxArg)
  # after processing write the size commands and read back the data
  var
    w: float
    h: float
    d: float
    matched = false
    idx = 0
  for cmd in sizeCommands.strip.splitLines():
    echo "Writing: ", cmd
    td.write(cmd)
    var res = td.read()
    while "pt" notin res: ## If there is some more data in the stream before, make all read
      res = td.read()
    echo "READ: ", res
    case idx
    of 0: (matched, w) = res.strip().scanTuple("$fpt")
    of 1: (matched, h) = res.strip().scanTuple("$fpt")
    of 2: (matched, d) = res.strip().scanTuple("$fpt")
    else: doAssert false, "Why at index : " & $idx
    doAssert matched, "Did not match '$fpt', input was: " & $res
    inc idx
  result = (w, h, d)

const setup = """
\documentclass[draft]{article}

\usepackage{unicode-math}
\usepackage{amsmath}
\usepackage{siunitx}
\usepackage{tikz}

\newbox\mybox
\newlength\mywidth
\newlength\myheight
\newlength\mydepth

\begin{document}
"""

let d = initTexDaemon()
d.setupForInput()
d.process(setup)

let style = r"\fontsize{12.0}{14.4}\selectfont"
let arg = r"\texttt{B:\ (x:\ -3.9e-07\ ,\ y:\ 0.08271)}"
echo d.checkSize(style, arg)

let style2 = r"\fontsize{16.0}{19.0}\selectfont"
let arg2 = r"\texttt{C:\ (x:\ -3.4e-07\ ,\ y:\ 0.08271)}"
echo d.checkSize(style2, arg2)

#let data = readFile("/tmp/stuff.tex")
#
#for line in data.strip.splitLines:
#  echo "Writing: ", line
#  d.write(line) # write one line
#  echo "---------read"
#  echo d.read() # read back data
