---
description: Convert reviewed Markdown draft to LaTeX source files
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Transform the reviewed Markdown draft into properly structured LaTeX files ready for compilation.

1. **Detect current project**:
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` OR manually detect:
     - Get current git branch: `git rev-parse --abbrev-ref HEAD`
     - If not in git repo or on main branch, check `LATEXKIT_DOCUMENT` environment variable
     - Set `CURRENT_BRANCH` to the branch name (format: `NNN-project-name`)
     - Set `DOCUMENT_DIR` to `documents/$CURRENT_BRANCH/`
   - All subsequent paths should be relative to `DOCUMENT_DIR`
   - If `DOCUMENT_DIR` doesn't exist, report error and suggest running `/latexkit.start` first

1a. **Import LaTeX template if needed** (convert command's responsibility):
   - Check if `$DOCUMENT_DIR/latex_source/` directory exists and is populated
   - If latex_source doesn't exist OR is empty (only contains .gitkeep):
     - This is EXPECTED behavior - convert command imports the template
     - Copy layout from registry: `registry/layouts/academic-assignment/` → `$DOCUMENT_DIR/latex_source/`
     - Copy `.latexmkrc` from `.latexkit/templates/latexmkrc` → `$DOCUMENT_DIR/latex_source/.latexmkrc`
     - Create required subdirectories if missing: `sections/`, `images/`, `components/`
     - Log: "Imported LaTeX template structure from registry"
   - If latex_source exists and has content:
     - Skip template import (already configured)
     - Verify `.latexmkrc` exists, if not copy from template
   - Then run validation: `.latexkit/scripts/bash/validate-structure.sh "$DOCUMENT_DIR"`
   - If validation still fails after import, check for other critical missing files
   - If start.md is missing, stop and require re-run of `/latexkit.start`

2. **Load context files**:
   - Read `$DOCUMENT_DIR/start.md` (or `_assignment_info.md` if exists) for metadata
   - **CRITICAL**: Extract "Final Document Language" or "Document Output Language" from start.md
     - This determines the language for ALL LaTeX output (sections, headings, text)
     - Default: Indonesian (if not specified)
     - Possible values: Indonesian, English, Bilingual
     - This applies to the FINAL compiled document, regardless of draft language
   - Read final reviewed draft from `$DOCUMENT_DIR/generated_work/drafts/`
   - Read `$DOCUMENT_DIR/latex_source/main.tex` for document structure
   - Read `$DOCUMENT_DIR/latex_source/preamble.tex` for available packages and commands
   - Read `.latexkit/templates/latex-conversion-guide.md` for formatting rules
   - **CRITICAL**: Read `.latexkit/templates/chatgpt-latex-warnings.md` for ChatGPT-specific issues

2a. **Silent prerequisite validation** (no CLI output):
   - Validate prerequisites exist but do not output to CLI
   - Check that start.md exists (if missing, stop and require `/latexkit.start`)
   - Check that draft exists (if missing, stop and require `/latexkit.draft`)
   - Only report critical blocking issues
   - Skip running validate-checklists.sh in this step to avoid verbose output

3. **Generate main.tex metadata** based on start.md:
   
   ```latex
   % Document metadata - extract from start.md
   \newcommand{\docTitle}{[from start.md: title]}
   \newcommand{\docCourse}{[from start.md: course_name]}
   \newcommand{\docAuthor}{[from start.md: author name]}
   \newcommand{\docProfessor}{[from start.md: instructor_name]}
   \newcommand{\docDate}{[from start.md: due_date, formatted as "Month Day, Year"]}
   ```
   
   **For group assignments**:
   ```latex
   \newcommand{\docAuthorship}{%
       \begin{tabular}{ll}
           Kelompok & : [Group Name/Number] \\
           Anggota  & : [Member 1 Name (ID)] \\
                    & \phantom{:} [Member 2 Name (ID)] \\
                    & \phantom{:} [Member 3 Name (ID)]
       \end{tabular}%
   }
   ```
   
   **For individual assignments**:
   ```latex
   \newcommand{\docAuthorship}{%
       \begin{tabular}{ll}
           Nama & : \docAuthor \\
           NIM  & : \docNIM
       \end{tabular}%
   }
   ```

4. **Convert Markdown to LaTeX** (section by section):
   
   **⚠️ CRITICAL - Document Language Enforcement**:
   Before converting, confirm the "Final Document Language" setting from start.md:
   - **Indonesian** (default): ALL LaTeX output MUST be in Indonesian
   - **English**: ALL LaTeX output MUST be in English  
   - **Bilingual**: Preserve language mix from draft appropriately
   
   **Language Transformation Rules**:
   - If draft language ≠ final document language, TRANSLATE ALL content
   - Section headings: "Introduction" → "Pendahuluan" (if Indonesian target)
   - Body paragraphs: Translate while preserving academic tone and meaning
   - Preserve: Citation keys `\cite{key}`, technical terms, proper nouns
   - Maintain: Grammatical correctness in target language
   
   **Examples**:
   - Draft: "The research shows..." + Indonesian target → "Penelitian ini menunjukkan..."
   - Draft: "## Methodology" + Indonesian target → `\section{Metodologi}`
   - Draft: "Hasil penelitian..." + English target → "Research results..."
   
   **⚠️ CRITICAL - LaTeX Command Escaping**:
   When writing LaTeX commands, you MUST properly escape backslashes to prevent them from being interpreted as escape sequences:
   - **WRONG**: `\textbf{text}` can become `<TAB>extbf{text}` if `\t` is interpreted as tab character
   - **CORRECT**: Always write LaTeX commands with proper backslash: `\textbf{text}`
   - **VALIDATION**: After conversion, verify NO tab characters exist in LaTeX files
   - Common problematic commands: `\textbf`, `\textit`, `\texttt`, `\cite`, `\section`, `\subsection`
   - This issue primarily affects ChatGPT/OpenAI models - be extra careful with backslash handling
   
   **Text formatting**:
   - `**bold**` → `\textbf{bold}` (NOT `<TAB>extbf{bold}`)
   - `*italic*` → `\textit{italic}` (NOT `<TAB>extit{italic}`)
   - `` `code` `` → `\texttt{code}` (NOT `<TAB>exttt{code}`)
   
   **Headings** (determine level based on structure):
   - `## Section` → `\section{Section}` (major sections)
   - `### Subsection` → `\subsection{Subsection}`
   - `#### Subsubsection` → `\subsubsection{Subsubsection}`
   
   **Lists**:
   - Bullet lists → `\begin{itemize}...\end{itemize}`
   - Numbered lists → `\begin{enumerate}...\end{enumerate}`
   
   **Citations** (preserve as-is):
   - `\cite{key}` → `\cite{key}` (no change)
   - Ensure all citation keys exist in bibliography.bib
   
   **Quotes**:
   - Short quotes → ```quote text''` (LaTeX-style quotes)
   - Block quotes (>3 lines) → `\begin{quote}...\end{quote}`
   
   **Special characters**:
   - `&` → `\&`
   - `%` → `\%`
   - `$` → `\$`
   - `_` → `\_`
   - Preserve `\cite{}` and other LaTeX commands

5. **Split content into section files** (respecting document language):
   - Introduction → `$DOCUMENT_DIR/latex_source/sections/01_introduction.tex`
   - Body sections → `$DOCUMENT_DIR/latex_source/sections/02_body.tex` (or split further if needed)
   - Conclusion → `$DOCUMENT_DIR/latex_source/sections/03_conclusion.tex`
   - Create additional numbered files for complex structures (04, 05, etc.)
   - **ALL content in these files MUST be in the language specified in start.md**
   - Section headings, paragraphs, labels ALL follow the final document language

5. **Set up bibliography** (if citations exist in draft):
   - Check if a `.bib` file exists under `$DOCUMENT_DIR/zotero_export/` (the export folder and filename may vary)
   - If `.bib` file exists:
     - Uncomment the `\addbibresource{}` line in `preamble.tex`
     - Set the path to the found bib file, e.g., `\addbibresource{../zotero_export/filename.bib}`
     - Log: "Auto-configured bibliography path to found .bib file"
   - If no `.bib` file exists:
     - Leave commented
     - Inform user to export bibliography from Zotero
     - Log: "No bibliography file found - manual configuration required"
   - **NOTE**: If `zotero_export` folder is missing, create it with `.gitkeep` file to preserve structure
   - If `.bib` file exists, validate all `\cite{}` keys exist in bibliography (report any missing citations)
   - If no bib file, report that citations exist but bibliography needs manual setup

7. **Validate LaTeX structure**:
   - **CRITICAL**: Search for tab characters (`\t` or literal tabs) in all LaTeX files - these indicate broken LaTeX commands
   - **CRITICAL**: Verify all LaTeX commands start with backslash `\` (e.g., `\textbf`, `\cite`, `\section`)
   - Check matching `\begin{}...\end{}` pairs
   - Verify special characters are escaped
   - Ensure no raw Markdown syntax remains
   - Validate section hierarchy
   - Check that all `\input{}` files exist
   - **Common ChatGPT error**: `\textbf` → `<TAB>extbf` - scan for this specifically

8. **Update main.tex**:
   - Replace placeholder `\newcommand` definitions with generated ones
   - Ensure correct `\input{}` statements for all section files
   - Verify document class and preamble are appropriate

9. **Create conversion report**:
   - Ensure directory exists: create if missing and add `.gitkeep` to preserve structure
   - Save to `$DOCUMENT_DIR/generated_work/conversion/YYYYMMDD_conversion-report.md`
   - List all files created/updated
   - Note any conversion issues or warnings
   - Document any manual fixes needed

9a. **Create convert checklist**:
   - Copy template from `.latexkit/templates/checklists/latexkit.convert.md`
   - Save to `$DOCUMENT_DIR/checklists/latexkit.convert.md`
   - Replace placeholders:
     - `DOCUMENT_ID` → actual document/branch name
     - `CREATED_DATE` → today's date (YYYY-MM-DD)
     - `LAST_CHECK_DATE` → today's date (YYYY-MM-DD)

10. **Run preliminary check** (if requested):
   - **REQUIRED**: Execute `.latexkit/scripts/bash/check-latex-escaping.sh` to detect backslash escape issues
   - This catches the ChatGPT `\textbf` → `<TAB>extbf` bug before compilation
   - If errors found, you MUST fix them before proceeding
   - Report any LaTeX issues detected
   - Suggest fixes for common issues
   
   **⚠️ CRITICAL - Testing LaTeX Compilation**:
   - **NEVER** run `lualatex`, `pdflatex`, or `xelatex` directly from terminal
   - **NEVER** run LaTeX commands without proper output directory configuration
   - **CORRECT METHODS** to test compilation (in order of preference):
     1. Use `/latexkit.build` command (recommended for full build)
     2. Use `.latexkit/scripts/bash/test-latex-build.sh` (quick test with proper output dir)
     3. Use `latexmk` from `$DOCUMENT_DIR/latex_source/` (respects `.latexmkrc` config)
     4. Use `.latexkit/scripts/bash/compile-latex.sh -d "$DOCUMENT_DIR/latex_source"`
   - **WHY**: Direct LaTeX commands output to current directory instead of `build/`
   - **RESULT**: Files end up in wrong location, breaking project structure
   - **VERIFY**: After any test, confirm PDF is at `$DOCUMENT_DIR/build/main.pdf` NOT elsewhere

10a. **Silent checklist validation at completion**:
   - Run `.latexkit/scripts/bash/validate-checklists.sh --command convert >/dev/null 2>&1` (silent mode)
   - This silently validates and updates the convert checklist without CLI output
   - Updates checklist based on actual LaTeX files created
   - Marks completed items as done
   - Do not output validation results to user

11. **Self-check workspace problems**:
   - Check VS Code workspace for any LaTeX errors or warnings
   - Look for compilation errors, syntax errors, or missing packages
   - Report any detected issues with suggested fixes
   - Verify all LaTeX projects in workspace can compile successfully
   - If errors found, list them with file paths and line numbers

12. **Report to user**:
   - Confirm current branch/document: `$CURRENT_BRANCH`
   - Confirm document directory: `$DOCUMENT_DIR`
   - **Confirm final document language**: State which language was used (from start.md)
   - If language transformation occurred: Note "Content translated from [source] to [target] as specified in start.md"
   - If LaTeX template was imported: Note "Imported LaTeX template from registry (first-time conversion)"
   - Conversion complete with file list
   - Any citation or syntax warnings
   - Workspace problems check results (if any errors found)
   - Estimated compilation readiness
   - Next command: `/latexkit.build` to generate PDF

13. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all conversion work is complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh convert` from repository root
        - **CRITICAL**: Pass "convert" as the stage parameter to ensure CONVERT label
     2. The script will auto-stage changes, use explicit "convert" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand conversion results
     5. Create descriptive commit message:
        - Format: `CONVERT-NN: Descriptive title`
        - Body: Specific details about conversion
        - Example:
          ```
          CONVERT-05: Transform Markdown draft to LaTeX source files
          
          - Converted [N] sections from Markdown to LaTeX
          - Preserved [N] citations with proper formatting
          - Generated section files: introduction, body, conclusion
          - Updated main.tex with document metadata
          - Validated LaTeX structure and escaping
          - Created conversion report with [N] warnings
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Conversion Quality Gates

Ready for compilation when:
- ✅ All section files created
- ✅ main.tex metadata populated
- ✅ Bibliography is up to date
- ✅ All citations have matching keys
- ✅ No Markdown syntax remains
- ✅ Special characters properly escaped
- ✅ LaTeX structure is valid
- ✅ No missing `\input{}` files

## Key Rules

- Preserve all `\cite{}` commands exactly
- Use semantic LaTeX (e.g., `\emph{}` not `\textit{}` for emphasis)
- Maintain proper LaTeX escaping for special characters
- Keep section files focused and manageable
- Never lose content during conversion
- Version the conversion report
- Validate before declaring complete
