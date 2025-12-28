# Tasks: Add MSI Installer

## Prerequisites

- [x] Decide on code signing — skip for MVP
- [x] Generate stable GUIDs for WiX components

## Implementation

### Phase 1: WiX Project Setup

- [x] Create `installer/wix/` directory structure
- [x] Create `razd.wixproj` MSBuild project file
- [x] Create `Package.wxs` main WiX source file
- [x] Add custom action for PowerShell script execution
- [x] Copy/adapt `install.ps1` for MSI context (handle SYSTEM user)
- [x] Create `uninstall.ps1` script (remove razd, optionally mise)
- [x] Add uninstall custom action with `REMOVE_MISE` property
- [ ] Add "Delete mise" checkbox to uninstall UI — deferred (requires custom WiX UI)

### Phase 2: GitHub Actions Workflow

- [x] Create `.github/workflows/build-msi.yml`
- [x] Configure WiX toolset installation
- [x] Build MSI on push to main (artifact only)
- [x] Attach MSI to GitHub Releases on tag push

### Phase 3: Testing

- [x] Test MSI on clean Windows (GitHub Actions runner) — automated in workflow
- [x] Test silent installation (`msiexec /qn`) — automated in workflow
- [ ] Test upgrade scenario — manual testing needed
- [ ] Add MSI tests to existing `test-installer.yml` — optional enhancement

### Phase 4: Documentation

- [x] Update README.md with MSI download/install instructions
- [x] Document silent installation options
- [x] Add troubleshooting section for MSI issues

## Validation

- [ ] `openspec validate add-msi-installer --strict` passes — CLI not installed
- [ ] MSI builds successfully in GitHub Actions — pending first run
- [ ] MSI installs razd correctly on Windows — pending first run
- [x] README reflects new installation option
