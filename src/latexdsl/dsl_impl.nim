import macros, strutils, strformat, sequtils

import macrocache
const NoCommandChecks = CacheCounter"CommandCounterCheck"
when NoCommandChecks.value > 0:
  import valid_tex_commands_dummy
else:
  import valid_tex_commands

## Decides the math delimiter to use
when not defined(js):
  var MathDelim* {.compileTime.} = "$"
else: # on the JS backend a compileTime variable causes an ICE
  var MathDelim* = "$" # runtime variable

proc `&&`(n, m: NimNode): NimNode = nnkCall.newTree(ident"&&", n, m)

proc `&&`*(s: varargs[string]): string =
  if s.len == 0: result = ""
  elif s.len == 1: result = s[0]
  else:
    for ch in s:
      result &= ch

proc isTexCommand(n: NimNode): bool =
  ## compile time check whether the given is a valid TeX command
  when NoCommandChecks.value > 0:
    result = true
  else:
    let nStr = n.strVal
    var val = INVALID_CMD
    if nStr.len > 0:
      val = parseEnum[LatexCommands](nStr, INVALID_CMD)
    result = val != INVALID_CMD

template checkCmd(arg: NimNode): untyped =
  var cmd = arg
  if "_" in arg.strVal:
    # split by "_" and try each
    let sp = arg.strVal.split("_")
    doAssert sp.len == 2, "Multiple `_` not allowed!"
    cmd = ident(sp[0])
  if not isTexCommand(cmd):
    error("Invalid tex command: " && $(cmd.strVal))

template `\`(n: untyped): string = "\\" && $n

proc makeOpts*(name: string, args: varargs[string]): string =
  result = &"{name}["
  result.add args.join(",")
  result.add "]"

proc makeArg*(arg: string): string =
  result = "{" & $arg & "}"

proc makeBeginEnd*(name, header, body: string): string =
  let headerNoName = multiReplace(header, [(name, "")])
  when (NimMajor, NimMinor, NimPatch) > (1, 7, 0):
    let delim = MathDelim
  else:
    when not defined(js):
      const delim = MathDelim
    else:
      let delim = MathDelim
  if name == "math":
    result = delim & $body & delim
  else:
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
    result = nnkCall.newTree(ident"&&")
    var i = 0
    for ch in n:
      if i == 0:
        result.add toTex(ch)
      else:
        result.add newLit("\n") && toTex(ch)
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
    if n.len == 1:
      # case of empty `{}`
      result = toTex(n[0]) && parseCurly(newLit "")
    else:
      result = toTex(n[0]) && parseCurly(n[1])
  of nnkCurly:
    result = parseCurly(n[0])
  of nnkCall:
    let name = extractName(n[0])
    if name.strVal != "&&":
      # otherwise we're calling this proc again and have already checked the
      # actual command!
      #checkCmd(name)
      discard
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
    elif n[0].strVal == "$" and n[1].kind == nnkPar:
      # argument is a nim node to leave as is and return as a `&&` call (to ignore it further)
      return nnkCall.newTree(ident"&&", n)
    elif n[0].strVal == "$" and n[1].kind == nnkCommand and n[1][0].kind == nnkPar:
      return nnkCall.newTree(
        ident"&&",
        nnkCall.newTree(ident"$", n[1][0])) && parseBody(n[1][1])

    elif n[0].strVal != "\\\\" and hasNoAccQuote:
      error("Invalid command prefix " & $(n[0].strVal))
    if n.len == 3 and n[^1].kind == nnkStmtList:
      # \ prefix and a block at the end. In this case, the block logic takes precedent.
      # We drop the `\` from here on
      let stmtList = parseStmtList(n[2])
      result = beginEndCall(name, toTex(n[1]), stmtList)
    elif n.len == 2:
      result = toTex(n[0]) && toTex(n[1])
    else: error("Invalid nnkPrefix tree with " & $(n.len) & " child nodes!")
  of nnkExprEqExpr:
    result = toTex(n[0]) && newLit("=") && toTex(n[1])
  of nnkCommand:
    doAssert n.len == 2
    result = toTex(n[0]) && newLit(" ") && toTex(n[1])
  of nnkRefTy:
    ## NOTE: this corresponds to the `\ref` command.
    result = newLit"ref" && toTex(n[0])
  of nnkPragma:
    ## Workaround for multiline `{}` arguments with multiple lines starting with `\` commands
    if n[0].kind == nnkExprColonExpr:
      # in this case all children of `n` are actually children on n[0], it's just not
      # parsed that way by the Nim parser
      var nCall = nnkCall.newTree(n[0][0]) # [0][0] is the name + header of the tex begin/end block
      var nStmts = newStmtList()
      # other children of n[0] (RHS of ExprColonExpr) must become StmtList argument 1
      for i in 1 ..< n[0].len:
        nStmts.add n[0][i]
      # finally all other arguments to the pragma are added
      for i in 1 ..< n.len:
        nStmts.add n[i]
      nCall.add nStmts
      result = toTex(nCall)
    else:
      # just convert to simple stmt liste
      var nStmts = nnkStmtList.newTree()
      for ch in n:
        nStmts.add ch
      result = parseCurly(toTex(nStmts))
  of nnkPragmaExpr:
    doAssert n.len == 2
    result = toTex(n[0]) && parseCurly(toTex(n[1]))
  of nnkInfix:
    result = toTex(n[1]) && toTex(n[0]) && toTex(n[2])
  of nnkExprColonExpr:
    doAssert n.len == 2
    let name = extractName(n[0])
    result = beginEndCall(name, toTex(n[0]), toTex(n[1]))
  of nnkBracket:
    result = newLit("[")
    for i, ch in n:
      result = result && parseBody(ch)
      if i < n.len - 1:
        result = result && newLit(", ")
    result = result && newLit("]")
  of nnkAsgn:
    result = parseBody(n[0]) && newLit("=") && parseBody(n[1])
  of nnkTupleConstr:
    result = newLit("(")
    for i, ch in n:
      result = result && parseBody(ch)
      if i < n.len - 1:
        result = result && newLit(", ")
    result = result && newLit(")")
  of nnkIdent: result = toTex(n)
  of nnkIntLit, nnkFloatLit: result = toTex(n)
  of nnkAccQuoted: result = toTex(n)
  of nnkCommentStmt: result = toTex(n)
  #of nnkPar: result = toTex(n)
  of nnkForStmt:
    var n = n
    let tmp = genSym(nskVar, "tmp")
    n[^1] = newAssignment(tmp, tmp && toTex(n[^1]))
    result = quote do:
      block:
        var `tmp`: string
        `n`
        `tmp`
  else:
    error("Invalid kind " & $n.kind)

proc fromAccToDotExpr(n: NimNode): NimNode =
  ## Turns a accent quoted node back into a dot expression to evaluate
  ## the quoted Nim expression.
  doAssert n.kind == nnkAccQuoted
  if n.len == 1:
    result = nnkCall.newTree(ident"$", n[0])
  elif n.len mod 2 == 0:
    error("Invalid term in accent quoted: " & $n.treerepr & ". Only supports " &
      "dot expressions at the moment, e.g. `foo.bar.baz`.")
  else:
    var res: NimNode
    for i in countup(0, n.len - 2, 2):
      ## This processes:
      ## AccQuoted
      ##   Ident "cv"      Iter 0, i = 0
      ##   Ident "."       Iter 0, i = 1
      ##   Ident "cfg"     Iter 0, i = 2;   Iter 1, i = 0
      ##   Ident "."                        Iter 1, i = 1
      ##   Ident "pEmail"                   Iter 1, i = 2
      ## so we reassign to `res` below.
      doAssert n[i+1].kind == nnkIdent and n[i+1].strVal == ".", "The node at index : " & $i & " is not a `.`. Invalid " &
        "node in accent quote: " & $n.treerepr
      if res == nil:
        res = nnkDotExpr.newTree(n[i], n[i+2])
      else:
        # in this case `n[i]` already processed in `res`
        res = nnkDotExpr.newTree(res, n[i+2])
    result = res

proc toTex(n: NimNode): NimNode =
  case n.kind
  of nnkSym: result = n
  of nnkAccQuoted: result = fromAccToDotExpr(n)
  of nnkIdent, nnkStrLit, nnkTripleStrLit, nnkRStrLit:
    let nStr = n.strVal
    result = if nStr == "\\\\": newLit r"\\" else: newLit nStr
  of nnkIntLit, nnkFloatLit: result = n.toStrLit
  of nnkNilLit: result = newLit ""
  of nnkCall:
    if n[0].kind in {nnkIdent, nnkSym} and n[0].strVal == "&&" or
      n[0].kind == nnkSym:
      # already called, just return n
      result = n
    else:
      result = parseBody(n)
  of nnkCommentStmt:
    var cmt: string
    for el in n.strVal.splitLines:
      cmt.add "%" & el
    result = newLit(cmt)
  else: result = parseBody(n)

proc unsym(n: NimNode): NimNode =
  ## *Very* simple "unsym" procedure, replacing all symbols by idents.
  ## Used in the first step before entering the actual latex DSL logic,
  ## to make sure every symbol is an ident, as we have symbol based
  ## logic to detect if we enter a recursive loop.
  case n.kind
  of nnkSym: result = ident(n.strVal)
  else:
    if n.len > 0:
      result = newTree(n.kind)
      for ch in n:
        result.add ch.unsym()
    else:
      result = n

macro latex*(body: untyped): untyped =
  let res = genSym(nskVar, "res")
  result = newStmtList()
  result.add quote do:
    var `res`: string
  for cmd in body:
    let cmdRes = toTex(cmd.unsym)
    result.add quote do:
      `res` = `res` && `cmdRes` && "\n"
  result = quote do:
    block:
      `result`
      `res`
  #echo result.repr
