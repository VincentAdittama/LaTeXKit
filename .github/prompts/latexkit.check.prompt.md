---
description: Check assignment against requirements and academic standards
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Perform a final quality review before submission, checking content, format, and compliance.

1. **Detect current project**:
   - Run `.latexkit/scripts/bash/common.sh` function `get_document_paths` OR manually detect:
     - Get current git branch: `git rev-parse --abbrev-ref HEAD`
     - If not in git repo or on main branch, check `LATEXKIT_DOCUMENT` environment variable
     - Set `CURRENT_BRANCH` to the branch name (format: `NNN-project-name`)
     - Set `DOCUMENT_DIR` to `documents/$CURRENT_BRANCH/`
   - All subsequent paths should be relative to `DOCUMENT_DIR`
   - If `DOCUMENT_DIR` doesn't exist, report error and suggest running `/latexkit.start` first

2. **Load context files**:
   - Read `$DOCUMENT_DIR/start.md` for metadata and requirements
   - Read final draft from `$DOCUMENT_DIR/generated_work/drafts/`
   - Read compiled PDF from `$DOCUMENT_DIR/build/main.pdf`
   - Read LaTeX source files from `$DOCUMENT_DIR/latex_source/`
   - Read `$DOCUMENT_DIR/_writing_style_guide.md` if exists
   - Read bibliography (any `.bib` file) from `$DOCUMENT_DIR/zotero_export/` (export subfolder/filename may vary)

3. **Requirements compliance check**:
   
   **Structural requirements**:
   - Word count within specified range
   - Required sections present
   - Formatting matches specifications (font, spacing, margins)
   - Citation style correct (APA, MLA, Chicago, IEEE, etc.)
   - Page count appropriate
   
   **Content requirements**:
   - Assignment prompt fully addressed
   - All required topics covered
   - Depth of analysis appropriate for level
   - Argument is clear and supported
   - Sources meet quantity and quality requirements

4. **Academic quality assessment**:
   
   **Argument & Analysis**:
   - Thesis is clear, specific, and precisely articulated
   - Arguments are logical and rigorously supported with evidence
   - Evidence is relevant, properly interpreted, and critically analyzed
   - Analysis demonstrates depth beyond mere description
   - Counterarguments are systematically addressed (if applicable)
   - Conclusion synthesizes with scholarly precision and insight
   
   **Writing Quality**:
   - Clear, professional academic voice with precise terminology
   - Grammar and spelling are flawless with academic conventions
   - Sentences are varied, readable, and demonstrate scholarly style
   - Paragraphs are coherent with explicit topic sentences
   - Transitions connect ideas smoothly and logically
   - Terminology is used correctly and consistently
   
   **Citation & Research**:
   - All claims have appropriate citations
   - Citations are formatted correctly
   - Bibliography is complete and formatted properly
   - Sources are credible and current
   - No over-reliance on single source
   - Proper balance of source types

5. **Academic integrity verification**:
   
   **Plagiarism check**:
   - All direct quotes are in quotation marks + cited
   - Paraphrases are sufficiently transformed + cited
   - Common knowledge is distinguished from cited material
   - No suspicious similarity to sources
   
   **Original contribution**:
   - Analysis reflects independent thinking
   - Synthesis of sources, not just summary
   - Student's voice is clear
   - Conclusion shows original insight
   
   **Constitution compliance**:
   - Read `.latexkit/memory/constitution.md`
   - Verify adherence to all principles
   - Flag any borderline issues

6. **Formatting and presentation**:
   
   **Document formatting**:
   - Title page correct and complete
   - Headers/footers (if required)
   - Page numbers present and correct
   - Margins and spacing consistent
   - Font size and style appropriate
   - No orphaned headers or widows
   
   **Bibliography formatting**:
   - All entries complete
   - Format consistent throughout
   - Proper alphabetization
   - All cited works in bibliography
   - No uncited works in bibliography (unless annotated bibliography)

7. **Generate review report**:
   - Ensure directory exists: create if missing and add `.gitkeep` to preserve structure
   - Save to `$DOCUMENT_DIR/generated_work/reviews/YYYYMMDD_review-report.md`
   - Structure report:
     ```markdown
     # Assignment Review Report
     
     ## Overall Assessment
     [Ready/Needs revision/Significant issues]
     
     ## Requirements Compliance
     - ✅/❌ Word count: [actual] vs [required]
     - ✅/❌ Citation style: [style]
     - ✅/❌ Required sections: [list]
     - ...
     
     ## Quality Assessment
     ### Strengths
     - [strength 1]
     - [strength 2]
     
     ### Areas for Improvement
     - [issue 1 with suggestion]
     - [issue 2 with suggestion]
     
     ## Academic Integrity
     - ✅/❌ Plagiarism check
     - ✅/❌ Original analysis
     - ✅/❌ Proper attribution
     
     ## Submission Readiness
     [List of items to address before submission]
     ```

8. **Create submission checklist**:
   - Generate `$DOCUMENT_DIR/checklists/latexkit.check.md`
   - Include final checks:
     - PDF opens correctly
     - File naming follows requirements
     - All required components included
     - Submission portal/method confirmed
     - Backup copy created
     - Met all assignment-specific criteria

9. **Grading prediction** (optional, if helpful):
   - Estimate grade based on rubric (if available in start.md or assignment requirements)
   - Identify criteria likely to score well
   - Flag criteria needing strengthening
   - Suggest priority improvements for grade impact

10. **Report to user**:
   - Confirm current branch/document: `$CURRENT_BRANCH`
   - Confirm document directory: `$DOCUMENT_DIR`
   - Overall readiness status
   - Key strengths to celebrate
   - Critical issues requiring fixes
   - Optional improvements with time/impact estimate
   - Submission checklist status
   - Estimated completion time for remaining tasks

11. **Commit (if requested)**:
   - Check if user included "commit" argument in the command (check $ARGUMENTS for the word "commit")
   - **ONLY proceed with commit if "commit" argument is present**
   - If "commit" argument found, proceed AFTER all quality checks are complete:
     1. Run `.latexkit/scripts/bash/smart-commit.sh check` from repository root
        - **CRITICAL**: Pass "check" as the stage parameter to ensure CHECK label
     2. The script will auto-stage changes, use explicit "check" stage, and create changes file
     3. **CRITICAL**: Read the changes file from `/tmp/latexkit_commit_changes_*.txt`
     4. Analyze actual changes to understand review results
     5. Create descriptive commit message:
        - Format: `CHECK-NN: Descriptive title`
        - Body: Specific details about quality review
        - Example:
          ```
          CHECK-07: Complete quality review with submission readiness assessment
          
          - Validated all assignment requirements met
          - Confirmed [N] citations properly formatted
          - Verified academic integrity standards
          - Generated comprehensive review report
          - Identified [N] critical issues and [N] optional improvements
          - Created submission checklist with [N] final tasks
          ```
     6. Execute commit: `git commit -m "message"`
     7. Confirm commit success
   - If "commit" argument NOT found: Skip all commit steps and finish after completing the work

## Review Quality Gates

Ready for submission when:
- ✅ All requirements met
- ✅ No academic integrity concerns
- ✅ Writing quality is appropriate for level
- ✅ Citations and bibliography are correct
- ✅ Formatting matches specifications
- ✅ No critical errors or omissions
- ✅ Submission checklist complete

## Key Rules

- Be honest but constructive in feedback
- Prioritize issues by impact on grade
- Provide specific, actionable suggestions
- Distinguish between required fixes and enhancements
- Consider assignment weight and time constraints
- Verify constitution compliance
- Never suggest cutting corners on academic integrity
