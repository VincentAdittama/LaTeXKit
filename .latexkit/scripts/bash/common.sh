#!/usr/bin/env bash
# =================================================================
# common.sh
# Common utilities and functions for LaTeXKit scripts
# Enhanced with speckit-style git branching and workflow support
#
# NOTE: Function exports are silenced to prevent verbose output when
# sourcing this file. Use validate-structure.sh for clean validation.
# =================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    # When LATEXKIT_SILENT=true, suppress informational logs
    if [[ "${LATEXKIT_SILENT:-false}" = "true" ]]; then
        return
    fi
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    # Success messages can be suppressed when LATEXKIT_SILENT is true
    if [[ "${LATEXKIT_SILENT:-false}" = "true" ]]; then
        return
    fi
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get repository root, with fallback for non-git repositories
get_repo_root() {
    # First check for LATEXKIT_SUPER_REPO_ROOT (set by wrapper in Private Super Repo)
    if [[ -n "${LATEXKIT_SUPER_REPO_ROOT:-}" ]]; then
        echo "$LATEXKIT_SUPER_REPO_ROOT"
        return
    fi
    
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fall back to script location for non-git repos
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# =================================================================
# MAIN-ONLY WORKFLOW: Project Detection (v2 - Nested & Free Naming)
# =================================================================
# This system uses file-based project detection with support for:
#   - Nested folders (e.g., "Semester 1/Tugas Fisika")
#   - Free naming (no mandatory NNN- prefix)
#   - Project identification via start.md file
#
# Priority:
#   1. Environment variable LATEXKIT_DOCUMENT
#   2. .active_project file in repo root (stores relative path)
#   3. Current working directory detection (if inside a project with start.md)
#   4. Fallback to empty (no active project)
# =================================================================

# Get the active project PATH (relative to documents/)
# Returns: "Semester 1/Tugas Fisika" or "Project A" or ""
get_active_project() {
    local repo_root=$(get_repo_root)
    local docs_dir="$repo_root/documents"
    local active_project_file="$repo_root/.active_project"
    
    # 1. Check environment variable (highest priority)
    if [[ -n "${LATEXKIT_DOCUMENT:-}" ]]; then
        echo "$LATEXKIT_DOCUMENT"
        return
    fi
    
    # 2. Check .active_project file (now stores relative path, may contain spaces)
    if [[ -f "$active_project_file" ]]; then
        local relative_path=$(cat "$active_project_file" | tr -d '\n')
        # Validate directory exists AND has start.md (is a valid project)
        if [[ -n "$relative_path" && -d "$docs_dir/$relative_path" && -f "$docs_dir/$relative_path/start.md" ]]; then
            echo "$relative_path"
            return
        fi
    fi
    
    # 3. Detect from current working directory
    local current_dir=$(pwd)
    if [[ "$current_dir" == "$docs_dir"* ]]; then
        # Remove prefix path to get relative path inside documents/
        local rel="${current_dir#$docs_dir/}"
        
        # Check if current directory has start.md (we're in project root)
        if [[ -f "$current_dir/start.md" ]]; then
            echo "$rel"
            return
        fi
        
        # Check parent (if inside latex_source or other subfolder)
        if [[ -f "$(dirname "$current_dir")/start.md" ]]; then
            echo "$(dirname "$rel")"
            return
        fi
        
        # Check grandparent (if inside latex_source/sections etc)
        local grandparent="$(dirname "$(dirname "$current_dir")")"
        if [[ -f "$grandparent/start.md" ]]; then
            local grandrel="$(dirname "$(dirname "$rel")")"
            echo "$grandrel"
            return
        fi
    fi
    
    # 4. Final fallback: no active project
    echo ""
}

# Set the active project (writes to .active_project file)
# Now accepts relative path like "Semester 1/Project Name"
set_active_project() {
    local project_path="$1"
    local repo_root=$(get_repo_root)
    local active_project_file="$repo_root/.active_project"
    local docs_dir="$repo_root/documents"
    
    if [[ -z "$project_path" ]]; then
        # Clear active project
        rm -f "$active_project_file"
        return 0
    fi
    
    # Validate project exists AND has start.md
    if [[ ! -d "$docs_dir/$project_path" ]]; then
        error "Project directory not found: $project_path"
        return 1
    fi
    
    if [[ ! -f "$docs_dir/$project_path/start.md" ]]; then
        error "Not a valid project (missing start.md): $project_path"
        return 1
    fi
    
    # Write to .active_project (full relative path)
    echo "$project_path" > "$active_project_file"
    success "Active project set to: $project_path"
    return 0
}

# List all projects in documents/ (recursive, detects via start.md)
list_projects() {
    local repo_root=$(get_repo_root)
    local docs_dir="$repo_root/documents"
    local active_project=$(get_active_project)
    
    if [[ ! -d "$docs_dir" ]]; then
        warn "No documents directory found"
        return 0
    fi
    
    # Find all directories containing start.md
    while IFS= read -r start_file; do
        local project_dir=$(dirname "$start_file")
        local relative_path="${project_dir#$docs_dir/}"
        
        if [[ "$relative_path" == "$active_project" ]]; then
            echo "  * $relative_path (active)"
        else
            echo "    $relative_path"
        fi
    done < <(find "$docs_dir" -name "start.md" -not -path "*/.*" 2>/dev/null | sort)
}

# Get current branch/project - DEPRECATED but kept for backward compatibility
# Now delegates to get_active_project for Main-Only workflow
get_current_branch() {
    local active_project=$(get_active_project)
    
    if [[ -n "$active_project" ]]; then
        echo "$active_project"
        return
    fi
    
    # Legacy: check git branch if no active project
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        local branch=$(git rev-parse --abbrev-ref HEAD)
        # If on main/master, return empty to signal no project
        if [[ "$branch" == "main" || "$branch" == "master" ]]; then
            echo ""
            return
        fi
        echo "$branch"
        return
    fi
    
    echo ""  # No active project
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

# Check document branch naming convention - DEPRECATED
# Kept for backward compatibility, now always returns success
check_document_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, skip validation
    if [[ "$has_git_repo" != "true" ]]; then
        return 0
    fi

    # With free naming, we no longer enforce NNN- prefix
    # Just warn if we detect legacy format for info purposes
    return 0
}

# Find document directory by project path (supports nested folders)
# Usage: find_document_dir_by_id "$repo_root" "Semester 1/Project Name"
find_document_dir_by_id() {
    local repo_root="$1"
    local project_path="$2"  # Now expects "Semester/Project" or just "Project"
    local docs_dir="$repo_root/documents"

    # If empty, return empty path
    if [[ -z "$project_path" ]]; then
        echo ""
        return
    fi
    
    # Direct match with relative path
    if [[ -d "$docs_dir/$project_path" ]]; then
        echo "$docs_dir/$project_path"
        return
    fi
    
    # Legacy support: If it's a number (e.g., "001" or "1"), search for NNN- prefix
    if [[ "$project_path" =~ ^[0-9]+$ ]]; then
        local padded=$(printf "%03d" "$((10#$project_path))")
        # Search recursively for directories starting with this number
        local found=$(find "$docs_dir" -type d -name "${padded}-*" 2>/dev/null | head -1)
        if [[ -n "$found" && -f "$found/start.md" ]]; then
            echo "$found"
            return
        fi
    fi
    
    # Legacy support: If it matches NNN-* pattern, search for it
    if [[ "$project_path" =~ ^([0-9]{3})- ]]; then
        local found=$(find "$docs_dir" -type d -name "$project_path" 2>/dev/null | head -1)
        if [[ -n "$found" && -f "$found/start.md" ]]; then
            echo "$found"
            return
        fi
    fi

    echo ""
}

# DEPRECATED: Legacy function for backward compatibility
find_document_dir_by_prefix() {
    find_document_dir_by_id "$@"
}

# Get document paths for current active project (Main-Only Workflow)
# This is the primary function used by all scripts to get project paths
get_document_paths() {
    local repo_root=$(get_repo_root)
    local active_project=$(get_active_project)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    local document_dir=""
    if [[ -n "$active_project" ]]; then
        document_dir=$(find_document_dir_by_id "$repo_root" "$active_project")
    fi

    # For backward compatibility, CURRENT_BRANCH is set to active_project
    # This allows existing prompt files to work without modification
    local current_branch="$active_project"

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
ACTIVE_PROJECT='$active_project'
HAS_GIT='$has_git_repo'
DOCUMENT_DIR='$document_dir'
DOCUMENT_SPEC='$document_dir/start.md'
LATEX_PLAN='$document_dir/plan.md'
TASKS='$document_dir/tasks.md'
CONTENT_OUTLINE='$document_dir/outline.md'
BIBLIOGRAPHY='$document_dir/bibliography.bib'
LATEX_SOURCE='$document_dir/latex_source'
BUILD_DIR='$document_dir/build'
CHECKLISTS_DIR='$document_dir/checklists'
EOF
}

# Validate file exists
validate_file() {
    local file="$1"
    local description="${2:-File}"
    
    if [ ! -f "$file" ]; then
        error "${description} not found: ${file}"
        return 1
    fi
    return 0
}

# Validate directory exists
validate_dir() {
    local dir="$1"
    local description="${2:-Directory}"
    
    if [ ! -d "$dir" ]; then
        error "${description} not found: ${dir}"
        return 1
    fi
    return 0
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log "Created directory: ${dir}"
    fi
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

# Validate required files after latexkit start command
validate_project_structure() {
    local document_dir="$1"
    local missing_files=()
    local missing_dirs=()
    
    # Required files (note: .latexmkrc is imported during convert phase, not start)
    local required_files=(
        "$document_dir/start.md"
    )
    
    # Required directories
    local required_dirs=(
        "$document_dir/checklists"
        "$document_dir/latex_source"
        "$document_dir/latex_source/sections"
        "$document_dir/latex_source/images"
        "$document_dir/build"
        "$document_dir/assignment_info"
        "$document_dir/zotero_export"
        "$document_dir/generated_work/research"
        "$document_dir/generated_work/outlines"
        "$document_dir/generated_work/drafts"
        "$document_dir/generated_work/conversion"
        "$document_dir/generated_work/compilation"
        "$document_dir/generated_work/reviews"
    )
    
    # Check files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    # Check directories
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    # Report results
    if [[ ${#missing_files[@]} -gt 0 ]] || [[ ${#missing_dirs[@]} -gt 0 ]]; then
        error "Project structure validation failed!"
        echo ""
        
        if [[ ${#missing_files[@]} -gt 0 ]]; then
            warn "Missing required files:"
            for file in "${missing_files[@]}"; do
                echo "  - $file"
            done
            echo ""
        fi
        
        if [[ ${#missing_dirs[@]} -gt 0 ]]; then
            warn "Missing required directories:"
            for dir in "${missing_dirs[@]}"; do
                echo "  - $dir"
            done
            echo ""
        fi
        
        error "Some files/directories generated by /latexkit.start are missing."
        error "Please run /latexkit.start again to recreate the project structure."
        return 1
    fi
    
    return 0
}

# Get next version number for a file pattern
get_next_version() {
    local dir="$1"
    local pattern="$2"  # e.g., "YYYYMMDD_v*_draft.md"
    
    # Find highest version number
    local max_version=0
    for file in "${dir}"/${pattern}; do
        if [ -f "$file" ]; then
            # Extract version number (assumes format v01, v02, etc.)
            local version=$(echo "$file" | grep -o 'v[0-9]\+' | sed 's/v//')
            if [ "$version" -gt "$max_version" ]; then
                max_version=$version
            fi
        fi
    done
    
    # Return next version (padded to 2 digits)
    printf "v%02d" $((max_version + 1))
}

# Get current date in YYYYMMDD format
get_date_stamp() {
    date +%Y%m%d
}

# LaTeX-specific utilities
check_latex_installed() {
    if command_exists lualatex || command_exists pdflatex; then
        return 0
    else
        error "LaTeX not found. Please install a LaTeX distribution."
        return 1
    fi
}

check_biber_installed() {
    if command_exists biber; then
        return 0
    else
        warn "Biber not found. Bibliography compilation may fail."
        return 1
    fi
}

# Validate LaTeX document type
validate_document_type() {
    local doc_type="$1"
    local valid_types=("academic-assignment" "paper" "custom")
    
    for type in "${valid_types[@]}"; do
        if [[ "$type" == "$doc_type" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Export functions for use in subshells (silent)
export -f log success warn error command_exists validate_file validate_dir ensure_dir validate_project_structure >/dev/null 2>&1
export -f get_repo_root get_active_project set_active_project list_projects get_current_branch has_git >/dev/null 2>&1
export -f find_document_dir_by_id find_document_dir_by_prefix get_document_paths >/dev/null 2>&1

# ---------------------------------------------------------------
# Naming & slug utilities
# ---------------------------------------------------------------

# Load naming configuration from config file or environment
load_naming_config() {
    local repo_root=$(get_repo_root)
    local config_file="${repo_root}/.latexkit/config/naming.conf"
    
    # Defaults - can be overridden by config file or environment
    export LATEXKIT_MAX_WORDS="${LATEXKIT_MAX_WORDS:-4}"
    export LATEXKIT_MAX_CHARS="${LATEXKIT_MAX_CHARS:-48}"
    export LATEXKIT_ID_PREFIX="${LATEXKIT_ID_PREFIX:-date}"  # date, counter, or custom
    export LATEXKIT_ID_FORMAT="${LATEXKIT_ID_FORMAT:-YYYYMMDD}"  # YYYYMMDD, YYMMDD, counter3, counter4
    export LATEXKIT_STOP_WORDS_REGEX="${LATEXKIT_STOP_WORDS_REGEX:-^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set|write|create|make|draft|document|paper|report)$}"
    
    # Load from config file if exists
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# Generate ID prefix based on configuration
generate_id_prefix() {
    local prefix_type="${LATEXKIT_ID_PREFIX:-date}"
    local format="${LATEXKIT_ID_FORMAT:-YYYYMMDD}"
    
    case "$prefix_type" in
        date)
            case "$format" in
                YYYYMMDD) date +%Y%m%d ;;
                YYMMDD) date +%y%m%d ;;
                YYYY-MM-DD) date +%Y-%m-%d ;;
                *) date +%Y%m%d ;;
            esac
            ;;
        counter)
            local repo_root=$(get_repo_root)
            local docs_dir="${repo_root}/documents"
            local highest=0
            
            if [[ -d "$docs_dir" ]]; then
                for dir in "$docs_dir"/*; do
                    [[ -d "$dir" ]] || continue
                    local dirname=$(basename "$dir")
                    local number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then highest=$number; fi
                done
            fi
            
            local next=$((highest + 1))
            case "$format" in
                counter3) printf "%03d" "$next" ;;
                counter4) printf "%04d" "$next" ;;
                counter) printf "%03d" "$next" ;;
                *) printf "%03d" "$next" ;;
            esac
            ;;
        none)
            echo ""
            ;;
        *)
            # Custom prefix
            echo "$prefix_type"
            ;;
    esac
}

# Create a short, filesystem-safe slug from free text.
# Usage: generate_concise_slug "Some description here" [max_words] [max_chars]
# - Removes common stop words (configurable)
# - Keeps acronyms (ALLCAPS in original) even if short
# - Limits by words and by total characters (cut on word boundaries)
# - ASCII-only, lowercase, hyphen-separated
generate_concise_slug() {
    local text="$1"
    local max_words="${2:-${LATEXKIT_MAX_WORDS:-4}}"
    local max_chars="${3:-${LATEXKIT_MAX_CHARS:-48}}"

    # Load config if not already loaded
    [[ -z "${LATEXKIT_STOP_WORDS_REGEX:-}" ]] && load_naming_config

    # Normalize to ASCII when possible
    local normalized="$text"
    if command_exists iconv; then
        normalized=$(printf "%s" "$text" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null || printf "%s" "$text")
    fi

    # Build lowercase, non-alnum as spaces
    local lower=$(printf "%s" "$normalized" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')

    # Stop words (expandable via env or config)
    local stop_words_regex="${LATEXKIT_STOP_WORDS_REGEX}"

    # Select meaningful words
    local words=()
    for word in $lower; do
        [[ -z "$word" ]] && continue
        # Keep if not a stop word and length >= 3, or acronym in original
        if ! echo "$word" | grep -qiE "$stop_words_regex"; then
            if [[ ${#word} -ge 3 ]]; then
                words+=("$word")
            else
                # Keep short word if it appears as ALLCAPS in original text (acronym)
                local upper_w
                upper_w=$(printf "%s" "$word" | tr '[:lower:]' '[:upper:]')
                if printf "%s" "$text" \
                    | tr '[:lower:]' '[:upper:]' \
                    | tr -cs 'A-Z0-9' '\n' \
                    | grep -qx "$upper_w"; then
                    words+=("$word")
                fi
            fi
        fi
    done

    # Fallback: take first few words of the raw slug
    if [[ ${#words[@]} -eq 0 ]]; then
        local raw_slug=$(printf "%s" "$normalized" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g; s/^-//; s/-$//')
        IFS='-' read -r -a words <<< "$raw_slug"
    fi

    # Build up to max_words, respecting max_chars by cutting on word boundary
    local result=""
    local count=0
    for w in "${words[@]}"; do
        [[ -z "$w" ]] && continue
        if (( count >= max_words )); then break; fi
        local candidate
        if [[ -z "$result" ]]; then candidate="$w"; else candidate="${result}-$w"; fi
        if (( ${#candidate} > max_chars )); then break; fi
        result="$candidate"
        count=$((count + 1))
    done

    # If result empty, fall back to first token truncated
    if [[ -z "$result" ]]; then
        local first="${words[0]}"
        result="${first:0:$((max_chars>0?max_chars:1))}"
    fi

    # Ensure it's a safe slug: lowercase, hyphens, trimmed
    result=$(printf "%s" "$result" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/-\+/-/g; s/^-//; s/-$//')
    printf "%s" "$result"
}

# Generate a complete document ID with prefix and slug
# Usage: generate_document_id "description text" [custom_prefix]
generate_document_id() {
    local description="$1"
    local custom_prefix="${2:-}"
    
    load_naming_config
    
    local prefix
    if [[ -n "$custom_prefix" ]]; then
        prefix="$custom_prefix"
    else
        prefix=$(generate_id_prefix)
    fi
    
    local slug=$(generate_concise_slug "$description")
    
    # Combine prefix and slug
    if [[ -n "$prefix" ]]; then
        echo "${prefix}-${slug}"
    else
        echo "$slug"
    fi
}

# Optional AI naming hook: if an executable hook exists, use it to suggest a slug.
# The hook should print a single line slug (it will be sanitized).
ai_name_hook() {
    local text="$1"
    local hook_path="$(get_repo_root)/.latexkit/scripts/bash/name-from-ai.sh"
    if [[ -x "$hook_path" ]]; then
        local ai_suggestion
        ai_suggestion=$("$hook_path" "$text" 2>/dev/null || true)
        if [[ -n "$ai_suggestion" ]]; then
            # Sanitize and cap to avoid path issues
            printf "%s" "$ai_suggestion" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g; s/^-//; s/-$//'
            return 0
        fi
    fi
    return 1
}

export -f load_naming_config generate_id_prefix generate_concise_slug generate_document_id ai_name_hook >/dev/null 2>&1
