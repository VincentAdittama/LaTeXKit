#!/usr/bin/env bash
# =================================================================
# init.sh
# Initializes the .latexkit-workspace configuration file.
# Intelligently detects if running in a standalone repo or a submodule.
# =================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =================================================================
# Main
# =================================================================

main() {
    log "Initializing LatexKit workspace..."

    # Detect the correct repository root (Monorepo or Super-Repo)
    local repo_root
    repo_root=$(get_repo_root)
    
    if [[ -z "$repo_root" ]]; then
        error "Could not determine repository root. Are you in a git repository?"
        exit 1
    fi
    
    log "Detected project root: ${repo_root}"
    
    local workspace_file="${repo_root}/.latexkit-workspace"
    
    # Check if workspace file already exists
    if [[ -f "$workspace_file" ]]; then
        warn "Workspace configuration already exists at: ${workspace_file}"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Aborted."
            exit 0
        fi
    fi
    
    # Create the workspace file with default template
    log "Creating .latexkit-workspace..."
    
    cat > "$workspace_file" <<EOF
# LatexKit Workspace Configuration
# ================================
# This file stores project-wide settings and variables.
# It works for both standalone repositories and submodule setups.

# Active Project (Managed by 'latexkit switch')
ACTIVE_PROJECT=""

# University Configuration
# ------------------------
# These variables are automatically injected into your LaTeX templates.
# Customize them for your specific institution.

UNI_NAME="Institut Seni Indonesia Yogyakarta"
UNI_FACULTY="Fakultas Seni Pertunjukan"
UNI_PROGRAM="Prodi Musik"
UNI_SEMESTER="Gasal 2025/2026"
UNI_LOGO="logo-isi-yogyakarta.png"

# Tip: Place your logo file (e.g., logo-isi-yogyakarta.png) in:
# .latexkit/assets/
EOF

    success "LatexKit initialized successfully!"
    log "Configuration created at: ${workspace_file}"
    log "You can now edit this file to customize your university details."
}

main "$@"
