# Start Command Checklist

**Document**: `DOCUMENT_ID`  
**Created**: `CREATED_DATE`  
**Command**: `/latexkit.start`  
**Purpose**: Validate initial project setup and requirements gathering

---

## ✅ Pre-Checks (Setup)
- [ ] Document directory structure created
- [ ] Start file (`start.md`) exists with complete metadata
- [ ] LaTeX source directory initialized (`latex_source/`)
- [ ] Checklists directory (`checklists/`) created
- [x] Complete directory structure created
  - `checklists/`, `latex_source/`, `build/`
  - `assignment_info/`, `zotero_export/`
  - `generated_work/` with subdirectories
- [ ] Generated work directories exist (research, outlines, drafts, conversion, compilation, reviews)
- [ ] Zotero export directory (`zotero_export/`) ready

## Start File Completeness
- [ ] All required sections filled
- [ ] Document metadata complete
- [ ] Requirements clearly defined

## Research Context
- [ ] Key topics and themes identified
- [ ] Required theoretical frameworks noted
- [ ] Special requirements documented
- [ ] Initial research direction established

## LaTeX Structure Preparation
- [ ] LaTeX source directory ready (`latex_source/`)
- [ ] Section files structure prepared (`latex_source/sections/`)
- [ ] Images directory created (`latex_source/images/`)
- [ ] Build directory ready (`build/`)

> **Note**: LaTeX source files (`main.tex`, `preamble.tex`) and build configuration (`.latexmkrc`) will be imported during `/latexkit.convert` phase.

## Next Steps
- [ ] User informed about Zotero export location (for academic documents)
- [ ] User knows next command: `/latexkit.research` (academic) or `/latexkit.outline` (non-academic)

---

## Notes

<!-- Add any setup-specific notes or clarifications needed -->

---

**Status**: `Pass` / `Fail` / `In Progress`  
**Last Validated**: `LAST_CHECK_DATE`
