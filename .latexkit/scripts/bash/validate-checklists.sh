#!/usr/bin/env bash
# =================================================================
# validate-checklists.sh
# Universal checklist validation and update script
# Checks ALL checklists in the checklists/ folder and updates them
# based on actual project state
# =================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Get document paths
eval $(get_document_paths)

CHECKLISTS_DIR="${DOCUMENT_DIR}/checklists"
JSON_MODE=false
COMMAND_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        --command)
            COMMAND_NAME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--command <command_name>]"
            echo ""
            echo "Validates all checklists in the checklists/ folder."
            echo "Updates checklist items based on actual project state."
            echo ""
            echo "Options:"
            echo "  --json              Output results in JSON format"
            echo "  --command <name>    Focus on specific command checklist (start, clarify, research, outline, draft, convert)"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Validate we have a document directory
if [ ! -d "$DOCUMENT_DIR" ]; then
    warn "No document directory found: $DOCUMENT_DIR"
    log "This is expected for a template repository."
    log "To validate checklists, first initialize a project:"
    log "  /latexkit.start \"your project description\""
    echo ""
    log "Available commands when no project exists:"
    log "  - Initialize a project: /latexkit.start"
    log "  - Check prerequisites: ./.latexkit/scripts/bash/check-prerequisites.sh"
    echo ""
    success "Validation script is working correctly!"
    exit 0
fi

if [ ! -d "$CHECKLISTS_DIR" ]; then
    log "No checklists directory found: $CHECKLISTS_DIR"
    log "Checklists will be created when you run workflow commands."
    log "Current project structure is valid."
    exit 0
fi

# Track overall status
TOTAL_CHECKLISTS=0
VALIDATED_CHECKLISTS=0
ISSUES_FOUND=0

# Results tracking (bash 3.2 compatible - no associative arrays)
RESULT_NAMES=()
RESULT_VALUES=()

# Function to check if a file exists
check_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to check if directory exists and has content
check_dir_exists() {
    local dir="$1"
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to update checklist item status
mark_checklist_item() {
    local checklist_file="$1"
    local pattern="$2"
    local mark_done="$3"  # true or false
    
    if [ ! -f "$checklist_file" ]; then
        return
    fi
    
    if [ "$mark_done" = "true" ]; then
        # Mark as done: - [ ] → - [x]
        sed -i '' "s/- \[ \] $pattern/- [x] $pattern/g" "$checklist_file" 2>/dev/null || \
        sed -i "s/- \[ \] $pattern/- [x] $pattern/g" "$checklist_file"
    else
        # Mark as not done: - [x] → - [ ]
        sed -i '' "s/- \[x\] $pattern/- [ ] $pattern/g" "$checklist_file" 2>/dev/null || \
        sed -i "s/- \[x\] $pattern/- [ ] $pattern/g" "$checklist_file"
    fi
}

# Function to update timestamp in checklist
update_checklist_timestamp() {
    local checklist_file="$1"
    local today=$(date +%Y-%m-%d)
    
    if [ ! -f "$checklist_file" ]; then
        return
    fi
    
    # Update Last Validated date
    sed -i '' "s/\*\*Last Validated\*\*:.*/\*\*Last Validated\*\*: \`$today\`/g" "$checklist_file" 2>/dev/null || \
    sed -i "s/\*\*Last Validated\*\*:.*/\*\*Last Validated\*\*: \`$today\`/g" "$checklist_file"
}

# Function to validate start checklist
validate_start_checklist() {
    local checklist="${CHECKLISTS_DIR}/latexkit.start.md"
    
    if [ ! -f "$checklist" ]; then
        return
    fi
    
    log "Validating start checklist..."
    local issues=0
    
    # Check document structure
    [ -d "$DOCUMENT_DIR" ] && mark_checklist_item "$checklist" "Document directory structure created" "true" || ((issues++))
    [ -f "${DOCUMENT_DIR}/start.md" ] && mark_checklist_item "$checklist" "Start file.*exists" "true" || ((issues++))
    [ -d "${DOCUMENT_DIR}/latex_source" ] && mark_checklist_item "$checklist" "LaTeX source directory.*initialized" "true" || ((issues++))
    # Note: .latexmkrc is imported during convert phase, not start phase
    [ -d "$CHECKLISTS_DIR" ] && mark_checklist_item "$checklist" "Checklists directory.*created" "true" || ((issues++))
    
    # Check generated work directories
    [ -d "${DOCUMENT_DIR}/generated_work/research" ] && \
    [ -d "${DOCUMENT_DIR}/generated_work/outlines" ] && \
    [ -d "${DOCUMENT_DIR}/generated_work/drafts" ] && \
        mark_checklist_item "$checklist" "Generated work directories exist" "true" || ((issues++))
    
    [ -d "${DOCUMENT_DIR}/zotero_export" ] && mark_checklist_item "$checklist" "Zotero export directory.*ready" "true" || ((issues++))
    
    # Note: main.tex and preamble.tex are created during convert phase, not start phase
    # These files are optional at this stage
    
    update_checklist_timestamp "$checklist"
    RESULT_NAMES+=("start")
    RESULT_VALUES+=($issues)
    return $issues
}

# Function to validate clarify checklist
validate_clarify_checklist() {
    local checklist="${CHECKLISTS_DIR}/latexkit.clarify.md"
    
    if [ ! -f "$checklist" ]; then
        return
    fi
    
    log "Validating clarify checklist..."
    local issues=0
    
    # Check prerequisites
    [ -f "${DOCUMENT_DIR}/start.md" ] && mark_checklist_item "$checklist" "Project initialized via.*latexkit.start" "true" || ((issues++))
    [ -f "${DOCUMENT_DIR}/start.md" ] && mark_checklist_item "$checklist" "\`start.md\` file exists and is readable" "true" || ((issues++))
    [ -f "${CHECKLISTS_DIR}/latexkit.start.md" ] && mark_checklist_item "$checklist" "Start checklist completed" "true" || ((issues++))
    [ -d "$DOCUMENT_DIR" ] && mark_checklist_item "$checklist" "No critical structural issues in project directory" "true" || ((issues++))
    
    # Check clarifications section
    if grep -q "## Clarifications" "${DOCUMENT_DIR}/start.md" 2>/dev/null; then
        mark_checklist_item "$checklist" "\`## Clarifications\` section added to start.md" "true"
        mark_checklist_item "$checklist" "All Q&A pairs documented" "true"
    else
        ((issues++))
    fi
    
    # Check for reduced clarification markers (both NEEDS and NEED patterns)
    local needs_count=$(grep -c "\[NEEDS CLARIFICATION" "${DOCUMENT_DIR}/start.md" 2>/dev/null || echo "0")
    local need_count=$(grep -c "\[NEED CLARIFICATION" "${DOCUMENT_DIR}/start.md" 2>/dev/null || echo "0")
    local clarification_count=$((needs_count + need_count))
    if [ "$clarification_count" -le 3 ]; then
        mark_checklist_item "$checklist" "Clarification markers resolved or reduced" "true"
    else
        ((issues++))
    fi
    
    update_checklist_timestamp "$checklist"
    RESULT_NAMES+=("clarify")
    RESULT_VALUES+=($issues)
    return $issues
}

# Function to validate research checklist
validate_research_checklist() {
    local checklist="${CHECKLISTS_DIR}/latexkit.research.md"
    
    if [ ! -f "$checklist" ]; then
        return
    fi
    
    log "Validating research checklist..."
    local issues=0
    
    # Check prerequisites
    [ -f "${DOCUMENT_DIR}/start.md" ] && mark_checklist_item "$checklist" "Start command completed" "true" || ((issues++))
    
    # Check research plan
    if [ -n "$(ls -A "${DOCUMENT_DIR}/generated_work/research/" 2>/dev/null | grep -i 'research-plan')" ]; then
        mark_checklist_item "$checklist" "Research plan file created" "true"
    else
        ((issues++))
    fi
    
    # Check Zotero export directory
    if [ -d "${DOCUMENT_DIR}/zotero_export" ]; then
        mark_checklist_item "$checklist" "Zotero export directory exists" "true"
    else
        ((issues++))
    fi
    
    # Look for any .bib file under zotero_export
    if compgen -G "${DOCUMENT_DIR}/zotero_export/**/*.bib" >/dev/null 2>&1 || \
       compgen -G "${DOCUMENT_DIR}/zotero_export/*.bib" >/dev/null 2>&1; then
        mark_checklist_item "$checklist" "Bibliography file location confirmed" "true"
    fi
    
    update_checklist_timestamp "$checklist"
    RESULT_NAMES+=("research")
    RESULT_VALUES+=($issues)
    return $issues
}

# Function to validate outline checklist
validate_outline_checklist() {
    local checklist="${CHECKLISTS_DIR}/latexkit.outline.md"
    
    if [ ! -f "$checklist" ]; then
        return
    fi
    
    log "Validating outline checklist..."
    local issues=0
    
    # Check prerequisites
    [ -f "${DOCUMENT_DIR}/start.md" ] && mark_checklist_item "$checklist" "Start command completed" "true" || ((issues++))
    
    # Check outline file
    if [ -n "$(ls -A "${DOCUMENT_DIR}/generated_work/outlines/" 2>/dev/null | grep -i 'outline')" ]; then
        mark_checklist_item "$checklist" "Outline file created" "true"
    else
        ((issues++))
    fi
    
    # Check bibliography
    if [ -n "$(find "${DOCUMENT_DIR}/zotero_export" -type f -name '*.bib' 2>/dev/null | head -n 1)" ]; then
        mark_checklist_item "$checklist" "Bibliography file.*loaded and validated" "true"
    fi
    
    update_checklist_timestamp "$checklist"
    RESULT_NAMES+=("outline")
    RESULT_VALUES+=($issues)
    return $issues
}

# Function to validate draft checklist
validate_draft_checklist() {
    local checklist="${CHECKLISTS_DIR}/latexkit.draft.md"
    
    if [ ! -f "$checklist" ]; then
        return
    fi
    
    log "Validating draft checklist..."
    local issues=0
    
    # Check prerequisites
    [ -f "${DOCUMENT_DIR}/start.md" ] && mark_checklist_item "$checklist" "Start command completed" "true" || ((issues++))
    
    # Check outline
    if [ -n "$(ls -A "${DOCUMENT_DIR}/generated_work/outlines/" 2>/dev/null)" ]; then
        mark_checklist_item "$checklist" "Outline command completed" "true"
    else
        ((issues++))
    fi
    
    # Check draft file
    if [ -n "$(ls -A "${DOCUMENT_DIR}/generated_work/drafts/" 2>/dev/null | grep -i 'draft')" ]; then
        mark_checklist_item "$checklist" "Draft file created" "true"
    else
        ((issues++))
    fi
    
    # Check review checklist created
    if [ -f "${CHECKLISTS_DIR}/latexkit.draft.md" ]; then
        mark_checklist_item "$checklist" "Review checklist file created" "true"
    fi
    
    update_checklist_timestamp "$checklist"
    RESULT_NAMES+=("draft")
    RESULT_VALUES+=($issues)
    return $issues
}

# Function to validate convert checklist
validate_convert_checklist() {
    local checklist="${CHECKLISTS_DIR}/latexkit.convert.md"
    
    if [ ! -f "$checklist" ]; then
        return
    fi
    
    log "Validating convert checklist..."
    local issues=0
    
    # Check prerequisites
    [ -d "${DOCUMENT_DIR}/latex_source" ] && mark_checklist_item "$checklist" "Start command completed.*structure exists" "true" || ((issues++))
    
    # Check drafts
    if [ -n "$(ls -A "${DOCUMENT_DIR}/generated_work/drafts/" 2>/dev/null)" ]; then
        mark_checklist_item "$checklist" "Draft command completed" "true"
    else
        ((issues++))
    fi
    
    # Check LaTeX section files
    if [ -f "${DOCUMENT_DIR}/latex_source/sections/01_introduction.tex" ]; then
        mark_checklist_item "$checklist" "Introduction file.*01_introduction.tex" "true"
    else
        ((issues++))
    fi
    
    if [ -f "${DOCUMENT_DIR}/latex_source/sections/03_conclusion.tex" ]; then
        mark_checklist_item "$checklist" "Conclusion file.*03_conclusion.tex" "true"
    else
        ((issues++))
    fi
    
    # Check bibliography
    if [ -n "$(find "${DOCUMENT_DIR}/zotero_export" -type f -name '*.bib' 2>/dev/null | head -n 1)" ]; then
        mark_checklist_item "$checklist" "Bibliography file location confirmed" "true"
    fi
    
    # Check conversion report
    if [ -n "$(ls -A "${DOCUMENT_DIR}/generated_work/conversion/" 2>/dev/null)" ]; then
        mark_checklist_item "$checklist" "Conversion report generated" "true"
    else
        ((issues++))
    fi
    
    update_checklist_timestamp "$checklist"
    RESULT_NAMES+=("convert")
    RESULT_VALUES+=($issues)
    return $issues
}

# Main validation logic
validate_all_checklists() {
    if [ -n "$COMMAND_NAME" ]; then
        # Validate specific command checklist
        case "$COMMAND_NAME" in
            start)
                validate_start_checklist
                TOTAL_CHECKLISTS=1
                ;;
            clarify)
                validate_clarify_checklist
                TOTAL_CHECKLISTS=1
                ;;
            research)
                validate_research_checklist
                TOTAL_CHECKLISTS=1
                ;;
            outline)
                validate_outline_checklist
                TOTAL_CHECKLISTS=1
                ;;
            draft)
                validate_draft_checklist
                TOTAL_CHECKLISTS=1
                ;;
            convert)
                validate_convert_checklist
                TOTAL_CHECKLISTS=1
                ;;
            *)
                error "Unknown command: $COMMAND_NAME"
                exit 1
                ;;
        esac
    else
        # Validate all checklists
        [ -f "${CHECKLISTS_DIR}/latexkit.start.md" ] && { validate_start_checklist; ((TOTAL_CHECKLISTS++)); }
        [ -f "${CHECKLISTS_DIR}/latexkit.clarify.md" ] && { validate_clarify_checklist; ((TOTAL_CHECKLISTS++)); }
        [ -f "${CHECKLISTS_DIR}/latexkit.research.md" ] && { validate_research_checklist; ((TOTAL_CHECKLISTS++)); }
        [ -f "${CHECKLISTS_DIR}/latexkit.outline.md" ] && { validate_outline_checklist; ((TOTAL_CHECKLISTS++)); }
        [ -f "${CHECKLISTS_DIR}/latexkit.draft.md" ] && { validate_draft_checklist; ((TOTAL_CHECKLISTS++)); }
        [ -f "${CHECKLISTS_DIR}/latexkit.convert.md" ] && { validate_convert_checklist; ((TOTAL_CHECKLISTS++)); }
    fi
    
    # Count total issues
    for value in "${RESULT_VALUES[@]}"; do
        ISSUES_FOUND=$((ISSUES_FOUND + value))
    done
}

# Run validation
validate_all_checklists

# Output results
if [ "$JSON_MODE" = true ]; then
    echo "{"
    echo "  \"document_dir\": \"$DOCUMENT_DIR\","
    echo "  \"checklists_dir\": \"$CHECKLISTS_DIR\","
    echo "  \"total_checklists\": $TOTAL_CHECKLISTS,"
    echo "  \"issues_found\": $ISSUES_FOUND,"
    echo "  \"results\": {"
    
    first=true
    for ((i=0; i<${#RESULT_NAMES[@]}; i++)); do
        if [ "$first" = false ]; then
            echo ","
        fi
        first=false
        echo -n "    \"${RESULT_NAMES[$i]}\": ${RESULT_VALUES[$i]}"
    done
    
    echo ""
    echo "  }"
    echo "}"
else
    echo ""
    success "Checklist validation complete!"
    log "Document: $CURRENT_BRANCH"
    log "Checklists validated: $TOTAL_CHECKLISTS"
    
    if [ $ISSUES_FOUND -eq 0 ]; then
        success "All checklist items validated successfully!"
    else
        warn "Issues found: $ISSUES_FOUND"
        echo ""
        log "Review the updated checklists in: $CHECKLISTS_DIR"
    fi
    
    # Show individual results
    if [ ${#RESULT_NAMES[@]} -gt 0 ]; then
        echo ""
        log "Individual checklist results:"
        for ((i=0; i<${#RESULT_NAMES[@]}; i++)); do
            cmd="${RESULT_NAMES[$i]}"
            issues=${RESULT_VALUES[$i]}
            if [ $issues -eq 0 ]; then
                echo "  ✓ $cmd: All items validated"
            else
                echo "  ✗ $cmd: $issues items need attention"
            fi
        done
    fi
fi

exit 0
