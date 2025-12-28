# Specification: PowerShell Installer

## ADDED Requirements

### Requirement: Mise Installation with Fallback

The installer SHALL install mise using winget as the primary method, with a direct download fallback.

#### Scenario: Winget available and succeeds

- **GIVEN** winget is available on the system
- **WHEN** the installer runs
- **THEN** `winget install jdx.mise` is executed
- **AND** mise is added to the current session PATH

#### Scenario: Winget fails or unavailable

- **GIVEN** winget is not available or the install command fails
- **WHEN** the installer runs
- **THEN** the installer downloads mise directly from GitHub releases
- **AND** extracts it to `$env:LOCALAPPDATA\mise\bin`
- **AND** adds the path to both session and persistent User PATH

#### Scenario: Mise already installed

- **GIVEN** mise is already installed
- **WHEN** the installer runs
- **THEN** the mise installation step is skipped

---

### Requirement: Architecture Detection

The installer SHALL detect system architecture for direct downloads.

#### Scenario: x64 architecture

- **GIVEN** the system architecture is x64
- **WHEN** downloading mise directly
- **THEN** the `mise-*-windows-x64.zip` file is downloaded

#### Scenario: ARM64 architecture

- **GIVEN** the system architecture is ARM64
- **WHEN** downloading mise directly
- **THEN** the `mise-*-windows-arm64.zip` file is downloaded

---

### Requirement: Dynamic Version Resolution

The installer SHALL NOT hardcode mise version numbers; it SHALL use the GitHub releases latest pattern.

#### Scenario: Download latest mise

- **WHEN** downloading mise directly
- **THEN** the URL pattern `https://github.com/jdx/mise/releases/latest/download/mise-*-windows-<arch>.zip` is used

---

### Requirement: Razd Installation via Mise

The installer SHALL install razd using mise's global tool management.

#### Scenario: Install razd

- **GIVEN** mise is available
- **WHEN** the installer runs
- **THEN** `mise use -g razd -y` is executed
- **AND** errors are handled gracefully with clear messages

---

### Requirement: PATH Management

The installer SHALL manage PATH for both the current session and persistent user environment.

#### Scenario: Session PATH

- **WHEN** mise is installed via direct download
- **THEN** `$env:Path` is updated to include the mise bin directory immediately

#### Scenario: Persistent PATH

- **WHEN** mise is installed via direct download
- **THEN** the User environment variable PATH is updated persistently
- **AND** future PowerShell sessions will have mise available

---

### Requirement: Colored Output

The installer SHALL use `Write-Host` with colors to distinguish message types.

#### Scenario: Step message

- **WHEN** the installer begins a major step
- **THEN** a colored message is printed (e.g., Cyan for steps)

#### Scenario: Error message

- **WHEN** an error occurs
- **THEN** a red-colored error message is printed

#### Scenario: Success message

- **WHEN** installation completes
- **THEN** a green-colored success message is printed

---

### Requirement: Cleanup

The installer SHALL clean up temporary files after installation.

#### Scenario: Direct download cleanup

- **GIVEN** mise was installed via direct ZIP download
- **WHEN** installation completes (success or failure)
- **THEN** the downloaded ZIP file is deleted
- **AND** any temporary extraction folders are removed

---

### Requirement: Version Environment Variable

The installer SHALL respect the `RAZD_VERSION` environment variable.

#### Scenario: Default version

- **GIVEN** `$env:RAZD_VERSION` is not set
- **WHEN** the installer runs
- **THEN** the latest version of razd is installed

#### Scenario: Explicit version

- **GIVEN** `$env:RAZD_VERSION = "0.5.0"`
- **WHEN** the installer runs
- **THEN** razd version 0.5.0 is installed
