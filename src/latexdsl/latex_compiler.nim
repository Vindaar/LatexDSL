# local
import ./dsl_impl

# stdlib
import std / [strutils, os]

# nimble
import pkg / shell

const cfgPreamble = "common_preamble.tex"
const cfgXeLaTeX = "xelatex_fonts.tex"
const cfgLuaLaTeX = "lualatex_fonts.tex"
proc f(fn: string): string = getConfigDir() / "latexdsl" / fn
## These define the used preamble and font settings based on files in the users
## configuration directory. If they don't exist we use the hardcoded values from
## below.
let PreambleText* = if fileExists(f(cfgPreamble)): readFile(f(cfgPreamble))
                   else: ""
let XeFonts*  = if fileExists(f(cfgXeLaTeX)): readFile(f(cfgXeLaTeX))
                   else: ""
let LuaFonts* = if fileExists(f(cfgLuaLaTeX)): readFile(f(cfgLuaLaTeX))
                   else: ""

proc getStandaloneTmpl(): string =
  let common = if PreambleText.len > 0: PreambleText
               else:
                 latex:
                   \usepackage[utf8]{inputenc}
                   \usepackage[margin="2.5cm"]{geometry}
                   \usepackage{unicode-math} # for unicode support in math environments
                   \usepackage{amsmath}
                   \usepackage{siunitx}
                   \usepackage{booktabs}
  result = latex:
    \documentclass[border = "2mm", varwidth]{standalone}
    `common`
    document:
      "$#"

proc xelatexFontSettings*(): string =
  ## XXX: This XeLaTeX support is pretty crappy and easily breaks. :( If someone
  ## knows how to make it robust without specifying every single character or
  ## "unicode class" (of ucharclasses) I'm happy to hear it.
  result = if XeFonts.len > 0: XeFonts
           else:
             """
\usepackage{fontspec}
\usepackage{ucharclasses}

% Set main font as Latin Modern Roman (vectorized Computer Modern)
\setmainfont{CMU Serif}[Ligatures=TeX]

% Fallback font for non-ASCII characters
\newfontfamily{\fallbackfont}{DejaVu Serif}[Ligatures=TeX]
\newfontfamily{\mainfont}{CMU Serif}[Ligatures=TeX]
\setDefaultTransitions{\fallbackfont}{}
"""

proc lualatexFontSettings*(): string =
  result = if LuaFonts.len > 0: LuaFonts
           else:
             """
\usepackage{fontspec}

\directlua{
  luaotfload.add_fallback(
  "FallbackFonts",
  {
        "DejaVu Serif:mode=harf;",
        "DejaVu Sans Mono:mode=harf;",
        % we could add many more fonts here optionally!
    }
  )
}

\setmainfont{CMU Serif}[RawFeature={fallback=FallbackFonts}]
\setmonofont{Inconsolata}[RawFeature={fallback=FallbackFonts}]
"""

proc writeTeXFile*(fname, body, tmpl: string,
                   fullBody = false) =
  let tmpl = if fullBody: body else: tmpl % body
  when nimvm:
    writeFile(fname, tmpl)
  else:
    var f = open(fname, fmWrite)
    f.write(tmpl)
    f.close()

when (NimMajor, NimMinor, NimPatch) >= (2, 0, 0):
  import std / [envvars, strutils]
else:
  import std / [os, strutils]
proc compile*(fname, body: string, tmpl = getStandaloneTmpl(),
              path = "", fullBody = false, verbose = true) =
  ## Writes and compiles the file `fname` with contents `body`. If no explicit
  ## template is given a default template including a few common packages are
  ## included and your `body` is inserted into the `document` part. You can
  ## hand either a custom template, which requires a `$#` field where the body
  ## will be inserted. Or hand an entire TeX file and set `fullBody = true`.
  ##
  ## If `verbose` is `true`, the TeX compilation output will be printed.
  if fname.endsWith(".pdf"):
    echo "[WARNING] Given filename `", fname, "` ends with .pdf. This means we overwrite the temporary ",
     ".tex file that is created!"
  # Allow overwriting by `DEBUG_TEX` environment variable.
  let verbose = getEnv("DEBUG_TEX", $verbose).parseBool

  # get path
  let path = if path.len > 0: path else: fname.parentDir

  # 1. define command to check if TeX compiler exists
  when defined(linux) or defined(macosx):
    let checkCmd = "command -v"
  elif defined(windows):
    let checkCmd = "WHERE"
  else:
    static: error("Unsupported platform for PDF generation. Please open an issue.")

  var generated = false
  template checkAndRun(cmd: untyped): untyped =
    var cfg = { dokCommand, dokError, dokRuntime }
    if verbose:
      cfg.incl dokOutput
    var
      res: string
      err: int
    when nimvm:
      (res, err) = gorgeEx(@[checkCmd, cmd].join(" "))
    else:
      (res, err) = shellVerbose(debugConfig = cfg):
        ($checkCmd) ($cmd)
    if err == 0:
      # 1. patch the TeX file depending on the compiler
      let fontSettings =
        case cmd
        of "xelatex": xelatexFontSettings()
        of "lualatex": lualatexFontSettings()
        else: ""
      var body = body
      if not fullBody:
        body = body.replace(r"\begin{document}", fontSettings & "\n" & r"\begin{document}")
      # 2. write the TeX file with injected body
      writeTexFile(fname, body, tmpl, fullBody)
      when nimvm:
        (res, err) = gorgeEx(@[$cmd, "-output-directory", $path, $fname].join(" "))
      else:
        (res, err) = shellVerbose(debugConfig = cfg):
          ($cmd) "-output-directory" ($path) ($fname)
      if err == 0:
        # successfully generated
        generated = true
        if not verbose: # only print in this case, otherwise the TeX output shows something similar
          echo "Generated: ", fname.replace(".tex", ".pdf")
      else:
        echo "Could not generate PDF from TeX file `" & $fname &
          & "` using TeX compiler: `" & $cmd & "`. Output was: " & res
        #raise newException(IOError, "Could not generate PDF from TeX file `" & $fname &
        #  & "` using TeX compiler: `" & $cmd & "`. Output was: " & res)
  ## Note: `xelatex` may be a bit slower than `xelatex` but at least it has sane
  ## font handling!
  checkAndRun("lualatex")
  if generated: return # success, no need to try `xelatex`
  checkAndRun("xelatex")
  if generated: return # success, no need to try `pdflatex`
  checkAndRun("pdflatex") # currently broken, as we import `unicode-math`
  if not generated:
    raise newException(IOError, "Could not generate a PDF from TeX file " &
      $fname & " as neither `lualatex`, `xelatex` nor `pdflatex` was found in PATH")
