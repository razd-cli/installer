#!/usr/bin/env bash
#
# Razd CLI Installer for Linux/macOS
# https://github.com/razd-cli/razd
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/razd-cli/installer/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/razd-cli/installer/main/install.sh | bash -s -- --version 1.0.0
#   ./install.sh --list
#   ./install.sh --version 1.0.0-dev.0
#
# Environment Variables:
#   RAZD_VERSION    - Version to install (default: "latest")
#   RAZD_INSTALL_DIR - Installation directory (default: ~/.local/bin)
#   GITHUB_TOKEN     - GitHub token to avoid rate limiting
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
BOLD='\033[1m'
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

github_api_get() {
    local endpoint="$1"
    local url="https://api.github.com${endpoint}"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Authorization: token ${GITHUB_TOKEN}" "$url" 2>/dev/null
    else
        curl -fsSL "$url" 2>/dev/null
    fi
}

get_latest_version() {
    local version
    version=$(github_api_get "/repos/${GITHUB_REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/')
    echo "$version"
}

list_versions() {
    local limit="${1:-20}"
    step "Fetching available razd versions..."
    echo ""

    local json
    json=$(github_api_get "/repos/${GITHUB_REPO}/releases?per_page=${limit}")
    if [ -z "$json" ]; then
        error "Could not fetch releases from GitHub API"
    fi

    echo -e "  ${BOLD}Available versions:${NC}"
    echo ""

    echo "$json" | grep -E '"(tag_name)"|"(prerelease)"' | while read -r tag_line; do
        read -r pre_line
        local tag=$(echo "$tag_line" | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/')
        local pre=$(echo "$pre_line" | sed -E 's/.*"prerelease": *(true|false).*/\1/')
        local label=""
        if [ "$pre" = "true" ]; then
            label=" (pre-release)"
        fi
        echo -e "  ${GREEN}${tag}${NC}${label}"
    done

    echo ""
    info "Install a specific version:"
    echo "" >&2
    echo -e "  ${CYAN}RAZD_VERSION=1.0.0${NC} ./install.sh" >&2
    echo -e "  ${CYAN}./install.sh --version 1.0.0-dev.0${NC}" >&2
    echo ""
}

resolve_version() {
    local version_input="$1"
    if [ "$version_input" = "latest" ]; then
        info "Fetching latest razd version..."
        local version
        version=$(get_latest_version)
        if [ -z "$version" ]; then
            error "Could not determine latest version. Please specify a version with --version or RAZD_VERSION."
        fi
        echo "$version"
    else
        echo "$version_input"
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
    local version_input="$1"
    step "Installing razd..."

    local version
    version=$(resolve_version "$version_input")
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
# Help
# =============================================================================

show_help() {
    echo ""
    echo -e "${BOLD}Razd CLI Installer${NC}"
    echo ""
    echo "Usage:"
    echo "  ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION  Install specific version (default: latest)"
    echo "  -l, --list [N]        List available versions (default: 20)"
    echo "  -d, --dir DIR         Installation directory (default: ~/.local/bin)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  RAZD_VERSION          Version to install (default: latest)"
    echo "  RAZD_INSTALL_DIR      Installation directory (default: ~/.local/bin)"
    echo "  GITHUB_TOKEN          GitHub token to avoid rate limiting"
    echo ""
    echo "Examples:"
    echo "  ./install.sh                          # Install latest version"
    echo "  ./install.sh --version 1.0.0          # Install specific version"
    echo "  ./install.sh --version 1.0.0-dev.0    # Install pre-release"
    echo "  ./install.sh --list                    # List available versions"
    echo "  ./install.sh --list 50                 # List up to 50 versions"
    echo ""
    echo "Piped usage:"
    echo "  curl -fsSL <url>/install.sh | bash"
    echo "  RAZD_VERSION=1.0.0 curl -fsSL <url>/install.sh | bash"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    local version="${RAZD_VERSION}"
    local action="install"

    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--version)
                shift
                if [ $# -eq 0 ]; then
                    error "Missing argument for --version"
                fi
                version="$1"
                shift
                ;;
            -l|--list)
                local list_count="20"
                shift
                if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                    list_count="$1"
                    shift
                fi
                action="list"
                list_versions "$list_count"
                exit 0
                ;;
            -d|--dir)
                shift
                if [ $# -eq 0 ]; then
                    error "Missing argument for --dir"
                fi
                RAZD_INSTALL_DIR="$1"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1. Use --help for usage."
                ;;
        esac
    done

    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Razd CLI Installer               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    if ! command_exists curl; then
        error "curl is required but not installed. Please install curl and try again."
    fi

    install_razd "${version}"

    echo ""
    success "Installation complete!"
    echo ""
    info "Run 'razd --help' to get started."
    echo ""
}

main "$@"