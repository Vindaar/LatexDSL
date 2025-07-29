import ../src/latexdsl
import unittest, strutils
import datamancer

const exp1 = """
\begin{usepackage}[english,german]{random}{moreArg}
more text
\end{usepackage}


\begin{center}
yeah
\end{center}

\documentclass{article}
figure[\textwidth]
command[margin=2cm]{test}
"""

const exp2 = """
\documentclass{article}
\usepackage[german]{babel}
\usepackage[utf8]{inputenc}
\newcolumntype{Y}{>{\raggedleft\arraybackslash}X}
"""

const exp3 = """
\begin{center}
some random stuff
\end{center}
"""

const exp4 = """
\begin{center}

\begin{figure}
\includegraphics[width=0.8\textwidth]{myImage}
\end{figure}

\end{center}
"""

const expFigure = """
\begin{figure}[htbp]
\centering
\includegraphics[width=0.8\textwidth]{/tmp/my_figure.pdf}
\caption{A fancy plot it is!}

\end{figure}
"""

const expFor = """
\begin{tabular}{|r|l|l|l|}
\hline
 & a & b & c
\\
\hline
\textbf{0}
 & 1 & 2 & 3
\\\textbf{1}
 & 4 & 5 & 6
\\\textbf{2}
 & 7 & 8 & 9
\\
\hline
\end{tabular}
"""

suite "LaTeX DSL simple tests":
  test "Multiple TeX statementsn":
    let res = latex:
      \usepackage[english, german]{random}{moreArg}:
        "more text"
      center:
        "yeah"
      \documentclass{article}
      figure[\textwidth]
      command[margin="2cm"]{test}
    check res.strip == exp1.strip

  test "Multiple statements including Nim symbol interpolation":
    let lang = "german"
    let res = latex:
      \documentclass{article}
      \usepackage[`lang`]{babel}
      \usepackage[utf8]{inputenc}
      \newcolumntype{Y}{r">{\raggedleft\arraybackslash}X"}

    check res == exp2

  test "Insertion of begin and end for blocks":
    let res = latex:
      center:
        "some random stuff"
    check res.strip == exp3.strip

  test "Nested blocks":
    let res = latex:
      center:
        figure:
          \includegraphics[width=r"0.8\textwidth"]{myImage}
    check res.strip == exp4.strip


  test "for statements":
    let res = latex:
      tabular{"|r|l|l|l|"}:
        \hline
        for title in ["a", "b", "c"]:
          " &" `title`
        r"\\"
        \hline
        for i, v in [[1, 2, 3], [4, 5, 6], [7, 8, 9]]:
          \textbf{`i`}
          for v in v:
            " &" `v`
          r"\\"
        \hline 
    check res.strip == expFor.strip


  test "textwidth/height":
    check textwidth() == "\\textwidth"
    check textheight() == "\\textheight"
    check textwidth(0.8) == "0.8\\textwidth"
    check textheight(0.8) == "0.8\\textheight"

  test "Insert figure using `figure` func":
    let path = "/tmp/my_figure.pdf"
    let caption = "A fancy plot it is!"
    let res = figure(path, caption, width = textwidth(0.8))
    check res.strip == expFigure.strip

  test "`figure` raises if neither width nor height given":
    let path = "/tmp/my_figure.pdf"
    let caption = "A fancy plot it is!"
    doAssertRaises(ValueError):
      let res = figure(path, caption)

  when not defined(js):
    test "Checking for file in `figure` works as expected":
      let path = "/tmp/my_figure.pdf"
      let caption = "A fancy plot it is!"
      doAssertRaises(AssertionError):
        let res = figure(path, caption, width = textwidth(0.8), checkFile = true)

  test "Multiline `{}` using pragma syntax":
    let exp = """
\newcommand\invisiblesection[1]{{\refstepcounter{section}
\addcontentsline{toc}{section}{\protect\numberline{\thesection}#1}
\sectionmark{#1}}}
"""
    let res = latex:
      \newcommand\invisiblesection[1]{.
        \refstepcounter{section}
        \addcontentsline{toc}{section}{r"\protect\numberline{\thesection}#1"}
        \sectionmark{"#1"}
      .}
    check res.strip == exp.strip

  test "Multiline `{}` using pragma syntax containing a block":
    let body = "my body yay"
    let exp = """
\vspace{0.5cm}
\framebox[\textwidth]{
\begin{minipage}{\dimexpr\linewidth-2\fboxrule-2\fboxsep}
my body yay
\end{minipage}
}
\vspace{0.5cm}  \\
"""
    let res = latex:
      \vspace{"0.5cm"}
      \framebox[\textwidth]{.
        minipage{r"\dimexpr\linewidth-2\fboxrule-2\fboxsep"}:
          `body`
      .}
      \vspace{"0.5cm"} r" \\"
    check res.strip == exp.strip

  test "Multiline `{}` using pragma syntax containing a block with multiple lines":
    ## multiple lines in pragma syntax are special, because the AST is "wrong"
    ## for our purposes and we have to rebuild it (see handling of nnkPragma
    ## + nnkExprColonExpr).
    let body = "my body yay"
    let exp = """
\vspace{0.5cm}
\framebox[\textwidth]{
\begin{minipage}{\dimexpr\linewidth-2\fboxrule-2\fboxsep}
line 1
my body yay
line 3
\end{minipage}
}
\vspace{0.5cm}  \\
"""
    let res = latex:
      \vspace{"0.5cm"}
      \framebox[\textwidth]{.
        minipage{r"\dimexpr\linewidth-2\fboxrule-2\fboxsep"}:
          "line 1"
          `body`
          "line 3"
      .}
      \vspace{"0.5cm"} r" \\"
    check res.strip == exp.strip

  test "`math` helper generates math delimited code":
    let b = latex:
      math:
        e^{\pi i} = -1
    check $b.strip == r"$e^{\pi i}=-1$"

  when not defined(js):
    test "`latex` can be used in CT context":
      const b = latex:
        math:
          e^{\pi i} = -1
      static:
        echo $b
        doAssert $b.strip == r"$e^{\pi i}=-1$", " was ? " & $b

  test "`latex` can be used inside a template (unsym)":
    template nbMath(body: untyped): untyped =
      let s = latex:
        math:
          body
      s

    let b = nbMath:
      e^{\pi i} = -1
    check $b.strip == r"$e^{\pi i}=-1$"

when (NimMajor, NimMinor, NimPatch) >= (1, 6, 0):
  suite "Datamancer DF to table":
    let x = @[1, 2, 3, 4, 5]
    let y = @["a", "b", "c", "d", "e"]
    let df = seqsToDf(x, y)
    test "DF to table, no caption or label":
      let noCptNoLab = """
\begin{table}[htbp]
\centering

\begin{tabular}{l l}
\toprule
x & y\\
\midrule
1 & a\\
2 & b\\
3 & c\\
4 & d\\
5 & e
\bottomrule
\end{tabular}


\end{table}
"""
      check toTexTable(df).strip == noCptNoLab.strip

    test "DF to table, no label":
      let noCpt = """
\begin{table}[htbp]
\centering

\begin{tabular}{l l}
\toprule
x & y\\
\midrule
1 & a\\
2 & b\\
3 & c\\
4 & d\\
5 & e
\bottomrule
\end{tabular}

\caption{test caption}

\end{table}
"""
      check toTexTable(df, caption = "test caption").strip == noCpt.strip

    test "DF to table, both label and caption":
      let both = """
\begin{table}[htbp]
\centering

\begin{tabular}{l l}
\toprule
x & y\\
\midrule
1 & a\\
2 & b\\
3 & c\\
4 & d\\
5 & e
\bottomrule
\end{tabular}

\caption{test caption}
\label{testLabel}

\end{table}
"""
      check toTexTable(df, caption = "test caption",
                       label = "testLabel").strip == both.strip
