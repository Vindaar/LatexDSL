import macros, strformat, strutils, os, sequtils
export strformat

import latexdsl / valid_tex_commands

type
  ValueLike = concept v
    $v[string] is string
    $v is string
  DataFrameLike = concept df
    df.getKeys() is seq[string]
    df.row(int) is ValueLike
    df.len is int

  AlignmentKind = enum
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

proc `&`(n, m: NimNode): NimNode = nnkCall.newTree(ident"&", n, m)

proc `&`*(s: varargs[string]): string =
  if s.len == 0: result = ""
  elif s.len == 1: result = s[0]
  else:
    for ch in s:
      result &= ch

proc isTexCommand(n: NimNode): bool =
  ## compile time check whether the given is a valid TeX command
  let nStr = n.strVal
  let val = parseEnum[LatexCommands](nStr, INVALID_CMD)
  result = val != INVALID_CMD

template checkCmd(arg: NimNode): untyped =
  if not isTexCommand(arg):
    error("Invalid tex command: " & $(arg.strVal))

template `\`(n: untyped): string = "\\" & $n

proc makeOpts*(name: string, args: varargs[string]): string =
  result = &"{name}["
  result.add args.join(",")
  result.add "]"

proc makeArg*(arg: string): string =
  result = "{" & $arg & "}"

proc makeBeginEnd*(name, header, body: string): string =
  let headerNoName = multiReplace(header, [(name, "")])
  result = "\n\\begin{" & $name & "}" & $headerNoName & "\n"
  result.add body & "\n"
  result.add "\\end{" & $name & "}\n"

proc toTex(n: NimNode): NimNode
proc parseBracket(n: NimNode): NimNode =
  var argBracket = nnkBracket.newTree()
  for i in 1 ..< n.len:
    argBracket.add toTex(n[i])
  let n = toTex(n[0])
  result = quote do:
    makeOpts(`n`, `argBracket`)

proc parseCurly(n: NimNode): NimNode =
  let nOut = toTex(n)
  result = quote do:
    makeArg(`nOut`)

proc parseStmtList(n: NimNode): NimNode =
  if n.len > 1:
    result = nnkCall.newTree(ident"&")
    var i = 0
    for ch in n:
      if i == 0:
        result.add toTex(ch)
      else:
        result.add newLit("\n") & toTex(ch)
      inc i
  elif n.len == 1:
    result = toTex(n[0])
  else:
    result = toTex(n)

proc beginEndCall(name, header, n: NimNode): NimNode =
  result = nnkCall.newTree(bindSym"makeBeginEnd",
                           toTex(name),
                           toTex(header),
                           n)

proc extractName(n: NimNode): NimNode =
  if n.len == 0: result = n
  else: result = extractName(n[0])

proc isNotAccQuote(n: NimNode): bool =
  ## recursively check if first child contains accented quote node
  if n.len > 0 and n.kind != nnkAccQuoted:
    result = isNotAccQuote(n[0])
  elif n.len > 0 and n.kind == nnkAccQuoted:
    result = false
  else:
    result = true

proc parseBody(n: NimNode): NimNode =
  case n.kind
  of nnkBracketExpr:
    result = parseBracket(n)
  of nnkCurlyExpr:
    result = toTex(n[0]) & parseCurly(n[1])
  of nnkCurly:
    result = parseCurly(n[0])
  of nnkCall:
    let name = extractName(n[0])
    if name.strVal != "&":
      # otherwise we're calling this proc again and have already checked the
      # actual command!
      checkCmd(name)
    expectKind(n[^1], nnkStmtList)
    let stmtList = parseStmtList(n[1])
    result = beginEndCall(name, n[0], stmtList)
  of nnkStmtList:
    result = parseStmtList(n)
  of nnkPrefix:
    # TODO: prefix can have more than 2 children!
    let name = extractName(n[1])
    ## We only check the name for prefixed commands, if they use a single `\`
    ## By using `\\` one can circumvent the check to use any command
    let hasNoAccQuote = n[1].isNotAccQuote()
    if n[0].strVal == "\\" and hasNoAccQuote:
      checkCmd(name)
    elif n[0].strVal != "\\\\" and hasNoAccQuote:
      error("Invalid command prefix " & $(n[0].strVal))
    if n.len == 3 and n[^1].kind == nnkStmtList:
      # \ prefix and a block at the end. In this case, the block logic takes precedent.
      # We drop the `\` from here on
      let stmtList = parseStmtList(n[2])
      result = beginEndCall(name, toTex(n[1]), stmtList)
    elif n.len == 2:
      result = toTex(n[0]) & toTex(n[1])
    else: error("Invalid nnkPrefix tree with " & $(n.len) & " child nodes!")
  of nnkExprEqExpr:
    result = toTex(n[0]) & newLit("=") & toTex(n[1])
  of nnkCommand:
    doAssert n.len == 2
    result = toTex(n[0]) & toTex(n[1])
  of nnkRefTy:
    ## NOTE: this corresponds to the `\ref` command.
    result = newLit"ref" & toTex(n[0])
  of nnkPragma:
    ## Workaround for multiline `{}` arguments with multiple lines starting with `\` commands
    var nStmts = nnkStmtList.newTree()
    for ch in n:
      nStmts.add ch
    result = parseCurly(nStmts)
  of nnkPragmaExpr:
    doAssert n.len == 2
    result = toTex(n[0]) & toTex(n[1])
  of nnkInfix:
    result = toTex(n[1]) & toTex(n[0]) & toTex(n[2])
  else:
    error("Invalid kind " & $n.kind)

proc toTex(n: NimNode): NimNode =
  case n.kind
  of nnkSym: result = n
  of nnkAccQuoted: result = n[0]
  of nnkIdent, nnkStrLit, nnkTripleStrLit, nnkRStrLit:
    let nStr = n.strVal
    result = if nStr == "\\\\": newLit "\\" else: newLit nStr
  of nnkIntLit, nnkFloatLit: result = n.toStrLit
  of nnkNilLit: result = newLit ""
  of nnkCall:
    if n[0].kind in {nnkIdent, nnkSym} and n[0].strVal == "&" or
      n[0].kind == nnkSym:
      # already called, just return n
      result = n
    else:
      result = parseBody(n)
  else: result = parseBody(n)

macro latex*(body: untyped): untyped =
  let res = genSym(nskVar, "res")
  result = newStmtList()
  result.add quote do:
    var `res`: string
  for cmd in body:
    let cmdRes = toTex(cmd)
    result.add quote do:
      `res` = `res` & `cmdRes` & "\n"
  result = quote do:
    block:
      `result`
      `res`
func textwidth*[T](arg: T = ""): string = $arg & "\\textwidth"
func textheight*[T](arg: T = ""): string = $arg & "\\textheight"

# sugar to make using this even neater
func figure*(path: string,
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
    doAssert existsFile(path), "The file " & $path & " for which to generate TeX " &
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
