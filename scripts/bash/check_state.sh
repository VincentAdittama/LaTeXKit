#!/usr/bin/env bash
# check_state.sh
# A robust, standalone script for AI agents to check the current project state.
# Usage: ./check_state.sh

# 1. Resolve Project Root
#    We need to find where the .latexkit folder is relative to this script.
#    This script is in .latexkit/scripts/bash/check_state.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assuming standard structure: root/.latexkit/scripts/bash/
# So root is 3 levels up
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 2. Source Common Utilities (Suppress logs to keep output clean)
export LATEXKIT_SILENT=true
source "$SCRIPT_DIR/common.sh" 2>/dev/null || {
    echo "ERROR: Could not source common.sh"
    exit 1
}

# 3. Detect Active Project
#    We explicitly call get_active_project from common.sh
ACTIVE_PROJECT=$(get_active_project)

# 4. Output Result in KEY=VALUE format
if [[ -n "$ACTIVE_PROJECT" ]]; then
    echo "ACTIVE_PROJECT=$ACTIVE_PROJECT"
else
    echo "ACTIVE_PROJECT="
fi
