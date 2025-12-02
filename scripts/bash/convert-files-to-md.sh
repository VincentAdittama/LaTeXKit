#!/usr/bin/env bash
# LatexKit: Unified File to Markdown Converter
# Converts files to markdown in assignment_info and zotero_export directories only
# Usage: convert-files-to-md.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Counters
CONVERTED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     LatexKit: File to Markdown Converter       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check dependencies
check_dependencies() {
    local missing_deps=()
    local can_auto_install=false
    
    # Check if Homebrew is available for auto-install
    if command -v brew &> /dev/null; then
        can_auto_install=true
    fi
    
    if ! command -v pandoc &> /dev/null; then
        missing_deps+=("pandoc")
    fi
    
    if ! command -v uvx &> /dev/null; then
        missing_deps+=("uv")
    fi
    
    if ! command -v tesseract &> /dev/null; then
        missing_deps+=("tesseract")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - $dep"
        done
        echo ""
        
        if [ "$can_auto_install" = true ]; then
            echo -e "${YELLOW}Would you like to install missing dependencies automatically? (y/n)${NC}"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Installing dependencies via Homebrew...${NC}"
                for dep in "${missing_deps[@]}"; do
                    echo -e "  Installing $dep..."
                    if brew install "$dep" 2>/dev/null; then
                        echo -e "  ${GREEN}✓ Installed $dep${NC}"
                    else
                        echo -e "  ${RED}✗ Failed to install $dep${NC}"
                    fi
                done
                echo ""
                echo -e "${GREEN}✓ Installation complete. Please run the script again.${NC}"
                exit 0
            else
                echo -e "${YELLOW}Manual installation:${NC}"
                echo "  brew install ${missing_deps[*]}"
                echo ""
                exit 1
            fi
        else
            echo -e "${YELLOW}Install Homebrew first:${NC}"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo ""
            echo -e "${YELLOW}Then install dependencies:${NC}"
            echo "  brew install ${missing_deps[*]}"
            echo ""
            exit 1
        fi
    fi
}

# Prompt for scope selection
select_scope() {
    echo -e "${CYAN}Select conversion scope:${NC}"
    echo -e "  ${YELLOW}1)${NC} Current project (from .active_project)"
    echo -e "  ${YELLOW}2)${NC} All projects"
    echo -e "  ${YELLOW}3)${NC} Custom path"
    echo ""
    
    read -p "Enter choice [1-3]: " choice
    
    case "$choice" in
        1)
            SCOPE="current"
            ;;
        2)
            SCOPE="all"
            ;;
        3)
            SCOPE="custom"
            echo ""
            read -p "Enter custom path (absolute or relative to workspace): " CUSTOM_PATH
            ;;
        *)
            echo -e "${RED}✗ Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Prompt for cleanup option
select_cleanup() {
    echo ""
    echo -e "${CYAN}Delete original files after successful conversion?${NC}"
    echo -e "  ${YELLOW}1)${NC} No - Keep original files (recommended)"
    echo -e "  ${YELLOW}2)${NC} Yes - Delete originals (⚠️  cannot be undone)"
    echo ""
    
    read -p "Enter choice [1-2]: " choice
    
    case "$choice" in
        1)
            CLEANUP_ORIGINALS="false"
            ;;
        2)
            CLEANUP_ORIGINALS="true"
            ;;
        *)
            echo -e "${RED}✗ Invalid choice${NC}"
            exit 1
            ;;
    esac
    echo ""
}

# Source common utilities
source "$SCRIPT_DIR/common.sh"

# Get target directories based on scope
get_target_dirs() {
    local dirs=()
    
    case "$SCOPE" in
        "all")
            # Find all project directories in documents (recursive)
            if [ -d "$WORKSPACE_ROOT/documents" ]; then
                # Use find to locate directories containing start.md
                while IFS= read -r -d '' start_file; do
                    local project_dir=$(dirname "$start_file")
                    dirs+=("$project_dir")
                done < <(find "$WORKSPACE_ROOT/documents" -type f -name "start.md" -print0)
            fi
            ;;
        "current")
            # =================================================================
            # MAIN-ONLY WORKFLOW: Detect project from shared state
            # =================================================================
            local active_project=$(get_active_project)
            
            if [ -z "$active_project" ]; then
                echo -e "${RED}✗ No active project found${NC}" >&2
                echo -e "${YELLOW}Set an active project first:${NC}" >&2
                echo -e "  ${BLUE}./latexkit switch <project-id>${NC}" >&2
                echo -e "  ${BLUE}./latexkit new \"Project Description\"${NC}" >&2
                echo "" >&2
                echo -e "${YELLOW}Available projects:${NC}" >&2
                if declare -f list_projects >/dev/null; then
                    list_projects >&2
                fi
                exit 1
            fi
            
            # Map active project to project directory using shared logic
            local project_dir=""
            if declare -f find_document_dir_by_id >/dev/null; then
                project_dir=$(find_document_dir_by_id "$WORKSPACE_ROOT" "$active_project")
            else
                project_dir="$WORKSPACE_ROOT/documents/$active_project"
            fi
            
            if [ -n "$project_dir" ] && [ -d "$project_dir" ]; then
                dirs+=("$project_dir")
                echo -e "${GREEN}✓ Using active project: ${YELLOW}$active_project${NC}" >&2
                echo "" >&2
            else
                echo -e "${RED}✗ No project directory found: $active_project${NC}" >&2
                echo -e "${YELLOW}Expected path: documents/.../$active_project${NC}" >&2
                exit 1
            fi
            ;;
        "custom")
            # Resolve custom path
            local resolved_path
            if [[ "$CUSTOM_PATH" = /* ]]; then
                resolved_path="$CUSTOM_PATH"
            else
                resolved_path="$WORKSPACE_ROOT/$CUSTOM_PATH"
            fi
            
            if [ ! -d "$resolved_path" ]; then
                echo -e "${RED}✗ Path not found: $resolved_path${NC}" >&2
                exit 1
            fi
            
            dirs+=("$resolved_path")
            ;;
    esac
    
    echo "${dirs[@]}"
}

# Convert a single file to markdown
convert_file() {
    local file="$1"
    local ext="${file##*.}"
    local base="${file%.*}"
    local md_file="${base}.md"
    local filename=$(basename "$file")
    
    # Skip if already markdown, bibliography, LaTeX, system files, or .latexmkrc
    if [[ "$ext" == "md" || "$ext" == "bib" || "$ext" == "tex" || "$filename" == ".gitkeep" || "$filename" == ".DS_Store" || "$filename" == ".latexmkrc" ]]; then
        return 0
    fi
    
    # Skip if markdown already exists
    if [ -f "$md_file" ]; then
        echo -e "  ${YELLOW}⊙ Skipped:${NC} $filename (markdown already exists)"
        ((SKIPPED_COUNT++))
        return 0
    fi
    
    echo -e "  ${BLUE}→ Converting:${NC} $filename"
    
    # Handle PDF files specially with enhanced Python converter
    if [[ "$ext" == "pdf" ]]; then
        # Use uvx to run the Python script with dependencies
        local error_output
        error_output=$(uvx --with pdfplumber --with pytesseract --with Pillow python "$SCRIPT_DIR/../python/pdf_to_md.py" "$file" "$md_file" 2>&1)
        if [ $? -eq 0 ] && [ -f "$md_file" ]; then
            echo -e "  ${GREEN}✓ Success:${NC} Created $(basename "$md_file")"
            ((CONVERTED_COUNT++))
            
            # Cleanup original if requested
            if [ "$CLEANUP_ORIGINALS" = "true" ]; then
                rm -f "$file"
                echo -e "    ${YELLOW}⚠ Removed original PDF${NC}"
            fi
            return 0
        else
            echo -e "  ${RED}✗ Failed:${NC} PDF conversion failed"
            # Show error details if available
            if [ -n "$error_output" ]; then
                echo -e "    ${RED}Error details:${NC}"
                echo "$error_output" | head -3 | sed 's/^/    /'
            fi
            ((FAILED_COUNT++))
            return 1
        fi
    else
        # Try direct conversion with pandoc
        if pandoc "$file" -t markdown -o "$md_file" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Success:${NC} Created $(basename "$md_file")"
            ((CONVERTED_COUNT++))
            
            # Cleanup original if requested
            if [ "$CLEANUP_ORIGINALS" = "true" ]; then
                rm -f "$file"
                echo -e "    ${YELLOW}⚠ Removed original file${NC}"
            fi
            return 0
        else
            echo -e "  ${RED}✗ Failed:${NC} Pandoc conversion failed"
            ((FAILED_COUNT++))
            return 1
        fi
    fi
}

# Main conversion process
main() {
    check_dependencies
    
    # Interactive prompts
    select_scope
    select_cleanup
    
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Scope: ${YELLOW}$SCOPE${NC}"
    if [ "$SCOPE" = "custom" ]; then
        echo -e "  Path: ${YELLOW}$CUSTOM_PATH${NC}"
    fi
    echo -e "  Cleanup: ${YELLOW}$CLEANUP_ORIGINALS${NC}"
    echo ""
    
    # Get target directories
    local target_dirs=($(get_target_dirs))
    
    if [ ${#target_dirs[@]} -eq 0 ]; then
        echo -e "${RED}✗ No directories found to process${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Found ${#target_dirs[@]} director(ies) to process${NC}"
    echo ""
    
    # Process each directory
    for target_dir in "${target_dirs[@]}"; do
        local project_name
        if [[ "$target_dir" == *"/documents/"* ]]; then
            project_name=$(echo "$target_dir" | sed -E 's|.*/documents/([^/]+)/.*|\1|')
        else
            project_name=$(basename "$target_dir")
        fi
        
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Processing: ${YELLOW}$project_name${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  Directory: $target_dir"
        echo ""
        
        # Find all convertible files in assignment_info and zotero_export only
        local file_count=0
        
        # Process assignment_info directory
        if [ -d "$target_dir/assignment_info" ]; then
            while IFS= read -r -d '' file; do
                convert_file "$file"
                ((file_count++))
            done < <(find "$target_dir/assignment_info" -type f ! -name ".DS_Store" ! -name ".gitkeep" ! -name ".latexmkrc" -print0 2>/dev/null) || true
        fi
        
        # Process zotero_export directory
        if [ -d "$target_dir/zotero_export" ]; then
            while IFS= read -r -d '' file; do
                convert_file "$file"
                ((file_count++))
            done < <(find "$target_dir/zotero_export" -type f ! -name ".DS_Store" ! -name ".gitkeep" ! -name ".latexmkrc" -print0 2>/dev/null) || true
        fi
        
        if [ $file_count -eq 0 ]; then
            echo -e "  ${YELLOW}⊙ No convertible files found in assignment_info/ or zotero_export/${NC}"
        fi
        echo ""
    done
    
    # Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Conversion Summary                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}✓ Converted:${NC} $CONVERTED_COUNT file(s)"
    echo -e "${YELLOW}⊙ Skipped:${NC}   $SKIPPED_COUNT file(s)"
    echo -e "${RED}✗ Failed:${NC}    $FAILED_COUNT file(s)"
    echo ""
    
    if [ $CONVERTED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓ Conversion complete!${NC}"
        
        if [ "$CLEANUP_ORIGINALS" = "true" ]; then
            echo -e "${YELLOW}⚠ Original files have been removed${NC}"
        fi
    elif [ $FAILED_COUNT -eq 0 ] && [ $SKIPPED_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⊙ All files already converted or skipped${NC}"
    fi
    
    if [ $FAILED_COUNT -gt 0 ]; then
        echo -e "${RED}⚠ Some conversions failed. Check the output above for details.${NC}"
        exit 1
    fi
}

main
