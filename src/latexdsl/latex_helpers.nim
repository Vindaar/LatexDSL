import os, strutils, sequtils

import dsl_impl, valid_tex_commands

type
  ValueLike* = concept v
    $v[string] is string
    $v is string
  DataFrameLike* = concept df
    df.getKeys() is seq[string]
    df.row(int) is ValueLike
    df.len is int

  AlignmentKind* = enum
    akNone = ""
    akLeft = "left"
    akRight = "right"
    akCenter = "center"

proc toStr(akKind: AlignmentKind): string =
  case akKind
  of akNone: result = ""
  of akLeft: result = "l"
  of akRight: result = "r"
  of akCenter: result = "c"

func textwidth*[T](arg: T = ""): string = $arg && "\\textwidth"
func textheight*[T](arg: T = ""): string = $arg && "\\textheight"

# sugar to make using this even neater
proc figure*(path: string,
             caption = "",
             width = "",
             height = "",
             location = "htbp",
             label = "",
             checkFile = false): string =
  ## creates a full figure environment, with a given `caption`.
  ## Either a width or height has to passed, otherwise it will raise
  ## `ValueError`.
  ## The figure placement can be controlled via `location`.
  ## Finally, if `checkFile` is set to true we perform a runtime check
  ## on whether the path points to a valid existing file. In many cases
  ## this is not desired behavior (TeX code may be generated for figures,
  ## which will be generated at a later time), but it can provide a convenient
  ## check if one piece of code is generating both plot and TeX code!
  let size = if width.len > 0:
               "width=" & width
             elif height.len > 0:
               "height=" & height
             else:
               raise newException(ValueError, "Please hand either a width or a height!")
  if checkFile:
    doAssert fileExists(path), "The file " & $path & " for which to generate TeX " &
      "doesn't exist yet!"
  var mainBody = latex:
    \centering
    \includegraphics[`size`]{`path`}

  if label.len > 0:
    let tmp = latex:
      \label{`label`}
    mainBody.add tmp
  if caption.len > 0:
    let tmp = latex:
      \caption{`caption`}
    mainBody.add tmp
  result = latex:
      figure[`location`]:
        `mainBody`

func tableRow*(s: varargs[string]): string =
  ## simply joins a variable number of arguments to a valid row of a TeX table
  for i, el in s:
    if i == 0:
      result.add el
    else:
      result.add " & " & el
  result.add " \\\\\n"

proc toTexTable*(df: DataFrameLike,
                 caption = "",
                 label = "",
                 alignment = "left",
                 location = "htbp"): string =
  ## Turns a DataFrame into a TeX table.
  ## If `alignment` it overrides the `tabular` alignment argument (e.g. `l l l`)
  ## It's possible to set the alignment via:
  ## - left, right, center
  ##   then the number of columns is determined from the data frame, but they are
  ##   all aligned accordingly.
  ## - hand a valid TeX string for alignment
  let keys = df.getKeys()
  let header = keys.join(" & ") & "\\\\"
  var rows: string
  for i in 0 ..< df.len:
    var row = ""
    let dfRow = df.row(i)
    for j, k in keys:
      if j == 0:
        row.add $dfRow[k]
      else:
        row.add " & " & $dfRow[k]
    if i < df.len - 1:
      rows.add row & "\\\\\n"
    else:
      rows.add row

  let align = block:
    var align = ""
    var akKind = parseEnum[AlignmentKind](alignment, akNone)
    if akKind == akNone and alignment.len > 0:
      # use user given alignment
      align = alignment
      doAssert align.strip.split(Whitespace).len == keys.len, "Given user alignment does not " &
        "assign all columns of the DataFrame! Alignment: " & $alignment & " for DataFrame with" &
        $keys.len & " columns."
    else:
      # determine the alignment based on the number of columns
      akKind = if akKind == akNone: akLeft else: akKind
      align = toSeq(0 ..< keys.len).mapIt(toStr(akKind)).join(" ")
    align

  # construct only the table body without possible label, caption
  var mainBody = latex:
    \centering
    \tabular{`align`}:
      \toprule
      `header`
      \midrule
      `rows`
      \bottomrule

  if caption.len > 0:
    ## NOTE: if we try to do `mainBody.add` we run into some bizarre issue
    ## where it complains about `{}` being an undeclared identifier. What's the
    ## problem here?
    let tmp = latex:
      \caption{`caption`}
    mainBody.add tmp
  if label.len > 0:
    let tmp = latex:
      \label{`label`}
    mainBody.add tmp
  result = latex:
    \table[`location`]:
      `mainBody`
