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

## Install a Specific Version

Set the `RAZD_VERSION` environment variable before running the installer:

### Linux / macOS

```bash
RAZD_VERSION=1.0.0 curl -fsSL https://get.razd-cli.com/install.sh | bash
```

### Install a pre-release version

```bash
RAZD_VERSION=1.0.0-dev.0 curl -fsSL https://get.razd-cli.com/install.sh | bash
```

### Windows (PowerShell)

```powershell
$env:RAZD_VERSION = "1.0.0"; irm https://get.razd-cli.com/install.ps1 | iex
```

## Custom Install Location

Set the `RAZD_INSTALL_DIR` environment variable:

### Linux / macOS

```bash
RAZD_INSTALL_DIR=/usr/local/bin curl -fsSL https://get.razd-cli.com/install.sh | bash
```

### Windows (PowerShell)

```powershell
$env:RAZD_INSTALL_DIR = "C:\Tools\razd"; irm https://get.razd-cli.com/install.ps1 | iex
```

## Prerequisites

### Linux / macOS

- `curl` (pre-installed on most systems)
- `tar` (pre-installed on most systems)

### Windows

- PowerShell 5.1 or later (pre-installed on Windows 10+)

## Supported Platforms

| Platform | Architecture | Status       |
| -------- | ------------ | ------------ |
| Linux    | x64, arm64   | Supported    |
| macOS    | x64, arm64   | Supported    |
| Windows  | x64, arm64   | Supported    |

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

## License

MIT