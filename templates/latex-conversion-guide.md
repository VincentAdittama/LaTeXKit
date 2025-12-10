# LaTeX Conversion Guide

**Purpose**: This guide provides rules and examples for converting Markdown to LaTeX format.

---

## ⚠️ CRITICAL WARNING: Backslash Escape Issues

**Common ChatGPT/OpenAI Error**: When generating LaTeX code, the LLM may incorrectly interpret `\t` in LaTeX commands as a tab character escape sequence, resulting in broken LaTeX code.

### The Problem

```latex
❌ WRONG (Tab character):    extbf{text}      % \t became tab character
❌ WRONG (Tab character):    extit{emphasis}  % \t became tab character
❌ WRONG (Tab character):    exttt{code}      % \t became tab character
```

### The Solution

```latex
✅ CORRECT: \textbf{text}       % Proper backslash
✅ CORRECT: \textit{emphasis}   % Proper backslash
✅ CORRECT: \texttt{code}       % Proper backslash
✅ CORRECT: \cite{key}          % Proper backslash
✅ CORRECT: \section{Title}     % Proper backslash
```

### Prevention Steps

When writing LaTeX commands:
- [ ] **Always** write full backslash before command: `\textbf` not `\textbf`
- [ ] **Never** let `\t`, `\n`, `\r` be interpreted as escape sequences
- [ ] **Verify** no tab characters exist in generated files (search for literal tabs)
- [ ] **Test** compilation immediately after conversion
- [ ] **Scan** for common patterns: search `extbf`, `extit`, `exttt`, `section` without backslash

### Detection

After conversion, search your LaTeX files for these patterns (indicators of the tab character bug):
```bash
# Search for tab characters followed by common LaTeX commands
grep -n "	ext" *.tex    # Tab + ext (should be \text...)
grep -n "	cite" *.tex   # Tab + cite (should be \cite)
grep -n "	section" *.tex # Tab + section (should be \section)
```

Or visually check for alignment issues - tab characters will create unexpected spacing.

---

## Text Formatting

### Basic Formatting

| Markdown | LaTeX | Example |
|----------|-------|---------|
| `**bold**` | `\textbf{bold}` | `\textbf{important concept}` |
| `*italic*` | `\textit{italic}` | `\textit{emphasis}` |
| `` `code` `` | `\texttt{code}` | `\texttt{variable\_name}` |

### Emphasis (Semantic)

For semantic emphasis (rather than just visual italics):
```latex
\emph{emphasized text}
```

### Underline (use sparingly)
```latex
\underline{underlined text}
```

---

## Headings

Markdown headings convert to LaTeX sections based on level:

```markdown
# Chapter (if using book class)
## Section
### Subsection
#### Subsubsection
```

Becomes:

```latex
\chapter{Chapter Title}      % Only in book/report class
\section{Section Title}
\subsection{Subsection Title}
\subsubsection{Subsubsection Title}
```

**For unnumbered sections**:
```latex
\section*{Unnumbered Section}
```

---

## Lists

### Unordered Lists (Bullets)

**Markdown**:
```markdown
- Item 1
- Item 2
  - Nested item
- Item 3
```

**LaTeX**:
```latex
\begin{itemize}
    \item Item 1
    \item Item 2
    \begin{itemize}
        \item Nested item
    \end{itemize}
    \item Item 3
\end{itemize}
```

### Ordered Lists (Numbered)

**Markdown**:
```markdown
1. First item
2. Second item
3. Third item
```

**LaTeX**:
```latex
\begin{enumerate}
    \item First item
    \item Second item
    \item Third item
\end{enumerate}
```

### Description Lists

**LaTeX**:
```latex
\begin{description}
    \item[Term 1] Definition of term 1
    \item[Term 2] Definition of term 2
\end{description}
```

---

## Citations

### In-Text Citations

**DO NOT CHANGE** citation commands - keep them as-is:

```markdown
According to Smith \cite{smith2020}, the evidence suggests...
```

Stays:
```latex
According to Smith \cite{smith2020}, the evidence suggests...
```

### Multiple Citations

```latex
Several studies support this finding \cite{smith2020, jones2021, brown2022}.
```

### Citations with Page Numbers

```latex
As noted by Smith \cite[p.~42]{smith2020}...
```

### Citation Variations (with natbib)

```latex
\citet{smith2020}      % Smith (2020)
\citep{smith2020}      % (Smith, 2020)
\citeauthor{smith2020} % Smith
\citeyear{smith2020}   % 2020
```

---

## Quotations

### Inline Quotes

**Markdown**: `"quote text"`

**LaTeX**: Use proper LaTeX quotes:
```latex
``quote text''
```
Note: Two backticks to open, two single quotes to close.

### Block Quotes (> 3 lines or 40 words)

**Markdown**:
```markdown
> This is a longer quotation that
> spans multiple lines and should
> be formatted as a block quote.
```

**LaTeX**:
```latex
\begin{quote}
This is a longer quotation that spans multiple lines and should be formatted as a block quote.
\end{quote}
```

For APA style (40+ words):
```latex
\begin{quotation}
Long quotation text here. Make sure to cite the source properly including page number.
\end{quotation}
\cite[p.~123]{author2020}
```

---

## Special Characters

**Must be escaped** in LaTeX:

| Character | Markdown | LaTeX |
|-----------|----------|-------|
| Ampersand | `&` | `\&` |
| Percent | `%` | `\%` |
| Dollar | `$` | `\$` |
| Underscore | `_` | `\_` |
| Curly braces | `{}` | `\{\}` |
| Hash | `#` | `\#` |
| Tilde | `~` | `\textasciitilde` |
| Caret | `^` | `\textasciicircum` |
| Backslash | `\` | `\textbackslash` |

**Exception**: Don't escape characters inside `\texttt{}` or verbatim environments.

---

## Paragraphs & Spacing

### New Paragraph

In LaTeX, a blank line creates a new paragraph:

```latex
This is paragraph one.

This is paragraph two.
```

### Line Break (without new paragraph)

```latex
First line\\
Second line (same paragraph)
```

### Non-breaking Space

Use `~` to prevent line break:
```latex
Dr.~Smith
Figure~1
p.~42
```

---

## Tables

**Markdown**:
```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

**LaTeX**:
```latex
\begin{table}[htbp]
\centering
\begin{tabular}{lll}
\toprule
Header 1 & Header 2 & Header 3 \\
\midrule
Cell 1 & Cell 2 & Cell 3 \\
Cell 4 & Cell 5 & Cell 6 \\
\bottomrule
\end{tabular}
\caption{Table caption here}
\label{tab:mytable}
\end{table}
```

**Column alignment**:
- `l` = left
- `c` = center
- `r` = right
- `p{5cm}` = paragraph column with width

---

## Figures & Images

**Markdown**:
```markdown
![Alt text](path/to/image.png)
```

**LaTeX**:
```latex
\begin{figure}[htbp]
\centering
\includegraphics[width=0.8\textwidth]{images/image.png}
\caption{Figure caption}
\label{fig:myfigure}
\end{figure}
```

**Positioning options** `[htbp]`:
- `h` = here (approximately)
- `t` = top of page
- `b` = bottom of page
- `p` = separate page
- `!` = override LaTeX's placement rules

---

## Links & URLs

### Hyperlinks

**Markdown**: `[link text](https://example.com)`

**LaTeX**:
```latex
\href{https://example.com}{link text}
```

### URLs (displayed as-is)

```latex
\url{https://example.com}
```

For long URLs, use:
```latex
\url{https://very-long-url-that-needs-to-break.com}
```

---

## Footnotes

**Markdown**: `Text with footnote[^1]`

**LaTeX**:
```latex
Text with footnote\footnote{Footnote content here.}
```

---

## Math & Equations

### Inline Math

**Markdown**: `$E = mc^2$`

**LaTeX**: `$E = mc^2$` (same)

### Display Math (Centered)

**Markdown**:
```markdown
$$
E = mc^2
$$
```

**LaTeX**:
```latex
\begin{equation}
E = mc^2
\label{eq:einstein}
\end{equation}
```

Or without numbering:
```latex
\[
E = mc^2
\]
```

---

## Code Blocks

### Inline Code

**Markdown**: `` `code` ``

**LaTeX**: `\texttt{code}`

### Code Blocks

**Markdown**:
````markdown
```python
def hello():
    print("Hello, world!")
```
````

**LaTeX** (requires `listings` package):
```latex
\begin{lstlisting}[language=Python]
def hello():
    print("Hello, world!")
\end{lstlisting}
```

---

## Cross-References

Reference figures, tables, sections:

```latex
% In text:
As shown in Figure~\ref{fig:myfigure}...
See Table~\ref{tab:mytable} for details.
In Section~\ref{sec:introduction}...

% Labels are placed in the element:
\section{Introduction}
\label{sec:introduction}

\begin{figure}
...
\label{fig:myfigure}
\end{figure}
```

---

## Common Patterns

### Starting a Section

```latex
\section{Introduction}

This paper examines...
```

### Subsection with Citation

```latex
\subsection{Theoretical Framework}

The social cognitive theory \cite{bandura1986} proposes that...
```

### Paragraph with Multiple Citations

```latex
Several studies have demonstrated this effect \cite{smith2020, jones2021}. 
However, recent research suggests a more nuanced view \cite{brown2022}.
```

### Figure with Citation

```latex
\begin{figure}[htbp]
\centering
\includegraphics[width=0.7\textwidth]{images/diagram.pdf}
\caption{Conceptual model adapted from \cite{smith2020}}
\label{fig:model}
\end{figure}
```

---

## Conversion Validation

When converting Markdown to LaTeX, verify:

- [ ] All special characters escaped (`&`, `%`, `$`, `_`)
- [ ] Quotes changed to LaTeX style (`` `` and `''`)
- [ ] Headings converted to appropriate section levels
- [ ] Lists use `itemize` or `enumerate` environments
- [ ] Citations preserved exactly (no changes to `\cite{}`)
- [ ] All citation keys exist in bibliography.bib
- [ ] Block quotes use `quote` or `quotation` environment
- [ ] Figures have proper labels and captions
- [ ] No raw Markdown syntax remains
- [ ] All `\begin{}` have matching `\end{}`

---

## Common Mistakes to Avoid

❌ **Don't**:
```latex
% Wrong quote marks
"quoted text"

% Unescaped special characters
Research & Development costs 50%

% Missing environment
\item Item without \begin{itemize}

% Broken citation
\cite{smith2020, missing space} % No space before }
```

✅ **Do**:
```latex
% Correct quote marks
``quoted text''

% Escaped special characters
Research \& Development costs 50\%

% Proper environment
\begin{itemize}
\item Item with proper environment
\end{itemize}

% Clean citation
\cite{smith2020, jones2021}
```

---

**Remember**: LaTeX is precise. Small errors (missing `}`, unescaped `&`) cause compilation to fail. Always validate structure before compiling.
