import std / [osproc, streams, strutils, strscans]

type
  TeXDaemon* = object
    isReady*: bool
    pid*: Process
    stdin*: Stream
    stdout*: Stream

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
    while c != '*' and d.pid.running:
      c = d.stdout.readChar()
      data.add c
    result = data
  else:
    raise newException(IOError, "The TeXDaemon is not running anymore. Reading failed.")

proc close*(td: TexDaemon) =
  if td.isReady:
    td.write(r"\end{document}") # this should shut down the interpreter
    discard td.read()
    if td.pid.running:
      terminate(td.pid)
    #doAssert not td.pid.running
  else:
    doAssert not td.pid.running

proc setupForInput*(t: TeXDaemon): bool =
  let d = t.read()
  result = d[^1] == '*'
  echo "[INFO] TeXDaemon ready for input."

proc initTexDaemon*(texCompiler = "xelatex"): TeXDaemon =
  ## Initializes a TeX compiler to run as a daemon in the background to process
  ## TeX commands for you at will.
  const args = ["-shell-escape"]
  const defaultProcessOptions: set[ProcessOption] = {poStdErrToStdOut, poDaemon, poUsePath}
  let pid = startProcess(texCompiler, args = args, options = defaultProcessOptions)
  result = TeXDaemon(pid: pid,
                     stdin: pid.inputStream,
                     stdout: pid.peekableOutputStream)
  result.isReady = result.setupForInput()

proc process*(d: TeXDaemon, data: string) =
  ## Processes the user data. Can be used to bring the
  ## TeXDaemon into initial processing mode by passing
  ## an initial setup.
  ## This simply discards all read data.
  for line in data.strip.splitLines:
    d.write(line.strip) # write one line
    discard d.read() # read back data, but discard

when isMainModule:
  let d = initTexDaemon()
  echo d.setupForInput()
  const setup = """
\documentclass[draft]{article}

\usepackage{unicode-math}
\usepackage{amsmath}
\usepackage{siunitx}
\usepackage{tikz}

\newbox\mybox
% \newlength\mywidth
% \newlength\myheight
% \newlength\mydepth

\begin{document}
"""

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
