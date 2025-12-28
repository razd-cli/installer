# Specification: GitHub Pages

## ADDED Requirements

### Requirement: Landing Page

The system SHALL serve a landing page at the root URL that displays installation instructions for all supported platforms.

#### Scenario: User visits landing page

- **GIVEN** a user navigates to `https://get.razd-cli.com/`
- **WHEN** the page loads
- **THEN** the user sees installation commands for Linux/macOS and Windows
- **AND** each command has a copy-to-clipboard button
- **AND** the page is responsive on mobile devices

#### Scenario: User copies install command

- **GIVEN** a user is on the landing page
- **WHEN** the user clicks the copy button next to an install command
- **THEN** the command is copied to the clipboard
- **AND** visual feedback indicates successful copy

---

### Requirement: Shell Installer Endpoint

The system SHALL serve the shell installation script at `/install.sh`.

#### Scenario: curl downloads shell script

- **GIVEN** a Unix-like system with curl installed
- **WHEN** the user runs `curl -fsSL https://get.razd-cli.com/install.sh`
- **THEN** the complete shell script content is returned
- **AND** the script is executable when piped to bash

#### Scenario: Script content matches source

- **GIVEN** the `install.sh` file in repository root is updated
- **WHEN** the deploy workflow completes
- **THEN** `https://get.razd-cli.com/install.sh` returns identical content

---

### Requirement: PowerShell Installer Endpoint

The system SHALL serve the PowerShell installation script at `/install.ps1`.

#### Scenario: irm downloads PowerShell script

- **GIVEN** a Windows system with PowerShell
- **WHEN** the user runs `irm https://get.razd-cli.com/install.ps1`
- **THEN** the complete PowerShell script content is returned
- **AND** the script executes correctly when piped to `iex`

#### Scenario: Script content matches source

- **GIVEN** the `install.ps1` file in repository root is updated
- **WHEN** the deploy workflow completes
- **THEN** `https://get.razd-cli.com/install.ps1` returns identical content

---

### Requirement: HTTPS Enforcement

The system SHALL enforce HTTPS for all requests.

#### Scenario: HTTP request redirects to HTTPS

- **GIVEN** a user attempts to access `http://get.razd-cli.com/`
- **WHEN** the request is made
- **THEN** the user is redirected to `https://get.razd-cli.com/`

---

### Requirement: Automatic Deployment

The system SHALL automatically deploy updated scripts to GitHub Pages when source files change.

#### Scenario: Shell script updated

- **GIVEN** a commit modifies `install.sh` in repository root
- **WHEN** the commit is pushed to `main` branch
- **THEN** GitHub Action builds deployment artifact with updated script
- **AND** deploys to GitHub Pages

#### Scenario: PowerShell script updated

- **GIVEN** a commit modifies `install.ps1` in repository root
- **WHEN** the commit is pushed to `main` branch
- **THEN** GitHub Action builds deployment artifact with updated script
- **AND** deploys to GitHub Pages

#### Scenario: Landing page updated

- **GIVEN** a commit modifies files in `docs/` folder
- **WHEN** the commit is pushed to `main` branch
- **THEN** GitHub Action deploys updated content to GitHub Pages
