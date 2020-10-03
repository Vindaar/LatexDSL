import macros, strformat, strutils
export strformat

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
    var m = n[0]
    let name = extractName(m)
    expectKind(n[1], nnkStmtList)
    result = parseStmtList(name, m, n[1])
  of nnkStmtList:
    doAssert false, "Handled above"
  of nnkPrefix:
    result = toTex(n[0]) & toTex(n[1])
  of nnkExprEqExpr:
    result = toTex(n[0]) & newLit("=") & toTex(n[1])
  else:
    error("Invalid kind " & $n.kind)

proc toTex(n: NimNode): NimNode =
  case n.kind
  of nnkSym: result = n
  of nnkAccQuoted: result = n[0]
  of nnkIdent, nnkStrLit, nnkTripleStrLit, nnkRStrLit: result = newLit n.strVal
  of nnkNilLit: result = newLit ""
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
