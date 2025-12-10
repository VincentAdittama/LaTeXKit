# Convert Command Checklist

**Document**: `DOCUMENT_ID`  
**Created**: `CREATED_DATE`  
**Command**: `/latexkit.convert`  
**Purpose**: Validate Markdown to LaTeX conversion completeness

---

## Prerequisites (from previous commands)
- [ ] Plan command completed (latex_source/ structure exists)
- [ ] Draft command completed (reviewed draft ready)
- [ ] Project structure validated
- [ ] Human review of draft completed

## Conversion Setup
- [ ] Final reviewed draft located in `generated_work/drafts/`
- [ ] **Final Document Language** confirmed from plan.md (Indonesian/English/Bilingual)
- [ ] Language transformation requirements identified (if draft ≠ final language)
- [ ] LaTeX source directory accessible
- [ ] Conversion guide template loaded
- [ ] Preamble.tex packages and commands reviewed

## Metadata Generation
- [ ] main.tex metadata populated from plan.md
- [ ] Document title command created (`\docTitle`)
- [ ] Course/context commands created (if applicable)
- [ ] Author information formatted correctly
- [ ] For group assignments: Member table generated with proper LaTeX formatting
- [ ] For individual: Student name and ID formatted
- [ ] Date formatted correctly (Month Day, Year)

## Content Conversion
- [ ] **Document language enforced**: ALL content matches "Final Document Language" from plan.md
- [ ] Language transformation completed (if draft language ≠ final language)
- [ ] Section headings translated to target language (e.g., "Introduction" → "Pendahuluan")
- [ ] Body paragraphs translated while preserving academic tone and meaning
- [ ] Technical terms and proper nouns preserved appropriately
- [ ] Text formatting converted: **bold** → `\textbf{}`, *italic* → `\textit{}`
- [ ] Headings converted to appropriate LaTeX commands (\section, \subsection, etc.)
- [ ] Lists converted: bullets → itemize, numbered → enumerate
- [ ] Citations preserved exactly: `\cite{key}` unchanged
- [ ] Quotes converted: short → LaTeX quotes, long → quote environment
- [ ] Special characters escaped: &, %, $, _, etc.
- [ ] No raw Markdown syntax remains

## Section Files Created
- [ ] Introduction file: `sections/01_introduction.tex`
- [ ] Body sections file(s): `sections/02_body.tex` (or split further)
- [ ] Conclusion file: `sections/03_conclusion.tex`
- [ ] Additional section files numbered sequentially (if needed)
- [ ] All section files have proper LaTeX syntax

## Bibliography Validation
- [ ] Bibliography file location confirmed: `zotero_export/<your-export>.bib`
- [ ] All `\cite{}` keys validated against .bib file
- [ ] Missing citation keys identified and reported
- [ ] Bibliography path correct in main.tex
- [ ] No duplicate or conflicting citation keys

## LaTeX Structure Validation
- [ ] **CRITICAL**: No tab characters in LaTeX commands (ChatGPT `\textbf` → `<TAB>extbf` bug)
- [ ] Escaping check passed: `.latexkit/scripts/bash/check-latex-escaping.sh` run and passed
- [ ] All LaTeX commands have proper backslash: `\textbf`, `\cite`, `\section`, etc.
- [ ] All `\begin{}...\end{}` pairs match
- [ ] Section hierarchy valid (no skipped levels)
- [ ] All `\input{}` statements reference existing files
- [ ] Special characters properly escaped throughout
- [ ] No conversion artifacts or errors

## Main.tex Updates
- [ ] Placeholder `\newcommand` definitions replaced with actual content
- [ ] Correct `\input{}` statements for all section files
- [ ] Document class appropriate for assignment type
- [ ] Preamble loaded correctly
- [ ] Bibliography configuration correct

## Quality Checks
- [ ] Conversion report generated in `generated_work/conversion/`
- [ ] All files created/updated listed in report
- [ ] Conversion issues or warnings documented
- [ ] Manual fixes needed (if any) identified
- [ ] LaTeX syntax validation passed (if checked)

## Compilation Readiness
- [ ] All section files present
- [ ] No missing `\input{}` files
- [ ] Bibliography path valid
- [ ] All citations have matching keys
- [ ] LaTeX structure is valid
- [ ] Special characters properly handled

## Deliverables
- [ ] Conversion report saved (YYYYMMDD_conversion-report.md)
- [ ] All LaTeX files created/updated in latex_source/
- [ ] File list documented
- [ ] Warnings and issues reported

## Next Steps
- [ ] User informed: Ready for PDF compilation
- [ ] User knows next command: `/latexkit.build`
- [ ] Any syntax or citation warnings communicated

---

## Notes

<!-- Add conversion-specific notes, issues encountered, or manual fixes needed -->

---

**Status**: `Pass` / `Fail` / `In Progress`  
**Last Validated**: `LAST_CHECK_DATE`
