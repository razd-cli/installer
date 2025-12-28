# Change: Add MSI installer built via GitHub Actions

## Why

Enterprise environments and IT administrators often require MSI packages for:

- Group Policy (GPO) software deployment
- SCCM/Intune distribution
- Standardized Windows software management
- Silent installation support (`msiexec /i razd.msi /qn`)

Currently, Windows users must run a PowerShell one-liner which may be blocked by execution policies in managed environments.

## What Changes

- **NEW** `installer/wix/` — WiX Toolset source files for MSI generation
- **NEW** `.github/workflows/build-msi.yml` — GitHub Actions workflow to build and publish MSI
- **MODIFIED** `README.md` — Add MSI download instructions
- **MODIFIED** GitHub Releases — Attach `razd-installer.msi` as release asset

## Impact

- Affected specs: `installer-msi` (new capability)
- Affected code: New `installer/wix/` directory, new workflow, README updates
- Dependencies: WiX Toolset v4+ (available in GitHub Actions Windows runners)

## Design Decisions

### WiX Toolset v4

WiX is the industry-standard open-source tool for creating MSI packages:

- Free and MIT licensed
- Native support in GitHub Actions (pre-installed on `windows-latest`)
- XML-based declarative configuration
- Supports Custom Actions for running PowerShell scripts

### MSI Installation Strategy

The MSI will be a **bootstrapper** that:

1. Extracts the embedded `install.ps1` script
2. Executes it with `ExecutionPolicy Bypass`
3. Reports success/failure to MSI engine

This approach:

- Reuses existing installation logic (DRY)
- Keeps MSI simple and maintainable
- Ensures consistency between script and MSI installations

### Silent Installation Support

```batch
# Silent install
msiexec /i razd-installer.msi /qn

# Silent install with logging
msiexec /i razd-installer.msi /qn /l*v install.log
```

### Release Workflow

| Trigger         | Action                                   |
| --------------- | ---------------------------------------- |
| Tag `v*` push   | Build MSI → Attach to GitHub Release     |
| Manual dispatch | Build MSI → Upload as artifact (testing) |

### File Naming

- `razd-installer-{version}-x64.msi` — 64-bit installer
- `razd-installer-{version}-arm64.msi` — ARM64 installer (future)

### Code Signing

MSI will NOT be code-signed (MVP decision):

- Reduces complexity and cost (certificates ~$200-500/year)
- Windows SmartScreen will show "Unknown publisher" warning — acceptable for open-source
- Can be added later if enterprise adoption requires it

### Uninstall Behavior

Uninstall will:

- **Always remove razd** — runs `mise uninstall razd` and removes razd plugin
- **Optionally remove mise** — checkbox "Delete mise" in uninstall dialog (default: unchecked)
- Remove Windows MSI registration

Silent uninstall options:

```batch
# Uninstall razd only (default)
msiexec /x razd-installer.msi /qn

# Uninstall razd AND mise
msiexec /x razd-installer.msi /qn REMOVE_MISE=1
```
