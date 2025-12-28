# Design: Cross-Platform Installation Scripts

## Architecture Overview

```
User runs one-liner
        │
        ▼
┌───────────────────┐
│  install.sh/.ps1  │
└────────┬──────────┘
         │
    ┌────┴────┐
    ▼         ▼
[Check mise] [Check razd]
    │             │
    ▼             ▼
Install if     Install via
missing        mise use -g
    │             │
    └──────┬──────┘
           ▼
   Print activation
   instructions
```

## Shell Script Design (`install.sh`)

### Portability

- Target: POSIX-compatible shells (sh, bash, zsh, dash)
- Shebang: `#!/usr/bin/env bash` (bash required for arrays and `[[`)
- Tested shells: bash 4+, zsh 5+, dash (for sourcing compatibility)

### Mise PATH Injection

After installing mise, it is not yet on PATH. The script will:

```bash
# Detect mise install location
MISE_BIN="${HOME}/.local/bin/mise"
if [ -f "$MISE_BIN" ]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi
```

### Shell Detection for Activation Instructions

```bash
case "$SHELL" in
  */zsh)  RC_FILE="~/.zshrc" ;;
  */bash) RC_FILE="~/.bashrc" ;;
  */fish) RC_FILE="~/.config/fish/config.fish" ;;
  *)      RC_FILE="your shell's rc file" ;;
esac
```

### Color Scheme

| Type    | Color | ANSI Code    |
| ------- | ----- | ------------ |
| Step    | Blue  | `\033[1;34m` |
| Info    | Cyan  | `\033[0;36m` |
| Success | Green | `\033[0;32m` |
| Error   | Red   | `\033[0;31m` |
| Reset   | —     | `\033[0m`    |

## PowerShell Script Design (`install.ps1`)

### Mise Installation Strategy

**Primary: winget**

```powershell
winget install jdx.mise --accept-package-agreements --accept-source-agreements
```

**Fallback: Direct download**

1. Detect architecture (`x64` vs `arm64`)
2. Download from `https://github.com/jdx/mise/releases/latest/download/mise-<version>-windows-<arch>.zip`
3. Extract to `$env:LOCALAPPDATA\mise\bin`
4. Add to User PATH persistently

### Architecture Detection

```powershell
$arch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq 'Arm64') { 'arm64' } else { 'x64' }
```

### PATH Management

```powershell
# Session PATH
$env:Path = "$env:LOCALAPPDATA\mise\bin;$env:Path"

# Persistent User PATH
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
```

### Error Handling

- `$ErrorActionPreference = 'Stop'` at script start
- try/catch blocks around external commands
- Clean up temp files in finally block

## Version Resolution

Both scripts support:

- `RAZD_VERSION=latest` (default) → `mise use -g razd@latest`
- `RAZD_VERSION=1.2.3` → `mise use -g razd@1.2.3`

## Future Considerations

### Registry vs Git-based install

If `razd` is not yet in the mise registry, the install command changes:

```bash
# Registry (preferred)
mise use -g razd@latest

# Git-based fallback
mise use -g cargo:razd-cli/razd@latest
```

Scripts include comments indicating how to switch.

### Uninstall

Not in scope for this change. Could be added as `uninstall.sh` / `uninstall.ps1` later.
