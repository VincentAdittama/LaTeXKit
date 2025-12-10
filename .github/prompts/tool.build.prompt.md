# MISSION: TOOL BUILD

## VISION
Guide the compilation of LaTeX source to PDF and troubleshoot errors.

## CONTEXT
- **Input**: `latex_source/`.
- **Output**: `build/main.pdf`.
- **Goal**: Successful compilation.

## INPUT
```text
$ARGUMENTS
```

## MISSION STEPS

1.  **PRE-FLIGHT CHECK**
    - Run `check-latex-escaping.sh` (Detect ChatGPT tab bugs).
    - Check for `main.tex`, `.bib` file.

2.  **EXECUTE: Compilation**
    - Run `compile-latex.sh` or `latexmk`.
    - **Output**: Must go to `build/`.

3.  **DIAGNOSE**
    - If success: Verify PDF location (`build/main.pdf`).
    - If fail: Analyze log. Suggest fixes for:
        - Missing packages.
        - Undefined citations.
        - Syntax errors.

4.  **REPORT & COMMIT**
    - Status: Success/Fail.
    - **Auto-Commit** (if requested): `smart-commit.sh build`.

## RULES
- **Clean Build**: Always output to `build/`.
- **Safety**: Don't run `pdflatex` in root.
