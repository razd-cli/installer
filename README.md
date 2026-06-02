# Razd CLI Installer

Cross-platform installation scripts for the [razd](https://github.com/razd-cli/razd) CLI tool.

## Quick Install

### Linux / macOS

```bash
curl -fsSL https://get.razd-cli.com/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://get.razd-cli.com/install.ps1 | iex
```

> **Alternative:** If the short URL is unavailable, use the raw GitHub URLs:
>
> - Linux/macOS: `curl -fsSL https://raw.githubusercontent.com/razd-cli/installer/main/install.sh | bash`
> - Windows: `irm https://raw.githubusercontent.com/razd-cli/installer/main/install.ps1 | iex`

## What It Does

The installer will:

1. **Detect platform** — Automatically determine your OS and architecture
2. **Download razd** — Fetch the binary from [GitHub Releases](https://github.com/razd-cli/razd/releases)
3. **Install to PATH** — Place the binary in `~/.local/bin` (Linux/macOS) or `%LOCALAPPDATA%\razd` (Windows)
4. **Configure PATH** — Offer to add the install directory to your shell's rc file if needed

## List Available Versions

See all releases on GitHub before installing:

### Linux / macOS

```bash
./install.sh --list
./install.sh --list 50
```

### Windows (PowerShell)

```powershell
.\install.ps1 -List
.\install.ps1 -List -ListCount 50
```

## Install a Specific Version

### Linux / macOS

```bash
# Using environment variable (works with piped curl)
RAZD_VERSION=1.0.0 curl -fsSL https://get.razd-cli.com/install.sh | bash

# Using command-line flag (when running directly)
./install.sh --version 1.0.0
./install.sh -v 1.0.0-dev.0
```

### Windows (PowerShell)

```powershell
# Using environment variable
$env:RAZD_VERSION = "1.0.0"; irm https://get.razd-cli.com/install.ps1 | iex

# Using parameter (when running directly)
.\install.ps1 -Version 1.0.0
.\install.ps1 -Version 1.0.0-dev.0
```

Pre-release versions (containing a `-` suffix like `1.0.0-dev.0`) are marked with a warning during installation.

## Custom Install Location

### Linux / macOS

```bash
RAZD_INSTALL_DIR=/usr/local/bin curl -fsSL https://get.razd-cli.com/install.sh | bash
# or
./install.sh --dir /usr/local/bin
```

### Windows (PowerShell)

```powershell
$env:RAZD_INSTALL_DIR = "C:\Tools\razd"; irm https://get.razd-cli.com/install.ps1 | iex
# or
.\install.ps1 -InstallDir "C:\Tools\razd"
```

## CLI Reference

### install.sh

```
Usage:
  ./install.sh [OPTIONS]

Options:
  -v, --version VERSION  Install specific version (default: latest)
  -l, --list [N]         List available versions (default: 20)
  -d, --dir DIR          Installation directory (default: ~/.local/bin)
  -h, --help             Show help message

Environment Variables:
  RAZD_VERSION           Version to install (default: latest)
  RAZD_INSTALL_DIR       Installation directory
  GITHUB_TOKEN            GitHub token to avoid rate limiting
```

### install.ps1

```
Options:
  -Version VERSION    Install specific version (default: latest)
  -List               List available versions
  -ListCount N        Number of versions to list (default: 20)
  -InstallDir DIR     Installation directory
  -Help               Show help message

Environment Variables:
  RAZD_VERSION         Version to install
  RAZD_INSTALL_DIR     Installation directory
  GITHUB_TOKEN          GitHub token to avoid rate limiting
```

## Prerequisites

### Linux / macOS

- `curl` (pre-installed on most systems)
- `tar` (pre-installed on most systems)

### Windows

- PowerShell 5.1 or later (pre-installed on Windows 10+)

## Supported Platforms

| Platform | Architecture | Status    |
| -------- | ------------ | --------- |
| Linux    | x64, arm64   | Supported |
| macOS    | x64, arm64   | Supported |
| Windows  | x64, arm64   | Supported |

## Troubleshooting

### "razd: command not found" after installation

1. Make sure the install directory is in your PATH
2. Restart your terminal or source your rc file
3. Check the install location: `~/.local/bin/razd` (Linux/macOS) or `%LOCALAPPDATA%\razd\razd.exe` (Windows)

### PATH not updated

The installer offers to add the install directory to your shell's rc file. If you skipped this, you can add it manually:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### GitHub API rate limiting

If you hit rate limits, set the `GITHUB_TOKEN` environment variable:

```bash
GITHUB_TOKEN=ghp_xxx curl -fsSL https://get.razd-cli.com/install.sh | bash
```

## License

MIT