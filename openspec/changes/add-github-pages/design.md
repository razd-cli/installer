# Design: GitHub Pages for Installation URLs

## Overview

This document describes the technical architecture for serving Razd CLI installation scripts via GitHub Pages with a custom domain.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                          │
│  razd-cli/installer                                               │
│                                                                   │
│  ┌─────────────┐                        ┌─────────────────────┐  │
│  │ install.sh  │                        │ docs/index.html     │  │
│  │ install.ps1 │                        │ docs/CNAME          │  │
│  └─────────────┘                        └─────────────────────┘  │
│         │                                        │                │
│         └──────────────┬─────────────────────────┘                │
│                        │                                          │
│                  GitHub Action                                    │
│              (deploy-pages.yml)                                   │
│                        │                                          │
│                        ▼                                          │
│              ┌─────────────────┐                                  │
│              │     _site/      │  (build artifact)                │
│              │  index.html     │                                  │
│              │  CNAME          │                                  │
│              │  install.sh     │                                  │
│              │  install.ps1    │                                  │
│              └─────────────────┘                                  │
│                        │                                          │
└────────────────────────┼──────────────────────────────────────────┘
                         │
               actions/deploy-pages
                         │
                         ▼
                ┌───────────────────────────┐
                │   get.razd-cli.com        │
                │                           │
                │   /           → index.html│
                │   /install.sh → script    │
                │   /install.ps1→ script    │
                └───────────────────────────┘
```

## Components

### 1. docs/ Directory Structure

```
docs/
├── CNAME           # Contains: get.razd-cli.com
└── index.html      # Landing page
```

Scripts (`install.sh`, `install.ps1`) remain in repository root and are assembled into the deployment artifact by GitHub Action.

### 2. GitHub Action Workflow

**Trigger**: Push to `main` when `install.sh`, `install.ps1`, or `docs/` changes

**Steps**:

1. Checkout repository
2. Configure Pages
3. Build `_site/` by copying docs + scripts
4. Upload artifact
5. Deploy to GitHub Pages

**Benefits**:

- No file duplication in repository
- Single source of truth for scripts
- Automatic deployment on any change

### 3. Landing Page (index.html)

**Requirements**:

- Mobile-responsive
- Dark/light mode support (prefers-color-scheme)
- Copy-to-clipboard for commands
- No external dependencies
- Fast loading (<50KB total)

**Content sections**:

1. Header with logo/title
2. Platform tabs (Linux/macOS, Windows)
3. Install commands with copy buttons
4. Version selection (optional, future)
5. Link to GitHub repository

### 4. DNS Configuration

User must configure DNS before GitHub Pages works:

| Type  | Name | Value              |
| ----- | ---- | ------------------ |
| CNAME | get  | razd-cli.github.io |

Or for apex domain:
| Type | Name | Value |
|------|------|-------|
| A | @ | 185.199.108.153 |
| A | @ | 185.199.109.153 |
| A | @ | 185.199.110.153 |
| A | @ | 185.199.111.153 |

### 5. GitHub Pages Settings

Configure in repository Settings → Pages:

- **Source**: GitHub Actions
- **Custom domain**: `get.razd-cli.com`
- **Enforce HTTPS**: ✓

## Content-Type Handling

GitHub Pages serves files based on extension:

- `.sh` → `text/x-sh` or `application/x-sh`
- `.ps1` → `text/plain`

Both work correctly with `curl` and `irm`.

## Alternatives Considered

### Alternative 1: gh-pages branch

- **Pros**: Cleaner main branch
- **Cons**: More complex sync workflow, harder to review
- **Decision**: Rejected — `docs/` folder is simpler

### Alternative 2: Symlinks in docs/

- **Pros**: No sync needed
- **Cons**: GitHub Pages doesn't follow symlinks
- **Decision**: Rejected — doesn't work

### Alternative 3: Build step to copy files

- **Pros**: Can add preprocessing (minification, etc.)
- **Cons**: Overkill for simple file copy
- **Decision**: Rejected — simple copy is sufficient

## Security Considerations

1. **HTTPS enforced** — prevents MITM attacks during script download
2. **Scripts served as-is** — no server-side processing
3. **GitHub-hosted** — benefits from GitHub's security infrastructure
4. **Version control** — all changes tracked in git history

## Future Enhancements

1. **Version selector** — Allow installing specific versions from landing page
2. **Platform detection** — Auto-highlight relevant command based on User-Agent
3. **Analytics** — Optional privacy-respecting analytics (e.g., Plausible)
4. **Health check** — Verify scripts are accessible and match source
