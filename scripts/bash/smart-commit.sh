#!/usr/bin/env bash
# =================================================================
# smart-commit.sh
# Intelligent git commit with contextual message generation
# Creates commit messages with workflow labels (START, RESEARCH, etc.)
# and automatic iteration numbering
# =================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get workflow stage from argument or detect from changes
get_workflow_stage() {
    local stage_arg="$1"
    
    # If stage provided, validate and return uppercase (HIGHEST PRIORITY)
    if [[ -n "$stage_arg" ]]; then
        local upper_stage=$(echo "$stage_arg" | tr '[:lower:]' '[:upper:]')
        case "$upper_stage" in
            START|PLAN|CLARIFY|RESEARCH|OUTLINE|DRAFT|CONVERT|BUILD|CHECK|FIX|REFACTOR|DOCS|FEAT|CHORE)
                echo "$upper_stage"
                return 0
                ;;
            *)
                error "Invalid workflow stage: $stage_arg"
                error "Valid stages: start, plan, clarify, research, outline, draft, convert, build, check, fix, refactor, docs, feat, chore"
                return 1
                ;;
        esac
    fi
    
    # Auto-detect from all changed files (staged + unstaged)
    local all_files=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || git ls-files --others --exclude-standard)
    
    # Prioritize detection based on artifacts and file patterns
    # Each workflow command creates specific artifacts that indicate the phase
    
    # PLAN/START: Initial project setup
    if echo "$all_files" | grep -q "checklists/latexkit\.plan\.md"; then
        echo "PLAN"
        return 0
    fi
    if echo "$all_files" | grep -q "checklists/latexkit\.start\.md"; then
        # Check if this is the first time start checklist is created
        if ! git log --all --oneline -- "*checklists/latexkit.start.md" 2>/dev/null | grep -q "."; then
            echo "START"
            return 0
        fi
    fi
    
    # START: Alternative detection - plan.md being created for first time
    if echo "$all_files" | grep -q "generated_work/plan\.md" || echo "$all_files" | grep -q "^plan\.md"; then
        if ! git log --all --oneline -- "*plan.md" 2>/dev/null | grep -q "."; then
            echo "PLAN"
            return 0
        fi
    fi
    
    # START: Alternative detection - start.md being created for first time
    if echo "$all_files" | grep -q "start\.md"; then
        if ! git log --all --oneline -- "*start.md" 2>/dev/null | grep -q "."; then
            echo "PLAN"
            return 0
        fi
    fi
    
    # CLARIFY: Clarify checklist exists OR start.md being edited after initial creation
    if echo "$all_files" | grep -q "checklists/latexkit\.clarify\.md"; then
        echo "CLARIFY"
        return 0
    fi
    
    # CLARIFY: start.md edited after first commit (not a new file)
    if echo "$all_files" | grep -q "start\.md"; then
        if git log --all --oneline -- "*start.md" 2>/dev/null | grep -q "."; then
            # start.md exists in history and being modified
            echo "CLARIFY"
            return 0
        fi
    fi
    
    # RESEARCH: Research artifacts in generated_work/research OR research checklist
    if echo "$all_files" | grep -q "checklists/latexkit\.research\.md"; then
        echo "RESEARCH"
        return 0
    fi
    if echo "$all_files" | grep -q "generated_work/research"; then
        echo "RESEARCH"
        return 0
    fi
    
    # OUTLINE: Outline artifacts in generated_work/outline OR outline checklist
    if echo "$all_files" | grep -q "checklists/latexkit\.outline\.md"; then
        echo "OUTLINE"
        return 0
    fi
    if echo "$all_files" | grep -q "generated_work/outline"; then
        echo "OUTLINE"
        return 0
    fi
    
    # DRAFT: Draft artifacts in generated_work/draft OR draft checklist
    if echo "$all_files" | grep -q "checklists/latexkit\.draft\.md"; then
        echo "DRAFT"
        return 0
    fi
    if echo "$all_files" | grep -q "generated_work/draft"; then
        echo "DRAFT"
        return 0
    fi
    
    # CONVERT: LaTeX sections OR conversion artifacts OR convert checklist
    if echo "$all_files" | grep -q "checklists/latexkit\.convert\.md"; then
        echo "CONVERT"
        return 0
    fi
    if echo "$all_files" | grep -q "latex_source/sections.*\.tex"; then
        echo "CONVERT"
        return 0
    fi
    if echo "$all_files" | grep -q "generated_work/convert"; then
        echo "CONVERT"
        return 0
    fi
    
    # BUILD: PDF files OR build artifacts OR build checklist
    if echo "$all_files" | grep -q "checklists/latexkit\.build\.md"; then
        echo "BUILD"
        return 0
    fi
    if echo "$all_files" | grep -q "build/.*\.pdf"; then
        echo "BUILD"
        return 0
    fi
    
    # CHECK: Quality check artifacts OR check checklist
    if echo "$all_files" | grep -q "checklists/latexkit\.check\.md"; then
        echo "CHECK"
        return 0
    fi
    
    # Template/system changes
    if echo "$all_files" | grep -q "\.latexkit/\|scripts/\|registry/\|config/"; then
        echo "REFACTOR"
        return 0
    fi
    
    # Documentation updates
    if echo "$all_files" | grep -q "README\.md\|docs/\|\.github/prompts/"; then
        echo "DOCS"
        return 0
    fi
    
    # Default fallback
    echo "CHORE"
}

# =================================================================
# MAIN-ONLY WORKFLOW: Path-Scoped Iteration Counting
# =================================================================
# In Main-Only (Trunk-Based) workflow, all commits are on main branch.
# We scope iteration counting to the ACTIVE PROJECT folder to ensure
# each project has its own independent sequence (01, 02, 03...).
# =================================================================

# Get the active project path from .active_project file
# Get the active project path from shared state
get_active_project_path() {
    local project_id=$(get_active_project)
    
    if [[ -n "$project_id" ]]; then
        local repo_root=$(get_repo_root)
        local project_dir=$(find_document_dir_by_id "$repo_root" "$project_id")
        
        if [[ -n "$project_dir" ]]; then
            # Return relative path from repo root for git log filtering
            echo "${project_dir#$repo_root/}"
            return 0
        fi
    fi
    
    # Fallback: No active project
    echo ""
    return 1
}

# Get next sequential number for active project (path-scoped)
get_next_iteration() {
    local project_path="${1:-$(get_active_project_path)}"
    
    # =================================================================
    # MAIN-ONLY WORKFLOW: Scope git log to project folder
    # =================================================================
    # Instead of counting all commits on branch (which would mix
    # all projects), we filter by path to get project-specific count.
    # =================================================================
    
    local all_commits=""
    
    if [[ -n "$project_path" ]]; then
        # Path-scoped: Only count commits that touched this project's folder
        # This ensures each project has its own iteration sequence
        all_commits=$(git log --oneline --no-merges --grep="^[A-Z]\+-[0-9]\{2\}" HEAD -- "$project_path" 2>/dev/null || true)
        
        # Debug info (only in verbose mode)
        if [[ "${LATEXKIT_VERBOSE:-}" == "true" ]]; then
            >&2 echo "[latexkit] Counting iterations for path: $project_path"
            >&2 echo "[latexkit] Found commits: $(echo "$all_commits" | wc -l | tr -d ' ')"
        fi
    else
        # No active project - fallback to global count (legacy behavior)
        # This should rarely happen in normal workflow
        >&2 echo "[latexkit] Warning: No active project found, using global iteration count"
        all_commits=$(git log --oneline --no-merges --grep="^[A-Z]\+-[0-9]\{2\}" HEAD 2>/dev/null || true)
    fi
    
    if [[ -z "$all_commits" ]]; then
        echo "01"
        return
    fi
    
    # Extract all iteration numbers across all stages
    local max_iter=0
    while IFS= read -r commit; do
        # Match any STAGE-NN pattern
        if [[ "$commit" =~ [A-Z]+-([0-9]{2}) ]]; then
            local iter=${BASH_REMATCH[1]}
            # Remove leading zero for comparison
            iter=$((10#$iter))
            if [[ $iter -gt $max_iter ]]; then
                max_iter=$iter
            fi
        fi
    done <<< "$all_commits"
    
    # Return next iteration (padded to 2 digits)
    printf "%02d" $((max_iter + 1))
}

# Get summary of staged changes
get_staged_changes_summary() {
    local changes=$(git diff --cached --stat)
    local files_changed=$(git diff --cached --name-only | wc -l | tr -d ' ')
    local insertions=$(git diff --cached --numstat | awk '{sum+=$1} END {print sum}')
    local deletions=$(git diff --cached --numstat | awk '{sum+=$2} END {print sum}')
    
    echo "$files_changed files changed, $insertions insertions(+), $deletions deletions(-)"
}

# Get detailed change summary with actual content
get_changes_summary() {
    # Get all staged files
    local all_files=$(git diff --cached --name-only)
    
    # Create a summary file for the LLM to analyze
    local summary=""
    
    # Add file statistics
    local files_changed=$(echo "$all_files" | wc -l | tr -d ' ')
    summary="${summary}FILES CHANGED: $files_changed\n\n"
    
    # For each changed file, get a meaningful diff summary
    while IFS= read -r file; do
        if [[ -z "$file" ]]; then
            continue
        fi
        
        summary="${summary}═══ $file ═══\n"
        
        # Check if file is new (A), modified (M), or deleted (D)
        local status=$(git diff --cached --name-status | grep "^[AMD]\s\+$file" | cut -f1)
        
        case "$status" in
            A)
                summary="${summary}[NEW FILE]\n"
                # Show first 10 lines of new file for context
                local preview=$(git diff --cached "$file" | grep "^+" | grep -v "^+++" | head -10 | sed 's/^+/  /')
                summary="${summary}${preview}\n"
                ;;
            D)
                summary="${summary}[DELETED]\n"
                ;;
            M)
                summary="${summary}[MODIFIED]\n"
                # Show actual changes (additions and deletions)
                local changes=$(git diff --cached "$file" | grep "^[+-]" | grep -v "^[+-][+-][+-]" | head -20)
                summary="${summary}${changes}\n"
                ;;
        esac
        
        summary="${summary}\n"
    done <<< "$all_files"
    
    echo -e "$summary"
}

# Legacy categorize_changes for backwards compatibility
categorize_changes() {
    # This function now just provides a simple categorized list
    # The detailed changes are handled by get_changes_summary()
    local all_files=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || git ls-files --others --exclude-standard)
    
    local categories=""
    
    if echo "$all_files" | grep -q "^documents/.*start\.md"; then
        categories="${categories}- Project start files\n"
    fi
    
    if echo "$all_files" | grep -q "generated_work/research"; then
        categories="${categories}- Research materials\n"
    fi
    
    if echo "$all_files" | grep -q "generated_work/outline"; then
        categories="${categories}- Content outlines\n"
    fi
    
    if echo "$all_files" | grep -q "generated_work/draft"; then
        categories="${categories}- Draft content\n"
    fi
    
    if echo "$all_files" | grep -q "latex_source/sections"; then
        categories="${categories}- LaTeX source files\n"
    fi
    
    if echo "$all_files" | grep -q "latex_source/.*\.bib"; then
        categories="${categories}- Bibliography\n"
    fi
    
    if echo "$all_files" | grep -q "checklists/"; then
        categories="${categories}- Checklists\n"
    fi
    
    if echo "$all_files" | grep -q "assignment_info/"; then
        categories="${categories}- Assignment context files\n"
    fi
    
    if echo "$all_files" | grep -q "zotero_export"; then
        categories="${categories}- Zotero exports\n"
    fi
    
    if echo "$all_files" | grep -q "\.latexkit/"; then
        categories="${categories}- LaTeXKit system files\n"
    fi
    
    if echo "$all_files" | grep -q "README\.md\|docs/"; then
        categories="${categories}- Documentation\n"
    fi
    
    if echo "$all_files" | grep -q "\.github/prompts/"; then
        categories="${categories}- GitHub prompts\n"
    fi
    
    # If no categories matched, list changed files
    if [[ -z "$categories" ]]; then
        local file_list=$(echo "$all_files" | head -5 | sed 's/^/- /')
        local file_count=$(echo "$all_files" | wc -l | tr -d ' ')
        if [[ $file_count -gt 5 ]]; then
            categories="${file_list}\n- ... and $((file_count - 5)) more files"
        else
            categories="$file_list"
        fi
    fi
    
    echo -e "$categories"
}

# Main execution
main() {
    # 1. Determine the Correct Root (Super Repo or Standalone)
    local repo_root=$(get_repo_root)
    
    # 2. Switch to that Root
    # This is crucial so that git status/add/commit commands run in the context of the Super Repo.
    cd "$repo_root" || {
        error "Could not change directory to $repo_root"
        exit 1
    }

    local workflow_stage=""
    local custom_message=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--message)
                custom_message="$2"
                shift 2
                ;;
            -s|--stage)
                workflow_stage="$2"
                shift 2
                ;;
            *)
                # First positional argument is the stage
                if [[ -z "$workflow_stage" ]]; then
                    workflow_stage="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not a git repository (checked at $repo_root)!"
        exit 1
    fi
    
    # Check if there are ANY changes (staged or unstaged)
    local has_changes=false
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [[ -n $(git ls-files --others --exclude-standard) ]]; then
        has_changes=true
    fi
    
    if [[ "$has_changes" == false ]]; then
        error "No changes to commit!"
        log "Working directory is clean"
        exit 1
    fi
    
    # Auto-stage ALL changes (unstaged + untracked)
    log "Auto-staging all changes..."
    git add -A
    
    # Get active project (formerly current branch)
    local current_branch=$(get_current_branch)
    log "Active Project: $current_branch"
    
    # Get or detect workflow stage
    if [[ -z "$workflow_stage" ]]; then
        workflow_stage=$(get_workflow_stage "")
        log "Auto-detected stage: $workflow_stage"
    else
        workflow_stage=$(get_workflow_stage "$workflow_stage")
        log "Using stage: $workflow_stage"
    fi
    
    # Get sequential iteration number (continuous across all stages)
    local iteration=$(get_next_iteration)
    log "Sequential number: $iteration"
    
    # Generate detailed changes summary for LLM analysis
    local changes_file="/tmp/latexkit_commit_changes_$$.txt"
    get_changes_summary > "$changes_file"
    
    # Show staged changes summary
    log "Changes to commit:"
    echo ""
    git diff --cached --stat
    echo ""
    
    # Generate commit message metadata for LLM
    local commit_label="${workflow_stage}-${iteration}"
    local commit_categories=$(categorize_changes)
    
    # Output metadata for LLM to use
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Commit Metadata for LLM${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Label:${NC} $commit_label"
    echo -e "${YELLOW}Stage:${NC} $workflow_stage"
    echo -e "${YELLOW}Iteration:${NC} $iteration"
    echo -e "${YELLOW}Context:${NC} $current_branch"
    echo ""
    echo -e "${YELLOW}Change Categories:${NC}"
    echo -e "$commit_categories"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓ Changes staged${NC}"
    echo -e "${GREEN}✓ Detailed changes file created: $changes_file${NC}"
    echo ""
    echo -e "${YELLOW}→ LLM: Read the changes file and create a descriptive commit message${NC}"
    echo -e "${YELLOW}→ Format: $commit_label: [Your descriptive title]${NC}"
}

# Show help
show_help() {
    cat <<EOF
Usage: $0 [STAGE] [OPTIONS]

Create intelligent commits with automatic workflow labeling and iteration numbering.

ARGUMENTS:
  STAGE                 Workflow stage (plan, clarify, research, outline, draft, 
                        convert, build, check, fix, refactor, docs, feat, chore)
                        **RECOMMENDED**: Always specify the stage explicitly for consistency.
                        If omitted, auto-detects from changed files (may be inconsistent).

OPTIONS:
  -m, --message TEXT    Custom commit title message
  -s, --stage STAGE     Explicitly set workflow stage
  -h, --help            Show this help message

AUTOMATIC STAGING:
  This command automatically stages ALL changes (unstaged + untracked) before committing.
  No need to run 'git add' first - just run this command!

SEQUENTIAL NUMBERING:
  Numbers are sequential (01, 02, 03...) for commits made on the CURRENT BRANCH ONLY.
  - Each new branch starts numbering from 01
  - Only counts commits created on this branch (not inherited from main)
  - On main/master: always starts from 01 for new documents
  - Branch isolation ensures clean, independent sequences
  - Sequential across ALL stages: PLAN-01, RESEARCH-02, OUTLINE-03, DRAFT-04, etc.

BEST PRACTICES:
  - **Always specify the stage explicitly**: $0 start, $0 research, $0 draft
  - Auto-detection is available but explicit stages ensure consistency
  - The /latexkit.[command] commit workflow automatically uses explicit stages

EXAMPLES:
  # Explicit stage (RECOMMENDED) - auto-stages all changes
  $0 plan
  # Result: PLAN-01 (if first commit on this branch)

  # Explicit stage with sequential numbering
  $0 research
  # Result: RESEARCH-02 (sequential number continues on this branch)

  # Specify stage with custom message
  $0 draft -m "Complete introduction and methodology sections"
  # Result: DRAFT-03: Complete introduction and methodology sections

  # Auto-detect (not recommended - may be inconsistent)
  $0
  # Result: Detects stage from changed files (e.g., RESEARCH-02)

  # Long form
  $0 --stage outline --message "Restructure argument flow"
  # Result: OUTLINE-04: Restructure argument flow

WORKFLOW STAGES:
  plan       - Initial project setup and plan creation (formerly start)
  start      - Alias for plan (deprecated)
  clarify    - Resolve ambiguities in plan.md
  research   - Research planning and source gathering
  outline    - Content structure and organization
  draft      - Writing and drafting content
  convert    - Converting between formats (MD to LaTeX)
  build      - Compilation and build artifacts
  check      - Quality checks and validation
  fix        - Bug fixes and corrections
  refactor   - Code/content restructuring
  docs       - Documentation updates
  feat       - New features
  chore      - Maintenance tasks

COMMIT FORMAT:
  STAGE-NN: Title message
  
  - Change category 1
  - Change category 2
  - ...

  Where NN is sequential for commits on THIS BRANCH only (01, 02, 03, ...)
  Each branch has independent numbering starting from 01.

EXAMPLES OUTPUT:
  PLAN-01: Initial project setup
  
  - Created project structure
  - Added start file

  RESEARCH-02: Add peer-reviewed sources on climate change
  
  - Modified research materials
  - Updated Zotero exports

  OUTLINE-03: Structure content sections
  
  - Updated content outline

  DRAFT-04: Complete introduction and methodology
  
  - Revised draft content
  - Updated checklists

  Note: Numbers are sequential for commits on THIS BRANCH only.

EOF
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

main "$@"
