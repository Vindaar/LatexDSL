import ../src/latexdsl
import unittest, strutils

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
      \\newcolumntype{Y}{r">{\raggedleft\arraybackslash}X"}

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

  test "Checking for file in `figure` works as expected":
    let path = "/tmp/my_figure.pdf"
    let caption = "A fancy plot it is!"
    doAssertRaises(AssertionError):
      let res = figure(path, caption, width = textwidth(0.8), checkFile = true)
