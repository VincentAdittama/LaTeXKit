---
description: Build LaTeX source to PDF and troubleshoot compilation errors
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Compile the LaTeX project and handle any errors that arise.

1. **Detect current project**:
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` OR manually detect:
     - Check `.active_project` file in repo root for current project ID
     - Or detect from current working directory if inside `documents/xxx`
   - Set `CURRENT_BRANCH` to the project ID (e.g., `001-my-project`) for backward compatibility
   - Set `DOCUMENT_DIR` to `documents/$CURRENT_BRANCH/`
   - All subsequent paths should be relative to `DOCUMENT_DIR`
   - If `DOCUMENT_DIR` doesn't exist, report error and suggest running `/latexkit.start` first

2. **Pre-compilation checks**:
   - **CRITICAL**: Run `.latexkit/scripts/bash/check-latex-escaping.sh` to detect backslash escape issues
   - This catches the ChatGPT `\textbf` → `<TAB>extbf` bug that causes compilation failures
   - If escaping errors found, STOP and report to user - they must fix before compilation
   - Verify `$DOCUMENT_DIR/latex_source/main.tex` exists
   - If latex_source doesn't exist or is empty, report error and suggest running `/latexkit.convert` first
   - Check all `\input{}` files exist
   - Validate a `.bib` file exists under `$DOCUMENT_DIR/zotero_export/` (Zotero exports may use different subfolders or filenames)
   - Confirm all required LaTeX packages are available
   - Run `.latexkit/scripts/bash/check-prerequisites.sh` to verify LaTeX installation

3. **Execute compilation**:
   
   **⚠️ CRITICAL - Proper Build Methods**:
   - **CORRECT METHODS** (use ONE of these):
     1. **Recommended**: Run `.latexkit/scripts/bash/compile-latex.sh -d "$DOCUMENT_DIR/latex_source"`
     2. **Alternative**: Run `latexmk` from `$DOCUMENT_DIR/latex_source/` (respects `.latexmkrc`)
     3. **CLI tool**: Use `./latexkit build` from repository root
   
   - **NEVER** run `lualatex`, `pdflatex`, or `xelatex` directly without output directory flags
   - **NEVER** run compilation from `$DOCUMENT_DIR` root (outputs will go to wrong location)
   - **WHY**: These commands default to outputting in current directory, not `build/`
   - **CORRECT OUTPUT**: All build files MUST go to `$DOCUMENT_DIR/build/` directory
   
   - Capture full output for error analysis
   - Monitor for common issues:
     - Missing packages
     - Bibliography errors
     - Citation undefined warnings
     - Overfull/underfull boxes
     - File not found errors
     - **Output directory issues** (files in wrong location)

4. **Error handling workflow**:
   
   **If compilation succeeds**:
   - **Verify PDF location**: MUST be at `$DOCUMENT_DIR/build/main.pdf`
   - **NOT** at `$DOCUMENT_DIR/main.pdf` or `$DOCUMENT_DIR/latex_source/main.pdf`
   - If PDF is in wrong location, compilation method was incorrect
   - Report PDF location: `$DOCUMENT_DIR/build/main.pdf`
   - Note any warnings (overfull boxes, citations)
   - Suggest next step: `/latexkit.check` or manual review
   
   **If compilation fails**:
   - Parse error messages for root cause
   - Categorize error type:
     - **Syntax error**: Show line number and suggest fix
     - **Missing package**: Provide installation command
     - **Bibliography error**: Check .bib file syntax
     - **File not found**: Verify file paths
     - **Encoding error**: Check special characters
   
   - For each error:
     - Explain in plain language
     - Show relevant code snippet
     - Suggest specific fix
     - Offer to apply fix automatically if trivial

5. **Common error solutions**:
   
   **Tab character in LaTeX command (ChatGPT bug)**:
   - Symptom: `! Undefined control sequence` with broken command name
   - Cause: `\textbf` was interpreted as `<TAB>extbf` during generation
   - Solution: Run `.latexkit/scripts/bash/check-latex-escaping.sh` to find all occurrences
   - Fix: Replace tab characters with proper backslash `\`
   - Example: `<TAB>extbf{text}` → `\textbf{text}`
   
   **Missing citation**:
   - Check if key exists in bibliography.bib
   - Suggest running BibTeX if needed
   - Verify citation key spelling
   
   **Package not found**:
   - Identify package name
   - Provide installation command: `tlmgr install [package]` or `sudo apt-get install texlive-[collection]`
   
   **Overfull hbox**:
   - Note location (usually harmless)
   - Suggest adjustments if severe (>5pt)
   
   **Undefined control sequence**:
   - Check for typos in LaTeX commands
   - Verify required package is loaded in preamble

6. **Multi-pass compilation**:
   - First pass: LaTeX (resolve structure)
   - Second pass: BibTeX (process bibliography)
   - Third pass: LaTeX (resolve citations)
   - Fourth pass: LaTeX (resolve cross-references)
   - Report progress after each pass

7. **Output validation**:
   - Verify PDF is created
   - Check PDF file size (>0 bytes)
   - Count pages and compare to expected
   - Note if bibliography is rendered
   - Check for blank pages or formatting issues

8. **Generate compilation log**:
   - Ensure directory exists: create if missing and add `.gitkeep` to preserve structure
   - Save to `$DOCUMENT_DIR/generated_work/compilation/YYYYMMDD_compile-log.txt`
   - Include full LaTeX output
   - Highlight errors and warnings
   - Document fixes applied

9. **Quality checks on PDF**:
   - All sections present
   - Bibliography rendered correctly
   - Citations appear (not [?])
   - Formatting matches requirements
   - No obvious visual errors

10. **Report to user**:
   - Confirm current project: `$CURRENT_BRANCH`
   - Confirm document directory: `$DOCUMENT_DIR`
   - Compilation status (success/failure)
   - PDF location if successful
   - Error summary with fixes if failed
   - Warnings to address
   - Next command: `/latexkit.check` or manual review

11. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER compilation is complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh build` from repository root
        - **CRITICAL**: Pass "build" as the stage parameter to ensure BUILD label
     2. The script will auto-stage changes, use explicit "build" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand build results
     5. Create descriptive commit message:
        - Format: `BUILD-NN: Descriptive title`
        - Body: Specific details about compilation
        - Example:
          ```
          BUILD-06: Successfully compile PDF with all citations and formatting
          
          - Compiled LaTeX source to PDF ([N] pages)
          - Processed bibliography with [N] sources
          - Resolved all citations and cross-references
          - Generated build artifacts in build/ directory
          - PDF ready for quality review
          ```
        - Or if build failed:
          ```
          BUILD-06: Fix compilation errors in [section]
          
          - Corrected LaTeX syntax errors in [file]
          - Fixed missing package references
          - Updated bibliography configuration
          - Compilation log saved for debugging
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Compilation Success Criteria

PDF is ready when:
- ✅ Compilation completes without errors
- ✅ PDF file is created and readable
- ✅ All citations resolve (no [?])
- ✅ Bibliography is complete
- ✅ Page count is reasonable
- ✅ No critical formatting issues
- ✅ All sections are present

## Key Rules

- Always run multiple passes for bibliography
- Never ignore citation warnings
- Provide specific, actionable error messages
- Save full logs for debugging
- Suggest fixes before asking user to manual edit
- Check prerequisites before compilation
- Handle errors gracefully with clear explanations
