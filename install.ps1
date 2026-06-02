#Requires -Version 5.1
<#
.SYNOPSIS
    Razd CLI Installer for Windows

.DESCRIPTION
    Installs razd CLI tool by downloading the binary from GitHub Releases.
    
.PARAMETER Version
    Version of razd to install. Defaults to "latest".

.PARAMETER List
    List available versions instead of installing.

.PARAMETER InstallDir
    Installation directory. Defaults to %LOCALAPPDATA%\razd.

.EXAMPLE
    # Run from PowerShell:
    irm https://raw.githubusercontent.com/razd-cli/installer/main/install.ps1 | iex

.EXAMPLE
    # Install specific version:
    $env:RAZD_VERSION = "1.0.0"; irm https://raw.githubusercontent.com/razd-cli/installer/main/install.ps1 | iex

.EXAMPLE
    # List available versions:
    .\install.ps1 -List

.LINK
    https://github.com/razd-cli/razd
#>

param(
    [string]$Version,
    [switch]$List,
    [int]$ListCount = 20,
    [string]$InstallDir,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# =============================================================================
# Configuration
# =============================================================================

$RazdVersion = if ($Version) { $Version } elseif ($env:RAZD_VERSION) { $env:RAZD_VERSION } else { "latest" }
$RazdInstallDir = if ($InstallDir) { $InstallDir } elseif ($env:RAZD_INSTALL_DIR) { $env:RAZD_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "razd" }
$GithubRepo = "razd-cli/razd"
$GithubBaseUrl = "https://github.com/$GithubRepo"

# =============================================================================
# Output Functions
# =============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "==> " -ForegroundColor Blue -NoNewline
    Write-Host $Message -ForegroundColor Blue
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] Error: " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor Red
}

# =============================================================================
# Utility Functions
# =============================================================================

function Get-SystemArchitecture {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        'Arm64' { return 'arm64' }
        default { return 'amd64' }
    }
}

function Invoke-GitHubApi {
    param([string]$Endpoint)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $headers = @{}
        if ($env:GITHUB_TOKEN) {
            $headers["Authorization"] = "token $env:GITHUB_TOKEN"
        }
        return Invoke-RestMethod -Uri "https://api.github.com$Endpoint" -Headers $headers -UseBasicParsing
    }
    catch {
        Write-Error "GitHub API request failed: $_"
        return $null
    }
}

function Get-LatestVersion {
    try {
        $releaseInfo = Invoke-GitHubApi -Endpoint "/repos/$GithubRepo/releases/latest"
        if ($null -eq $releaseInfo) { return $null }
        $version = $releaseInfo.tag_name -replace '^v', ''
        return $version
    }
    catch {
        Write-Error "Could not fetch latest version: $_"
        return $null
    }
}

function Get-AvailableVersions {
    param([int]$Count = 20)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $headers = @{}
        if ($env:GITHUB_TOKEN) {
            $headers["Authorization"] = "token $env:GITHUB_TOKEN"
        }
        
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$GithubRepo/releases?per_page=$Count" -Headers $headers -UseBasicParsing
        
        Write-Host ""
        Write-Host "  Available versions:" -ForegroundColor White
        Write-Host ""
        
        foreach ($release in $releases) {
            $ver = $release.tag_name -replace '^v', ''
            $preLabel = if ($release.prerelease) { " (pre-release)" } else { "" }
            $color = if ($release.prerelease) { "Yellow" } else { "Green" }
            Write-Host "  " -NoNewline
            Write-Host $ver -ForegroundColor $color -NoNewline
            Write-Host $preLabel
        }
        
        Write-Host ""
        Write-Info "Install a specific version:"
        Write-Host ""
        Write-Host "  .\install.ps1 -Version 1.0.0" -ForegroundColor Cyan
        Write-Host "  .\install.ps1 -Version 1.0.0-dev.0" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Error "Could not fetch releases: $_"
    }
}

function Resolve-Version {
    if ($RazdVersion -eq "latest") {
        Write-Info "Fetching latest razd version..."
        $version = Get-LatestVersion
        if ($null -eq $version -or $version -eq "") {
            Write-Error "Could not determine latest version. Please specify a version with -Version or `$env:RAZD_VERSION."
            exit 1
        }
        return $version
    }
    return $RazdVersion
}

function Get-Tag {
    param([string]$Version)
    return "v$Version"
}

function Test-Prerelease {
    param([string]$Version)
    return $Version -match '-'
}

function Get-DownloadUrl {
    param(
        [string]$Tag,
        [string]$Arch
    )
    return "$GithubBaseUrl/releases/download/$Tag/razd_windows_$Arch.zip"
}

function Add-ToPath {
    param(
        [string]$Path,
        [switch]$Persistent
    )
    
    if ($env:Path -notlike "*$Path*") {
        $env:Path = "$Path;$env:Path"
    }
    
    if ($Persistent) {
        $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($currentPath -notlike "*$Path*") {
            $newPath = "$Path;$currentPath"
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        }
    }
}

# =============================================================================
# Installation
# =============================================================================

function Install-Razd {
    Write-Step "Installing razd..."
    
    $version = Resolve-Version
    $tag = Get-Tag -Version $version
    $isPrerelease = Test-Prerelease -Version $version
    
    if ($isPrerelease) {
        Write-Warning "Installing pre-release version: $version"
    }
    
    Write-Info "Version: $version (tag: $tag)"
    
    $arch = Get-SystemArchitecture
    Write-Info "Platform: windows/$arch"
    
    $downloadUrl = Get-DownloadUrl -Tag $tag -Arch $arch
    Write-Info "Downloading from: $downloadUrl"
    
    $tempDir = Join-Path $env:TEMP "razd-install-$(Get-Random)"
    $zipFile = Join-Path $tempDir "razd.zip"
    
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        }
        catch {
            throw "Failed to download razd $version. Check that the version exists at $GithubBaseUrl/releases/tag/$tag"
        }
        
        Write-Info "Extracting..."
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        
        $razdExe = Get-ChildItem -Path $tempDir -Filter "razd.exe" -Recurse | Select-Object -First 1
        if ($null -eq $razdExe) {
            throw "Could not find razd.exe in archive"
        }
        
        if (-not (Test-Path $RazdInstallDir)) {
            New-Item -ItemType Directory -Path $RazdInstallDir -Force | Out-Null
        }
        
        $targetPath = Join-Path $RazdInstallDir "razd.exe"
        Copy-Item -Path $razdExe.FullName -Destination $targetPath -Force
        
        Add-ToPath -Path $RazdInstallDir -Persistent
        
        Write-Success "razd installed to: $targetPath"
        
        if (-not (Get-Command "razd" -ErrorAction SilentlyContinue)) {
            Write-Warning "$RazdInstallDir is not in your PATH"
            Write-Info "You may need to restart your terminal for PATH changes to take effect."
        }
    }
    catch {
        Write-Error "Installation failed: $_"
        exit 1
    }
    finally {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# =============================================================================
# Help
# =============================================================================

function Show-Help {
    Write-Host ""
    Write-Host "Razd CLI Installer" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  .\install.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Version VERSION   Install specific version (default: latest)"
    Write-Host "  -List               List available versions"
    Write-Host "  -ListCount N        Number of versions to list (default: 20)"
    Write-Host "  -InstallDir DIR     Installation directory (default: %LOCALAPPDATA%\razd)"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor White
    Write-Host "  RAZD_VERSION        Version to install (default: latest)"
    Write-Host "  RAZD_INSTALL_DIR    Installation directory"
    Write-Host "  GITHUB_TOKEN        GitHub token to avoid rate limiting"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\install.ps1                                # Install latest version"
    Write-Host "  .\install.ps1 -Version 1.0.0                 # Install specific version"
    Write-Host "  .\install.ps1 -Version 1.0.0-dev.0           # Install pre-release"
    Write-Host "  .\install.ps1 -List                          # List available versions"
    Write-Host "  .\install.ps1 -List -ListCount 50            # List up to 50 versions"
    Write-Host ""
}

# =============================================================================
# Main
# =============================================================================

if ($Help) {
    Show-Help
    exit 0
}

if ($List) {
    Get-AvailableVersions -Count $ListCount
    exit 0
}

Write-Host ""
Write-Host "+----------------------------------------+" -ForegroundColor Blue
Write-Host "|       Razd CLI Installer               |" -ForegroundColor Blue
Write-Host "+----------------------------------------+" -ForegroundColor Blue
Write-Host ""

Install-Razd

Write-Host ""
Write-Info "You may need to restart your terminal for PATH changes to take effect."
Write-Host ""
Write-Success "Installation complete!"
Write-Host ""
Write-Info "Run 'razd --help' to get started."
Write-Host ""