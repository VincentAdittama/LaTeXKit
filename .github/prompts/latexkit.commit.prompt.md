---
description: Create intelligent git commits with contextual workflow labels and iteration numbering
---

## CRITICAL PRINCIPLE

**THIS COMMAND IS PRIMARILY FOR MANUAL COMMITS OR DEBUGGING.**

All workflow commands (`/latexkit.start`, `/latexkit.research`, `/latexkit.draft`, etc.) **automatically commit** after completion using the smart-commit script. You typically don't need to run this command manually.

**When to use this command**:
- Manual commits outside of workflow commands
- Debugging commit message generation
- Custom commits for template/system changes
- When you want to commit without running a full workflow command

The smart-commit script (`smart-commit.sh`) handles preparation:
- ✅ **Auto-staging**: Automatically runs `git add -A` to stage ALL changes (unstaged + untracked)
- ✅ **Content analysis**: Creates detailed change summary file for LLM to analyze actual changes
- ✅ **Stage parameter**: Accepts explicit stage parameter (RECOMMENDED) or auto-detects from artifacts
- ✅ **Sequential numbering**: Finds next sequential number across all stages (continuous: 01, 02, 03...)
- ✅ **Metadata output**: Provides commit label, stage, iteration for LLM to use

**Artifact-based stage detection** (when no stage parameter provided):
- START: `checklists/latexkit.start.md` (first time) OR `start.md` (first time)
- CLARIFY: `checklists/latexkit.clarify.md` OR `start.md` (edited after creation)
- RESEARCH: `checklists/latexkit.research.md` OR `generated_work/research/` files
- OUTLINE: `checklists/latexkit.outline.md` OR `generated_work/outlines/` files
- DRAFT: `checklists/latexkit.draft.md` OR `generated_work/drafts/` files
- CONVERT: `checklists/latexkit.convert.md` OR `latex_source/sections/*.tex` files
- BUILD: `checklists/latexkit.build.md` OR `build/*.pdf` files
- CHECK: `checklists/latexkit.check.md` OR `generated_work/reviews/` files
- REFACTOR: `.latexkit/` system files
- DOCS: `README.md`, `docs/`, `.github/prompts/` files
- CHORE: Other files

**IMPORTANT**: When called from workflow commands (e.g., `/latexkit.start`, `/latexkit.research`), the workflow 
command MUST pass the explicit stage parameter to ensure consistency:
- `/latexkit.start` → calls `smart-commit.sh start`
- `/latexkit.research` → calls `smart-commit.sh research`
- `/latexkit.outline` → calls `smart-commit.sh outline`
- And so on...

**LLM workflow (CRITICAL):**
1. Run the script with appropriate stage parameter (if known)
2. Script outputs: commit label (e.g., "START-01"), changes file path, and categories
3. **READ the changes file** at `/tmp/latexkit_commit_changes_*.txt`
4. **ANALYZE actual content** to understand what changed
5. **CREATE descriptive commit message** based on real changes
6. **EXECUTE the commit** using `git commit -m` with the generated message

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

This command creates intelligent git commits by automatically staging all changes, analyzing actual file contents, and applying proper workflow labels.

1. **Invoke the smart-commit script**:
   - Script location: `.latexkit/scripts/bash/smart-commit.sh`
   - **RECOMMENDED**: Pass explicit stage parameter if known (e.g., `start`, `research`, `draft`)
   - If stage is unknown, pass user arguments directly and script will auto-detect
   - The script stages changes and prepares metadata

2. **Script outputs metadata**:
   - **Auto-stages ALL changes**: Runs `git add -A` automatically
   - **Generates detailed changes file**: Creates `/tmp/latexkit_commit_changes_$$.txt`
   - **Uses explicit stage OR auto-detects**: Prefers explicit stage parameter, falls back to file analysis
   - **Calculates sequential number**: Finds next sequential number in current branch (continuous: 01, 02, 03...)
   - **Outputs commit label**: Shows the label to use (e.g., "START-01", "RESEARCH-02")
   - **Lists change categories**: Shows general file categories changed
   - **Provides changes file path**: Shows exact path to detailed changes file

3. **CRITICAL: Read and analyze the changes file**:
   - **IMMEDIATELY after script runs**, you MUST:
     - Look for the output line: "Detailed changes file created: /tmp/latexkit_commit_changes_*.txt"
     - **Read that file completely** using the read_file tool
     - Analyze what actually changed in each file
     - Understand the context of the changes
   
   - The changes file contains:
     - List of all changed files with status (NEW/MODIFIED/DELETED)
     - Actual diff content (additions/deletions)
     - Preview of new files (first 10 lines)
     - Line-by-line changes for modified files (up to 20 lines)
   
   - Use this information to create a **descriptive, contextual commit message** that explains:
     - What was added, changed, or removed
     - Why these changes were made (based on content analysis)
     - What the changes accomplish
     - Any important implementation details

4. **Generate commit message based on actual changes**:
   - **Format**: `LABEL: Descriptive title`
   - Use the LABEL from script output (e.g., "START-01")
   - **Title**: Should describe the actual change, not generic phrases
   - Use insights from the changes file to create specific, meaningful titles
   - Examples:
     - ❌ Bad: "START-01: Update workflow progress"
     - ✅ Good: "START-01: Initialize annotated bibliography project on choir conducting ethics"
     - ✅ Good: "RESEARCH-02: Add systematic review strategy with 5 academic databases"
     - ✅ Good: "DRAFT-03: Complete introduction section with thesis statement and framework"
   
   - **Body**: Should detail what actually changed (multi-line format)
   - Include specific details from the changes file analysis
   - Examples:
     ```
     - Created complete project structure with LaTeX source, metadata directories, and checklists
     - Documented requirements: annotated bibliography with 5 keywords, minimum 25 sources, APA 7th style
     - Set up academic assignment framework with course details and deadline
     - Initialized LaTeX template with main.tex, preamble.tex, and section files
     ```
   
   vs. generic (DON'T DO THIS):
     ```
     - Project start files
     - LaTeX source files
     - Checklists
     ```

5. **Execute the commit**:
   - Use `git commit -m` with your generated message
   - Format the message properly with title and body:
     ```bash
     git commit -m "LABEL: Title

     - Detail 1
     - Detail 2
     - Detail 3"
     ```
   - Do NOT use `git commit --amend` unless user specifically requests it
   - The changes are already staged by the script

6. **Stage detection priority** (artifact-based, from highest to lowest priority):
   
   **Checklist-based detection (HIGHEST PRIORITY)**:
   - `checklists/latexkit.start.md` (first time) → **START**
   - `checklists/latexkit.clarify.md` → **CLARIFY**
   - `checklists/latexkit.research.md` → **RESEARCH**
   - `checklists/latexkit.outline.md` → **OUTLINE**
   - `checklists/latexkit.draft.md` → **DRAFT**
   - `checklists/latexkit.convert.md` → **CONVERT**
   - `checklists/latexkit.build.md` → **BUILD**
   - `checklists/latexkit.check.md` → **CHECK**
   
   **Artifact-based detection (if no checklist)**:
   - `start.md` (first time) → **START**
   - `start.md` (edited after creation) → **CLARIFY**
   - `generated_work/research/` → **RESEARCH**
   - `generated_work/outlines/` → **OUTLINE**
   - `generated_work/drafts/` → **DRAFT**
   - `latex_source/sections/*.tex` → **CONVERT**
   - `build/*.pdf` → **BUILD**
   - `generated_work/reviews/` → **CHECK**
   
   **System/documentation changes**:
   - `.latexkit/` → **REFACTOR**
   - `README.md`, `docs/`, `.github/prompts/` → **DOCS**
   - Other files → **CHORE**

7. **User can override stage**:
   ```
   /latexkit.commit research
   /latexkit.commit draft -m "Custom message"
   /latexkit.commit --stage outline --message "Restructure"
   ```

8. **Commit format**:
   ```
   STAGE-NN: Descriptive title based on actual changes
   
   - Specific change 1 with details
   - Specific change 2 with details
   - ...
   ```
   
   Numbers are sequential and continuous (01, 02, 03...) regardless of stage.

## Implementation

**Step 1: Run the preparation script**

```bash
cd /path/to/workspace && .latexkit/scripts/bash/smart-commit.sh [ARGUMENTS]
```

This script:
- Stages all changes automatically
- Detects workflow stage and iteration number
- Creates detailed changes file at `/tmp/latexkit_commit_changes_*.txt`
- Outputs metadata for LLM to use

**Step 2: Read the changes file**

```bash
cat /tmp/latexkit_commit_changes_[PID].txt
```

Extract the PID from script output and read the complete file.

**Step 3: Analyze and create commit message**

Based on the changes file content:
1. Understand what actually changed
2. Create descriptive title reflecting real changes
3. List specific details in the body

**Step 4: Execute the commit**

```bash
cd /path/to/workspace && git commit -m "LABEL: Title

- Specific detail 1
- Specific detail 2
- Specific detail 3"
```

Use the LABEL from script output (e.g., START-01, RESEARCH-02).

## Examples

### Example 1: First commit with content analysis

**User command:**
```
/latexkit.commit
```

**Script execution:**
```bash
cd /path/to/workspace && .latexkit/scripts/bash/smart-commit.sh
```

**Script output:**
```
[INFO] Auto-staging all changes...
[INFO] Current branch: 003-research-paper-topic
[INFO] Using stage: START
[INFO] Sequential number: 01
[INFO] Changes to commit:

 documents/003-research-paper-topic/start.md              | 280 +++++++++++++
 documents/003-research-paper-topic/latex_source/main.tex |  57 +++
 ... (more files)

═══════════════════════════════════════════════════
Commit Metadata for LLM
═══════════════════════════════════════════════════

Label: START-01
Stage: START
Iteration: 01
Branch: 003-research-paper-topic

Change Categories:
- Project start files
- LaTeX source files
- Checklists

═══════════════════════════════════════════════════

✓ Changes staged
✓ Detailed changes file created: /tmp/latexkit_commit_changes_12345.txt

→ LLM: Read the changes file and create a descriptive commit message
→ Format: START-01: [Your descriptive title]
```

**LLM reads changes file:**
```bash
cat /tmp/latexkit_commit_changes_12345.txt
```

**Changes file contains:**
```
FILES CHANGED: 20

═══ documents/003-research-paper-topic/start.md ═══
[NEW FILE]
  # Research Paper: [Your Topic]
  ## Requirements
  - Research paper format
  - 5 keywords related to topic
  - Minimum 10 scholarly sources
  - APA 7th Edition citation style
  ...
```

**LLM analyzes and creates commit:**
```bash
cd /path/to/workspace && git commit -m "START-01: Initialize research paper project on [topic]

- Created complete project structure with LaTeX source, metadata directories, and checklists
- Documented requirements: annotated bibliography with 5 keywords, minimum 25 sources, APA 7th style
- Set up academic assignment framework with course details and deadline (2025-10-27)
- Initialized LaTeX template with main.tex, preamble.tex, and section files
- Prepared research workflow directories for outlines, drafts, and source management"
```

### Example 2: Research phase with detailed changes

**Script output:**
```
Label: RESEARCH-02
✓ Detailed changes file created: /tmp/latexkit_commit_changes_23456.txt
```

**Changes file shows:**
```
═══ generated_work/research/20250124_v01_research-plan.md ═══
[NEW FILE]
  # Research Strategy
  ## Primary Databases
  - JSTOR: Focus on environmental science journals
  - Google Scholar: Broad academic coverage
  - ProQuest: Recent policy papers
  
  ## Search Keywords
  - climate change impacts
  - global warming effects
  ...
```

**LLM creates commit:**
```bash
cd /path/to/workspace && git commit -m "RESEARCH-02: Develop comprehensive research strategy for climate sources

- Identified 3 primary academic databases (JSTOR, Google Scholar, ProQuest)
- Defined database-specific search strategies for environmental science
- Created keyword taxonomy: impacts, effects, degradation, adaptation
- Set inclusion criteria: peer-reviewed, published 2015-2025
- Planned systematic review approach with quality assessment framework"
```

### Example 3: Draft with specific content

**Changes file shows:**
```
═══ generated_work/drafts/YYYYMMDD_v02_draft.md ═══
[MODIFIED]
+## Introduction
+Climate change represents one of the most pressing challenges of our time.
+Recent studies demonstrate accelerating impacts on ecosystems \cite{author2023climate}.
+This essay examines three critical areas: mitigation, adaptation, and policy.
...
```

**LLM creates commit:**
```bash
cd /path/to/workspace && git commit -m "DRAFT-03: Complete introduction with thesis and framework

- Added hook connecting climate urgency to current scientific findings
- Integrated 3 recent citations establishing baseline context (Author 2023, Author 2022)
- Developed clear thesis statement covering mitigation, adaptation, and policy
- Created roadmap paragraph previewing three-part essay structure
- Strengthened transitions between contextual and analytical paragraphs"
```

## Workflow Stage Guide

| Stage | Artifact Detection | Example Files |
|-------|-------------------|---------------|
| START | start.md (new) OR latexkit.start.md checklist (first time) | documents/*/start.md, checklists/latexkit.start.md |
| CLARIFY | start.md (edited) OR latexkit.clarify.md checklist | start.md (edited), checklists/latexkit.clarify.md |
| RESEARCH | latexkit.research.md checklist OR research/ artifacts | checklists/latexkit.research.md, generated_work/research/*.md |
| OUTLINE | latexkit.outline.md checklist OR outlines/ artifacts | checklists/latexkit.outline.md, generated_work/outlines/*.md |
| DRAFT | latexkit.draft.md checklist OR drafts/ artifacts | checklists/latexkit.draft.md, generated_work/drafts/*.md |
| CONVERT | latexkit.convert.md checklist OR LaTeX sections | checklists/latexkit.convert.md, latex_source/sections/*.tex |
| BUILD | latexkit.build.md checklist OR PDF files | checklists/latexkit.build.md, build/*.pdf |
| CHECK | latexkit.check.md checklist OR reviews/ artifacts | checklists/latexkit.check.md, generated_work/reviews/*.md |
| FIX | (manual) | Any corrections |
| REFACTOR | System files | .latexkit/**/* |
| DOCS | Documentation | docs/*.md, README.md, .github/prompts/*.md |
| FEAT | (manual) | New features |
| CHORE | Other files | Config, cleanup |

**Detection Priority**: Checklists are checked first, then artifact files, then fallback patterns.
This ensures accurate stage detection based on the actual workflow phase.

## Important Notes

1. **ALWAYS read the changes file**: Extract PID from script output and read `/tmp/latexkit_commit_changes_[PID].txt`
2. **Analyze actual content**: Don't just categorize files, understand what changed
3. **Be specific**: Commit messages should reflect real changes, not generic categories
4. **Script only stages**: The script does NOT create the commit - LLM must do it
5. **No amend needed**: Use regular `git commit -m`, not `--amend`
6. **Stage detection is smart**: Prioritizes most specific file patterns
7. **Sequential numbering per branch**: Numbers are continuous (01, 02, 03...) regardless of stage type
8. **Branch isolation**: Each branch has its own numbering sequence starting from 01
9. **User can override**: Explicitly specify stage if auto-detection is wrong
10. **Format is LABEL: Title**: Use the exact label from script (e.g., START-01, RESEARCH-02)

## Error Handling

Common issues and solutions:

**Changes file not found:**
- Script output shows the exact filename with PID
- Extract the PID from output line: "Detailed changes file created: /tmp/latexkit_commit_changes_12345.txt"
- Read that specific file immediately after script runs

**No changes to commit:**
- Script reports "No changes to commit" and exits
- Verify you made changes before running the command

**Not in git repository:**
- Script reports error and exits
- Ensure you're in a git repository

**Invalid stage:**
- Script shows valid stages and exits
- Use one of: start, clarify, research, outline, draft, convert, build, check, fix, refactor, docs, feat, chore

## Success Criteria

A successful commit should:
- ✅ Have proper workflow label format (STAGE-NN, e.g., START-01)
- ✅ Show continuous sequential number (01, 02, 03...)
- ✅ Describe actual content changes (not just file categories)
- ✅ Include specific details from the changes file analysis
- ✅ Be meaningful and understandable
- ✅ Provide context for future developers/reviewers
- ✅ Track workflow progress linearly
- ✅ Use multi-line format with title and detailed body

**Example of good commit:**
```
START-01: Initialize annotated bibliography project on choir conducting ethics

- Created complete project structure with LaTeX source, metadata directories, and checklists
- Documented requirements: annotated bibliography with 5 keywords, minimum 25 sources, APA 7th style
- Set up academic assignment framework with course details and deadline (2025-10-27)
- Initialized LaTeX template with main.tex, preamble.tex, and section files
```

**Example of bad commit (DON'T DO THIS):**
```
START-01: Update workflow progress

- Project start files
- LaTeX source files
- Checklists
```

## Integration with Workflow

**NOTE**: All workflow commands now automatically commit after completion. You typically don't need to run this command manually.

Each workflow command automatically commits:
```
/latexkit.start     → Auto-commits with START label
/latexkit.clarify   → Auto-commits with CLARIFY label
/latexkit.research  → Auto-commits with RESEARCH label
/latexkit.outline   → Auto-commits with OUTLINE label
/latexkit.draft     → Auto-commits with DRAFT label
/latexkit.convert   → Auto-commits with CONVERT label
/latexkit.build     → Auto-commits with BUILD label
/latexkit.check     → Auto-commits with CHECK label
```

The LLM reads the changes file and creates descriptive commits automatically after each workflow step!