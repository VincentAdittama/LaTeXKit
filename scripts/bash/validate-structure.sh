#!/usr/bin/env bash
# =================================================================
# validate-structure.sh
# Validates LaTeXKit project structure
# =================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" 2>/dev/null

# Get document directory
if [[ -n "$1" ]]; then
    DOCUMENT_DIR="$1"
else
    eval "$(get_document_paths)"
fi

# Check if document directory exists
if [[ ! -d "$DOCUMENT_DIR" ]]; then
    warn "No document directory found: $DOCUMENT_DIR"
    log "This is expected for a template repository."
    log "To validate structure, first initialize a project:"
    log "  /latexkit.start \"your project description\""
    echo ""
    success "Validation script is working correctly!"
    exit 0
fi

# Show what we're validating
log "Validating project structure: $DOCUMENT_DIR"
echo ""

# Run validation
if validate_project_structure "$DOCUMENT_DIR"; then
    success "Project structure validation passed!"
    echo ""
    log "All required files and directories are present:"
    echo "  ✓ generated_work/plan.md"

    echo "  ✓ latex_source/"
    echo "  ✓ latex_source/sections/"
    echo "  ✓ latex_source/images/"
    echo "  ✓ build/"
    echo "  ✓ generated_work/"
    echo "  ✓ assignment_info/"
    echo "  ✓ zotero_export/"
    echo ""
    exit 0
else
    echo ""
    error "Project structure validation failed!"
    echo ""
    exit 1
fi
