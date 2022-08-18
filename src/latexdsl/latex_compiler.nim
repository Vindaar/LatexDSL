# local
import ./dsl_impl

# stdlib
import std / [strutils, os]

# nimble
import pkg / shell

proc getStandaloneTmpl(): string =
  result = latex:
    \documentclass[border = "2mm", varwidth]{standalone}
    \usepackage[utf8]{inputenc}
    \usepackage[margin="2.5cm"]{geometry}
    \usepackage{unicode-math} # for unicode support in math environments
    \usepackage{amsmath}
    \usepackage{siunitx}
    \usepackage{booktabs}
    document:
      "$#"

proc writeTeXFile*(fname, body: string) =
  let tmpl = getStandaloneTmpl()
  var f = open(fname, fmWrite)
  f.write(tmpl % body)
  f.close()

proc compile*(fname, body: string) =
  # 1. write the file
  writeTexFile(fname, body)

  # get path
  let path = fname.parentDir

  # 2. compile
  when defined(linux) or defined(macosx):
    let checkCmd = "command -v"
  elif defined(windows):
    let checkCmd = "WHERE"
  else:
    static: error("Unsupported platform for PDF generation. Please open an issue.")

  var generated = false
  template checkAndRun(cmd: untyped): untyped =
    var (res, err) = shellVerbose:
      ($checkCmd) ($cmd)
    if err == 0:
      (res, err) = shellVerbose:
        ($cmd) "-output-directory" ($path) ($fname)
      if err == 0:
        # successfully generated
        generated = true
      else:
        raise newException(IOError, "Could not generate PDF from TeX file `" & $fname &
          & "` using TeX compiler: `" & $cmd & "`. Output was: " &
          res)
  checkAndRun("xelatex")
  if generated: return # success, no need to try `lualatex`
  ## NOTE: lualatex is 2nd as it's a slower compiler than xelatex
  checkAndRun("lualatex")
  if generated: return # success, no need to try `pdflatex`
  checkAndRun("pdflatex") # currently broken, as we import `unicode-math`
  if not generated:
    raise newException(IOError, "Could not generate a PDF from TeX file " &
      $fname & " as neither `lualatex`, `xelatex` nor `pdflatex` was found in PATH")
