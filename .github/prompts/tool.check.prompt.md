# MISSION: TOOL CHECK

## VISION
Perform a final quality review before submission, ensuring compliance with requirements and academic standards.

## CONTEXT
- **Input**: Draft, PDF, Assignment Info.
- **Output**: Review Report and Submission Checklist.
- **Goal**: Detect last-minute issues.

## INPUT
```text
$ARGUMENTS
```

## MISSION STEPS

1.  **DETECT & VALIDATE**
    - Load `start.md`, final draft, and PDF.
    - Check requirements: Word count, sections, formatting.

2.  **EXECUTE: Quality Assessment**
    - **Content**: Argument clarity, evidence depth.
    - **Language**: Academic voice, grammar.
    - **Integrity**: Plagiarism checks, proper citations.

3.  **EXECUTE: Report**
    - Create `generated_work/reviews/YYYYMMDD_review-report.md`.
    - Rate: Strengths, Improvements, Submission Readiness.

4.  **EXECUTE: Checklist**
    - Generate `checklists/latexkit.check.md`.
    - Silent validation.

5.  **REPORT & COMMIT**
    - Summary of readiness.
    - **Auto-Commit** (if requested): `smart-commit.sh check`.

## RULES
- **Honesty**: Be constructive but strict.
- **Priorities**: Flag critical issues first.
