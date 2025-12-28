# Tasks: Add Installer Scripts

## 1. Shell Installer (`install.sh`)

- [x] Create `install.sh` with shebang and strict mode
- [x] Implement color output functions (step, info, success, error)
- [x] Add mise detection and installation logic
- [x] Add temporary PATH injection for mise
- [x] Add razd installation via `mise use -g`
- [x] Implement shell detection for activation instructions
- [x] Support `RAZD_VERSION` environment variable
- [x] Add idempotency checks (skip if already installed)
- [ ] Test on bash and zsh

## 2. PowerShell Installer (`install.ps1`)

- [x] Create `install.ps1` with strict error handling
- [x] Implement colored output functions
- [x] Add winget-based mise installation (primary)
- [x] Add direct ZIP download fallback with architecture detection
- [x] Add PATH management (session + persistent)
- [x] Add razd installation via `mise use -g`
- [x] Support `RAZD_VERSION` environment variable
- [x] Clean up temporary files
- [ ] Test on Windows PowerShell 5.1 and PowerShell 7

## 3. Documentation

- [x] Update `README.md` with one-liner install commands
- [x] Add usage examples for version pinning
- [x] Document prerequisites and supported platforms

## 4. Validation

- [ ] Verify scripts are idempotent (run twice without errors)
- [ ] Verify error messages are clear and actionable
- [ ] Verify activation instructions are correct per shell
