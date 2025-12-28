# Tasks: Add GitHub Pages

## 1. Setup

- [x] Create `docs/` directory structure
- [x] Create `docs/CNAME` with `get.razd-cli.com`

## 2. Landing Page

- [x] Create `docs/index.html` with installation instructions
- [x] Add responsive CSS (inline, no external deps)
- [x] Add copy-to-clipboard functionality for commands
- [ ] Test on mobile viewport

## 3. GitHub Action

- [x] Create `.github/workflows/deploy-pages.yml`
- [x] Configure trigger on `install.sh` / `install.ps1` / `docs/` changes
- [x] Add step to build `_site/` with docs + scripts
- [x] Add step to deploy via `actions/deploy-pages`

## 4. GitHub Pages Configuration (Manual)

- [ ] Enable GitHub Pages in repository settings
- [ ] Set source to "GitHub Actions"
- [ ] Add custom domain `get.razd-cli.com`
- [ ] Enable "Enforce HTTPS"

## 5. DNS Configuration (Manual)

- [ ] Add CNAME record: `get` → `razd-cli.github.io`
- [ ] Wait for DNS propagation
- [ ] Verify HTTPS certificate is issued

## 6. Documentation

- [x] Update `README.md` with new short installation URLs
- [x] Add fallback note about raw.githubusercontent.com URLs

## 7. Validation

- [ ] Verify `https://get.razd-cli.com/` loads landing page
- [ ] Verify `curl -fsSL https://get.razd-cli.com/install.sh | bash` works
- [ ] Verify `irm https://get.razd-cli.com/install.ps1 | iex` works
