#!/usr/bin/env bash
# =================================================================
# compile-latex.sh
# Compiles LaTeX project with proper multi-pass handling
# =================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =================================================================
# Configuration
# =================================================================

DEFAULT_MAIN_FILE="main.tex"
DEFAULT_OUTPUT_DIR="."

# =================================================================
# Functions
# =================================================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Compiles LaTeX project with automatic multi-pass handling for bibliography.

Options:
    -f, --file FILE     Main .tex file (default: main.tex)
    -d, --dir DIR       LaTeX source directory (default: ./latex_source)
    -c, --clean         Clean auxiliary files after compilation
    -h, --help          Show this help message

Examples:
    $0                              # Compile default main.tex
    $0 --file custom.tex            # Compile custom file
    $0 --dir documents/<project-slug>/latex_source  # Specify directory
    $0 --clean                      # Compile and clean auxiliary files
EOF
    exit 1
}

clean_aux_files() {
    local dir="$1"
    
    log "Cleaning auxiliary files..."
    cd "$dir"
    
    # Remove common auxiliary files
    rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.bcf *.run.xml
    rm -f *.fls *.fdb_latexmk *.synctex.gz
    
    # Clean in sections directory
    if [ -d "sections" ]; then
        rm -f sections/*.aux
    fi
    
    success "Auxiliary files cleaned"
}

compile_latex() {
    local main_file="$1"
    local source_dir="$2"
    local clean_after="$3"
    
    # Determine output directory (build dir is always one level up from latex_source)
    local build_dir
    if [[ "$source_dir" == */latex_source ]]; then
        build_dir="$(dirname "$source_dir")/build"
    else
        # Fallback if not in standard structure
        build_dir="$(dirname "$source_dir")/build"
    fi
    
    # Create build directory
    mkdir -p "$build_dir"
    
    # Change to source directory
    cd "$source_dir"
    
    # Validate main file exists
    validate_file "$main_file" "Main LaTeX file" || exit 1
    
    local base_name="${main_file%.tex}"
    
    log "Starting LaTeX compilation..."
    log "Main file: ${main_file}"
    log "Source directory: $(pwd)"
    log "Output directory: ${build_dir}"
    echo ""
    
    # Pass 1: Initial LaTeX compilation with explicit output directory
    log "Pass 1/4: Initial LaTeX compilation..."
    if ! pdflatex -output-directory="$build_dir" -interaction=nonstopmode -halt-on-error "$main_file" > /dev/null 2>&1; then
        error "First LaTeX pass failed!"
        log "Showing last 20 lines of log:"
        echo ""
        tail -n 20 "${build_dir}/${base_name}.log" 2>/dev/null || echo "Log file not found"
        exit 1
    fi
    success "Pass 1 complete"
    echo ""
    
    # Pass 2: BibTeX (if bibliography exists)
    if [ -f "bibliography.bib" ] || grep -q "\\\\bibliography" "$main_file" || grep -q "\\\\addbibresource" "$main_file"; then
        log "Pass 2/4: Processing bibliography with Biber..."
        # Biber needs to run in build directory
        if ! (cd "$build_dir" && biber "$base_name") > /dev/null 2>&1; then
            warn "Biber encountered issues (check .blg file for details)"
        else
            success "Pass 2 complete"
        fi
        echo ""
        
        # Pass 3: Resolve citations
        log "Pass 3/4: Resolving citations..."
        if ! pdflatex -output-directory="$build_dir" -interaction=nonstopmode -halt-on-error "$main_file" > /dev/null 2>&1; then
            error "Third LaTeX pass failed!"
            tail -n 20 "${build_dir}/${base_name}.log" 2>/dev/null || echo "Log file not found"
            exit 1
        fi
        success "Pass 3 complete"
        echo ""
        
        # Pass 4: Final pass for references
        log "Pass 4/4: Final compilation pass..."
        if ! pdflatex -output-directory="$build_dir" -interaction=nonstopmode -halt-on-error "$main_file" > /dev/null 2>&1; then
            error "Final LaTeX pass failed!"
            tail -n 20 "${build_dir}/${base_name}.log" 2>/dev/null || echo "Log file not found"
            exit 1
        fi
        success "Pass 4 complete"
    else
        log "No bibliography detected, skipping BibTeX passes"
    fi
    
    echo ""
    
    # Check if PDF was created in the correct location
    if [ -f "${build_dir}/${base_name}.pdf" ]; then
        local pdf_size=$(du -h "${build_dir}/${base_name}.pdf" | cut -f1)
        local pdf_pages=$(pdfinfo "${build_dir}/${base_name}.pdf" 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "unknown")
        
        success "PDF generated successfully!"
        log "  Location: ${build_dir}/${base_name}.pdf"
        log "  Size: ${pdf_size}"
        log "  Pages: ${pdf_pages}"
        
        # Warn if PDF exists in wrong locations
        if [ -f "${source_dir}/${base_name}.pdf" ]; then
            warn "PDF also found in source directory (this should not happen)"
            log "  Wrong location: ${source_dir}/${base_name}.pdf"
        fi
        
        # Check for warnings
        if grep -q "LaTeX Warning" "${build_dir}/${base_name}.log" 2>/dev/null; then
            warn "Compilation warnings detected:"
            grep "LaTeX Warning" "${build_dir}/${base_name}.log" | head -n 5
            if [ $(grep -c "LaTeX Warning" "${build_dir}/${base_name}.log" 2>/dev/null || echo 0) -gt 5 ]; then
                log "  ... and $(($(grep -c "LaTeX Warning" "${build_dir}/${base_name}.log") - 5)) more warnings"
            fi
            log "  See ${build_dir}/${base_name}.log for full details"
        fi
    else
        error "PDF was not generated in expected location!"
        log "Expected: ${build_dir}/${base_name}.pdf"
        
        # Check if PDF was created in wrong location
        if [ -f "${source_dir}/${base_name}.pdf" ]; then
            error "PDF found in SOURCE directory instead of BUILD directory!"
            log "Wrong location: ${source_dir}/${base_name}.pdf"
            log "This indicates compilation was run incorrectly."
            log "Always use -output-directory flag or run from correct location."
        fi
        
        log "Check ${build_dir}/${base_name}.log for errors"
        exit 1
    fi
    
    # Clean auxiliary files if requested (only in build dir)
    if [ "$clean_after" = true ]; then
        echo ""
        clean_aux_files "$build_dir"
    fi
}

# =================================================================
# Main
# =================================================================

main() {
    local main_file="$DEFAULT_MAIN_FILE"
    local source_dir=""
    local clean_after=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                main_file="$2"
                shift 2
                ;;
            -d|--dir)
                source_dir="$2"
                shift 2
                ;;
            -c|--clean)
                clean_after=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Determine source directory
    if [ -z "$source_dir" ]; then
        # Try to find latex_source directory
        local repo_root=$(get_repo_root)
        if [ -d "${repo_root}/latex_source" ]; then
            source_dir="${repo_root}/latex_source"
        elif [ -d "./latex_source" ]; then
            source_dir="./latex_source"
        else
            source_dir="."
        fi
    fi
    
    # Validating source directory
    validate_dir "$source_dir" "LaTeX source directory" || exit 1
    
    # Compile
    compile_latex "$main_file" "$source_dir" "$clean_after"
    
    # Cleanup generated file if it wasn't there before (optional, maybe keep it for debugging)
    # rm -f "${source_dir}/university-info.tex"
}

main "$@"
