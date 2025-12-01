#!/usr/bin/env bash
# =================================================================
# check-prerequisites.sh
# Verifies required tools are installed for LaTeXKit workflow
# =================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =================================================================
# Configuration
# =================================================================

REQUIRED_TOOLS=(
    "pdflatex:LaTeX compiler (TeX Live or MiKTeX)"
    "bibtex:BibTeX for bibliography processing"
    "git:Version control"
)

RECOMMENDED_TOOLS=(
    "latexmk:Automated LaTeX compilation"
    "zotero:Reference management"
)

# =================================================================
# Functions
# =================================================================

check_tool() {
    local tool_spec="$1"
    local tool_name=$(echo "$tool_spec" | cut -d: -f1)
    local tool_desc=$(echo "$tool_spec" | cut -d: -f2)
    
    # Special handling for Zotero which is typically a GUI app on macOS
    if [[ "$tool_name" == "zotero" ]]; then
        if detect_zotero; then
            success "zotero is installed"
            local version
            version=$(get_zotero_version)
            if [[ -n "$version" ]]; then
                log "  Version: ${version}"
            fi
            return 0
        else
            error "zotero is NOT installed"
            warn "  Description: ${tool_desc}"
            return 1
        fi
    fi

    if command_exists "$tool_name"; then
        success "${tool_name} is installed"
        
        # Show version if available
        case "$tool_name" in
            pdflatex|bibtex)
                local version=$($tool_name --version 2>&1 | head -n1)
                log "  Version: ${version}"
                ;;
            git)
                local version=$(git --version)
                log "  Version: ${version}"
                ;;
            latexmk)
                local version=$(latexmk -v 2>&1 | head -n1)
                log "  ${version}"
                ;;
        esac
        return 0
    else
        error "${tool_name} is NOT installed"
        warn "  Description: ${tool_desc}"
        return 1
    fi
}

# Detect Zotero presence across platforms
detect_zotero() {
    local os_type
    os_type="$(uname -s)"

    # If a CLI exists, that's enough
    if command_exists zotero; then
        return 0
    fi

    case "$os_type" in
        Darwin*)
            # Common install locations for Homebrew cask or manual install
            if [[ -d "/Applications/Zotero.app" ]] || [[ -d "$HOME/Applications/Zotero.app" ]]; then
                return 0
            fi
            # Try system lookup of an app by name (returns 0 if found)
            if open -Ra "Zotero" >/dev/null 2>&1; then
                return 0
            fi
            return 1
            ;;
        Linux*)
            # Support common Linux packaging variants
            if command_exists zotero-snap; then
                return 0
            fi
            if command_exists flatpak && flatpak info org.zotero.Zotero >/dev/null 2>&1; then
                return 0
            fi
            # Check a typical tarball install location
            if [[ -x "$HOME/.local/share/zotero/zotero" ]]; then
                return 0
            fi
            return 1
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # On Windows, we can try where/where.exe
            if command_exists where && where zotero >/dev/null 2>&1; then
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Try to read Zotero version when available
get_zotero_version() {
    local os_type
    os_type="$(uname -s)"

    # CLI variant
    if command_exists zotero; then
        # Some builds support --version or -v; ignore errors
        zotero --version 2>/dev/null || zotero -v 2>/dev/null || true
        return 0
    fi

    case "$os_type" in
        Darwin*)
            local app_path=""
            if [[ -d "/Applications/Zotero.app" ]]; then
                app_path="/Applications/Zotero.app"
            elif [[ -d "$HOME/Applications/Zotero.app" ]]; then
                app_path="$HOME/Applications/Zotero.app"
            else
                # Try to locate via Spotlight by bundle identifier
                app_path=$(mdfind "kMDItemCFBundleIdentifier == 'org.zotero.zotero'" | head -n1)
            fi

            if [[ -n "$app_path" && -d "$app_path" ]]; then
                # Prefer mdls for version metadata
                local v
                v=$(mdls -name kMDItemVersion -raw "$app_path" 2>/dev/null || true)
                if [[ -n "$v" ]]; then
                    echo "Zotero ${v}"
                    return 0
                fi
                # Fallback to Info.plist
                v=$(defaults read "$app_path/Contents/Info" CFBundleShortVersionString 2>/dev/null || true)
                if [[ -n "$v" ]]; then
                    echo "Zotero ${v}"
                    return 0
                fi
            fi
            ;;
        Linux*)
            if command_exists flatpak && flatpak info org.zotero.Zotero >/dev/null 2>&1; then
                flatpak info org.zotero.Zotero | awk -F: '/Version/ {gsub(/^ +| +$/,"",$2); print "Zotero " $2}'
                return 0
            fi
            ;;
    esac

    # Unknown/unsupported method
    echo ""
}

provide_installation_instructions() {
    local os_type="$(uname -s)"
    
    echo ""
    log "Installation Instructions:"
    echo ""
    
    case "$os_type" in
        Darwin*)
            log "macOS detected - Install via Homebrew:"
            echo "  brew install --cask mactex     # LaTeX distribution"
            echo "  brew install git                # Git"
            echo "  brew install --cask zotero      # Zotero"
            ;;
        Linux*)
            log "Linux detected - Install via package manager:"
            echo "  sudo apt-get install texlive-full  # LaTeX (Debian/Ubuntu)"
            echo "  sudo apt-get install git           # Git"
            echo "  sudo snap install zotero-snap      # Zotero"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            log "Windows detected - Download installers:"
            echo "  LaTeX: https://miktex.org/download"
            echo "  Git: https://git-scm.com/download/win"
            echo "  Zotero: https://www.zotero.org/download/"
            ;;
        *)
            log "Unknown OS - Please install manually:"
            echo "  LaTeX: https://www.latex-project.org/get/"
            echo "  Git: https://git-scm.com/downloads"
            echo "  Zotero: https://www.zotero.org/download/"
            ;;
    esac
}

# =================================================================
# Main
# =================================================================

main() {
    log "Checking prerequisites for LaTeXKit..."
    echo ""
    
    local all_required_present=true
    local any_recommended_missing=false
    
    # Check required tools
    log "Required Tools:"
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! check_tool "$tool"; then
            all_required_present=false
        fi
        echo ""
    done
    
    # Check recommended tools
    log "Recommended Tools:"
    for tool in "${RECOMMENDED_TOOLS[@]}"; do
        if ! check_tool "$tool"; then
            any_recommended_missing=true
        fi
        echo ""
    done
    
    # Summary and recommendations
    echo ""
    echo "=================================================="
    if [ "$all_required_present" = true ]; then
        success "All required tools are installed!"
        
        if [ "$any_recommended_missing" = true ]; then
            warn "Some recommended tools are missing."
            log "The workflow will function, but recommended tools improve the experience."
        else
            success "All recommended tools are also installed!"
        fi
        
        log ""
        log "You're ready to use LaTeXKit!"
        log "Start with: /latexkit.start \"your assignment description\""
        exit 0
    else
        error "Some required tools are missing!"
        provide_installation_instructions
        exit 1
    fi
}

main "$@"
