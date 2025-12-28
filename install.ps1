#Requires -Version 5.1
<#
.SYNOPSIS
    Razd CLI Installer for Windows

.DESCRIPTION
    Installs mise (if needed) and razd CLI tool.
    
.PARAMETER Version
    Version of razd to install. Defaults to "latest".

.EXAMPLE
    # Run from PowerShell:
    irm https://raw.githubusercontent.com/razd-cli/installer/main/install.ps1 | iex

.EXAMPLE
    # Install specific version:
    $env:RAZD_VERSION = "1.0.0"; irm https://raw.githubusercontent.com/razd-cli/installer/main/install.ps1 | iex

.LINK
    https://github.com/razd-cli/razd
#>

$ErrorActionPreference = 'Stop'

# =============================================================================
# Configuration
# =============================================================================

$RazdVersion = if ($env:RAZD_VERSION) { $env:RAZD_VERSION } else { "latest" }
$MiseBinPath = Join-Path $env:LOCALAPPDATA "mise\bin"
$MiseExePath = Join-Path $MiseBinPath "mise.exe"

# razd plugin for mise
$RazdPluginUrl = "https://github.com/razd-cli/vfox-plugin-razd"

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
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ Error: " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor Red
}

# =============================================================================
# Utility Functions
# =============================================================================

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-SystemArchitecture {
    # Detect system architecture for download URL
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        'Arm64' { return 'arm64' }
        default { return 'x64' }
    }
}

function Add-ToPath {
    param(
        [string]$Path,
        [switch]$Persistent
    )
    
    # Add to current session
    if ($env:Path -notlike "*$Path*") {
        $env:Path = "$Path;$env:Path"
    }
    
    # Add to persistent user PATH
    if ($Persistent) {
        $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($currentPath -notlike "*$Path*") {
            $newPath = "$Path;$currentPath"
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        }
    }
}

# =============================================================================
# Mise Installation
# =============================================================================

function Install-MiseViaWinget {
    Write-Info "Attempting installation via winget..."
    
    try {
        $result = winget install jdx.mise --accept-package-agreements --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        # Check if already installed
        if ($result -match "already installed") {
            return $true
        }
    }
    catch {
        # winget failed, will try fallback
    }
    
    return $false
}

function Install-MiseViaDirectDownload {
    Write-Info "Downloading mise from GitHub releases..."
    
    $arch = Get-SystemArchitecture
    $tempDir = Join-Path $env:TEMP "mise-install-$(Get-Random)"
    $zipFile = Join-Path $tempDir "mise.zip"
    
    try {
        # Create temp directory
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        # Download URL - uses latest release redirect
        $downloadUrl = "https://github.com/jdx/mise/releases/latest/download/mise-windows-$arch.zip"
        
        Write-Info "Downloading from: $downloadUrl"
        
        # Download the ZIP file
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        
        # Create mise bin directory
        if (-not (Test-Path $MiseBinPath)) {
            New-Item -ItemType Directory -Path $MiseBinPath -Force | Out-Null
        }
        
        # Extract ZIP
        Write-Info "Extracting mise..."
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        
        # Find mise.exe in extracted contents (might be in a subdirectory)
        $miseExe = Get-ChildItem -Path $tempDir -Filter "mise.exe" -Recurse | Select-Object -First 1
        if ($null -eq $miseExe) {
            throw "mise.exe not found in downloaded archive"
        }
        
        # Copy to final location
        Copy-Item -Path $miseExe.FullName -Destination $MiseExePath -Force
        
        # Add to PATH (session and persistent)
        Add-ToPath -Path $MiseBinPath -Persistent
        
        Write-Success "mise installed to: $MiseBinPath"
        return $true
    }
    catch {
        Write-Error "Failed to download mise: $_"
        return $false
    }
    finally {
        # Cleanup temp files
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-Mise {
    Write-Step "Checking for mise..."
    
    # Check if mise is already installed
    if (Test-CommandExists "mise") {
        $version = & mise --version 2>&1
        Write-Success "mise is already installed ($version)"
        return $true
    }
    
    # Check if mise exists at expected location but not on PATH
    if (Test-Path $MiseExePath) {
        Add-ToPath -Path $MiseBinPath -Persistent
        Write-Success "mise found at $MiseBinPath (added to PATH)"
        return $true
    }
    
    Write-Step "Installing mise..."
    
    # Try winget first
    if (Test-CommandExists "winget") {
        if (Install-MiseViaWinget) {
            # Refresh PATH to find winget-installed mise
            $wingetMisePath = Join-Path $env:LOCALAPPDATA "Programs\mise\bin"
            if (Test-Path $wingetMisePath) {
                Add-ToPath -Path $wingetMisePath -Persistent
            }
            Write-Success "mise installed via winget"
            return $true
        }
        Write-Warning "winget installation failed, trying direct download..."
    }
    else {
        Write-Info "winget not available, using direct download..."
    }
    
    # Fallback to direct download
    if (Install-MiseViaDirectDownload) {
        return $true
    }
    
    Write-Error "Failed to install mise"
    return $false
}

# =============================================================================
# Task Installation
# =============================================================================

function Install-Task {
    Write-Step "Installing task..."
    
    # Ensure mise is on PATH
    if (-not (Test-CommandExists "mise")) {
        Write-Error "mise is not available."
        return $false
    }
    
    # Check if task is already installed globally
    $globalTools = & mise list -g 2>&1
    if ($globalTools -match "^task") {
        Write-Success "task is already installed globally"
        return $true
    }
    
    Write-Info "Installing task (go-task runner)..."
    
    try {
        # First install task
        & mise install task@latest
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to install task. You can install it manually with: mise install task@latest"
            return $true
        }
        
        # Then set it globally
        & mise use -g task@latest -y
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to set task globally. You can set it manually with: mise use -g task@latest"
            return $true
        }
        
        Write-Success "task installed successfully"
        return $true
    }
    catch {
        Write-Warning "Failed to install task: $_. You can install it manually with: mise install task@latest"
        return $true
    }
}

# =============================================================================
# Razd Installation
# =============================================================================

function Install-RazdPlugin {
    Write-Step "Installing razd plugin..."
    
    # Check if plugin is already installed
    $plugins = & mise plugin list 2>&1
    if ($plugins -match "^razd") {
        Write-Success "razd plugin is already installed"
        return $true
    }
    
    Write-Info "Adding razd plugin from $RazdPluginUrl"
    
    try {
        & mise plugin install razd $RazdPluginUrl
        if ($LASTEXITCODE -ne 0) {
            throw "mise plugin install command failed with exit code $LASTEXITCODE"
        }
        Write-Success "razd plugin installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install razd plugin: $_"
        return $false
    }
}

function Install-Razd {
    Write-Step "Installing razd..."
    
    # Ensure mise is on PATH
    if (-not (Test-CommandExists "mise")) {
        # Try known locations
        $possiblePaths = @(
            $MiseBinPath,
            (Join-Path $env:LOCALAPPDATA "Programs\mise\bin")
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path (Join-Path $path "mise.exe")) {
                Add-ToPath -Path $path
                break
            }
        }
    }
    
    if (-not (Test-CommandExists "mise")) {
        Write-Error "mise is not available. Please restart your terminal and try again."
        return $false
    }
    
    # Install razd plugin first
    if (-not (Install-RazdPlugin)) {
        return $false
    }
    
    # Determine version argument
    if ($RazdVersion -eq "latest") {
        $versionArg = "razd@latest"
    }
    else {
        $versionArg = "razd@$RazdVersion"
    }

    Write-Info "Installing razd version: $RazdVersion"

    # Install razd globally via mise
    try {
        & mise use -g $versionArg -y
        if ($LASTEXITCODE -ne 0) {
            throw "mise use command failed with exit code $LASTEXITCODE"
        }
        Write-Success "razd installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install razd: $_"
        return $false
    }
}

# =============================================================================
# Main
# =============================================================================

function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║       Razd CLI Installer               ║" -ForegroundColor Blue
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    
    # Install mise
    if (-not (Install-Mise)) {
        exit 1
    }
    
    # Install task
    Install-Task | Out-Null
    
    # Install razd
    if (-not (Install-Razd)) {
        exit 1
    }
    
    Write-Host ""
    Write-Step "Post-installation setup"
    Write-Host ""
    Write-Info "mise has been added to your PATH."
    Write-Info "You may need to restart your terminal for changes to take effect."
    Write-Host ""
    Write-Info "To activate mise in your current session, run:"
    Write-Host ""
    Write-Host "    mise activate pwsh | Invoke-Expression" -ForegroundColor Green
    Write-Host ""
    Write-Info "To make this permanent, add the above line to your PowerShell profile:"
    Write-Host ""
    Write-Host "    `$PROFILE" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Success "Installation complete!"
    Write-Host ""
    Write-Info "Run 'razd --help' to get started."
    Write-Host ""
}

# Run main
Main
