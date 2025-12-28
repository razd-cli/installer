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

# razd plugin for mise
RAZD_PLUGIN_URL="https://github.com/razd-cli/vfox-plugin-razd"

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

install_razd_plugin() {
    step "Installing razd plugin..."

    # Check if plugin is already installed
    if mise plugin list 2>/dev/null | grep -q "^razd"; then
        success "razd plugin is already installed"
        return 0
    fi

    info "Adding razd plugin from $RAZD_PLUGIN_URL"

    if ! mise plugin install razd "$RAZD_PLUGIN_URL"; then
        error "Failed to install razd plugin. Please check the output above."
    fi

    success "razd plugin installed successfully"
}

install_razd() {
    step "Installing razd..."

    ensure_mise_activated
    install_razd_plugin

    local version_arg=""
    if [ "$RAZD_VERSION" = "latest" ]; then
        version_arg="razd@latest"
    else
        version_arg="razd@${RAZD_VERSION}"
    fi

    info "Installing razd version: $RAZD_VERSION"

    if ! mise use -g "$version_arg" -y; then
        error "Failed to install razd. Please check the output above."
    fi

    success "razd installed successfully"
}

# =============================================================================
# Shell Activation Instructions
# =============================================================================

get_shell_config() {
    # Detect shell and return rc_file and activation_cmd
    case "${SHELL:-}" in
        */zsh)
            DETECTED_SHELL="zsh"
            RC_FILE="$HOME/.zshrc"
            ACTIVATION_CMD='eval "$(mise activate zsh)"'
            ;;
        */bash)
            DETECTED_SHELL="bash"
            RC_FILE="$HOME/.bashrc"
            ACTIVATION_CMD='eval "$(mise activate bash)"'
            ;;
        */fish)
            DETECTED_SHELL="fish"
            RC_FILE="$HOME/.config/fish/config.fish"
            ACTIVATION_CMD='mise activate fish | source'
            ;;
        *)
            DETECTED_SHELL=""
            RC_FILE=""
            ACTIVATION_CMD=""
            ;;
    esac
}

check_activation_exists() {
    # Check if mise activation is already in the rc file
    if [ -n "$RC_FILE" ] && [ -f "$RC_FILE" ]; then
        if grep -q "mise activate" "$RC_FILE" 2>/dev/null; then
            return 0  # Already exists
        fi
    fi
    return 1  # Not found
}

prompt_add_to_rc() {
    get_shell_config

    if [ -z "$DETECTED_SHELL" ]; then
        info "Could not detect your shell. Please manually add mise activation to your shell's rc file."
        return
    fi

    # Check if already configured
    if check_activation_exists; then
        success "mise activation already configured in $RC_FILE"
        return
    fi

    echo ""
    info "To use razd, mise must be activated in your shell."
    echo ""

    # Check if running interactively
    if [ -t 0 ]; then
        # Interactive mode - ask user
        echo -e "   ${CYAN}Add mise activation to ${RC_FILE}?${NC} [Y/n] "
        read -r response
        case "$response" in
            [nN][oO]|[nN])
                info "Skipped. You can manually add this line to $RC_FILE:"
                echo ""
                echo -e "   ${GREEN}${ACTIVATION_CMD}${NC}"
                echo ""
                ;;
            *)
                # Add to rc file
                echo "" >> "$RC_FILE"
                echo "# mise activation (added by razd installer)" >> "$RC_FILE"
                echo "$ACTIVATION_CMD" >> "$RC_FILE"
                success "Added mise activation to $RC_FILE"
                echo ""
                info "Restart your terminal or run:"
                echo ""
                echo -e "   ${GREEN}source $RC_FILE${NC}"
                echo ""
                ;;
        esac
    else
        # Non-interactive mode (piped) - print instructions
        info "Running in non-interactive mode. Please add this line to $RC_FILE:"
        echo ""
        echo -e "   ${GREEN}${ACTIVATION_CMD}${NC}"
        echo ""
        info "Or re-run the installer interactively:"
        echo ""
        echo -e "   ${GREEN}bash <(curl -fsSL https://raw.githubusercontent.com/razd-cli/installer/main/install.sh)${NC}"
        echo ""
    fi
}

print_activation_instructions() {
    step "Post-installation setup"
    prompt_add_to_rc
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
