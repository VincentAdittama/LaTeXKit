#!/usr/bin/env bash
# cleanup-bibtex.sh
# Cleans up common encoding issues in BibTeX files exported from Zotero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to clean a BibTeX file
cleanup_bibtex_file() {
    local file="$1"
    local backup="${file}.backup"
    local temp="${file}.tmp"
    
    if [[ ! -f "$file" ]]; then
        error "File not found: $file"
        return 1
    fi
    
    log "Cleaning up BibTeX file: $file"
    
    # Create backup
    cp "$file" "$backup"
    log "Backup created: $backup"
    
    # Use perl for better Unicode handling
    # Fix common encoding issues
    perl -C -i -pe '
        # Replace Unicode apostrophe issues
        s/\x{2019}/'"'"'/g;          # Right single quotation mark
        s/\x{2018}/'"'"'/g;          # Left single quotation mark  
        s/\x{201C}/"/g;          # Left double quotation mark
        s/\x{201D}/"/g;          # Right double quotation mark
        s/\x{2013}/-/g;          # En dash
        s/\x{2014}/--/g;         # Em dash
        
        # Fix common character sequences that appear as ???
        s/\?{3,}/'"'"'/g;        # Replace 3+ question marks with apostrophe
    ' "$file" 2>/dev/null || {
        # Fallback if perl fails - just restore backup
        warn "Perl processing failed, trying sed fallback"
        cp "$backup" "$file"
        
        # Simple sed approach (less comprehensive)
        LC_ALL=C sed -i '' 's/\?\?\?/'"'"'/g' "$file" 2>/dev/null || {
            error "Cleanup failed, restoring from backup"
            cp "$backup" "$file"
            return 1
        }
    }
    
    success "BibTeX file cleaned successfully"
    log "Original backed up to: $backup"
    log "If you encounter issues, restore with: mv \"$backup\" \"$file\""
}

# Main script
main() {
    if [[ $# -eq 0 ]]; then
        error "Usage: $0 <bibtex-file>"
        log "Example: $0 'documents/my-project/zotero_export/<your-export>.bib'"
        exit 1
    fi
    
    local bibtex_file="$1"
    cleanup_bibtex_file "$bibtex_file"
}

main "$@"
