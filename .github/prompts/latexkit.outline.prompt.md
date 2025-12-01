---
description: Create detailed paper outline with proper structure and citations
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Generate a comprehensive, citation-rich outline based on research and assignment requirements.

**Language Note**: This outline can be written in either English or Indonesian, regardless of the final document's output language specified in `start.md`. Choose the language that works best for your planning and organization.

1. **Detect current project**:
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` OR manually detect:
     - Check `.active_project` file in repo root for current project ID
     - Or detect from current working directory if inside `documents/xxx`
   - Set `CURRENT_BRANCH` to the project ID (e.g., `001-my-project`) for backward compatibility
   - Set `DOCUMENT_DIR` to `documents/$CURRENT_BRANCH/`
   - All subsequent paths should be relative to `DOCUMENT_DIR`
   - If `DOCUMENT_DIR` doesn't exist, report error and suggest running `/latexkit.start` first

1a. **Validate project structure**:
   - Run validation: `.latexkit/scripts/bash/validate-structure.sh "$DOCUMENT_DIR"`
   - If validation fails, warn the user about missing files/directories
   - Suggest running `/latexkit.start` to recreate missing structure
   - If critical files are missing (start.md), stop and require re-run of start command

2. **Load context files**:
   - Read `$DOCUMENT_DIR/start.md` (or `_assignment_info.md` if exists)
   - Read latest research plan from `$DOCUMENT_DIR/generated_work/research/`
   - Read `$DOCUMENT_DIR/_writing_style_guide.md` for formatting preferences
   - **CRITICAL**: Read ALL bibliography entries from the project's `.bib` file under `$DOCUMENT_DIR/zotero_export/`
   - **CRITICAL**: For each bibliography entry, check if corresponding PDF/MD context exists:
     - Look for PDF files with matching names or in subdirectories
     - Look for converted MD files from previous runs
     - If PDF/MD context exists, read and use it for content understanding
     - If NO PDF/MD context exists, GUESS content based on bib entry (title, abstract, keywords, authors, journal/conference)
   - Read any markdown notes or attachments under `$DOCUMENT_DIR/zotero_export/` (subfolder layout may vary)
   - Read all files in `$DOCUMENT_DIR/assignment_info/`
   - Read `.latexkit/memory/constitution.md`
   - **NOTE**: If `zotero_export` folder is missing, create it with `.gitkeep` file to preserve structure

2a. **Silent prerequisite validation** (no CLI output):
   - Validate prerequisites exist but do not output to CLI
   - Check that start.md exists (if missing, stop and require `/latexkit.start`)
   - Check that research exists (if missing, warn and suggest `/latexkit.research`)
   - Only report critical blocking issues
   - Skip running validate-checklists.sh in this step to avoid verbose output

3. **Determine paper structure** based on assignment type:
   - **Essay**: Introduction, Body (thematic sections), Conclusion
   - **Research Paper**: Introduction, Literature Review, Methodology, Results, Discussion, Conclusion
   - **Lab Report**: Introduction, Methods, Results, Discussion, Conclusion
   - **Case Study**: Introduction, Case Background, Analysis, Recommendations, Conclusion
      - **Standard**: Introduction → Literature Review → Methodology → Results → Discussion → Conclusion
   - **Custom**: Follow structure specified in start.md or assignment requirements

4. **Build outline hierarchy**:
   - Level 1: Major sections (e.g., Introduction, Body, Conclusion)
   - Level 2: Subsections (key arguments or themes)
   - Level 3: Supporting points with evidence
   - Level 4: Specific examples and citations

5. **Integrate citations**:
   - **CRITICAL RULE**: For every claim requiring support, add `\cite{citation_key}` with precise academic referencing
   - **MANDATORY**: Use ALL bibliography items from the .bib file contextually throughout the outline
   - Match citation keys EXACTLY from the .bib file
   - For bibliography items WITHOUT PDF/MD context: Guess and incorporate their likely content based on:
     - Title (main topic and argument)
     - Abstract (if available in bib entry)
     - Keywords (key concepts)
     - Authors (expertise and perspective)
     - Journal/conference (field and credibility)
     - Year (historical context)
   - Use multiple citations for well-established claims: `\cite{author2020}` `\cite{author2021}`
   - Place citations immediately after the point they support with academic precision
   - If a needed source is missing, note: [SOURCE NEEDED: describe what evidence is required]
   - **ENSURE COVERAGE**: Every bibliography item must be used at least once in the outline, even if content is guessed

6. **Quality checks**:
   - **Logical flow**: Each section builds on previous with clear academic progression
   - **Argument balance**: Major sections have similar depth and scholarly rigor
   - **Evidence density**: All major claims have citations with precise academic referencing
   - **Bibliography coverage**: ALL bibliography items from .bib file are used at least once
   - **Content guessing**: For items without PDF context, guessed content is reasonable and contextual
   - **Scope adherence**: Content fits assignment requirements with academic precision
   - **Word count alignment**: Estimate fits required length with scholarly depth

7. **Generate outline file**:
   - Ensure directory exists: create if missing and add `.gitkeep` to preserve structure
   - Save to `$DOCUMENT_DIR/generated_work/outlines/YYYYMMDD_v01_outline.md`
   - If outline exists for today, increment version
   - Use clear hierarchical formatting [level2, level3, level4]
   - Include estimated word counts per section
   - Add notes for complex arguments needing development

7a. **Create outline checklist**:
   - Copy template from `.latexkit/templates/checklists/latexkit.outline.md`
   - Save to `$DOCUMENT_DIR/checklists/latexkit.outline.md`
   - Replace placeholders:
     - `DOCUMENT_ID` → actual document/branch name
     - `CREATED_DATE` → today's date (YYYY-MM-DD)
     - `LAST_CHECK_DATE` → today's date (YYYY-MM-DD)

8. **Create writing roadmap**:
   - Identify sections that can be written independently
   - Flag sections requiring additional research
   - Note connections between sections
   - Suggest writing order (may differ from reading order)

9. **Constitution compliance**:
   - Verify outline supports original thinking
   - Check for proper attribution planning
   - Ensure balanced use of sources (no over-reliance)
   - Validate argument coherence

9a. **Silent checklist validation at completion**:
   - Run `.latexkit/scripts/bash/validate-checklists.sh --command outline >/dev/null 2>&1` (silent mode)
   - This silently validates and updates the outline checklist without CLI output
   - Updates checklist based on actual files created
   - Marks completed items as done
   - Do not output validation results to user

10. **Report to user**:
   - Confirm current project: `$CURRENT_BRANCH`
   - Confirm document directory: `$DOCUMENT_DIR`
   - Outline file created
   - Structure summary (section count, estimated length)
   - Citation statistics (total citations, unique sources, bibliography coverage)
   - Content guessing: Number of bibliography items where content was guessed vs. had PDF context
   - Any [SOURCE NEEDED] flags
   - Next command: `/latexkit.draft`

11. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all outline work is complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh outline` from repository root
        - **CRITICAL**: Pass "outline" as the stage parameter to ensure OUTLINE label
     2. The script will auto-stage changes, use explicit "outline" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand outline structure
     5. Create descriptive commit message:
        - Format: `OUTLINE-NN: Descriptive title`
        - Body: Specific details about outline structure
        - Example:
          ```
          OUTLINE-03: Create detailed structure for [topic] with citation mapping
          
          - Developed hierarchical outline with [N] main sections
          - Mapped [N] citations to specific arguments and claims
          - Estimated word count distribution across sections
          - Created writing roadmap with section dependencies
          - Identified [N] areas requiring additional sources
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Outline Quality Gates

Ready for drafting when:
- ✅ All major sections defined
- ✅ Logical argument flow established
- ✅ Citations mapped to claims
- ✅ Scope matches assignment requirements
- ✅ No structural violations of constitution
- ✅ Estimated length within ±20% of target

## Key Rules

- Every assertion needs evidence or citation
- Introduction must preview argument structure
- Conclusion must synthesize, not just summarize
- Transitions between sections must be explicit
- Use active voice and clear topic sentences
- Match outline depth to assignment complexity
