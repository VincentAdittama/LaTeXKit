---
description: Generate comprehensive research strategy and gather academic sources
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

This command creates a research strategy based on assignment requirements and available context.

**Language Note**: This research phase can be conducted in either English or Indonesian, regardless of the final document's output language specified in `start.md`. Choose the language that best suits your research materials and sources.

1. **Detect current project**:
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` OR manually detect:
     - Get current git branch: `git rev-parse --abbrev-ref HEAD`
     - If not in git repo or on main branch, check `LATEXKIT_DOCUMENT` environment variable
     - Set `CURRENT_BRANCH` to the branch name (e.g., `001-project-name`)
     - Set `DOCUMENT_DIR` to `documents/$CURRENT_BRANCH/`
   - All subsequent paths should be relative to `DOCUMENT_DIR`
   - If `DOCUMENT_DIR` doesn't exist, report error and suggest running `/latexkit.start` first

1a. **Validate project structure**:
   - Run validation: `.latexkit/scripts/bash/validate-structure.sh "$DOCUMENT_DIR"`
   - If validation fails, warn the user about missing files/directories
   - Suggest running `/latexkit.start` to recreate missing structure
   - If critical files are missing (start.md), stop and require re-run of start command

2. **Load context files**:
   - Read `$DOCUMENT_DIR/start.md` (or `_assignment_info.md` if it exists for backwards compatibility)
   - Read all files in `$DOCUMENT_DIR/assignment_info/`
   - Read `.latexkit/memory/constitution.md` for research standards
   - If Zotero export exists, read the project's `.bib` file under `$DOCUMENT_DIR/zotero_export/`
   - **NOTE**: If the `zotero_export` folder is missing, create it (e.g. add a `.gitkeep`) — subfolder layout and filenames may vary per export tool

2a. **Silent prerequisite validation** (no CLI output):
   - Validate prerequisites exist but do not output to CLI
   - Check that start.md exists (if missing, stop and require `/latexkit.start`)
   - Only report critical blocking issues
   - Skip running validate-checklists.sh in this step to avoid verbose output

3. **Analyze assignment requirements**:
   - Extract key concepts and themes
   - Identify required theoretical frameworks
   - Determine scope and depth of research needed
   - Note any specific source requirements (e.g., "minimum 10 peer-reviewed sources")

4. **Generate research strategy** including:
   - **Search Keywords**: Primary and secondary keywords for databases
   - **Key Authors & Works**: Foundational texts and seminal authors
   - **Research Questions**: Core questions the paper must answer
   - **Source Types**: Required mix (journals, books, reports, etc.)
   - **Database Recommendations**: Specific academic databases to search
   - **Search Strategy**: Boolean operators and search strings

5. **Analyze existing sources** (if Zotero export available):
   - Read bibliography entries
   - Read any markdown notes or attachments under `$DOCUMENT_DIR/zotero_export/` (subfolder layout may vary)
   - Identify gaps in current research
   - Suggest additional sources needed

6. **Create research plan file**:
   - Ensure directory exists: create if missing and add `.gitkeep` to preserve structure
   - Save to `$DOCUMENT_DIR/generated_work/research/YYYYMMDD_v01_research-plan.md`
   - If research plan exists for today, increment version (v02, v03, etc.)
   - Include all sections from step 4
   - Add "Source Gap Analysis" if Zotero data available

7. **Generate source evaluation checklist**:
   - Copy template from `.latexkit/templates/checklists/latexkit.research.md`
   - Save to `$DOCUMENT_DIR/checklists/latexkit.research.md`
   - Replace placeholders:
     - `DOCUMENT_ID` → actual document/branch name
     - `CREATED_DATE` → today's date (YYYY-MM-DD)
     - `LAST_CHECK_DATE` → today's date (YYYY-MM-DD)
   - Include CRAAP test criteria (Currency, Relevance, Authority, Accuracy, Purpose)
   - Add discipline-specific evaluation criteria

8. **Constitution compliance check**:
   - Verify research strategy promotes academic integrity
   - Ensure diverse source types (avoid over-reliance on single source type)
   - Check that plagiarism prevention is built into workflow

8a. **Silent checklist validation at completion**:
   - Run `.latexkit/scripts/bash/validate-checklists.sh --command research >/dev/null 2>&1` (silent mode)
   - This silently validates and updates the research checklist without CLI output
   - Updates checklist based on actual files created
   - Marks completed items as done
   - Do not output validation results to user

9. **Report to user**:
   - Confirm current branch/document: `$CURRENT_BRANCH`
   - Confirm document directory: `$DOCUMENT_DIR`
   - Confirm research plan created
   - List recommended databases and search terms
   - Show statistics (if sources exist): current source count, recommended count
   - Next command: `/latexkit.outline` (after gathering sources)

10. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all research work is complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh research` from repository root
        - **CRITICAL**: Pass "research" as the stage parameter to ensure RESEARCH label
     2. The script will auto-stage changes, use explicit "research" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand research strategy created
     5. Create descriptive commit message:
        - Format: `RESEARCH-NN: Descriptive title`
        - Body: Specific details about research strategy
        - Example:
          ```
          RESEARCH-02: Develop comprehensive research strategy for [topic]
          
          - Identified [N] primary academic databases with specific search strategies
          - Defined keyword taxonomy: [key terms]
          - Created systematic review approach with quality criteria
          - Set inclusion criteria: peer-reviewed, published [date range]
          - Documented source gap analysis and recommendations
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Research Quality Gates

Before proceeding to outline phase:
- ✅ Research questions clearly defined
- ✅ Search strategy is comprehensive
- ✅ Key theoretical frameworks identified
- ✅ Source diversity requirements met
- ✅ Gap analysis completed (if sources exist)

## Key Rules

- Prioritize peer-reviewed academic sources
- Balance breadth and depth appropriate to assignment level
- Consider recency requirements (esp. for fast-moving fields)
- Align citation style with discipline (APA for social sciences, MLA for humanities, IEEE for engineering, etc.)
- Version all generated files
