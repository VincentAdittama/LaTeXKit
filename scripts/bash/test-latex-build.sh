#!/usr/bin/env bash
# =================================================================
# test-latex-build.sh
# Quick test compilation for LLMs to verify LaTeX correctness
# Ensures output goes to correct build/ directory
# =================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =================================================================
# Configuration
# =================================================================

usage() {
    cat << EOF
Usage: $0 [DOCUMENT_DIR]

Quick test compilation to verify LaTeX correctness.
Ensures output goes to build/ directory (not latex_source/).

Arguments:
    DOCUMENT_DIR    Path to document directory (optional, auto-detects from active project)

Examples:
    $0                                    # Auto-detect from active project
    $0 documents/001-my-project           # Explicit document path

Output:
    - Compiles to DOCUMENT_DIR/build/main.pdf
    - Shows compilation status
    - Reports any errors

⚠️ Note: This is for quick testing. Use /latexkit.build for full compilation.
EOF
    exit 1
}

# =================================================================
# Main
# =================================================================

main() {
    local document_dir="$1"
    
    # Auto-detect document directory if not provided
    if [[ -z "$document_dir" ]]; then
        eval "$(get_document_paths)"
        document_dir="$DOCUMENT_DIR"
    fi
    
    # Convert to absolute path if relative
    if [[ ! "$document_dir" = /* ]]; then
        document_dir="$(cd "$document_dir" 2>/dev/null && pwd)" || {
            error "Cannot resolve document directory: $1"
            exit 1
        }
    fi
    
    # Validate paths
    if [[ ! -d "$document_dir" ]]; then
        error "Document directory not found: $document_dir"
        exit 1
    fi
    
    local latex_source="$document_dir/latex_source"
    local build_dir="$document_dir/build"
    
    if [[ ! -d "$latex_source" ]]; then
        error "LaTeX source directory not found: $latex_source"
        exit 1
    fi
    
    if [[ ! -f "$latex_source/main.tex" ]]; then
        error "main.tex not found in $latex_source"
        exit 1
    fi
    
    log "Quick LaTeX compilation test"
    log "Document: $document_dir"
    log "Source: $latex_source"
    log "Output: $build_dir"
    echo ""
    
    # Create build directory
    mkdir -p "$build_dir"
    
    # Change to latex_source
    cd "$latex_source"
    
    # Single pass compilation with explicit output directory
    log "Running test compilation..."
    
    # Run compilation (ignore exit code as lualatex returns non-zero for warnings)
    lualatex -output-directory="$build_dir" -interaction=nonstopmode main.tex > /dev/null 2>&1 || true
    
    # Check PDF location (success is determined by PDF existence, not exit code)
    if [[ -f "$build_dir/main.pdf" ]]; then
        success "✓ Compilation successful!"
        log "✓ PDF correctly placed in: $build_dir/main.pdf"
        
        # Warn if PDF in wrong location
        if [[ -f "$latex_source/main.pdf" ]]; then
            error "✗ WARNING: PDF also found in latex_source/ (wrong location)"
            error "  This should not happen with correct build method"
            return 1
        fi
        
        # Check for errors in log
        if [[ -f "$build_dir/main.log" ]] && grep -q "^!" "$build_dir/main.log"; then
            warn "Compilation completed with errors (but PDF generated)"
            log "Check $build_dir/main.log for details"
        fi
        
        return 0
    else
        error "✗ Compilation failed - PDF not generated"
        error "  Expected: $build_dir/main.pdf"
        
        if [[ -f "$latex_source/main.pdf" ]]; then
            error "  Found PDF in wrong location: $latex_source/main.pdf"
            error "  This indicates incorrect compilation method was used"
        fi
        
        if [[ -f "$build_dir/main.log" ]]; then
            log "Last 30 lines of log:"
            tail -n 30 "$build_dir/main.log"
        fi
        
        return 1
    fi
}

# Parse arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
fi

main "${1:-}"
