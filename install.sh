#!/usr/bin/env bash
#
# Razd CLI Installer for Linux/macOS
# https://github.com/razd-cli/razd
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/razd-cli/installer/main/install.sh | bash
#
# Environment Variables:
#   RAZD_VERSION - Version to install (default: "latest")
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

RAZD_VERSION="${RAZD_VERSION:-latest}"
MISE_INSTALL_URL="https://mise.run"

# =============================================================================
# Colors
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# =============================================================================
# Output Functions
# =============================================================================

step() {
    echo -e "${BLUE}==>${NC} ${BLUE}$1${NC}"
}

info() {
    echo -e "${CYAN}   $1${NC}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗ Error:${NC} $1" >&2
    exit 1
}

# =============================================================================
# Utility Functions
# =============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# Mise Installation
# =============================================================================

install_mise() {
    step "Checking for mise..."

    if command_exists mise; then
        success "mise is already installed ($(mise --version))"
        return 0
    fi

    step "Installing mise..."
    
    if ! command_exists curl; then
        error "curl is required but not installed. Please install curl and try again."
    fi

    # Install mise using the official installer
    curl -fsSL "$MISE_INSTALL_URL" | sh

    # Add mise to PATH for current session
    # mise installs to ~/.local/bin by default
    if [ -f "${HOME}/.local/bin/mise" ]; then
        export PATH="${HOME}/.local/bin:${PATH}"
        success "mise installed successfully"
    else
        error "mise installation failed. Please check the output above."
    fi
}

# =============================================================================
# Mise Activation Check
# =============================================================================

ensure_mise_activated() {
    # Check if mise shims are on PATH (indicates mise is activated)
    # If not, we need to activate it for this session
    if ! command_exists mise; then
        if [ -f "${HOME}/.local/bin/mise" ]; then
            export PATH="${HOME}/.local/bin:${PATH}"
        else
            error "mise not found. Installation may have failed."
        fi
    fi

    # Activate mise for current session so 'mise use -g' works
    eval "$(mise activate bash 2>/dev/null || true)"
}

# =============================================================================
# Razd Installation
# =============================================================================

install_razd() {
    step "Installing razd..."

    ensure_mise_activated

    local version_arg=""
    if [ "$RAZD_VERSION" = "latest" ]; then
        version_arg="razd@latest"
    else
        version_arg="razd@${RAZD_VERSION}"
    fi

    info "Installing razd version: $RAZD_VERSION"

    # Install razd globally via mise
    # NOTE: If razd is not in the mise registry, use one of these alternatives:
    #   mise use -g cargo:razd-cli/razd@latest     # Install from crates.io
    #   mise use -g ubi:razd-cli/razd@latest       # Install from GitHub releases
    if ! mise use -g "$version_arg" -y; then
        error "Failed to install razd. Please check the output above."
    fi

    success "razd installed successfully"
}

# =============================================================================
# Shell Activation Instructions
# =============================================================================

print_activation_instructions() {
    step "Post-installation setup"

    echo ""
    info "To use razd, mise must be activated in your shell."
    echo ""

    local shell_name
    local rc_file
    local activation_cmd

    # Detect shell from $SHELL environment variable
    case "${SHELL:-}" in
        */zsh)
            shell_name="zsh"
            rc_file="~/.zshrc"
            activation_cmd='eval "$(mise activate zsh)"'
            ;;
        */bash)
            shell_name="bash"
            rc_file="~/.bashrc"
            activation_cmd='eval "$(mise activate bash)"'
            ;;
        */fish)
            shell_name="fish"
            rc_file="~/.config/fish/config.fish"
            activation_cmd='mise activate fish | source'
            ;;
        *)
            shell_name="your shell"
            rc_file="your shell's rc file"
            activation_cmd='eval "$(mise activate <SHELL>)"'
            ;;
    esac

    echo -e "   Add this line to ${CYAN}${rc_file}${NC}:"
    echo ""
    echo -e "   ${GREEN}${activation_cmd}${NC}"
    echo ""
    info "Then restart your terminal or run:"
    echo ""
    echo -e "   ${GREEN}source ${rc_file}${NC}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Razd CLI Installer               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    install_mise
    install_razd
    print_activation_instructions

    echo ""
    success "Installation complete!"
    echo ""
    info "Run 'razd --help' to get started."
    echo ""
}

main "$@"
