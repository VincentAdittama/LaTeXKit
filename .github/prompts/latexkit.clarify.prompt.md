````markdown
---
description: Find and resolve clarification markers across the entire project by asking targeted questions one by one and updating files with answers
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Find and resolve clarification markers across the entire project by asking targeted clarification questions and updating documents with answers.

Note: This clarification workflow can run at ANY phase AFTER `/latexkit.start` - whether after start, research, outline, draft, or any other phase. It scans ALL files in the project for clarification markers (both `[NEEDS CLARIFICATION]` and `[NEED CLARIFICATION]` patterns) and resolves them one by one.

Execution steps:

1. **Detect current project**:
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` OR manually detect:
     - Get current git branch: `git rev-parse --abbrev-ref HEAD`
     - If not in git repo or on main branch, check `LATEXKIT_DOCUMENT` environment variable
     - Set `CURRENT_BRANCH` to the branch name (e.g., `<project-branch-name>`)
     - Set `DOCUMENT_DIR` to `documents/$CURRENT_BRANCH/`
   - All subsequent paths should be relative to `DOCUMENT_DIR`
   - Set `DOCUMENT_SPEC` to `$DOCUMENT_DIR/start.md`
   - If `DOCUMENT_DIR` doesn't exist or `start.md` missing, report error and suggest running `/latexkit.start` first

1a. **Validate project structure**:
   - Run validation: `.latexkit/scripts/bash/validate-structure.sh "$DOCUMENT_DIR"`
   - If validation fails, warn about missing files/directories
   - If critical files missing (start.md), stop and require re-run of start command

2. **Scan ALL project files for clarification markers**:
   - Search recursively in `$DOCUMENT_DIR` for ALL files containing clarification markers
   - **CRITICAL**: Search for BOTH patterns (case-sensitive):
     - `[NEEDS CLARIFICATION:` (plural, with S)
     - `[NEED CLARIFICATION:` (singular, without S)
   - Include these locations:
     - `start.md` - Assignment requirements and specifications
     - `checklists/*.md` - All checklist files (latexkit.start.md, latexkit.research.md, etc.)
     - `generated_work/research/*.md` - Research plans and notes
     - `generated_work/outlines/*.md` - Outline documents
     - `generated_work/drafts/*.md` - Draft documents
     - `assignment_info/*.md` - Assignment context files
     - Any other `.md` or `.tex` files in the project
   - For EACH marker found, extract:
     - File path (relative to DOCUMENT_DIR)
     - Marker text: `[NEEDS CLARIFICATION: question]` or `[NEED CLARIFICATION: question]`
     - Surrounding context (2-3 lines before and after)
     - Section/heading context where marker appears
   - Create a priority queue of ALL clarification needs found

2a. **Perform structured ambiguity & coverage scan on start.md** (if no explicit markers found or as supplementary scan). Use this taxonomy to detect implicit ambiguities. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output raw map unless no questions will be asked).

   **Document Purpose & Scope**:
   - Clear statement of document purpose and goals
   - Explicit out-of-scope declarations
   - Document type correctly identified
   - Target audience understood

   **Assignment Context**:
   - Course details complete (name, code, instructor)
   - Due date clearly specified
   - Grade weight/importance known
   - Group/team information complete (if group assignment)
   - All team member names and roles recorded

   **Content Requirements**:
   - Main topics and themes clearly defined
   - Research questions or essay questions explicit
   - Required sections/structure understood
   - Depth and breadth expectations clear

   **Format & Style Requirements**:
   - Length requirements (word count/pages) specified
   - Font, spacing, margins defined
   - Citation style explicitly stated
   - File format and submission method clear

   **Source & Research Requirements**:
   - Minimum number of sources specified
   - Source types required (peer-reviewed, books, etc.)
   - Recency requirements (publication date range)
   - Required readings or specific sources identified

   **Success Criteria**:
   - Grading rubric details known
   - Quality expectations clear
   - Deliverables well-defined
   - Academic standards understood

   **Constraints & Assumptions**:
   - Time constraints realistic
   - Resource availability confirmed
   - Knowledge prerequisites identified
   - Technical limitations known

   **Clarification Markers**:
   - All clarification tags reviewed (both `[NEEDS CLARIFICATION]` and `[NEED CLARIFICATION]`)
   - Vague adjectives ("robust", "comprehensive") identified
   - Ambiguous requirements flagged
   - Placeholder text detected

   For each category with Partial or Missing status, add a candidate question opportunity unless:
   - Clarification would not materially change the current or future phases
   - Information requires research or experimentation to answer

3. **Prioritize ALL clarification needs** (both explicit markers and implicit ambiguities):
   - **FIRST PRIORITY**: Explicit clarification markers found in files
     - Both `[NEEDS CLARIFICATION: ...]` and `[NEED CLARIFICATION: ...]` patterns
     - These are blocking issues that must be resolved
     - Group by file and present in logical order
   - **SECOND PRIORITY**: Implicit ambiguities from coverage scan
     - Only if explicit markers are few or already resolved
   - Prioritization factors:
     - Impact on current workflow phase
     - Impact on future workflow phases
     - Blocking vs. non-blocking for progression
     - Dependencies (some clarifications may depend on others)

4. **Generate (internally) a prioritized queue of candidate clarification questions (maximum 5 per session)**. Do NOT output them all at once. Apply these constraints:
    - Maximum of 5 total questions across the whole session.
    - **For explicit markers** (`[NEEDS CLARIFICATION: ...]` or `[NEED CLARIFICATION: ...]`): Use the question/description directly from the marker text
    - **For implicit ambiguities**: Formulate questions that can be answered with EITHER:
       - A short multiple‑choice selection (2–5 distinct, mutually exclusive options), OR
       - A one-word / short‑phrase answer (explicitly constrain: "Answer in ≤10 words").
    - Include context about WHERE the clarification is needed (file name, section)
    - Priority order:
       1. Blocking clarifications for current phase
       2. Blocking clarifications for next anticipated phase
       3. Non-blocking but high-impact clarifications
       4. Low-impact clarifications
    - If more than 5 clarifications exist, note remaining count and offer to continue in next session

5. **Sequential questioning loop (interactive)**:
    - Present EXACTLY ONE question at a time.
    - **Show context FIRST** before each question (critical for clarity):
      - Display the file where this clarification is needed
      - Display the section or heading where it appears
      - Format: `📄 **File**: \`path/to/file.md\` → **Section**: Section Name`
    - **Present the question** clearly and concisely
    - For multiple‑choice questions:
       - **Analyze all options** and determine the **most suitable option** based on:
          - Best practices for the document type (essay, research paper, report, etc.)
          - Common patterns in academic assignments at the specified level
          - Risk reduction (clarity, quality, academic standards)
          - Alignment with any explicit assignment goals or constraints visible in start.md
       - Present your **recommended option prominently** at the top with clear reasoning (1-2 sentences explaining why this is the best choice).
       - Format as: `**✅ Recommended:** Option [X] - <reasoning>`
       - Then render all options as a Markdown table:

       | Option | Description |
       |--------|-------------|
       | A | <Option A description> |
       | B | <Option B description> |
       | C | <Option C description> |
       | D | <Option D description> (add more as needed up to 5) |
       | Custom | Provide a different short answer (≤5 words) (Include only if free-form alternative makes sense) |

       - After the table, add: `**How to answer:** Reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.`
    - For short‑answer style (no meaningful discrete options):
       - Provide your **suggested answer** based on best practices and context.
       - Format as: `**✅ Suggested:** <your proposed answer> - <brief reasoning>`
       - Then output: `**How to answer:** Reply with a short answer (≤5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.`
    - **Show progress indicator**: `**Question X of Y**` at the top of each question
    - After the user answers:
       - If the user replies with "yes", "recommended", or "suggested", use your previously stated recommendation/suggestion as the answer.
       - Otherwise, validate the answer maps to one option or fits the ≤5 word constraint.
       - If ambiguous, ask for a quick disambiguation (count still belongs to same question; do not advance).
       - Once satisfactory, record it in working memory (do not yet write to disk)
       - **Show confirmation**: `✅ **Resolved**: <summary of answer> (updating \`filename\`...)`
       - Immediately update the file (see step 6)
       - Move to the next queued question.
    - Stop asking further questions when:
       - All critical ambiguities resolved early (remaining queued items become unnecessary), OR
       - User signals completion ("done", "good", "no more", "skip remaining"), OR
       - You reach 5 asked questions.
    - Never reveal future queued questions in advance.
    - If no valid questions exist at start, immediately report no critical ambiguities.

6. **Integration after EACH accepted answer (incremental update approach)**:
    - Identify which file the clarification belongs to (from step 2)
    - Load and maintain in-memory representation of that file
    
    **For start.md clarifications**:
    - For the first integrated answer in this session:
       - Ensure a `## Clarifications` section exists (create it just after the "Approval & Sign-off" section at the end if missing).
       - Under it, create (if not present) a `### Session YYYY-MM-DD` subheading for today.
    - Append a bullet line: `- Q: <question> (from <section>) → A: <final answer>`.
    - Apply the clarification to the appropriate section:
       - **Document purpose ambiguity** → Update Executive Summary or Purpose section
       - **Assignment context gaps** → Fill in Context & Background details
       - **Content requirement unclear** → Update Requirements section
       - **Format/style missing** → Complete Format Requirements section
       - **Source requirements vague** → Add explicit details to Citation Requirements
       - **Success criteria unclear** → Add measurable criteria to Success Criteria or Grading Rubric
       - **Constraints/assumptions ambiguous** → Clarify in Assumptions & Constraints section
       - **Clarification marker** → Replace marker with clarified information; remove placeholder entirely
         - Replace `[NEEDS CLARIFICATION: ...]` or `[NEED CLARIFICATION: ...]` with actual information
    
    **For checklist files** (checklists/*.md):
    - Find the clarification marker (`[NEEDS CLARIFICATION: ...]` or `[NEED CLARIFICATION: ...]`)
    - Replace entire marker line with: `- [x] <clarified requirement/instruction>`
    - Or if the clarification adds new information: Insert new checklist item with the clarification
    - Keep checklist structure intact
    
    **For other files** (research plans, outlines, drafts, context files):
    - Find the clarification marker (`[NEEDS CLARIFICATION: ...]` or `[NEED CLARIFICATION: ...]`)
    - Replace marker with the clarified information inline
    - Or insert clarified information in appropriate location nearby
    - Add comment if helpful: `<!-- Clarified YYYY-MM-DD: <answer> -->`
    
    **Universal rules**:
    - If clarification invalidates an earlier ambiguous statement, replace that statement
    - Leave no obsolete contradictory text
    - Save the file AFTER each integration (atomic overwrite)
    - Preserve formatting: do not reorder unrelated sections; keep heading hierarchy intact
    - Keep each inserted clarification minimal and testable

7. **Validation (performed after EACH write plus final pass)**:
   - For files with clarifications session log: exactly one bullet per accepted answer (no duplicates)
   - Total asked (accepted) questions ≤ 5
   - ALL clarification markers that were addressed are now removed
     - Check for both `[NEEDS CLARIFICATION]` and `[NEED CLARIFICATION]` patterns
   - No contradictory earlier statement remains
   - Markdown/LaTeX structure valid
   - Terminology consistency maintained across updated files
   - File-specific validation:
     - start.md: Session log exists if clarifications made, `## Clarifications` section properly formatted
     - Checklists: Checkboxes updated correctly, structure preserved
     - Other files: Clarifications integrated naturally, no orphaned markers

8. **Save all modified files**:
   - Write each updated file back to its original location
   - Files potentially modified:
     - `$DOCUMENT_DIR/start.md`
     - `$DOCUMENT_DIR/checklists/*.md`
     - `$DOCUMENT_DIR/generated_work/**/*.md`
     - `$DOCUMENT_DIR/assignment_info/*.md`
     - Any other file containing resolved markers

9. **Silent checklist validation at completion**:
   - Run `.latexkit/scripts/bash/validate-checklists.sh >/dev/null 2>&1` (silent mode)
   - This silently validates start, research, outline, draft, convert, and any other existing checklists
   - Does not output validation results to CLI
   - Note: Does not create new checklists - only validates existing ones

10. **Report completion (after questioning loop ends or early termination)**:
    - Confirm current branch/document: `$CURRENT_BRANCH`
    - Confirm document directory: `$DOCUMENT_DIR`
    - **Session Summary**:
      - Total clarification markers found: X (both `[NEEDS CLARIFICATION]` and `[NEED CLARIFICATION]` patterns)
      - Markers resolved this session: Y
      - Remaining markers: Z (if any)
      - Questions asked & answered: N
    - **Files Modified** (list all):
      - Path to each modified file
      - What was clarified in each file
    - **Remaining Work** (if applicable):
      - List remaining clarification markers by file
      - Suggest running `/latexkit.clarify` again to continue
      - Or note "All clarifications resolved! ✅"
    - **Next Steps**:
      - If in early phase (just after start): Suggest `/latexkit.research` or `/latexkit.outline`
      - If in middle phase (after research/outline): Suggest continuing to next workflow phase
      - If in late phase (after draft/convert): Suggest `/latexkit.build` or `/latexkit.check`
      - General: "Continue your workflow or run `/latexkit.clarify` again if more clarifications are added"

11. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all clarifications are complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh clarify` from repository root
        - **CRITICAL**: Pass "clarify" as the stage parameter to ensure CLARIFY label
     2. The script will auto-stage changes, use explicit "clarify" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand what was clarified
     5. Create descriptive commit message:
        - Format: `CLARIFY-NN: Descriptive title`
        - Body: List specific clarifications resolved
        - Example:
          ```
          CLARIFY-02: Resolve assignment requirements and format specifications
          
          - Clarified word count requirement: 2000-2500 words
          - Specified citation style: APA 7th Edition
          - Confirmed due date and submission format
          - Updated [X] files with clarification details
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Behavior Rules

- **Primary focus**: Resolve explicit clarification markers first, then implicit ambiguities
  - Search for both `[NEEDS CLARIFICATION: ...]` and `[NEED CLARIFICATION: ...]` patterns
- If NO clarification markers found AND no meaningful implicit ambiguities: 
  - Respond: "No clarifications needed! All requirements are clear. ✅"
  - Suggest continuing with current workflow phase
- If start.md file missing, instruct user to run `/latexkit.start` first
- Never exceed 5 questions per session (clarification retries for a single question do not count as new questions)
- If more than 5 clarifications exist, resolve first 5 and offer to continue in next session
- Respect user early termination signals ("stop", "done", "proceed", "skip", "skip remaining")
- Show progress: "**Question X of Y**" for each question
- After each answer, show: "✅ **Resolved**: <summary> (updating `filename`...)" before moving to next question
- Can be run multiple times - each session focuses on remaining clarifications
- Provide file context BEFORE each question so user knows WHERE the clarification applies
- Present ONE question at a time - never show all questions at once
- Always show recommended/suggested answers with reasoning
- Wait for user response before moving to next question

## Key Rules

- Use absolute paths for all files
- Always validate project structure before proceeding
- Preserve all manual edits in start.md
- Maximum 5 clarification questions per session
- Integration happens incrementally after each answer
- Remove all clarification markers when resolved (both `[NEEDS CLARIFICATION]` and `[NEED CLARIFICATION]` patterns)
- Never overwrite manual user additions to start.md
- Maintain markdown structure integrity
- Version control all changes (start.md is in git)
- Always show file context BEFORE presenting each question
- Present questions one at a time, never in batch
- Always provide recommended/suggested answers with clear reasoning

## Success Criteria

Clarification complete when:
- ✅ All asked questions answered
- ✅ Start.md updated with all clarifications (if applicable)
- ✅ Clarification markers reduced or eliminated
- ✅ No contradictory information in any files
- ✅ Coverage summary shows most categories Clear or Resolved
- ✅ Clarification checklist created
- ✅ Ready to proceed to next workflow phase

Context for prioritization: $ARGUMENTS