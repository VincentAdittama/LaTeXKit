# Clarification Phase Checklist

**Document ID**: `DOCUMENT_ID`  
**Phase**: Clarification  
**Created**: `CREATED_DATE`  
**Last Check**: `LAST_CHECK_DATE`

---

## Purpose

This checklist tracks resolution of clarification markers across the entire project. This command can be run at any phase after `/latexkit.start` to resolve uncertainties in any project file.

Searches for both:
- `[NEEDS CLARIFICATION: ...]` (plural)
- `[NEED CLARIFICATION: ...]` (singular)

---

## Pre-Clarification Checks

- [ ] Project initialized via `/latexkit.start`
- [ ] `start.md` file exists and is readable
- [ ] Start checklist completed
- [ ] No critical structural issues in project directory

---

## Ambiguity Analysis

### Document Purpose & Scope
- [ ] Document purpose clearly stated
- [ ] Scope boundaries explicit (what's included/excluded)
- [ ] Document type correctly identified
- [ ] Target audience understood

### Assignment Context
- [ ] Course details complete (name, code, instructor)
- [ ] Due date clearly specified
- [ ] Grade weight/importance known
- [ ] Group/team information complete (if applicable)
- [ ] All team member names and roles recorded (if group work)

### Content Requirements
- [ ] Main topics and themes clearly defined
- [ ] Research questions or essay questions explicit
- [ ] Required sections/structure understood
- [ ] Depth and breadth expectations clear

### Format & Style Requirements
- [ ] Length requirements specified (word count/pages)
- [ ] Font, spacing, margins defined
- [ ] Citation style explicitly stated
- [ ] File format and submission method clear

### Source & Research Requirements
- [ ] Minimum number of sources specified
- [ ] Source types required (peer-reviewed, books, etc.)
- [ ] Recency requirements clear (publication date range)
- [ ] Required readings or specific sources identified

### Success Criteria
- [ ] Grading rubric details known
- [ ] Quality expectations clear
- [ ] Deliverables well-defined
- [ ] Academic standards understood

### Constraints & Assumptions
- [ ] Time constraints realistic
- [ ] Resource availability confirmed
- [ ] Knowledge prerequisites identified
- [ ] Technical limitations known

---

## Clarification Discovery

- [ ] All project files scanned for clarification markers
- [ ] Both `[NEEDS CLARIFICATION]` and `[NEED CLARIFICATION]` patterns searched
- [ ] Markers found in: (list files)
  - [ ] start.md
  - [ ] checklists/*.md
  - [ ] research files
  - [ ] outline files
  - [ ] draft files
  - [ ] context files
  - [ ] other files
- [ ] Total markers found: ___
- [ ] Markers prioritized by impact and blocking status

## Clarification Process

- [ ] Questions presented one at a time (max 5 per session)
- [ ] File context shown BEFORE each question
- [ ] Progress indicator shown (Question X of Y)
- [ ] Recommended/suggested answers provided with reasoning
- [ ] All answers recorded in appropriate files
- [ ] Clarification markers removed when resolved
- [ ] Modified files saved correctly after each answer
- [ ] No contradictory information left in any file

---

## Documentation Updates

### start.md (if clarifications made)
- [ ] `## Clarifications` section added/updated
- [ ] Session date recorded (`### Session YYYY-MM-DD`)
- [ ] Q&A pairs documented with file context
- [ ] Relevant sections updated with clarifications
- [ ] Obsolete/contradictory text removed

### Checklists (if clarifications made)
- [ ] Clarification markers replaced with resolved items
- [ ] Checklist items updated or added
- [ ] Checkbox states updated correctly

### Other Files (if clarifications made)
- [ ] Research plans updated with clarifications
- [ ] Outlines updated with clarifications
- [ ] Drafts updated with clarifications
- [ ] Context files updated with clarifications
- [ ] All files maintain proper structure
- [ ] Markdown/LaTeX syntax preserved

---

## Coverage Assessment

| Category | Status | Notes |
|----------|--------|-------|
| Document Purpose & Scope | Clear / Partial / Missing | |
| Assignment Context | Clear / Partial / Missing | |
| Content Requirements | Clear / Partial / Missing | |
| Format & Style Requirements | Clear / Partial / Missing | |
| Source & Research Requirements | Clear / Partial / Missing | |
| Success Criteria | Clear / Partial / Missing | |
| Constraints & Assumptions | Clear / Partial / Missing | |

---

## Session Results

- [ ] Session completed successfully
- [ ] Questions asked this session: ___ (max 5)
- [ ] Total markers resolved: ___
- [ ] Remaining markers: ___ (if any)
- [ ] All modified files saved correctly
- [ ] No syntax errors introduced
- [ ] All files remain valid and properly formatted

## Quality Gates

- [ ] Maximum 5 questions asked per session
- [ ] All addressed clarifications properly integrated
- [ ] No orphaned clarification markers for resolved items
- [ ] All files consistent and complete
- [ ] No contradictions across files
- [ ] Ready to continue workflow or clarify more in next session

---

## Next Steps

**If all clarifications resolved**:
- [ ] All clarification markers eliminated ✅
- [ ] Continue with current workflow phase
- [ ] Or proceed to next phase as planned

**If clarifications remain**:
- [ ] ___ markers still need resolution
- [ ] Run `/latexkit.clarify` again to continue
- [ ] Or continue workflow and clarify later

**Suggested next command based on current phase**:
- [ ] Early phase: `/latexkit.research` or `/latexkit.outline`
- [ ] Mid phase: Continue to next workflow step
- [ ] Late phase: `/latexkit.build` or `/latexkit.check`
- [ ] More clarifications: `/latexkit.clarify` again

---

## Constitution Compliance

- [ ] All clarifications align with academic integrity standards
- [ ] No ambiguities that could lead to plagiarism
- [ ] Proper attribution planning in place
- [ ] Original thinking requirements understood

---

## Notes

<!-- Add any additional notes about the clarification process -->

---

**Checklist Version**: 1.0  
**Phase Complete**: ⬜ (Check when all items above are complete)
