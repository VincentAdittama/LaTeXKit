---
description: Generate complete Markdown draft following outline and style guide
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Create a full Markdown draft ready for human review and editing.

**Language Note**: This draft can be written in either English or Indonesian, regardless of the final document's output language specified in `start.md`. The conversion step will handle any necessary language adjustments for the final document. Write in whichever language is most comfortable for your initial drafting.

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
   - Read the most recent outline from `$DOCUMENT_DIR/generated_work/outlines/`
   - Read most recent research plan from `$DOCUMENT_DIR/generated_work/research/` (if available)
   - Read bibliography `.bib` file under `$DOCUMENT_DIR/zotero_export/` for citation keys
   - **CRITICAL**: For each bibliography entry, check if corresponding PDF/MD context exists:
     - Look for PDF files with matching names or in subdirectories
     - Look for converted MD files from previous runs
     - If PDF/MD context exists, read and use it for content understanding
     - If NO PDF/MD context exists, GUESS content based on bib entry (title, abstract, keywords, authors, journal/conference)
   - Read all files in `$DOCUMENT_DIR/assignment_info/`
   - Read `.latexkit/memory/constitution.md`
   - **NOTE**: If `zotero_export` folder is missing, create it with `.gitkeep` file to preserve structure

2a. **Silent prerequisite validation** (no CLI output):
   - Validate prerequisites exist but do not output to CLI
   - Check that start.md exists (if missing, stop and require `/latexkit.start`)
   - Check that outline exists (if missing, warn and suggest `/latexkit.outline`)
   - Only report critical blocking issues
   - Skip running validate-checklists.sh in this step to avoid verbose output

3. **Check for ambiguities and ask user preference**:
   
   Before writing the draft, scan the context files for:
   - Missing information that would require assumptions
   - Vague or unclear requirements in outline
   - Gaps in source material or research
   - Areas where multiple valid approaches exist
   - Placeholders or incomplete sections in outline
   
   If ambiguities are found:
   - **Ask the user**: "I found areas that need clarification. Would you like me to:
     - **A) Auto-fill** based on available context and best practices (faster, may need revision)
     - **B) Leave [NEEDS CLARIFICATION: description]** markers for manual review (more careful)
     - **C) Ask me** to clarify specific items interactively now"
   
   Based on user choice:
   - **Option A (Auto-fill)**: Make reasonable assumptions based on:
     - Assignment requirements and academic level
     - Available research and sources
     - Standard practices for the document type
     - Style guide and discipline conventions
     - Add `<!-- AUTO-FILLED: assumption made - <brief explanation> -->` comments
   - **Option B (Leave markers)**: Insert `[NEEDS CLARIFICATION: specific question or area]` markers
     - User can run `/latexkit.clarify` later to resolve these
     - Continue with draft using placeholders for unclear areas
   - **Option C (Interactive)**: Ask 2-3 most critical clarification questions now
     - Limit to essential blockers only (max 3 questions)
     - Continue with draft after getting answers
   
   If no significant ambiguities found, proceed directly to writing.

4. **Writing process** (follow outline structure):
   
   **For each section**:
   - Expand outline points into full paragraphs with precise academic language
   - Maintain formal academic tone and voice throughout
   - Integrate citations using `\cite{key}` notation with exact precision
   - Develop arguments with logical progression and supporting evidence
   - Use topic sentences that clearly state the paragraph's main idea
   - Include smooth transitions between paragraphs and ideas
   - Ensure each paragraph advances the overall argument systematically
   - If auto-fill mode: Add `<!-- AUTO-FILLED: assumption made - <brief explanation> -->` comments
   - If clarification mode: Insert `[NEEDS CLARIFICATION: specific question or area]` markers
   
   **Specific section requirements**:
   - **Introduction**: Hook → Context → Thesis → Roadmap
   - **Body sections**: Topic sentence → Evidence → Analysis → Synthesis
   - **Conclusion**: Restate thesis → Synthesize key points → Broader implications

5. **Citation integration**:
   - Use `\cite{author2020}` for single source
   - Use `\cite{author2020, author2021}` for multiple sources
   - Match citation keys EXACTLY from .bib file
   - Integrate citations naturally: "Studies show that... \cite{smith2020}"
   - Use signal phrases: "According to Smith \cite{smith2020}..."
   - Vary citation placement and integration style
   - **MANDATORY**: Use ALL bibliography items from the .bib file contextually throughout the draft
   - For bibliography items WITHOUT PDF/MD context: Guess and incorporate their likely content based on:
     - Title (main topic and argument)
     - Abstract (if available in bib entry)
     - Keywords (key concepts)
     - Authors (expertise and perspective)
     - Journal/conference (field and credibility)
     - Year (historical context)
   - **ENSURE COVERAGE**: Every bibliography item must be used at least once in the draft, even if content is guessed

6. **Style guide compliance**:
   - Follow specified tone (formal academic, professional, etc.)
   - Adhere to discipline-specific conventions
   - Use required terminology and avoid banned words
   - Match required person/voice (1st, 3rd person, etc.)
   - Apply formatting rules for headings, lists, emphasis

7. **Quality standards**:
   - **Clarity**: Every sentence has clear, unambiguous purpose with precise terminology
   - **Coherence**: Ideas flow logically within and between paragraphs with explicit connections
   - **Concision**: No unnecessary words or repetition; each word serves a specific function
   - **Correctness**: Grammar, spelling, and academic conventions are flawless
   - **Citation density**: Appropriate for academic level (undergrad: ~1-2 per paragraph, grad: 2-4)
   - **Bibliography coverage**: ALL bibliography items from .bib file are used at least once
   - **Content guessing**: For items without PDF context, guessed content is reasonable and contextual

8. **Generate draft file**:
   - Ensure directory exists: create if missing and add `.gitkeep` to preserve structure
   - Save to `$DOCUMENT_DIR/generated_work/drafts/YYYYMMDD_v01_draft.md`
   - If draft exists for today, increment version
   - Include metadata header (title, author, date, word count)
   - Add inline comments for areas needing human review: `<!-- REVIEW: reason -->`
   - Flag any [SOURCE NEEDED] items from outline
   - Include `<!-- AUTO-FILLED: explanation -->` comments if auto-fill mode was used
   - Include `[NEEDS CLARIFICATION: question]` markers if clarification mode was used

9. **Self-review checklist**:
   - Word count within required range (±10%)
   - All outline points addressed
   - Citations for all major claims
   - Bibliography coverage: ALL items from .bib file used at least once
   - Content guessing: Reasonable assumptions made for items without PDF context
   - No plagiarism flags (paraphrase + cite, never copy)
   - Consistent voice throughout
   - Clear argument progression

10. **Constitution validation**:
   - Verify original analysis (not just synthesis)
   - Check proper attribution throughout
   - Ensure academic integrity maintained
   - Validate no over-reliance on single source

11. **Create review checklist**:
   - Copy template from `.latexkit/templates/checklists/latexkit.draft.md`
   - Save to `$DOCUMENT_DIR/checklists/latexkit.draft.md`
   - Replace placeholders:
     - `DOCUMENT_ID` → actual document/branch name
     - `CREATED_DATE` → today's date (YYYY-MM-DD)
     - `LAST_CHECK_DATE` → today's date (YYYY-MM-DD)
   - Include content, structure, and style review points
   - Add assignment-specific criteria from requirements

11a. **Silent checklist validation at completion**:
   - Run `.latexkit/scripts/bash/validate-checklists.sh --command draft >/dev/null 2>&1` (silent mode)
   - This silently validates and updates the draft checklist without CLI output
   - Updates checklist based on actual files created
   - Marks completed items as done
   - Do not output validation results to user

12. **Report to user**:
   - Confirm current project: `$CURRENT_BRANCH`
   - Confirm document directory: `$DOCUMENT_DIR`
   - Draft file created with version number
   - Word count and target comparison
   - Citation statistics (total citations, unique sources, bibliography coverage)
   - Content guessing: Number of bibliography items where content was guessed vs. had PDF context
   - Review points flagged with `<!-- REVIEW -->`
   - If auto-fill mode was used: List areas where assumptions were made
   - If clarification mode was used: List `[NEEDS CLARIFICATION]` markers added
   - Suggest running `/latexkit.clarify` if markers were added
   - Next command: Human reviews draft, then `/latexkit.convert`

13. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all draft work is complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh draft` from repository root
        - **CRITICAL**: Pass "draft" as the stage parameter to ensure DRAFT label
     2. The script will auto-stage changes, use explicit "draft" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand draft content
     5. Create descriptive commit message:
        - Format: `DRAFT-NN: Descriptive title`
        - Body: Specific details about draft content
        - Example:
          ```
          DRAFT-04: Complete full draft with introduction, body, and conclusion
          
          - Wrote [N]-word draft covering all outline sections
          - Integrated [N] citations from research sources
          - Developed introduction with thesis and framework
          - Completed [main sections] with evidence and analysis
          - Added [N] review markers for human review
          - Applied [auto-fill/clarification] mode for ambiguous areas
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Draft Quality Gates

Ready for conversion when human confirms:
- ✅ Argument is clear and well-supported
- ✅ All major claims have citations
- ✅ Writing meets style guide standards
- ✅ Word count is appropriate
- ✅ No plagiarism or integrity issues
- ✅ Outline is fully realized
- ✅ All `<!-- REVIEW -->` items addressed

## Key Rules

- **NEVER copy source text verbatim** - always paraphrase + cite
- Maintain consistent academic voice
- Every paragraph should advance the argument
- Transitions are explicit, not assumed
- Citations are integrated, not tacked on
- Complex ideas are explained clearly
- Examples support, not replace, analysis
- Version all drafts - never overwrite
