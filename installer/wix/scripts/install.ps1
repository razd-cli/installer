#Requires -Version 5.1
<#
.SYNOPSIS
    Razd CLI Installer for Windows (MSI version)

.DESCRIPTION
    Installs mise (if needed) and razd CLI tool.
    This script is designed to run from MSI installer context (elevated, possibly SYSTEM user).
#>

$ErrorActionPreference = 'Stop'

# =============================================================================
# Configuration
# =============================================================================

$RazdVersion = if ($env:RAZD_VERSION) { $env:RAZD_VERSION } else { "latest" }
$MiseBinPath = Join-Path $env:LOCALAPPDATA "mise\bin"
$MiseExePath = Join-Path $MiseBinPath "mise.exe"

# If running as SYSTEM, use a shared location
if ($env:USERNAME -eq "SYSTEM" -or [Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    $MiseBinPath = Join-Path $env:ProgramData "mise\bin"
    $MiseExePath = Join-Path $MiseBinPath "mise.exe"
}

# razd plugin for mise
$RazdPluginUrl = "https://github.com/razd-cli/vfox-plugin-razd"

# Log file for MSI context
$LogFile = Join-Path $env:TEMP "razd-install.log"

# =============================================================================
# Output Functions
# =============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    Write-Host $logMessage
}

function Write-Step {
    param([string]$Message)
    Write-Log "==> $Message" "STEP"
}

function Write-Info {
    param([string]$Message)
    Write-Log "    $Message" "INFO"
}

function Write-Success {
    param([string]$Message)
    Write-Log "[OK] $Message" "SUCCESS"
}

function Write-Warning {
    param([string]$Message)
    Write-Log "[!] $Message" "WARN"
}

function Write-Error {
    param([string]$Message)
    Write-Log "[X] $Message" "ERROR"
}

# =============================================================================
# Utility Functions
# =============================================================================

function Invoke-Mise {
    param([Parameter(ValueFromRemainingArguments = $true)]$Arguments)
    $prevErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $MiseExePath @Arguments 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
    }
    finally {
        $ErrorActionPreference = $prevErrorActionPreference
    }
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-LatestRazdVersion {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $headers = @{}
        if ($env:GITHUB_TOKEN) {
            $headers["Authorization"] = "token $env:GITHUB_TOKEN"
        }
        
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/razd-cli/razd/releases/latest" -Headers $headers -UseBasicParsing
        $version = $releaseInfo.tag_name -replace '^v', ''
        return $version
    }
    catch {
        Write-Warning "Could not fetch latest version: $_"
        return $null
    }
}

function Get-SystemArchitecture {
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
    
    if ($env:Path -notlike "*$Path*") {
        $env:Path = "$Path;$env:Path"
    }
    
    if ($Persistent) {
        # Add to Machine PATH for all users (MSI runs elevated)
        $currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        if ($currentPath -notlike "*$Path*") {
            $newPath = "$Path;$currentPath"
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
        }
    }
}

# =============================================================================
# Mise Installation
# =============================================================================

function Install-MiseViaDirectDownload {
    Write-Info "Downloading mise from GitHub releases..."
    
    $arch = Get-SystemArchitecture
    $tempDir = Join-Path $env:TEMP "mise-install-$(Get-Random)"
    $zipFile = Join-Path $tempDir "mise.zip"
    
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        Write-Info "Fetching latest release info..."
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/jdx/mise/releases/latest" -UseBasicParsing
        
        $assetPattern = "mise-.*-windows-$arch\.zip$"
        $asset = $releaseInfo.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1
        
        if ($null -eq $asset) {
            throw "Could not find Windows $arch asset in latest mise release"
        }
        
        $downloadUrl = $asset.browser_download_url
        Write-Info "Downloading from: $downloadUrl"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        
        if (-not (Test-Path (Split-Path $MiseBinPath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $MiseBinPath -Parent) -Force | Out-Null
        }
        if (-not (Test-Path $MiseBinPath)) {
            New-Item -ItemType Directory -Path $MiseBinPath -Force | Out-Null
        }
        
        Write-Info "Extracting mise..."
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        
        $miseExe = Get-ChildItem -Path $tempDir -Filter "mise.exe" -Recurse | Select-Object -First 1
        if ($null -eq $miseExe) {
            throw "mise.exe not found in downloaded archive"
        }
        
        Copy-Item -Path $miseExe.FullName -Destination $MiseExePath -Force
        Add-ToPath -Path $MiseBinPath -Persistent
        
        Write-Success "mise installed to: $MiseBinPath"
        return $true
    }
    catch {
        Write-Error "Failed to download mise: $_"
        return $false
    }
    finally {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-Mise {
    Write-Step "Checking for mise..."
    
    if (Test-Path $MiseExePath) {
        Add-ToPath -Path $MiseBinPath -Persistent
        $version = Invoke-Mise --version
        Write-Success "mise is already installed ($version)"
        return $true
    }
    
    Write-Step "Installing mise..."
    
    if (Install-MiseViaDirectDownload) {
        return $true
    }
    
    Write-Error "Failed to install mise"
    return $false
}

# =============================================================================
# Razd Installation
# =============================================================================

function Install-RazdPlugin {
    Write-Step "Installing razd plugin..."
    
    $plugins = Invoke-Mise plugin list | Out-String
    if ($plugins -match "(?m)^razd" -or $plugins -match "\brazd\b") {
        Write-Success "razd plugin is already installed"
        return $true
    }
    
    Write-Info "Adding razd plugin from $RazdPluginUrl"
    
    try {
        Invoke-Mise plugin install razd $RazdPluginUrl
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
    
    if (-not (Test-Path $MiseExePath)) {
        Write-Error "mise is not available."
        return $false
    }
    
    if (-not (Install-RazdPlugin)) {
        return $false
    }
    
    $versionToInstall = $RazdVersion
    
    if ($RazdVersion -eq "latest") {
        Write-Info "Fetching latest razd version..."
        $versionToInstall = Get-LatestRazdVersion
        if ($null -eq $versionToInstall -or $versionToInstall -eq "") {
            Write-Warning "Could not fetch latest version, falling back to 'latest'"
            $versionToInstall = "latest"
        }
        else {
            Write-Info "Latest version: $versionToInstall"
        }
    }
    
    $versionArg = "razd@$versionToInstall"
    Write-Info "Installing razd version: $versionToInstall"

    try {
        Invoke-Mise use -g $versionArg -y
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
    Write-Log "Starting Razd CLI installation (MSI mode)" "INFO"
    Write-Log "User: $env:USERNAME, Elevated: $([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" "INFO"
    
    if (-not (Install-Mise)) {
        exit 1
    }
    
    if (-not (Install-Razd)) {
        exit 1
    }
    
    Write-Success "Installation complete!"
    exit 0
}

Main
