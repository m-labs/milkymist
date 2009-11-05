\NeedsTeXFormat{LaTeX2e}[95/06/01]
\ProvidesClass{kthesis}
              [2000/04/11 Document Class for KTH Theses, version 1.0]
\newcommand\@ptsize{10}
\newif\if@mainmatter \@mainmatterfalse
\newif\if@openright  \@openrighttrue
\@twosidetrue
\DeclareOption{g5paper}%
   {\setlength\paperheight {240mm}%
    \setlength\paperwidth  {170mm}%
    \setlength\textheight  {43pc}%
    \setlength\textwidth   {30pc}}
\DeclareOption{s5paper}%
   {\setlength\paperheight {242mm}%
    \setlength\paperwidth  {165mm}%
    \setlength\textheight  {44pc}%
    \setlength\textwidth   {29pc}}
\DeclareOption{a4paper}%
   {\setlength\paperheight {297mm}%
    \setlength\paperwidth  {210mm}%
    \setlength\textheight  {49pc}%
    \setlength\textwidth   {33pc}}
\DeclareOption{letterpaper}%
   {\setlength\paperheight {11in}%
    \setlength\paperwidth  {8.5in}%
    \setlength\textheight  {47pc}%
    \setlength\textwidth   {36pc}}
\DeclareOption{9pt}{\renewcommand\@ptsize{9}}
\DeclareOption{10pt}{\renewcommand\@ptsize{10}}
\DeclareOption{11pt}{\renewcommand\@ptsize{11}}
\DeclareOption{12pt}{\renewcommand\@ptsize{12}}
\DeclareOption{draft}{\setlength\overfullrule{5pt}}
\DeclareOption{final}{\setlength\overfullrule{0pt}}
\DeclareOption{fleqn}{\input{fleqn.clo}}
\DeclareOption{openright}{\@openrighttrue}
\DeclareOption{openany}{\@openrightfalse}
\DeclareOption{openbib}{%
  \AtEndOfPackage{%
   \renewcommand\@openbib@code{%
      \advance\leftmargin\bibindent
      \itemindent -\bibindent
      \listparindent \itemindent
      \parsep \z@
      }%
   \renewcommand\newblock{\par}}%
}
\ExecuteOptions{g5paper,10pt,final,openright}
\ProcessOptions
\RequirePackage{graphics}
\input{kthbk\@ptsize.clo}
\setlength\lineskip{1\p@}
\setlength\normallineskip{1\p@}
\renewcommand\baselinestretch{}
\setlength\parskip{0\p@ \@plus \p@}
\@lowpenalty   51
\@medpenalty  151
\@highpenalty 301
\clubpenalty=9996
\widowpenalty=9999
\brokenpenalty=4991
\predisplaypenalty=10000
\postdisplaypenalty=1549
\displaywidowpenalty=1602
\setcounter{topnumber}{2}
\renewcommand\topfraction{.7}
\setcounter{bottomnumber}{1}
\renewcommand\bottomfraction{.3}
\setcounter{totalnumber}{3}
\renewcommand\textfraction{.2}
\renewcommand\floatpagefraction{.5}
\setcounter{dbltopnumber}{2}
\renewcommand\dbltopfraction{.7}
\renewcommand\dblfloatpagefraction{.5}
\def\leftmark{\expandafter\@firstoftwo\firstmark{}{}}
\def\rightmark{\expandafter\@secondoftwo\botmark{}{}}
  \def\ps@headings{%
      \let\@oddfoot\@empty\let\@evenfoot\@empty
      \def\@evenhead{\thepage\hfil{\itshape\leftmark}}%
      \def\@oddhead{{\itshape\rightmark}\hfil\thepage}%
      \let\@mkboth\markboth
    \def\chaptermark##1{%
      \markboth {%
        \ifnum \c@secnumdepth >\m@ne
          \if@mainmatter
            \@chapapp\ \thechapter. \ %
          \fi
        \fi
        ##1}{}}%
    \def\sectionmark##1{%
      \markright {%
        \ifnum \c@secnumdepth >\z@
          \thesection. \ %
        \fi
        ##1}}}
\def\ps@myheadings{%
    \let\@oddfoot\@empty\let\@evenfoot\@empty
    \def\@evenhead{\thepage\hfil{\itshape\leftmark}}%
    \def\@oddhead{{\itshape\rightmark}\hfil\thepage}%
    \let\@mkboth\@gobbletwo
    \let\chaptermark\@gobble
    \let\sectionmark\@gobble
    }
\def\title#1{\ifx#1[\let\next\@bracket@title\else%
  \gdef\@title{#1}\gdef\@shorttitle{\@title}\let\next\relax\fi\next}
\def\@bracket@title#1]#2{\gdef\@shorttitle{#1}\gdef\@title{#2}}
\def\author#1{\ifx#1[\let\next\@bracket@author\else%
  \gdef\@author{#1}\gdef\@shortauthor{\@author}\let\next\relax\fi\next}
\def\@bracket@author#1]#2{\gdef\@shortauthor{#1}\gdef\@author{#2}}
\def\type#1{\gdef\@type{#1}}
\def\comment#1{\gdef\@comment{#1}}
\def\department#1{\gdef\@department{#1}}
\def\address#1{\gdef\@address{#1}}
\def\imprint#1{\gdef\@imprint{#1}}
\def\publisher#1{\gdef\@publisher{#1}}
\def\trita#1{\gdef\@trita{#1}}
\def\issn#1{\gdef\@issn{#1}}
\def\isrn#1{\gdef\@isrn{#1}}
\def\isbn#1{\@isbntrue \gdef\@isbn{#1}}
\def\dedication#1{\@dedicationtrue \gdef\@dedication{#1}}
\newif\if@isbn \@isbnfalse
\newif\if@dedication \@dedicationfalse
\def\@shortauthor{\@author}
\def\@shorttitle{\@title}
\def\@type{\@latex@warning{No report type given}}
\def\@comment{\relax}
\def\@imprint{\@latex@warning{No imprint given}}
\def\@institute{Royal Institute of Technology}
\def\@department{\@latex@warning{No department given}}
\def\@address{\@latex@warning{No address to the author given}}
\def\@publisher{\@latex@warning{No publisher given}}
\def\@trita{\@latex@warning{No TRITA number given}}
\def\@issn{\@latex@warning{No ISSN given}}
\def\@isrn{\@latex@warning{No ISRN given}}
\let\thanks\empty
\newcommand\@make@title@page{%
  \thispagestyle{empty}%
  \noindent%
  \vbox to 5mm{\vglue-\headheight\vglue-\headsep
      \hbox{\includegraphics{kthtext.eps}}\vss}%
  \hfill%
  \if@isbn\else%
  \vbox to 0mm{\vglue-\headheight\vglue-\headsep\scriptsize
      \hbox to 0mm{\hss TRITA-\@trita}
      \hbox to 0mm{\hss ISSN~\@issn}
      \hbox to 0mm{\hss ISRN~\@isrn}\vss}%
  \fi\par
  \vskip 120\p@
  \begin{center}%
    {\LARGE \@title \par}%
    \vskip 3em%
    {\Large
     \lineskip .75em%
      \begin{tabular}[t]{c}%
        \@author
      \end{tabular}\par}%
    \vfill%
    {\large \@imprint \par}
    \vskip 1em%
    {\large
     \lineskip .75em%
      \begin{tabular}[t]{c}%
        \@type \\ \@institute \\ \@department
      \end{tabular}\par}%
  \end{center}\par
  \setcounter{footnote}{0}}
\newcommand\@maketitle{%
  \cleardoublepage
  \@make@title@page%
  \clearpage
  \thispagestyle{empty}%
  \vglue 0pt plus 1fill
  \noindent%
  \@comment%
  \par%
  \vskip 1.5em\relax%
  \noindent\if@isbn%
    ISBN~\@isbn \\[\smallskipamount]
    TRITA-\@trita \\
    ISSN~\@issn \\
    ISRN~\@isrn \\[1.5em]
  \fi%
  \copyright \space \@author, \@date \\[1.5em]
  \@publisher, \@imprint \par
  \newpage
  \global\let\@maketitle\relax
  \global\let\title\relax
  \global\let\author\relax
  \global\let\date\relax
  \global\let\type\relax
  \global\let\comment\relax
  \global\let\department\relax
  \global\let\address\relax
  \global\let\imprint\relax
  \global\let\publisher\relax
  \global\let\trita\relax
  \global\let\issn\relax
  \global\let\isrn\relax
  \global\let\isbn\relax
  \global\let\dedication\relax
  \global\let\and\relax
}
\AtBeginDocument{%
  \@ifpackageloaded{babel}{%
    \addto\captionsenglish{\def\acknowledgmentsname{Acknowledgments}}%
    \addto\captionsswedish{\def\acknowledgmentsname{Tack}}}{}%
  \@maketitle}
\newcommand{\acknowledgmentsname}{Acknowledgments}
\newenvironment{acknowledgments}{%
  \chapter*{\acknowledgmentsname%
    \@mkboth{\acknowledgmentsname}{\acknowledgmentsname}}}{}
\newenvironment{preface}{%
  \chapter*{\prefacename%
    \@mkboth{\prefacename}{\prefacename}}}{}
\newenvironment{abstract}{%
  \cleardoublepage\thispagestyle{plain}%
  \section*{\abstractname%
    \@mkboth{\abstractname}{\abstractname}}%
}{%
  \par\medskip\vbox{\scriptsize\hbox to\textwidth{%
    \hss\if@isbn ISBN~\@isbn\space$\bullet$\space\fi%
    TRITA-\@trita\space$\bullet$\space%
    ISSN~\@issn\space$\bullet$\space%
    ISRN~\@isrn\hss}}\par
  \clearpage}
\newcommand*\chaptermark[1]{}
\setcounter{secnumdepth}{2}
\newcounter {part}
\newcounter {chapter}
\newcounter {section}[chapter]
\newcounter {subsection}[section]
\newcounter {subsubsection}[subsection]
\newcounter {paragraph}[subsubsection]
\newcounter {subparagraph}[paragraph]
\renewcommand \thepart {\@Roman\c@part}
\renewcommand \thechapter {\@arabic\c@chapter}
\renewcommand \thesection {\thechapter.\@arabic\c@section}
\renewcommand\thesubsection   {\thesection.\@arabic\c@subsection}
\renewcommand\thesubsubsection{\thesubsection .\@arabic\c@subsubsection}
\renewcommand\theparagraph    {\thesubsubsection.\@arabic\c@paragraph}
\renewcommand\thesubparagraph {\theparagraph.\@arabic\c@subparagraph}
\newcommand\@chapapp{\chaptername}
\newcommand\mainmatter{%
  \cleardoublepage
  \newpage
  \@mainmattertrue
  \pagestyle{headings}
  \pagenumbering{arabic}
  \if@dedication
  \thispagestyle{empty}
  \vglue 120\p@
  \begin{center}%
    {\LARGE\itshape \@dedication \par}%
  \end{center}\par
  \vfil
  \setcounter{footnote}{0}%
  \clearpage
  \thispagestyle{empty}%
  \vglue 0pt plus 1fill
  \newpage
  \fi
  \global\let\@title\relax
  \global\let\@author\relax
  \global\let\@date\relax
  \global\let\@type\relax
  \global\let\@comment\relax
  \global\let\@department\relax
  \global\let\@address\relax
  \global\let\@imprint\relax
  \global\let\@publisher\relax
  \global\let\@trita\relax
  \global\let\@issn\relax
  \global\let\@isrn\relax
  \global\let\@isbn\relax
  \global\let\@dedication\relax}
\newcommand\part{%
  \cleardoublepage
  \thispagestyle{plain}%
  \null\vfil
  \secdef\@part\@spart}

\def\@part[#1]#2{%
    \ifnum \c@secnumdepth >-2\relax
      \refstepcounter{part}%
      \addcontentsline{toc}{part}{\thepart\hspace{1em}#1}%
    \else
      \addcontentsline{toc}{part}{#1}%
    \fi
    \markboth{}{}%
    {\centering
     \interlinepenalty \@M
     \normalfont
     \ifnum \c@secnumdepth >-2\relax
       \huge\bfseries \partname~\thepart
       \par
       \vskip 20\p@
     \fi
     \Huge \bfseries #2\par}%
    \@endpart}
\def\@spart#1{%
    {\centering
     \interlinepenalty \@M
     \normalfont
     \Huge \bfseries #1\par}%
    \@endpart}
\def\@endpart{\vfil\newpage
              \null
              \thispagestyle{plain}%
              \newpage}
\newcommand\chapter{\if@openright\cleardoublepage\else\clearpage\fi
                    \thispagestyle{plain}%
                    \global\@topnum\z@
                    \@afterindentfalse
                    \secdef\@chapter\@schapter}
\def\@chapter[#1]#2{\ifnum \c@secnumdepth >\m@ne
                       \if@mainmatter
                         \refstepcounter{chapter}%
                         \typeout{\@chapapp\space\thechapter.}%
                         \addcontentsline{toc}{chapter}%
                                   {\protect\numberline{\thechapter}#1}%
                       \else
                         \addcontentsline{toc}{chapter}{#1}%
                       \fi
                    \else
                      \addcontentsline{toc}{chapter}{#1}%
                    \fi
                    \chaptermark{#1}%
                    \addtocontents{lof}{\protect\addvspace{10\p@}}%
                    \addtocontents{lot}{\protect\addvspace{10\p@}}%
                    \@makechapterhead{#2}%
                    \@afterheading}
\def\@makechapterhead#1{%
  \vspace*{50\p@}%
  {\parindent \z@ \raggedright \normalfont
    \ifnum \c@secnumdepth >\m@ne
      \if@mainmatter
        \huge\bfseries \@chapapp\space \thechapter
        \par\nobreak
        \vskip 20\p@
      \fi
    \fi
    \interlinepenalty\@M
    \Huge \bfseries #1\par\nobreak
    \vskip 40\p@ \@plus 10\p@
  }}
\def\@schapter#1{\@makeschapterhead{#1}%
                 \@afterheading}
\def\@makeschapterhead#1{%
  \vspace*{50\p@}%
  {\parindent \z@ \raggedright
    \normalfont
    \interlinepenalty\@M
    \Huge \bfseries  #1\par\nobreak
    \vskip 40\p@ \@plus 15\p@
  }}
\newcommand\section{\@startsection {section}{1}{\z@}%
                      {-3.5ex \@plus -1ex \@minus -.2ex}%
                      {2.3ex \@plus.2ex}%
                      {\normalfont\Large\bfseries\boldmath}}
\newcommand\subsection{\@startsection{subsection}{2}{\z@}%
                      {-3.25ex\@plus -1ex \@minus -.2ex}%
                      {1.5ex \@plus .2ex}%
                      {\normalfont\large\bfseries\boldmath}}
\newcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
                      {-3.25ex\@plus -1ex \@minus -.2ex}%
                      {1.5ex \@plus .2ex}%
                      {\normalfont\normalsize\bfseries\boldmath}}
\newcommand\paragraph{\@startsection{paragraph}{4}{\z@}%
                      {3.25ex \@plus1ex \@minus.2ex}%
                      {-1em}%
                      {\normalfont\normalsize\bfseries\boldmath}}
\newcommand\subparagraph{\@startsection{subparagraph}{5}{\parindent}%
                      {3.25ex \@plus1ex \@minus .2ex}%
                      {-1em}%
                      {\normalfont\normalsize\bfseries\boldmath}}
\setlength\leftmargini  {2.5em}
\leftmargin  \leftmargini
\setlength\leftmarginii  {2.2em}
\setlength\leftmarginiii {1.87em}
\setlength\leftmarginiv  {1.7em}
\setlength\leftmarginv  {1em}
\setlength\leftmarginvi {1em}
\setlength  \labelsep  {.5em}
\setlength  \labelwidth{\leftmargini}
\addtolength\labelwidth{-\labelsep}
\@beginparpenalty -\@lowpenalty
\@endparpenalty   -\@lowpenalty
\@itempenalty     -\@lowpenalty
\renewcommand\theenumi{\@arabic\c@enumi}
\renewcommand\theenumii{\@alph\c@enumii}
\renewcommand\theenumiii{\@roman\c@enumiii}
\renewcommand\theenumiv{\@Alph\c@enumiv}
\newcommand\labelenumi{\theenumi.}
\newcommand\labelenumii{(\theenumii)}
\newcommand\labelenumiii{\theenumiii.}
\newcommand\labelenumiv{\theenumiv.}
\renewcommand\p@enumii{\theenumi}
\renewcommand\p@enumiii{\theenumi(\theenumii)}
\renewcommand\p@enumiv{\p@enumiii\theenumiii}
\newcommand\labelitemi{\textbullet}
\newcommand\labelitemii{\normalfont\bfseries \textendash}
\newcommand\labelitemiii{\textasteriskcentered}
\newcommand\labelitemiv{\textperiodcentered}
\newenvironment{description}
               {\list{}{\labelwidth\z@ \itemindent-\leftmargin
                        \let\makelabel\descriptionlabel}}
               {\endlist}
\newcommand*\descriptionlabel[1]{\hspace\labelsep
                                \normalfont\bfseries #1}
\newenvironment{verse}
               {\let\\\@centercr
                \list{}{\itemsep      \z@
                        \itemindent   -1.5em%
                        \listparindent\itemindent
                        \rightmargin  \leftmargin
                        \advance\leftmargin 1.5em}%
                \item\relax}
               {\endlist}
\newenvironment{quotation}
               {\list{}{\listparindent 1.5em%
                        \itemindent    \listparindent
                        \rightmargin   \leftmargin
                        \parsep        \z@ \@plus\p@}%
                \item\relax}
               {\endlist}
\newenvironment{quote}
               {\list{}{\rightmargin\leftmargin}%
                \item\relax}
               {\endlist}
\newcommand\appendix{\par
  \setcounter{chapter}{0}%
  \setcounter{section}{0}%
  \renewcommand\@chapapp{\appendixname}%
  \renewcommand\thechapter{\@Alph\c@chapter}}
\setlength\arraycolsep{5\p@}
\setlength\tabcolsep{6\p@}
\setlength\arrayrulewidth{.4\p@}
\setlength\doublerulesep{2\p@}
\setlength\tabbingsep{\labelsep}
\skip\@mpfootins = \skip\footins
\setlength\fboxsep{3\p@}
\setlength\fboxrule{.4\p@}
\@addtoreset {equation}{chapter}
\renewcommand\theequation
  {\ifnum \c@chapter>\z@ \thechapter.\fi \@arabic\c@equation}
\newcounter{figure}[chapter]
\renewcommand \thefigure
     {\ifnum \c@chapter>\z@ \thechapter.\fi \@arabic\c@figure}
\def\fps@figure{tbp}
\def\ftype@figure{1}
\def\ext@figure{lof}
\def\fnum@figure{\figurename~\thefigure}
\newenvironment{figure}
               {\@float{figure}}
               {\end@float}
\newenvironment{figure*}
               {\@dblfloat{figure}}
               {\end@dblfloat}
\newcounter{table}[chapter]
\renewcommand \thetable
     {\ifnum \c@chapter>\z@ \thechapter.\fi \@arabic\c@table}
\def\fps@table{tbp}
\def\ftype@table{2}
\def\ext@table{lot}
\def\fnum@table{\tablename~\thetable}
\newenvironment{table}
               {\@float{table}}
               {\end@float}
\newenvironment{table*}
               {\@dblfloat{table}}
               {\end@dblfloat}
\newlength\abovecaptionskip
\newlength\belowcaptionskip
\newlength\captionindent
\setlength\abovecaptionskip{10\p@}
\setlength\belowcaptionskip{0\p@}
\setlength\captionindent{\leftmargini}
\def\onecaptflag{268 }
\long\def\@makecaption#1#2{\let\@tempa\relax
  {\advance\leftskip\captionindent
   \advance\rightskip\captionindent
   \ifdim\prevdepth>-99\p@ \vskip\abovecaptionskip \relax 
   \else \def\@tempa{\vbox to\topskip{}}\fi
   \footnotesize{\bfseries #1.} \@tempa \vadjust{\penalty \onecaptflag}#2\par
   \ifnum\lastpenalty=\onecaptflag
      \unpenalty \setbox\@tempboxa\lastbox
      \nointerlineskip
      \hbox to\hsize{\hskip\parfillskip\unhbox\@tempboxa}%
   \fi \vskip\belowcaptionskip}}
\newcommand\@pnumwidth{1.85em}
\newcommand\@tocrmarg{2.55em}
\newcommand\@dotsep{4.5}
\setcounter{tocdepth}{2}
\newcommand\tableofcontents{%
    \chapter*{\contentsname
        \@mkboth{\contentsname}{\contentsname}}%
    \@starttoc{toc}%
    }
\newcommand*\l@part[2]{%
  \ifnum \c@tocdepth >-2\relax
    \addpenalty{-\@highpenalty}%
    \addvspace{2.25em \@plus\p@}%
    \begingroup
      \setlength\@tempdima{3em}%
      \parindent \z@ \rightskip \@pnumwidth
      \parfillskip -\@pnumwidth
      {\leavevmode
       \large \bfseries #1\hfil \hb@xt@\@pnumwidth{\hss #2}}\par
       \nobreak
         \global\@nobreaktrue
         \everypar{\global\@nobreakfalse\everypar{}}%
    \endgroup
  \fi}
\newcommand*\l@chapter[2]{%
  \ifnum \c@tocdepth >\m@ne
    \addpenalty{-\@highpenalty}%
    \vskip 1.0em \@plus\p@
    \setlength\@tempdima{1.5em}%
    \begingroup
      \parindent \z@ \rightskip \@pnumwidth
      \parfillskip -\@pnumwidth
      \leavevmode \bfseries
      \advance\leftskip\@tempdima
      \hskip -\leftskip
      #1\nobreak\hfil \nobreak\hb@xt@\@pnumwidth{\hss #2}\par
      \penalty\@highpenalty
    \endgroup
  \fi}
\newcommand*\l@section{\@dottedtocline{1}{1.5em}{2.3em}}
\newcommand*\l@subsection{\@dottedtocline{2}{3.8em}{3.2em}}
\newcommand*\l@subsubsection{\@dottedtocline{3}{7.0em}{4.1em}}
\newcommand*\l@paragraph{\@dottedtocline{4}{10em}{5em}}
\newcommand*\l@subparagraph{\@dottedtocline{5}{12em}{6em}}
\newcommand\listoffigures{%
    \chapter*{\listfigurename
      \@mkboth{\listfigurename}{\listfigurename}}%
    \@starttoc{lof}%
    }
\newcommand*\l@figure{\@dottedtocline{1}{1.5em}{2.3em}}
\newcommand\listoftables{%
    \chapter*{\listtablename
      \@mkboth{\listtablename}{\listtablename}}%
    \@starttoc{lot}%
    }
\let\l@table\l@figure
\newdimen\bibindent
\setlength\bibindent{1.5em}
\newenvironment{thebibliography}[1]
     {\chapter*{\bibname
        \@mkboth{\bibname}{\bibname}}%
      \list{\@biblabel{\@arabic\c@enumiv}}%
           {\settowidth\labelwidth{\@biblabel{#1}}%
            \leftmargin\labelwidth
            \advance\leftmargin\labelsep
            \@openbib@code
            \usecounter{enumiv}%
            \let\p@enumiv\@empty
            \renewcommand\theenumiv{\@arabic\c@enumiv}}%
      \sloppy
      \clubpenalty4000
      \@clubpenalty \clubpenalty
      \widowpenalty4000%
      \sfcode`\.\@m}
     {\def\@noitemerr
       {\@latex@warning{Empty `thebibliography' environment}}%
      \endlist}
\newcommand\newblock{\hskip .11em\@plus.33em\@minus.07em}
\let\@openbib@code\@empty
\newenvironment{theindex}
               {\columnseprule \z@
                \columnsep 35\p@
                \twocolumn[\@makeschapterhead{\indexname}]%
                \@mkboth{\indexname}{\indexname}%
                \thispagestyle{plain}\parindent\z@
                \parskip\z@ \@plus .3\p@\relax
                \let\item\@idxitem}
               {\onecolumn}
\newcommand\@idxitem{\par\hangindent 40\p@}
\newcommand\subitem{\@idxitem \hspace*{20\p@}}
\newcommand\subsubitem{\@idxitem \hspace*{30\p@}}
\newcommand\indexspace{\par \vskip 10\p@ \@plus5\p@ \@minus3\p@\relax}
\renewcommand\footnoterule{%
  \kern-3\p@
  \hrule\@width.4\columnwidth
  \kern2.6\p@}
\@addtoreset{footnote}{chapter}
\newcommand\@makefntext[1]{%
    \parindent 1em%
    \noindent
    \hb@xt@1.8em{\hss\@makefnmark}#1}
\newcommand{\abstractname}{Abstract}
\newcommand{\contentsname}{Contents}
\newcommand{\listfigurename}{List of Figures}
\newcommand{\listtablename}{List of Tables}
\newcommand{\bibname}{Bibliography}
\newcommand{\indexname}{Index}
\newcommand{\figurename}{Figure}
\newcommand{\tablename}{Table}
\newcommand{\prefacename}{Preface}
\newcommand{\partname}{Part}
\newcommand{\chaptername}{Chapter}
\newcommand{\appendixname}{Appendix}
\newcommand{\today}{}
\edef\today{\ifcase\month\or
  January\or February\or March\or April\or May\or June\or
  July\or August\or September\or October\or November\or December\fi
  \space\number\day, \number\year}
\setlength\columnsep{10\p@}
\setlength\columnseprule{0\p@}
\onecolumn
\@mainmatterfalse
\pagenumbering{roman}
\pagestyle{headings}
\def\cleardoublepage{\clearpage\ifodd\c@page\else
    \thispagestyle{plain}\hbox{}\newpage\fi}
\endinput
