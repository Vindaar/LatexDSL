import macros, strformat, strutils
export strformat

import latexdsl / valid_tex_commands

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

proc parseStmtList(name, header, n: NimNode): NimNode =
  if n.len > 1:
    result = nnkCall.newTree(ident"&")
    for ch in n:
      result.add toTex(ch)
  elif n.len == 1:
    result = toTex(n[0])
  else:
    result = toTex(n)
  result = nnkCall.newTree(ident"makeBeginEnd",
                           toTex(name),
                           toTex(header),
                           result)

proc extractName(n: NimNode): NimNode =
  if n.len == 0: result = n
  else: result = extractName(n[0])

proc `&`(n, m: NimNode): NimNode = nnkCall.newTree(ident"&", n, m)

proc parseBody(n: NimNode): NimNode =
  case n.kind
  of nnkBracketExpr:
    result = parseBracket(n)
  of nnkCurlyExpr:
    result = toTex(n[0]) & parseCurly(n[1])
  of nnkCall:
    let name = extractName(n[0])
    if name.strVal != "&":
      # otherwise we're calling this proc again and have already checked the
      # actual command!
      checkCmd(name)
    expectKind(n[^1], nnkStmtList)
    result = parseStmtList(name, n[0], n[1])
  of nnkStmtList:
    doAssert false, "Handled above"
  of nnkPrefix:
    # TODO: prefix can have more than 2 children!
    echo n.treeRepr
    let name = extractName(n[1])
    ## We only check the name for prefixed commands, if they use a single `\`
    ## By using `\\` one can circumvent the check to use any command
    if n[0].strVal == "\\":
      checkCmd(name)
    elif n[0].strVal != "\\\\":
      error("Invalid command prefix " & $(n[0].strVal))
    if n.len == 3 and n[^1].kind == nnkStmtList:
      # \ prefix and a block at the end. In this case, the block logic takes precedent.
      # We drop the `\` from here on
      result = parseStmtList(name, toTex(n[1]), n[2])
    elif n.len == 2:
      result = toTex(n[0]) & toTex(n[1])
    else: error("Invalid nnkPrefix tree with " & $(n.len) & " child nodes!")
  of nnkExprEqExpr:
    result = toTex(n[0]) & newLit("=") & toTex(n[1])
  else:
    error("Invalid kind " & $n.kind)

proc toTex(n: NimNode): NimNode =
  case n.kind
  of nnkSym: result = n
  of nnkAccQuoted: result = n[0]
  of nnkIdent, nnkStrLit, nnkTripleStrLit, nnkRStrLit:
    let nStr = n.strVal
    result = if nStr == "\\\\": newLit "\\" else: newLit nStr
  of nnkNilLit: result = newLit ""
  of nnkCall:
    if n[0].strVal == "&":
      # already called, just return n
      result = n
    else:
      result = parseBody(n)
  else: result = parseBody(n)

macro withLatex*(body: untyped): untyped =
  let res = ident"res"
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

  echo result.repr
