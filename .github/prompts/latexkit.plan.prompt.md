---
description: Initialize a new academic assignment with proper structure and metadata
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

> IMPORTANT: When producing the final message for the user, avoid step-by-step log-style sentences such as "I've added", "replaced", "changed", "Created X todos", or other operational play-by-play. Present the final state concisely and as if delivering a finished initializer: confirm project directory and the recommended next step(s). Keep messages neutral and factual; do not enumerate internal implementation steps or transient helper operations.

## Main-Only Workflow Note

This template supports **Main-Only (Trunk-Based) workflow** where all projects live in `documents/` folder on the main branch. No branching is required - projects are managed via folder structure and `.active_project` file.

**Key Changes from Branch-Based Workflow:**
- Instead of creating branches, projects are created as folders in `documents/`
- Active project is tracked via `.active_project` file (not git branch)
- Use `get_active_project()` function from `common.sh` to detect current project
- All work stays on `main` branch, enabling easy search across all projects

## Outline

The text the user typed after `/latexkit.plan` is the assignment brief or description. This command initializes the complete assignment workflow.

0. **Detect current project** (Main-Only Workflow):
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` to get:
     - `ACTIVE_PROJECT` - current active project ID (from .active_project file)
     - `DOCUMENT_DIR` - full path to project directory
   - **If ACTIVE_PROJECT is set and DOCUMENT_DIR exists**: Switch to "edit mode" (steps 0a-0c)
   - **If no active project**: Report error and instruct user to create project via CLI (Step 1)

0a. **Edit mode: Detect existing project**:
   - Set `CURRENT_PROJECT` to active project name (format: `NNN-project-name`)
   - Set `DOCUMENT_DIR` to `documents/$CURRENT_PROJECT/`
   - If `DOCUMENT_DIR` doesn't exist, report error and suggest creating new project

0b. **Edit mode: Validate and update current implementation**:
   - Run validation: `.latexkit/scripts/bash/validate-structure.sh "$DOCUMENT_DIR"`
   - Check for missing files and recreate if needed
   - Read existing `start.md` and update with any new information from user input
   - Verify checklist completeness and update if needed
   - Check LaTeX structure integrity

0c. **Edit mode: Report status**:
   - Confirm current project and document directory
   - Report validation results
   - Suggest next steps based on current progress
   - Exit (do not proceed to creation steps)

1. **Handle "No Active Project" Case**:
   - If `ACTIVE_PROJECT` is empty or the directory doesn't exist:
     - **STOP IMMEDIATELY**. Do not attempt to create folders or files.
     - Inform the user: "No active project found. Please create a new project in the terminal first:"
     - Provide the command: \`./latexkit new "Project Name" --short-name "short-name"\`
     - Explain: "Once created, run \`/latexkit.plan\` again to populate the project metadata."
     - **EXIT**.

2. **Verify Project State**:
   - Confirm we are in `documents/$ACTIVE_PROJECT/`
   - If `start.md` already has content (not just the template), ask if user wants to overwrite or update.

3. **Load templates**: Read `.latexkit/templates/start-template.md` to understand required sections for the project start file.

4. **Extract document details** from user input:
   - Document title
   - Course name and code (if academic)
   - Instructor name (if academic)
   - Due date (if mentioned)
   - Document type (essay, report, lab report, case study, research paper, proposal, letter, etc.)
   - Special requirements (word count, formatting, citation style)
   - **Document Output Language**: The language for the final compiled document (PDF output)
     - Default: `Indonesian` (if not specified)
     - Look for language specifications in user input
     - **CRITICAL**: This determines the language of the FINAL LaTeX output and compiled PDF
     - Research, outline, and draft phases can be done in ANY language
     - The `/latexkit.convert` command handles translation to the final document language
     - Example: Draft in English → Convert reads this setting → Outputs Indonesian LaTeX if set to Indonesian
   - Key topics or themes
   - **Group/Team Information** (CRITICAL - DO NOT SKIP):
     - Group number/name (e.g., "Kelompok 7", "Group 7", "Team A")
     - Team member names with roles (e.g., Ketua/Leader, Anggota/Member)
     - Student IDs/NPM if provided
     - Maximum team size if specified
     - Any collaboration structure or division of work mentioned
   - **IMPORTANT**: If user mentions being part of a group/team or provides member names, you MUST extract ALL provided names and roles. Look for patterns like:
     - "aku kelompok X" (I'm in group X)
     - "kelompokku kelompok X" (my group is group X)
     - Lists of names with numbers (1. Name, 2. Name, etc.)
     - Role indicators (Ketua, Leader, Anggota, Member)
     - Student ID patterns (numbers after names)

5. **Create project start file**:
   - Write to START_FILE with extracted details using the start template structure
   - Include sections: Overview, Requirements, Success Criteria, Key Topics
   - **Document Output Language**: Set in the "Document Output Language" field
     - Default: `Indonesian` (if not specified by user)
     - Accepted values: `Indonesian`, `English`, or `Bilingual`
     - **CRITICAL EXPLANATION**: Add clear explanation that:
       - This setting controls the FINAL compiled LaTeX document language
       - Research/outline/draft can use ANY language for planning
       - The `/latexkit.convert` command will translate to match this setting
       - Example: "Draft in English, final PDF in Indonesian" is fully supported
     - Include examples in the template showing language transformation
   - **If user specified a project name in step 1**: Include the exact project name in the start file metadata
     - **MANDATORY**: If group/team information was found in user input:
     - Fill in the "Group/Team Information" section completely
     - List ALL provided member names with their roles
     - Include student IDs if provided
     - Specify group number/name
     - Note any collaboration requirements or structure
   - Use informed defaults for missing information:
     - doc_type: "report" (if unclear)
     - document_language: "Indonesian" (default for final document output)
     - citation_style: "APA 7th Edition" (default for all academic documents)
     - layout: "default" (12pt, A4, 1.5 spacing)
   - Mark unclear requirements with [NEEDS CLARIFICATION: question]
   - LIMIT: Maximum 3 clarification markers

6. **Create document checklist**:
   - Copy template from `.latexkit/templates/checklists/latexkit.start.md`
   - Save to `DOCUMENT_DIR/checklists/latexkit.start.md`
   - Replace placeholders:
     - `DOCUMENT_ID` → actual document/branch name
     - `CREATED_DATE` → today's date (YYYY-MM-DD)
     - `LAST_CHECK_DATE` → today's date (YYYY-MM-DD)
   - Customize based on document requirements (if needed)

7. **Verify directory structure**:
   - The script automatically creates a complete directory structure including:
     - `assignment_info/` - Place assignment context, attachments, and related materials here
     - `zotero_export/` - Place Zotero exports here (subfolder and filename may vary)
     - `generated_work/` - For research, outlines, drafts, etc.
     - `latex_source/` - Empty directory, will be populated by `/latexkit.convert`
     - `build/` - Directory for compiled PDF outputs
     - `checklists/` - Workflow tracking checklists
   - For academic documents (assignment, proposal, research paper):
     - Inform user about `zotero_export/` directory for Zotero Better BibTeX exports
     - Suggest: "Export your Zotero library to `DOCUMENT_DIR/zotero_export/` (include a .bib file and any attachments)"
     - Note: LaTeX templates will be imported and configured during the convert phase
   - For non-academic documents:
     - Directory exists but may not be needed (no action required)
   - **Validation**: Ensure all required files and directories were created successfully
     - start.md should exist
     - All subdirectories should exist

8. **Update constitution check**:
   - Read `.latexkit/memory/constitution.md`
   - Ensure document aligns with academic integrity standards
   - Flag any potential concerns (e.g., unclear collaboration policies)

9. **Silent checklist validation at completion**:
   - Run `.latexkit/scripts/bash/validate-checklists.sh --command plan >/dev/null 2>&1` (silent mode)
   - This silently validates and updates the start checklist without CLI output
   - Updates start checklist based on actual project state
   - Marks completed items as done
   - Do not output validation results to user

10. **Report to user**:
   - State: "New project initialized: `<DOC_NUM>-<short-name>` (Main-Only Workflow)."
   - Do NOT mention branch names - we're using folder-based workflow
   - If group assignment info was provided, add: "Team metadata recorded in start file."
   - If [NEEDS CLARIFICATION] items exist (max 3), add: "Remaining clarifications needed: [list]. Run `/latexkit.clarify` if needed."
   - For academic documents, add: "Export your Zotero library to `zotero_export/` (include a .bib file and any attachments) so the LaTeX templates can use it during conversion."
   - State recommended next step based on document type:
     - Academic: "Next recommended step: `/latexkit.research` to begin gathering sources."
     - Non-academic: "Next recommended step: `/latexkit.outline` to structure your content."

11. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all work is complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh plan` from repository root
        - **CRITICAL**: Pass "plan" as the stage parameter to ensure PLAN label
     2. The script will:
        - Auto-stage ALL changes (runs `git add -A`)
        - Use the explicit "start" stage (not auto-detect)
        - Calculate next sequential number for current branch
        - Create detailed changes file at `/tmp/latexkit_commit_changes_*.txt`
        - Output commit metadata (label, stage, iteration)
     3. **CRITICAL**: Read the changes file path from script output
     4. Use read_file tool to read the complete changes file
     5. Analyze actual file contents and changes
     6. Create descriptive commit message based on real changes:
        - Format: `PLAN-NN: Descriptive title`
        - Body: Specific details from changes file analysis
        - Example:
          ```
          PLAN-01: Initialize [topic] project with requirements and structure
          
          - Created complete project structure with LaTeX source and metadata directories
          - Documented requirements: [specific requirements from start.md]
          - Set up [document type] framework with [key details]
          - Initialized LaTeX template with sections and preamble
          ```
     7. Execute commit: `git commit -m "message"`
     8. Confirm commit was created successfully
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Key Rules

- **CLI FIRST**: Project creation MUST be done via `./latexkit new` in the terminal. The prompt only populates metadata.
- **MAIN-ONLY WORKFLOW**: All projects live in `documents/` on main branch - no branch switching needed
- Use absolute paths for all files
- Never overwrite existing assignments
- Preserve all manual edits in metadata files
- Create version-controlled checkpoints
- Validate all dates are in YYYY-MM-DD format
- **CRITICAL**: Always extract and save ALL group/team member information if provided
  - Never skip or omit member names from the start file
  - Include all roles (Ketua, Anggota, Leader, Member, etc.)
  - Preserve student IDs when provided
  - If user states "aku kelompok X" or lists members, this is MANDATORY information
- **ALWAYS quote file paths** in terminal commands to handle spaces correctly (e.g., `cd "$DOCUMENT_DIR"`)

## Success Criteria

Document is ready for next phase when:
- ✅ **New document mode**:
  - Project folder exists: `documents/NNN-short-name/`
  - `.active_project` points to this folder
  - **NO git branch created** - all work stays on `main` branch
  - Complete directory structure exists:
    - `checklists/`, `latex_source/`, `build/`
    - `assignment_info/`, `zotero_export/`
    - `generated_work/` (with subdirs for research, outlines, drafts, etc.)
  - Start file is complete (≤ 3 clarifications needed)
  - **If group assignment**: All team members and roles are recorded in start file
  - Initial checklist is generated
  - LaTeX structure will be initialized during convert phase
  - User informed about Zotero export location (if academic document)
  - Constitution check passes
  - No blocking errors
- ✅ **Edit mode** (active project exists):
  - Current project confirmed (from `.active_project` file)
  - Document directory exists and is accessible
  - Project structure validated
  - Start file updated with any new information
  - Status report provided
  - Next steps suggested based on current progress
