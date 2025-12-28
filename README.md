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

### Windows (MSI Installer)

For enterprise environments or if you prefer a traditional installer:

1. Download the latest MSI from [GitHub Releases](https://github.com/razd-cli/installer/releases)
2. Run the installer or use silent installation:

```batch
msiexec /i razd-installer-x64.msi /qn
```

> **Alternative:** If the short URL is unavailable, use the raw GitHub URLs:
>
> - Linux/macOS: `curl -fsSL https://raw.githubusercontent.com/razd-cli/installer/main/install.sh | bash`
> - Windows: `irm https://raw.githubusercontent.com/razd-cli/installer/main/install.ps1 | iex`

## What It Does

The installer will:

1. **Check for mise** — [mise](https://mise.jdx.dev) is required to manage razd versions
2. **Install mise** — If not already installed (via `curl https://mise.run | sh` on Unix, or `winget`/direct download on Windows)
3. **Install razd** — Using `mise use -g razd@latest`
4. **Print activation instructions** — Shows the command to add to your shell's rc file

## Install a Specific Version

Set the `RAZD_VERSION` environment variable before running the installer:

### Linux / macOS

```bash
RAZD_VERSION=1.0.0 curl -fsSL https://get.razd-cli.com/install.sh | bash
```

### Windows (PowerShell)

```powershell
$env:RAZD_VERSION = "1.0.0"; irm https://get.razd-cli.com/install.ps1 | iex
```

## Prerequisites

### Linux / macOS

- `curl` (pre-installed on most systems)
- `bash` or compatible shell

### Windows

- PowerShell 5.1 or later (pre-installed on Windows 10+)
- Optional: `winget` for preferred mise installation method

## Supported Platforms

| Platform | Architecture | Status       |
| -------- | ------------ | ------------ |
| Linux    | x64, arm64   | ✅ Supported |
| macOS    | x64, arm64   | ✅ Supported |
| Windows  | x64, arm64   | ✅ Supported |

## Post-Installation

After installation, you need to activate mise in your shell for razd to work.

### Bash

Add to `~/.bashrc`:

```bash
eval "$(mise activate bash)"
```

### Zsh

Add to `~/.zshrc`:

```bash
eval "$(mise activate zsh)"
```

### Fish

Add to `~/.config/fish/config.fish`:

```fish
mise activate fish | source
```

### PowerShell

Add to your `$PROFILE`:

```powershell
mise activate pwsh | Invoke-Expression
```

## Troubleshooting

### "razd: command not found" after installation

1. Make sure you've added the mise activation line to your shell's rc file
2. Restart your terminal or source your rc file
3. Run `mise doctor` to diagnose issues

### mise not found after installation

The installer adds mise to your PATH, but you may need to restart your terminal for changes to take effect.

## MSI Installer Options

### Silent Installation

```batch
# Install silently
msiexec /i razd-installer-x64.msi /qn

# Install with logging
msiexec /i razd-installer-x64.msi /qn /l*v install.log
```

### Uninstallation

```batch
# Uninstall (keeps mise installed)
msiexec /x razd-installer-x64.msi /qn

# Uninstall and remove mise
msiexec /x razd-installer-x64.msi /qn REMOVE_MISE=1
```

## License

MIT
