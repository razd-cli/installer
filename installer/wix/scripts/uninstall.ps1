#Requires -Version 5.1
<#
.SYNOPSIS
    Razd CLI Uninstaller for Windows (MSI version)

.DESCRIPTION
    Removes razd CLI and optionally mise.

.PARAMETER RemoveMise
    If set to "1", also removes mise completely.
#>

param(
    [string]$RemoveMise = "0"
)

$ErrorActionPreference = 'Continue'

# =============================================================================
# Configuration
# =============================================================================

# Check multiple possible mise locations
$MiseLocations = @(
    (Join-Path $env:LOCALAPPDATA "mise"),
    (Join-Path $env:ProgramData "mise"),
    (Join-Path $env:LOCALAPPDATA "Programs\mise")
)

$LogFile = Join-Path $env:TEMP "razd-uninstall.log"

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

# =============================================================================
# Utility Functions
# =============================================================================

function Get-MiseExePath {
    foreach ($location in $MiseLocations) {
        $exePath = Join-Path $location "bin\mise.exe"
        if (Test-Path $exePath) {
            return $exePath
        }
    }
    
    # Check PATH
    $mise = Get-Command "mise" -ErrorAction SilentlyContinue
    if ($mise) {
        return $mise.Source
    }
    
    return $null
}

function Invoke-Mise {
    param(
        [string]$MisePath,
        [Parameter(ValueFromRemainingArguments = $true)]$Arguments
    )
    try {
        & $MisePath @Arguments 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
    }
    catch {
        # Ignore errors
    }
}

function Remove-FromPath {
    param([string]$PathToRemove)
    
    # Remove from Machine PATH
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($machinePath -like "*$PathToRemove*") {
        $newPath = ($machinePath -split ';' | Where-Object { $_ -ne $PathToRemove -and $_ -ne "" }) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
        Write-Info "Removed from Machine PATH: $PathToRemove"
    }
    
    # Remove from User PATH
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -like "*$PathToRemove*") {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne $PathToRemove -and $_ -ne "" }) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Info "Removed from User PATH: $PathToRemove"
    }
}

# =============================================================================
# Uninstall Functions
# =============================================================================

function Uninstall-Razd {
    Write-Step "Removing razd..."
    
    $misePath = Get-MiseExePath
    
    if ($null -eq $misePath) {
        Write-Warning "mise not found, razd may already be removed"
        return $true
    }
    
    Write-Info "Using mise at: $misePath"
    
    # Uninstall razd versions
    try {
        Write-Info "Uninstalling razd..."
        Invoke-Mise -MisePath $misePath uninstall razd --all
    }
    catch {
        Write-Warning "Failed to uninstall razd versions: $_"
    }
    
    # Remove razd plugin
    try {
        Write-Info "Removing razd plugin..."
        Invoke-Mise -MisePath $misePath plugin uninstall razd
    }
    catch {
        Write-Warning "Failed to remove razd plugin: $_"
    }
    
    Write-Success "razd removed"
    return $true
}

function Uninstall-Mise {
    Write-Step "Removing mise..."
    
    foreach ($location in $MiseLocations) {
        if (Test-Path $location) {
            Write-Info "Removing mise directory: $location"
            
            # Remove from PATH first
            $binPath = Join-Path $location "bin"
            $shimsPath = Join-Path $location "shims"
            Remove-FromPath -PathToRemove $binPath
            Remove-FromPath -PathToRemove $shimsPath
            
            # Remove directory
            try {
                Remove-Item -Path $location -Recurse -Force -ErrorAction Stop
                Write-Success "Removed: $location"
            }
            catch {
                Write-Warning "Failed to remove $location : $_"
            }
        }
    }
    
    # Also remove mise data directory
    $miseDataDir = Join-Path $env:LOCALAPPDATA "mise"
    if (Test-Path $miseDataDir) {
        try {
            Remove-Item -Path $miseDataDir -Recurse -Force -ErrorAction Stop
            Write-Success "Removed mise data: $miseDataDir"
        }
        catch {
            Write-Warning "Failed to remove mise data: $_"
        }
    }
    
    Write-Success "mise removed"
    return $true
}

# =============================================================================
# Main
# =============================================================================

function Main {
    Write-Log "Starting Razd CLI uninstallation" "INFO"
    Write-Log "RemoveMise parameter: $RemoveMise" "INFO"
    
    # Always remove razd
    Uninstall-Razd
    
    # Optionally remove mise
    if ($RemoveMise -eq "1") {
        Uninstall-Mise
    }
    else {
        Write-Info "mise will be kept (use REMOVE_MISE=1 to remove)"
    }
    
    Write-Success "Uninstallation complete!"
    exit 0
}

Main
