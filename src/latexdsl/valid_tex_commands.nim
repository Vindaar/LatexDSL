type
  LatexCommands* = enum
    INVALID_CMD, `!`, `!x`, `"`, `"o`, `$`, `%`, `&`, `(`, `(.`, `(outdent`,
    `)`, `*`, `+`, `-`, `.`, `.o`, `/`, `<`, `=`, `=o`, `>`, `@`, Aa, Ae,
    Alphcounter, Box, Delta, Diamond, Downarrow, Gamma, H, Ho, Huge, Im, Join,
    L, Lambda, Large, Latex, Leftarrow, Leftrightarrow, Longleftarrow,
    Longleftrightarrow, Longrightarrow, O, Oe, Omega, P, Phi, Pi, Pr, Psi, Re,
    Rightarrow, Romancounter, S, SI, Sigma, Tex, Theta, Uparrow, Updownarrow,
    Upsilon, Vert, Xi, `[`, `]`, `^`, `^o`, `_`, a, aa, abstract, acute,
    acutea, addcontentsline, addcontentslinetoc, addresstext,
    addtocontentstoc, addtocountername, addtolength, ae, aleph, alpha,
    alphcounter, amalg, `and`, angle, appendix, approx, arabiccounter, arccos,
    arcsin, arctan, arg, array, arraycolsep, arrayrulewidth, arraystretch,
    ast, asymp, author, authornames, b, backslash, bar, bara, baselineskip,
    baselinestretch, begin, beta, bf, bibitemref, bibliographyfile,
    bibliographystylestyle, bigcap, bigcirc, bigcup, bigodot, bigoplus,
    bigotimes, bigskip, bigskipamount, bigsqcup, bigtriangledown,
    bigtriangleup, biguplus, bigvee, bigwedge, binname, bmod, bo, boldmath,
    bot, bottomfraction, bottomrule, bowtie, breve, brevea, bullet, c, cal,
    cap, caption, cctext, cdot, cdots, center, centering, chapter,
    chaptertitle, check, checka, chi, circ, circle, circlediameter, cite,
    cleardoublepage, clearpage, clinei, closing, closingtext, clubsuit, co,
    columnsep, columnseprule, columnwidth, cong, contentslinesection, coprod,
    copyright, cos, cosh, cot, coth, cs, csc, cup, d, dag, dagger,
    dashboxdwid, dashv, date, dateadate, day, dblfloatpagefraction,
    dblfloatsep, dbltextfloatsep, dbltopfraction, ddag, ddagger, ddot, ddota,
    ddots, deg, delta, description, det, diamond, diamondsuit, dim,
    displaymath, displaystyle, `div`, `do`, document, documentclass,
    documentstyle, dot, dota, doteq, dotfill, doublerulesep, downarrow, ell,
    em, emptyset, encltext, `end`, enumerate, environment, epsilon, eqnarray,
    equation, equiv, eta, evensidemargin, exists, exp, fbox, fboxrule,
    fboxsep, fboxtext, figure, fill, flat, floatpagefraction, floatsep,
    flushbottom, flushleft, flushright, fnsymbolcounter, footheight,
    footnotemark, footnotesep, footnotesize, footnotetext, footnotetexttext,
    footskip, forall, fracnumerator, framebox, frametext, frown, fussy, gamma,
    gcd, ge, geq, gets, gg, glossaryentry, glossaryentrytext, glossarytext,
    grave, gravea, hat, hata, hbar, headheight, headsep, heartsuit, hfill,
    hline, hom, hookleftarrow, hookrightarrow, hrulefill, hspace, hspacelen,
    huge, hyphenationwordlist, i, iff, imath, `in`, `include`,
    includefilename, includegraphics, includeonlyfile, indexentry,
    indexentrytext, indexspace, indextext, inf, infty, inputfile, int,
    intextsep, invisiblesection, invisiblesubsection, iota, it, item,
    itemindent, itemize, itemsep, j, jmath, kappa, ker, kill, l, label,
    labelsep, labeltext, labelwidth, lambda, land, langle, large, lbrace,
    lbrack, lceil, ldots, le, leadsto, left, leftarrow, lefteqnformula,
    leftharpoondown, leftharpoonup, leftmargin, leftmargini, leftmarginvi,
    leftrightarrow, leq, lfloor, lg, lhd, lim, liminf, limsup, line,
    linebreak, linethicknessdimen, linewidth, list, listoffigures,
    listoftables, listparindent, ll, ln, lnot, log, longleftarrow,
    longleftrightarrow, longmapsto, longrightarrow, lor, lq, makebox,
    makeglossary, makeindex, maketitle, mapsto, marginparpush, marginparsep,
    marginpartext, marginparwidth, markbothlhd, markrightrhd, math, max, mbox,
    mboxtext, medskip, medskipamount, mho, mid, midrule, min, minipage, mit,
    models, month, mp, mu, multicolumnnoc, multiput, nabla, natural, ne,
    nearrow, neg, neq, newcolumntype, newcommand, newcountercounter,
    newenvironment, newenvironmentenvname, newfontcs, newlength, newline,
    newpage, newtheorem, newtheoremenv, ni, nl, nofiles, noindent,
    nolinebreak, nonumber, nopagebreak, normalmarginpar, normalsize, `not`,
    `notin`, nu, num, nwarrow, o, obeycr, oddsidemargin, odot, oe, oint,
    omega, ominus, onecolumn, openingtext, oplus, oslash, otimes, oval,
    overbracetext, overlinetext, owns, pagebreak, pagenumberingstyle,
    pagereftext, pagestyle, pagestylesty, paragraph, parallel, parbox,
    parindent, parsep, parskip, part, partial, partopsep, perp, phi, pi,
    picture, pm, pmodmodulus, poptabs, pounds, prec, preceq, prime, prod,
    propto, protect, ps, psi, pushtabs, put, quad, quotation, quote,
    raggedbottom, raggedleft, raggedright, raiseboxdim, rangle, rbrace,
    rbrack, rceil, refstepcounter, reftext, renewenvironmentenvname,
    restorecr, reversemarginpar, rfloor, rhd, rho, right, rightarrow,
    rightharpoondown, rightharpoonup, rightleftharpoons, rightmargin, rm,
    romancounter, rq, rule, savebox, sc, scriptscriptstyle, scriptsize,
    scriptstyle, searrow, sec, section, sectionmark, setcountercounter,
    setlength, setminus, settowidth, sf, sharp, shortstack, si, sigma,
    signaturetext, sim, simeq, sin, sinh, sl, sloppy, small, smallint,
    smallskip, smallskipamount, smile, spadesuit, sqcap, sqcup, sqrt,
    sqsubset, sqsubseteq, sqsupset, sqsupseteq, ss, stackrelf, stackrelstuff,
    star, stop, subparagraph, subsection, subsectionmark, subset, subseteq,
    subsubsection, succ, succeq, sum, sup, supset, supseteq, surd, swarrow,
    symbolcc, t, tabbing, tabbingsep, tabcolsep, table, tableofcontents,
    tabular, tabularx, tan, tanh, tau, textbf, textfloatsep, textfraction,
    textheight, textit, textstyle, textwidth, thanksfootnote, theorem, theta,
    thicklines, thinlines, thinspace, thispagestylesty, tilde, tildea, times,
    tiny, title, titlepage, titletext, to, today, too, top, topfraction,
    topmargin, toprule, topsep, topskip, triangle, triangleleft,
    triangleright, tt, twocolumn, typein, typeouttext, u, unboldmath,
    underbracetext, underline, underlinetext, unitlength, unlhd, unrhd, uo,
    uparrow, updownarrow, uplus, upsilon, usecountercounter, usepackage, v,
    valuecounter, varepsilon, varphi, varpi, varrho, varsigma, vartheta,
    vdash, vdots, vec, veca, vector, vee, verb, verbatim, verse, vert, vfill,
    vline, vo, vspace, vspacelen, wedge, widehatarg, widetildearg, wp, wr, xi,
    year, zeta, zzz, `|`, `~`, `~o`, `‘`, `‘o`, `’`, `’.`, `’o`,
    draw, node, definecolor, fontsize, rotatebox, path, mycolorbar,
    pgfpathmoveto, pgfpointxy, pgfusepath, tikzpicture, align, aligned, frac
