# Specification: MSI Installer

## Overview

Windows MSI package for enterprise deployment of razd CLI via Group Policy, SCCM, Intune, or manual installation.

## ADDED Requirements

### Requirement: MSI Package Generation

The system MUST generate a valid Windows Installer (.msi) package via GitHub Actions.

#### Scenario: Build MSI on tag push

- **Given** a git tag matching `v*` is pushed
- **When** the `build-msi.yml` workflow runs
- **Then** a signed MSI file is attached to the GitHub Release

#### Scenario: Build MSI for testing

- **Given** a push to `main` branch modifies MSI-related files
- **When** the `build-msi.yml` workflow runs
- **Then** the MSI is uploaded as a workflow artifact (not attached to release)

---

### Requirement: Silent Installation Support

The MSI MUST support silent installation for automated deployment.

#### Scenario: Silent install via msiexec

- **Given** an administrator runs `msiexec /i razd-installer.msi /qn`
- **When** the installation completes
- **Then** razd CLI is installed and available in PATH
- **And** no user interaction prompts are displayed

#### Scenario: Silent install with logging

- **Given** an administrator runs `msiexec /i razd-installer.msi /qn /l*v install.log`
- **When** the installation completes
- **Then** a detailed log file is created at `install.log`

---

### Requirement: Prerequisite Installation

The MSI MUST install prerequisites (mise) if not already present.

#### Scenario: Fresh Windows installation

- **Given** mise is not installed on the system
- **When** the MSI is executed
- **Then** mise is installed automatically
- **And** razd is installed via mise
- **And** PATH is updated for the current user

#### Scenario: Existing mise installation

- **Given** mise is already installed on the system
- **When** the MSI is executed
- **Then** mise installation is skipped
- **And** razd is installed or updated via mise

---

### Requirement: Upgrade Support

The MSI MUST support clean upgrades from previous versions.

#### Scenario: Upgrade from older version

- **Given** razd-installer v1.0.0 is installed
- **When** the user installs razd-installer v2.0.0
- **Then** the old version is removed automatically
- **And** the new version is installed
- **And** user configuration is preserved

#### Scenario: Downgrade prevention

- **Given** razd-installer v2.0.0 is installed
- **When** the user attempts to install v1.0.0
- **Then** the installation fails with an error message
- **And** the existing installation remains unchanged

---

### Requirement: Uninstallation

The MSI MUST support standard Windows uninstallation with configurable cleanup.

#### Scenario: Uninstall via Control Panel (default)

- **Given** razd-installer is installed
- **When** the user uninstalls via "Add or Remove Programs"
- **And** leaves "Delete mise" checkbox unchecked
- **Then** razd is removed via `mise uninstall razd`
- **And** razd plugin is removed from mise
- **And** mise remains installed
- **And** MSI registration is removed

#### Scenario: Uninstall with mise removal

- **Given** razd-installer is installed
- **When** the user uninstalls via "Add or Remove Programs"
- **And** checks the "Delete mise" checkbox
- **Then** razd is removed
- **And** mise is completely uninstalled
- **And** mise directories are removed from PATH
- **And** MSI registration is removed

#### Scenario: Silent uninstall (razd only)

- **Given** razd-installer is installed
- **When** an administrator runs `msiexec /x razd-installer.msi /qn`
- **Then** razd is removed
- **And** mise remains installed

#### Scenario: Silent uninstall (razd and mise)

- **Given** razd-installer is installed
- **When** an administrator runs `msiexec /x razd-installer.msi /qn REMOVE_MISE=1`
- **Then** razd is removed
- **And** mise is completely uninstalled

---

## Technical Constraints

- WiX Toolset v4 or later
- Target Windows 10 version 1809 or later
- Requires administrator privileges for installation
- PowerShell 5.1 or later (built into Windows 10+)
