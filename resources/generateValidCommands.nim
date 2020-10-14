#[
This file generates all valid TeX commands we currently support.
The basis makes the following nice PDF:
https://www.ntg.nl/doc/biemesderfer/ltxcrib.pdf
which is converted to a txt file using `pdftotext`.

We could also use this one:
http://tug.ctan.org/info/symbols/comprehensive/symbols-letter.pdf
but I think that's going too far.
]#
import parseutils, sequtils, streams, sets, algorithm, strutils

const input = "ltxcrib.txt"
const outputTmpl = """
type
  LatexCommands* = enum
"""

const ManualCommandsToAdd = toHashSet(["usepackage", "documentclass", "si", "SI",
                                       "includegraphics", "num", "centering", "label",
                                       "toprule", "midrule", "bottomrule"])

const NimKeywords = toHashSet(["addr", "and", "as", "asm",
                               "bind", "block", "break",
                               "case", "cast", "concept", "const", "continue", "converter",
                               "defer", "discard", "distinct", "div", "do",
                               "elif", "else", "end", "enum", "except", "export",
                               "finally", "for", "from", "func",
                               "if", "import", "in", "include", "interface", "is", "isnot", "iterator",
                               "let",
                               "macro", "method", "mixin", "mod",
                               "nil", "not", "notin",
                               "object", "of", "or", "out",
                               "proc", "ptr",
                               "raise", "ref", "return",
                               "shl", "shr", "static",
                               "template", "try", "tuple", "type",
                               "using",
                               "var",
                               "when", "while",
                               "xor",
                               "yield"])

## We're just going to go through the whole file,
## essentially parsing for commands starting with each
## `\` and stopping at the next whitespace.
## At the end we will filter for unique elements.
## Finally we're going to write an output file containing
## all commands without `\`, separated joined by `, ` and
## split into multiple lines (each starting with 4 spaces)
## after max 80 columns. Finally each command that does not
## contain only letters will be typeset into accented quotes.

proc parseAllCommands(fname: string): HashSet[string] =
  result = initHashSet[string]()
  var
    s = newFileStream(input)
    cmd: string
    ch: char
    parsingCmd = false
    lastWasLetter = false
  if s.isNil:
    echo "Could not open file " & $fname
    return
  while true:
    ch = s.readChar()
    if ch == '\0':
      break
    case ch
    of '\\':
      # start parsing from here
      cmd = ""
      parsingCmd = true
      lastWasLetter = false
    of ' ', '\n':
      if parsingCmd:
        result.incl cmd.nimIdentNormalize
        cmd = ""
      parsingCmd = false
      lastWasLetter = false
    of '{':
      if parsingCmd and (cmd == "begin" or cmd == "end"):
        # parse the content of the {}, the actual command
        result.incl cmd.nimIdentNormalize # make sure begin, end are in it
        cmd = ""
      lastWasLetter = false
    of '}':
      if parsingCmd:
        result.incl cmd.nimIdentNormalize
        parsingCmd = false
      cmd = ""
      lastWasLetter = false
    of 'a' .. 'z', 'A' .. 'Z':
      if parsingCmd:
        cmd.add ch
      lastWasLetter = true
    else:
      if parsingCmd and lastWasLetter:
        result.incl cmd.nimIdentNormalize
        parsingCmd = false
      elif parsingCmd: # if not letters before, just part of the command
        cmd.add ch
      lastWasLetter = false

proc writeValidCommandsFile(validCommands: HashSet[string]) =
  var outf = open("valid_tex_commands.nim", fmWrite)
  outf.write(outputTmpl)
  var line = "    INVALID_CMD, "

  func addCmd(line: var string, cmd: string) =
    if cmd.allCharsInSet(Letters) and cmd notin NimKeywords:
      line.add cmd & ", "
    else:
      line.add "`" & cmd & "`, "

  for cmd in validCommands.toSeq.sorted:
    if cmd.len == 0 or
       '\0' in cmd or
       '#' in cmd or
       ';' in cmd or
       ',' in cmd or
       ':' in cmd:
      continue
    if line.len + cmd.len + 2 < 80:
      line.addCmd(cmd)
    else:
      line.add "\n"
      outf.write(line)
      line = "    "
      line.addCmd(cmd)
  if line.len > 0:
    line = line.strip(leading = false, chars = {',', ' '})
    line.add "\n"
    outf.write(line)
  outf.close()

when isMainModule:
  var validCommands = parseAllCommands(input)
  validCommands = validCommands + ManualCommandsToAdd
  writeValidCommandsFile(validCommands)
