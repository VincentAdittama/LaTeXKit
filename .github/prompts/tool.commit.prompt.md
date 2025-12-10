# MISSION: TOOL COMMIT

## VISION
Manually generate an intelligent git commit with a descriptive message and correct workflow label.

## CONTEXT
- **Note**: Most workflow commands (`latexkit plan`, etc.) auto-commit. Use this for manual/custom commits.
- **Input**: Staged/Unstaged changes.
- **Output**: A specific, labeled git commit.

## INPUT
```text
$ARGUMENTS
```

## MISSION STEPS

1.  **PREPARE**
    - Run `smart-commit.sh [STAGE]` (e.g., `refactor`, `fix`).
    - This auto-stages changes and outputs metadata.

2.  **ANALYZE**
    - Read the changes file structure (`/tmp/latexkit_commit_changes_*.txt`).
    - Understand *what* changed (not just file names).

3.  **EXECUTE: Commit**
    - Construct Message: `LABEL: Title` + Body.
    - Run `git commit -m "..."`.

## RULES
- **Descriptive**: "Fix typo" -> "FIX-05: Correct typography in Introduction".
- **Labels**: Use the label provided by the script (e.g., `REFACTOR-02`).