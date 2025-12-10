# MISSION: TOOL CLARIFY

## VISION
Resolve ambiguities in the project by interactively asking targeted questions and updating documents.

## CONTEXT
- **Goal**: Remove `[NEEDS CLARIFICATION]` markers.
- **Scope**: Scans `start.md`, checklists, and drafts.

## INPUT
```text
$ARGUMENTS
```

## MISSION STEPS

1.  **DETECT MARKERS**
    - Scan project for `[NEEDS CLARIFICATION]` or `[NEED CLARIFICATION]`.
    - Scan `start.md` for missing critical info.

2.  **INTERACTIVE LOOP (Max 5 Questions)**
    - Identify highest priority ambiguity.
    - **Ask User**: Present context + options/recommendations.
    - **Wait for Answer**.
    - **Integrate**: Update the file *immediately*, removing the marker.
    - Repeat until done or max 5.

3.  **REPORT & COMMIT**
    - Summary: Clarifications resolved/remaining.
    - **Auto-Commit** (if requested): `smart-commit.sh clarify`.

## RULES
- **Incremental**: Update files after *each* answer.
- **Context**: Always show the user *where* the question comes from.
- **Limit**: Don't ask endless questions. Max 5 per session.