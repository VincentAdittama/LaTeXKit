#!/usr/bin/env bash
# =================================================================
# create-new-document.sh
# Creates a new LaTeX document project (Main-Only Workflow)
# Projects are managed as folders in documents/, not git branches
# Enhanced with speckit-style workflow integration
# =================================================================

set -e

# Load common utilities (naming helpers, logging, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

JSON_MODE=false
SHORT_NAME=""
DOC_TYPE="academic-assignment"
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json) 
            JSON_MODE=true 
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --short-name requires a value' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --doc-type)
            if [ $((i + 1)) -gt $# ]; then
                echo 'Error: --doc-type requires a value' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo 'Error: --doc-type requires a value' >&2
                exit 1
            fi
            DOC_TYPE="$next_arg"
            ;;
        --help|-h) 
            echo "Usage: $0 [--json] [--short-name <name>] [--doc-type <type>] <document_description>"
            echo ""
            echo "Options:"
            echo "  --json              Output in JSON format"
            echo "  --short-name <name> Provide a custom short name (2-4 words) for the branch"
            echo "  --doc-type <type>   Document type (default: academic-assignment)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 'Write essay on climate change' --short-name 'climate-essay'"
            echo "  $0 'Research proposal for AI ethics'"
            exit 0
            ;;
        *) 
            ARGS+=("$arg") 
            ;;
    esac
    i=$((i + 1))
done

DOCUMENT_DESCRIPTION="${ARGS[*]}"
if [ -z "$DOCUMENT_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] [--short-name <name>] [--doc-type <type>] <document_description>" >&2
    exit 1
fi

# Function to find the repository root
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.latexkit" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Resolve repository root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "Error: Could not determine repository root. Please run this script from within the repository." >&2
        exit 1
    fi
    HAS_GIT=false
fi

cd "$REPO_ROOT"

# =================================================================
# MAIN-ONLY WORKFLOW (Trunk-Based Development)
# =================================================================
# All projects live in documents/ folder on the main branch.
# No git branching is used for projects.
# Projects are managed via .active_project file.
# =================================================================

# Check if there's already an active project (edit mode)
ACTIVE_PROJECT_FILE="$REPO_ROOT/.active_project"
if [ -f "$ACTIVE_PROJECT_FILE" ]; then
    CURRENT_PROJECT=$(cat "$ACTIVE_PROJECT_FILE" | tr -d '\n')
    DOCUMENT_DIR="$REPO_ROOT/documents/$CURRENT_PROJECT"
    
    if [ -d "$DOCUMENT_DIR" ]; then
        # Active project exists - report edit mode
        START_FILE="$DOCUMENT_DIR/start.md"
        
        # Validate project structure
        if validate_project_structure "$DOCUMENT_DIR" 2>/dev/null; then
            >&2 echo "✓ Project structure is valid for $CURRENT_PROJECT"
        else
            >&2 echo "⚠ Project structure has issues for $CURRENT_PROJECT"
        fi
        
        if [ -f "$START_FILE" ]; then
            >&2 echo "✓ Project start file exists: $START_FILE"
        else
            >&2 echo "⚠ Project start file missing: $START_FILE"
        fi
        
        >&2 echo "Active project: $CURRENT_PROJECT"
        >&2 echo "Document directory: $DOCUMENT_DIR"
        >&2 echo "To create a NEW project, clear .active_project first or use './latexkit new'"
        
        export LATEXKIT_DOCUMENT="$CURRENT_PROJECT"
        
        if $JSON_MODE; then
            printf '{"BRANCH_NAME":"%s","START_FILE":"%s","DOCUMENT_DIR":"%s","DOC_NUM":"","DOC_TYPE":"existing","mode":"edit"}\n' "$CURRENT_PROJECT" "$START_FILE" "$DOCUMENT_DIR"
        else
            echo "Mode: edit (existing document)"
        fi
        exit 0
    fi
fi

# Continue with creating new document (only on main/master branch)
DOCS_DIR="$REPO_ROOT/documents"
mkdir -p "$DOCS_DIR"

# Find highest document number
# IMPORTANT: HIGHEST starts at 0, so when no projects exist, NEXT will be 1, giving DOC_NUM="001"
# This ensures project numbering always starts from 001 when documents/ is empty or doesn't exist
HIGHEST=0
if [ -d "$DOCS_DIR" ]; then
    for dir in "$DOCS_DIR"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
        number=$((10#$number))
        if [ "$number" -gt "$HIGHEST" ]; then HIGHEST=$number; fi
    done
fi

NEXT=$((HIGHEST + 1))
DOC_NUM=$(printf "%03d" "$NEXT")

# Load naming configuration
load_naming_config

# Generate branch name using the flexible naming system
if [ -n "$SHORT_NAME" ]; then
    # User provided custom short name
    BRANCH_SUFFIX=$(echo "$SHORT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-${LATEXKIT_MAX_CHARS})
else
    # Use the sophisticated slug generator from common.sh
    BRANCH_SUFFIX=$(generate_concise_slug "$DOCUMENT_DESCRIPTION")
fi

# Generate branch name with counter prefix
BRANCH_NAME="${DOC_NUM}-${BRANCH_SUFFIX}"

# Validate branch name length (GitHub limit: 244 bytes)
MAX_BRANCH_LENGTH=244
if [ ${#BRANCH_NAME} -gt $MAX_BRANCH_LENGTH ]; then
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - 4))
    TRUNCATED_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH)
    TRUNCATED_SUFFIX=$(echo "$TRUNCATED_SUFFIX" | sed 's/-$//')
    
    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${DOC_NUM}-${TRUNCATED_SUFFIX}"
    
    >&2 echo "[latexkit] Warning: Branch name exceeded GitHub's 244-byte limit"
    >&2 echo "[latexkit] Original: $ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} bytes)"
    >&2 echo "[latexkit] Truncated to: $BRANCH_NAME (${#BRANCH_NAME} bytes)"
fi

# =================================================================
# MAIN-ONLY WORKFLOW: No branch creation
# =================================================================
# Projects are managed as folders in documents/, not as git branches.
# The .active_project file tracks which project is currently active.
# =================================================================

# No git checkout - we stay on main branch
>&2 echo "[latexkit] Creating project folder: $BRANCH_NAME (Main-Only Workflow)"

DOCUMENT_DIR="$DOCS_DIR/$BRANCH_NAME"
mkdir -p "$DOCUMENT_DIR"

# Create comprehensive directory structure for all document types
# This ensures consistency with the full LaTeXKit workflow
mkdir -p "$DOCUMENT_DIR"/checklists
mkdir -p "$DOCUMENT_DIR"/latex_source/sections
mkdir -p "$DOCUMENT_DIR"/latex_source/images
mkdir -p "$DOCUMENT_DIR"/build
mkdir -p "$DOCUMENT_DIR"/assignment_info
mkdir -p "$DOCUMENT_DIR"/zotero_export
mkdir -p "$DOCUMENT_DIR"/generated_work/research
mkdir -p "$DOCUMENT_DIR"/generated_work/outlines
mkdir -p "$DOCUMENT_DIR"/generated_work/drafts
mkdir -p "$DOCUMENT_DIR"/generated_work/conversion
mkdir -p "$DOCUMENT_DIR"/generated_work/compilation
mkdir -p "$DOCUMENT_DIR"/generated_work/reviews

# Create .gitkeep files to preserve empty directories
# This ensures folders survive git branch switching and `find . -type d -empty -delete`
touch "$DOCUMENT_DIR/checklists/.gitkeep"
touch "$DOCUMENT_DIR/latex_source/sections/.gitkeep"
touch "$DOCUMENT_DIR/latex_source/images/.gitkeep"
touch "$DOCUMENT_DIR/build/.gitkeep"
touch "$DOCUMENT_DIR/assignment_info/.gitkeep"
touch "$DOCUMENT_DIR/zotero_export/.gitkeep"
touch "$DOCUMENT_DIR/generated_work/research/.gitkeep"
touch "$DOCUMENT_DIR/generated_work/outlines/.gitkeep"
touch "$DOCUMENT_DIR/generated_work/drafts/.gitkeep"
touch "$DOCUMENT_DIR/generated_work/conversion/.gitkeep"
touch "$DOCUMENT_DIR/generated_work/compilation/.gitkeep"
touch "$DOCUMENT_DIR/generated_work/reviews/.gitkeep"

# Copy start template
TEMPLATE="$REPO_ROOT/.latexkit/templates/start-template.md"
START_FILE="$DOCUMENT_DIR/start.md"
if [ -f "$TEMPLATE" ]; then 
    cp "$TEMPLATE" "$START_FILE"
else 
    touch "$START_FILE"
fi

# NOTE: .latexmkrc and LaTeX templates are NOT copied here
# They will be imported during the /latexkit.convert phase when needed

# Set the LATEXKIT_DOCUMENT environment variable
export LATEXKIT_DOCUMENT="$BRANCH_NAME"

# =================================================================
# MAIN-ONLY WORKFLOW: Set active project
# =================================================================
# Write the project ID to .active_project file
# This replaces the need for git branch context
# =================================================================
echo "$BRANCH_NAME" > "$REPO_ROOT/.active_project"
>&2 echo "[latexkit] Active project set to: $BRANCH_NAME"

if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","START_FILE":"%s","DOCUMENT_DIR":"%s","DOC_NUM":"%s","DOC_TYPE":"%s","ACTIVE_PROJECT":"%s"}\n' "$BRANCH_NAME" "$START_FILE" "$DOCUMENT_DIR" "$DOC_NUM" "$DOC_TYPE" "$BRANCH_NAME"
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "START_FILE: $START_FILE"
    echo "DOCUMENT_DIR: $DOCUMENT_DIR"
    echo "DOC_NUM: $DOC_NUM"
    echo "DOC_TYPE: $DOC_TYPE"
    echo "ACTIVE_PROJECT: $BRANCH_NAME"
    echo "LATEXKIT_DOCUMENT environment variable set to: $BRANCH_NAME"
fi
