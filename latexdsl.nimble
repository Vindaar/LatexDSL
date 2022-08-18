# Package

version       = "0.1.8"
author        = "Vindaar"
description   = "A DSL to write LaTeX in Nim. No idea who wants that."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "datamancer"

import os, strutils, strformat
template canImport(x: untyped): untyped =
  compiles:
    import x

when canImport(docs / docs):
  # can define the `gen_docs` task (docs already imported now)
  # this is to hack around weird nimble + nimscript behavior.
  # when overwriting an install nimble will try to parse the generated
  # nimscript file and for some reason then it won't be able to import
  # the module (even if it's put into `src/`).
  task gen_docs, "Generate LatexDSL documentation":
    # build the actual docs and the index
    buildDocs(
      "src/", "docs/",
      defaultFlags = "--hints:off --warnings:off"
    )
