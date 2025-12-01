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
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fall back to script location for non-git repos
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Get current branch, with fallback for non-git repositories
get_current_branch() {
    # First check if LATEXKIT_DOCUMENT environment variable is set
    if [[ -n "${LATEXKIT_DOCUMENT:-}" ]]; then
        echo "$LATEXKIT_DOCUMENT"
        return
    fi

    # Then check git if available
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # For non-git repos, try to find the latest document directory
    local repo_root=$(get_repo_root)
    local docs_dir="$repo_root/documents"

    if [[ -d "$docs_dir" ]]; then
        local latest_document=""
        local highest=0

        for dir in "$docs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local number=${BASH_REMATCH[1]}
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then
                        highest=$number
                        latest_document=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_document" ]]; then
            echo "$latest_document"
            return
        fi
    fi

    echo "main"  # Final fallback
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

# Check document branch naming convention
check_document_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        warn "Git repository not detected; skipped branch validation"
        return 0
    fi

    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        error "Not on a document branch. Current branch: $branch"
        error "Document branches should be named like: 001-assignment-name"
        return 1
    fi

    return 0
}

# Find document directory by numeric prefix
find_document_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local docs_dir="$repo_root/documents"

    # Extract numeric prefix from branch (e.g., "004" from "004-whatever")
    if [[ ! "$branch_name" =~ ^([0-9]{3})- ]]; then
        # If branch doesn't have numeric prefix, fall back to exact match
        echo "$docs_dir/$branch_name"
        return
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Search for directories in documents/ that start with this prefix
    local matches=()
    if [[ -d "$docs_dir" ]]; then
        for dir in "$docs_dir"/"$prefix"-*; do
            if [[ -d "$dir" ]]; then
                matches+=("$(basename "$dir")")
            fi
        done
    fi

    # Handle results
    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "$docs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        echo "$docs_dir/${matches[0]}"
    else
        error "Multiple document directories found with prefix '$prefix': ${matches[*]}"
        error "Please ensure only one document directory exists per numeric prefix."
        echo "$docs_dir/$branch_name"
    fi
}

# Get document paths for current branch
get_document_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    local document_dir=$(find_document_dir_by_prefix "$repo_root" "$current_branch")

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
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
