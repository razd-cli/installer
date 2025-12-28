# Specification: Shell Installer

## ADDED Requirements

### Requirement: Idempotent Installation

The installer SHALL run safely multiple times without causing errors or duplicate installations.

#### Scenario: First-time installation

- **GIVEN** a system without mise or razd installed
- **WHEN** the user runs `install.sh`
- **THEN** mise is installed
- **AND** razd is installed via mise
- **AND** a success message is displayed

#### Scenario: Re-running installer with everything installed

- **GIVEN** mise and razd are already installed
- **WHEN** the user runs `install.sh` again
- **THEN** the script detects existing installations
- **AND** skips redundant install steps
- **AND** exits successfully without errors

---

### Requirement: Mise Installation

The installer SHALL install mise if it is not already present on the system.

#### Scenario: Mise not installed

- **GIVEN** mise is not installed
- **WHEN** the installer runs
- **THEN** mise is installed using `curl https://mise.run | sh`
- **AND** mise is added to the current session PATH immediately

#### Scenario: Mise already installed

- **GIVEN** mise is already installed and on PATH
- **WHEN** the installer runs
- **THEN** the mise installation step is skipped
- **AND** an info message indicates mise is already available

---

### Requirement: Razd Installation via Mise

The installer SHALL install razd using mise's global tool management.

#### Scenario: Install latest version

- **GIVEN** mise is available
- **AND** `RAZD_VERSION` is not set or set to "latest"
- **WHEN** the installer runs
- **THEN** `mise use -g razd@latest` is executed

#### Scenario: Install specific version

- **GIVEN** mise is available
- **AND** `RAZD_VERSION` is set to "1.2.3"
- **WHEN** the installer runs
- **THEN** `mise use -g razd@1.2.3` is executed

---

### Requirement: Colored Output

The installer SHALL use ANSI colors to distinguish message types.

#### Scenario: Step message

- **WHEN** the installer begins a major step
- **THEN** a blue-colored message is printed with step description

#### Scenario: Error message

- **WHEN** an error occurs
- **THEN** a red-colored error message is printed
- **AND** the script exits with non-zero status

#### Scenario: Success message

- **WHEN** installation completes successfully
- **THEN** a green-colored success message is printed

---

### Requirement: Shell Activation Instructions

The installer SHALL detect the user's shell and print the correct command to permanently activate mise.

#### Scenario: Zsh user

- **GIVEN** the user's `$SHELL` is `/bin/zsh`
- **WHEN** installation completes
- **THEN** the installer prints instructions to add mise activation to `~/.zshrc`

#### Scenario: Bash user

- **GIVEN** the user's `$SHELL` is `/bin/bash`
- **WHEN** installation completes
- **THEN** the installer prints instructions to add mise activation to `~/.bashrc`

#### Scenario: Fish user

- **GIVEN** the user's `$SHELL` is `/usr/bin/fish`
- **WHEN** installation completes
- **THEN** the installer prints instructions to add mise activation to `~/.config/fish/config.fish`

---

### Requirement: Version Environment Variable

The installer SHALL respect the `RAZD_VERSION` environment variable.

#### Scenario: Default version

- **GIVEN** `RAZD_VERSION` is not set
- **WHEN** the installer runs
- **THEN** the latest version of razd is installed

#### Scenario: Explicit version

- **GIVEN** `RAZD_VERSION=0.5.0`
- **WHEN** the installer runs
- **THEN** razd version 0.5.0 is installed
