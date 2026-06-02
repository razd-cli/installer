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
#   RAZD_INSTALL_DIR - Installation directory (default: ~/.local/bin)
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

RAZD_VERSION="${RAZD_VERSION:-latest}"
RAZD_INSTALL_DIR="${RAZD_INSTALL_DIR:-${HOME}/.local/bin}"
GITHUB_REPO="razd-cli/razd"
GITHUB_BASE_URL="https://github.com/${GITHUB_REPO}"

# =============================================================================
# Colors
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# =============================================================================
# Output Functions
# =============================================================================

step() {
    echo -e "${BLUE}==>${NC} ${BLUE}$1${NC}" >&2
}

info() {
    echo -e "${CYAN}   $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
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

detect_os() {
    local uname_out
    uname_out="$(uname -s)"
    case "${uname_out}" in
        Linux*) echo "linux" ;;
        Darwin*) echo "darwin" ;;
        *) error "Unsupported OS: ${uname_out}" ;;
    esac
}

detect_arch() {
    local uname_m
    uname_m="$(uname -m)"
    case "${uname_m}" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) error "Unsupported architecture: ${uname_m}" ;;
    esac
}

get_latest_version() {
    local auth_header=""
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        auth_header="Authorization: token $GITHUB_TOKEN"
    fi

    local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

    local version=""
    if [ -n "$auth_header" ]; then
        version=$(curl -fsSL -H "$auth_header" "$api_url" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/')
    else
        version=$(curl -fsSL "$api_url" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/')
    fi

    echo "$version"
}

resolve_version() {
    if [ "$RAZD_VERSION" = "latest" ]; then
        info "Fetching latest razd version..."
        local version
        version=$(get_latest_version)
        if [ -z "$version" ]; then
            error "Could not determine latest version. Please specify a version with RAZD_VERSION."
        fi
        echo "$version"
    else
        echo "$RAZD_VERSION"
    fi
}

get_tag() {
    local version="$1"
    echo "v${version}"
}

is_prerelease() {
    local version="$1"
    echo "$version" | grep -q '-' && echo "true" || echo "false"
}

get_download_url() {
    local tag="$1"
    local os="$2"
    local arch="$3"
    local ext="tar.gz"
    if [ "$os" = "windows" ]; then
        ext="zip"
    fi
    echo "${GITHUB_BASE_URL}/releases/download/${tag}/razd_${os}_${arch}.${ext}"
}

# =============================================================================
# Installation
# =============================================================================

install_razd() {
    step "Installing razd..."

    local version
    version=$(resolve_version)
    local tag
    tag=$(get_tag "$version")
    local prerelease
    prerelease=$(is_prerelease "$version")

    if [ "$prerelease" = "true" ]; then
        warn "Installing pre-release version: ${version}"
    fi

    info "Version: ${version} (tag: ${tag})"

    local os arch
    os=$(detect_os)
    arch=$(detect_arch)
    info "Platform: ${os}/${arch}"

    local download_url
    download_url=$(get_download_url "$tag" "$os" "$arch")
    info "Downloading from: ${download_url}"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local archive="${tmp_dir}/razd.tar.gz"

    if ! curl -fsSL --output "$archive" "$download_url"; then
        rm -rf "$tmp_dir"
        error "Failed to download razd ${version}. Check that the version exists at ${GITHUB_BASE_URL}/releases/tag/${tag}"
    fi

    info "Extracting..."
    tar -xzf "$archive" -C "$tmp_dir"

    local binary_name="razd"

    local razd_bin="${tmp_dir}/${binary_name}"
    if [ ! -f "$razd_bin" ]; then
        razd_bin=$(find "$tmp_dir" -name "${binary_name}" -type f | head -n 1)
    fi

    if [ ! -f "$razd_bin" ]; then
        rm -rf "$tmp_dir"
        error "Could not find razd binary in archive"
    fi

    chmod +x "$razd_bin"

    mkdir -p "$RAZD_INSTALL_DIR"

    local target="${RAZD_INSTALL_DIR}/${binary_name}"
    mv "$razd_bin" "$target"

    rm -rf "$tmp_dir"

    success "razd installed to ${target}"

    if ! command_exists razd; then
        if ! echo ":$PATH:" | grep -q ":${RAZD_INSTALL_DIR}:"; then
            warn "${RAZD_INSTALL_DIR} is not in your PATH"
            info "Add it to your PATH:"
            echo ""
            echo -e "   ${GREEN}export PATH=\"${RAZD_INSTALL_DIR}:\$PATH\"${NC}"
            echo ""

            add_to_path_if_interactive
        fi
    fi
}

add_to_path_if_interactive() {
    local rc_file=""
    local export_line="export PATH=\"${RAZD_INSTALL_DIR}:\$PATH\""

    case "${SHELL:-}" in
        */zsh)
            rc_file="$HOME/.zshrc"
            ;;
        */bash)
            rc_file="$HOME/.bashrc"
            ;;
        *)
            return
            ;;
    esac

    if [ -f "$rc_file" ] && grep -q "razd" "$rc_file" 2>/dev/null; then
        return
    fi

    if [ -t 0 ]; then
        echo -e "   ${CYAN}Add ${RAZD_INSTALL_DIR} to PATH in ${rc_file}?${NC} [Y/n] "
        read -r response
        case "$response" in
            [nN][oO]|[nN])
                info "Skipped. You can manually add this line to ${rc_file}:"
                echo ""
                echo -e "   ${GREEN}${export_line}${NC}"
                echo ""
                ;;
            *)
                echo "" >> "$rc_file"
                echo "# razd" >> "$rc_file"
                echo "$export_line" >> "$rc_file"
                success "Added ${RAZD_INSTALL_DIR} to PATH in ${rc_file}"
                echo ""
                info "Restart your terminal or run:"
                echo ""
                echo -e "   ${GREEN}source ${rc_file}${NC}"
                echo ""
                ;;
        esac
    else
        echo "" >> "$rc_file"
        echo "# razd" >> "$rc_file"
        echo "$export_line" >> "$rc_file"
        success "Added ${RAZD_INSTALL_DIR} to PATH in ${rc_file}"
    fi
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

    if ! command_exists curl; then
        error "curl is required but not installed. Please install curl and try again."
    fi

    install_razd

    echo ""
    success "Installation complete!"
    echo ""
    info "Run 'razd --help' to get started."
    echo ""
}

main "$@"