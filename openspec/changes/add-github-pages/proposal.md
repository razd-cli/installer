# Change: Add GitHub Pages for short installation URLs

## Why

Users need memorable, short installation commands. Currently, commands use long `raw.githubusercontent.com` URLs which are hard to type and remember. A custom domain `get.razd-cli.com` with GitHub Pages will provide clean, professional installation experience.

## What Changes

- **NEW** `docs/index.html` — Landing page with installation instructions
- **NEW** `docs/CNAME` — Custom domain configuration
- **NEW** `.github/workflows/deploy-pages.yml` — GitHub Action to build and deploy Pages
- **MODIFIED** `README.md` — Update installation commands to use short URLs

## Impact

- Affected specs: `github-pages` (new capability)
- Affected code: `docs/`, `.github/workflows/`, `README.md`

## Design Decisions

### URL Structure

| URL                                    | Content                        |
| -------------------------------------- | ------------------------------ |
| `https://get.razd-cli.com/`            | Landing page with instructions |
| `https://get.razd-cli.com/install.sh`  | Shell installer script         |
| `https://get.razd-cli.com/install.ps1` | PowerShell installer script    |

### New Installation Commands

```bash
# Linux / macOS
curl -fsSL https://get.razd-cli.com/install.sh | bash

# Windows PowerShell
irm https://get.razd-cli.com/install.ps1 | iex
```

### GitHub Pages Configuration

- **Source**: GitHub Actions deployment
- **Custom domain**: `get.razd-cli.com`
- **HTTPS**: Enforced (GitHub provides free SSL)

### Build and Deploy

GitHub Action triggers on:

- Push to `main` branch when `install.sh`, `install.ps1`, or `docs/` changes
- Builds site by copying `docs/` content + root scripts into `_site/`
- Deploys via `actions/deploy-pages`

Scripts are NOT duplicated in the repository — they are assembled at deploy time.

### Landing Page

Minimal, clean HTML page with:

- Project branding
- One-liner install commands for each platform
- Link to full documentation (README)
- No external dependencies (inline CSS)
