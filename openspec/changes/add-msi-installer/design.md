# Design: MSI Installer with WiX Toolset

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    MSI Package                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Embedded Files                                  │   │
│  │  └── install.ps1 (extracted to %TEMP%)          │   │
│  ├─────────────────────────────────────────────────┤   │
│  │  Custom Actions                                  │   │
│  │  └── Execute PowerShell script                  │   │
│  ├─────────────────────────────────────────────────┤   │
│  │  Deferred Execution (elevated)                  │   │
│  │  └── Runs with SYSTEM privileges               │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## WiX v4 Project Structure

```
installer/
└── wix/
    ├── razd.wixproj          # MSBuild project file
    ├── Package.wxs           # Main WiX source
    ├── install.ps1           # Symlink or copy of root install.ps1
    └── CustomActions.wxs     # PowerShell execution logic
```

## Key WiX Components

### Package.wxs (Main Configuration)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Package Name="Razd CLI"
           Manufacturer="Razd"
           Version="$(var.Version)"
           UpgradeCode="GUID-HERE"
           Scope="perMachine">

    <MajorUpgrade DowngradeErrorMessage="A newer version is installed." />

    <!-- Extract install.ps1 to temp directory -->
    <StandardDirectory Id="TempFolder">
      <Component Id="InstallScript" Guid="GUID-HERE">
        <File Id="InstallPs1" Source="install.ps1" />
      </Component>
    </StandardDirectory>

    <Feature Id="MainFeature" Level="1">
      <ComponentRef Id="InstallScript" />
    </Feature>
  </Package>
</Wix>
```

### Custom Action for PowerShell Execution

```xml
<CustomAction Id="RunInstallScript"
              Directory="TempFolder"
              ExeCommand="powershell.exe -ExecutionPolicy Bypass -NoProfile -File install.ps1"
              Execute="deferred"
              Impersonate="no"
              Return="check" />

<InstallExecuteSequence>
  <Custom Action="RunInstallScript" After="InstallFiles">
    NOT Installed
  </Custom>
</InstallExecuteSequence>
```

## GitHub Actions Workflow

### Build Steps

```yaml
jobs:
  build-msi:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup WiX
        run: dotnet tool install --global wix

      - name: Build MSI
        run: |
          cd installer/wix
          wix build -o razd-installer.msi -d Version=${{ github.ref_name }}

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: msi-installer
          path: installer/wix/razd-installer.msi
```

### Release Attachment

```yaml
- name: Attach to Release
  if: startsWith(github.ref, 'refs/tags/')
  uses: softprops/action-gh-release@v1
  with:
    files: installer/wix/razd-installer.msi
```

## Installation Flow

```
User runs: msiexec /i razd-installer.msi
                    │
                    ▼
┌─────────────────────────────────────┐
│ MSI Engine: InstallInitialize      │
│ - Check for previous version       │
│ - Request elevation (UAC)          │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│ MSI Engine: InstallFiles           │
│ - Extract install.ps1 to %TEMP%    │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│ Custom Action: RunInstallScript    │
│ - powershell -File install.ps1     │
│ - Installs mise (if needed)        │
│ - Installs razd via mise           │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│ MSI Engine: InstallFinalize        │
│ - Cleanup temp files               │
│ - Register uninstall               │
└─────────────────────────────────────┘
```

## Considerations

### Elevation

- MSI runs with `Scope="perMachine"` requiring admin rights
- Custom action runs as `SYSTEM` (Impersonate="no")
- install.ps1 modifications needed to handle SYSTEM context

### Error Handling

- Custom action returns exit code to MSI
- Non-zero exit = installation failed
- MSI performs automatic rollback

### Uninstallation

Uninstall behavior:

- **razd** — always removed via `mise uninstall razd` + `mise plugins uninstall razd`
- **mise** — removed only if user checks "Delete mise" checkbox (or passes `REMOVE_MISE=1` for silent)

#### Uninstall Custom Action

```xml
<!-- Uninstall script execution -->
<CustomAction Id="RunUninstallScript"
              Directory="TempFolder"
              ExeCommand="powershell.exe -ExecutionPolicy Bypass -NoProfile -File uninstall.ps1 -RemoveMise [REMOVE_MISE]"
              Execute="deferred"
              Impersonate="no"
              Return="check" />

<InstallExecuteSequence>
  <Custom Action="RunUninstallScript" Before="RemoveFiles">
    REMOVE~="ALL"
  </Custom>
</InstallExecuteSequence>
```

#### Uninstall Dialog (WiX UI)

```xml
<Property Id="REMOVE_MISE" Value="0" />
<Control Id="RemoveMiseCheckbox" Type="CheckBox" Property="REMOVE_MISE" CheckBoxValue="1">
  <Text>Also remove mise (version manager)</Text>
</Control>
```

### Testing

- Test on clean Windows VM
- Test upgrade scenario (v1 → v2)
- Test silent installation
- Test with/without internet connectivity
