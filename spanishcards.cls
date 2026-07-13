\NeedsTeXFormat{LaTeX2e}[2022-11-01]
\ProvidesClass{spanishcards}[2026-07-13 v0.1 Screen-first Spanish vocabulary cards]

\RequirePackage{iftex}
\ifLuaTeX\else
  \ClassError{spanishcards}
    {SpanishCards requires LuaLaTeX}
    {Compile this document with lualatex or latexmk -lualatex.}
\fi

\LoadClass[UTF8,fontset=fandol,scheme=plain]{ctexart}
\RequirePackage[
  paperwidth=160mm,
  paperheight=100mm,
  margin=7mm,
  noheadfoot
]{geometry}
\RequirePackage{spanishcards}

\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}
\pagestyle{empty}

\AtBeginDocument{%
  \pagecolor{SCPageBackground}%
  \color{SCText}%
}
