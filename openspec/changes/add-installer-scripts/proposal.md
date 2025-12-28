# Change: Add cross-platform installation scripts for razd CLI

## Why

Users need a frictionless, one-command installation experience for the `razd` CLI tool. The installation process must handle the prerequisite toolchain (`mise`) automatically, work across Linux, macOS, and Windows, and provide clear feedback during execution.

## What Changes

- **NEW** `install.sh` — Bash/POSIX installer for Linux and macOS
- **NEW** `install.ps1` — PowerShell installer for Windows
- **MODIFIED** `README.md` — Add one-liner installation commands

## Impact

- Affected specs: `installer-shell`, `installer-powershell` (new capabilities)
- Affected code: Root-level scripts `install.sh`, `install.ps1`, and `README.md`

## Design Decisions

### Mise as prerequisite

`razd` depends on `mise` for version management and activation. Both scripts will:

1. Detect if `mise` is already installed
2. Install `mise` if missing (idempotently)
3. Temporarily inject `mise` into the current session PATH so the script can continue without a shell restart
4. Print post-install instructions for permanent shell activation

### Installation strategy

| Platform    | Primary method                | Fallback                                 |
| ----------- | ----------------------------- | ---------------------------------------- |
| Linux/macOS | `curl https://mise.run \| sh` | —                                        |
| Windows     | `winget install jdx.mise`     | Direct ZIP download from GitHub releases |

### Versioning

Both scripts respect `RAZD_VERSION` environment variable (default: `latest`).

### UX Principles

- ANSI colors for step/info/success/error messaging
- Idempotent — safe to re-run
- Minimal dependencies (curl/sh for Unix; PowerShell 5.1+ for Windows)
- Clean up temporary files on Windows
