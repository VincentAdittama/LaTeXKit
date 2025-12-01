#!/usr/bin/env bash
# =================================================================
# check-latex-escaping.sh
# Detects broken LaTeX commands caused by backslash escape issues
# Specifically targets the ChatGPT \t → tab character bug
# =================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Get document paths
eval $(get_document_paths)

LATEX_DIR="${DOCUMENT_DIR}/latex_source"
ERRORS_FOUND=0
WARNINGS_FOUND=0

# Parse arguments
JSON_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--json]"
            echo ""
            echo "Checks LaTeX files for broken commands caused by escape sequence issues."
            echo "Specifically detects the ChatGPT bug where \textbf becomes <TAB>extbf."
            echo ""
            echo "Options:"
            echo "  --json    Output results in JSON format"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Validate LaTeX directory exists
if [ ! -d "$LATEX_DIR" ]; then
    error "LaTeX source directory not found: $LATEX_DIR"
    exit 1
fi

# Array to store issues (bash 3.2 compatible)
ISSUE_FILES=()
ISSUE_LINES=()
ISSUE_TYPES=()
ISSUE_CONTEXTS=()

# Function to check for tab characters in LaTeX commands
check_tab_characters() {
    local file="$1"
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Check for tab character followed by common LaTeX command patterns
        if echo "$line" | grep -q $'\t''ext\|'$'\t''cite\|'$'\t''section\|'$'\t''subsection\|'$'\t''begin\|'$'\t''end'; then
            ISSUE_FILES+=("$file")
            ISSUE_LINES+=("$line_num")
            ISSUE_TYPES+=("TAB_CHARACTER")
            ISSUE_CONTEXTS+=("$line")
            ((ERRORS_FOUND++))
        fi
    done < "$file"
}

# Function to check for LaTeX commands without backslash
check_missing_backslash() {
    local file="$1"
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Skip comments
        if echo "$line" | grep -q '^\s*%'; then
            continue
        fi
        
        # Check for common LaTeX commands without leading backslash
        # Pattern: word boundary, then command, then { (but not preceded by \)
        if echo "$line" | grep -qE '(^|[^\\])\<(textbf|textit|texttt|emph|cite|subsubsection|subsection|section|begin|end)\{'; then
            ISSUE_FILES+=("$file")
            ISSUE_LINES+=("$line_num")
            ISSUE_TYPES+=("MISSING_BACKSLASH")
            ISSUE_CONTEXTS+=("$line")
            ((WARNINGS_FOUND++))
        fi
    done < "$file"
}

# Function to check for suspicious spacing (tab characters)
check_suspicious_tabs() {
    local file="$1"
    local line_num=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Check for tab characters anywhere in non-verbatim content
        # (excluding lines that are clearly code listings or verbatim)
        if echo "$line" | grep -qv '\\begin{lstlisting}\|\\begin{verbatim}' && echo "$line" | grep -q $'\t'; then
            ISSUE_FILES+=("$file")
            ISSUE_LINES+=("$line_num")
            ISSUE_TYPES+=("SUSPICIOUS_TAB")
            ISSUE_CONTEXTS+=("$line")
            ((WARNINGS_FOUND++))
        fi
    done < "$file"
}

# Main validation
if [ "$JSON_MODE" = false ]; then
    log "Checking LaTeX files for escaping issues..."
    echo ""
fi

# Find all .tex files
CHECKED_FILES=0
while IFS= read -r -d '' tex_file; do
    ((CHECKED_FILES++))
    
    if [ "$JSON_MODE" = false ]; then
        log "Checking: $(basename "$tex_file")"
    fi
    
    check_tab_characters "$tex_file"
    check_missing_backslash "$tex_file"
    check_suspicious_tabs "$tex_file"
    
done < <(find "$LATEX_DIR" -name "*.tex" -type f -print0)

# Output results
if [ "$JSON_MODE" = true ]; then
    echo "{"
    echo "  \"document_dir\": \"$DOCUMENT_DIR\","
    echo "  \"latex_dir\": \"$LATEX_DIR\","
    echo "  \"files_checked\": $CHECKED_FILES,"
    echo "  \"errors\": $ERRORS_FOUND,"
    echo "  \"warnings\": $WARNINGS_FOUND,"
    echo "  \"issues\": ["
    
    first=true
    for ((i=0; i<${#ISSUE_FILES[@]}; i++)); do
        if [ "$first" = false ]; then
            echo ","
        fi
        first=false
        
        echo "    {"
        echo "      \"file\": \"${ISSUE_FILES[$i]}\","
        echo "      \"line\": ${ISSUE_LINES[$i]},"
        echo "      \"type\": \"${ISSUE_TYPES[$i]}\","
        echo "      \"context\": $(echo "${ISSUE_CONTEXTS[$i]}" | jq -Rs .)"
        echo -n "    }"
    done
    
    echo ""
    echo "  ]"
    echo "}"
else
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "LaTeX Escaping Check Results"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    log "Files checked: $CHECKED_FILES"
    
    if [ $ERRORS_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
        success "✓ No escaping issues found!"
        echo ""
        log "All LaTeX commands appear properly formatted."
    else
        if [ $ERRORS_FOUND -gt 0 ]; then
            error "✗ Critical errors found: $ERRORS_FOUND"
            echo ""
            
            for ((i=0; i<${#ISSUE_FILES[@]}; i++)); do
                if [ "${ISSUE_TYPES[$i]}" = "TAB_CHARACTER" ]; then
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    error "Tab character in LaTeX command"
                    echo "  File: ${ISSUE_FILES[$i]}"
                    echo "  Line: ${ISSUE_LINES[$i]}"
                    echo "  Context: ${ISSUE_CONTEXTS[$i]}"
                    echo ""
                    warn "This is the ChatGPT \\t → <TAB> bug!"
                    echo "  Expected: \\textbf{text}"
                    echo "  Got:      <TAB>extbf{text}"
                    echo ""
                    log "Fix: Replace tab character with backslash (\\)"
                    echo ""
                fi
            done
        fi
        
        if [ $WARNINGS_FOUND -gt 0 ]; then
            warn "⚠ Warnings found: $WARNINGS_FOUND"
            echo ""
            
            for ((i=0; i<${#ISSUE_FILES[@]}; i++)); do
                if [ "${ISSUE_TYPES[$i]}" != "TAB_CHARACTER" ]; then
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    warn "${ISSUE_TYPES[$i]}"
                    echo "  File: ${ISSUE_FILES[$i]}"
                    echo "  Line: ${ISSUE_LINES[$i]}"
                    echo "  Context: ${ISSUE_CONTEXTS[$i]}"
                    echo ""
                fi
            done
        fi
        
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        error "LaTeX escaping issues detected!"
        echo ""
        log "Common fixes:"
        echo "  1. Replace <TAB>extbf with \\textbf"
        echo "  2. Replace <TAB>extit with \\textit"
        echo "  3. Replace <TAB>exttt with \\texttt"
        echo "  4. Replace <TAB>cite with \\cite"
        echo "  5. Add backslash before LaTeX commands"
        echo ""
        log "For automated fix suggestions, see:"
        echo "  .latexkit/templates/latex-conversion-guide.md"
        echo ""
        
        exit 1
    fi
fi

exit 0
