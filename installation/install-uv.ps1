# PowerShell script to install uv with automatic elevation
# Tries online installation first (winget), then falls back to pre-built binaries

param(
    [switch]$Elevated
)

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-UV-Online {
    Write-Host "Attempting online installation using winget..." -ForegroundColor Green

    try {
        # Check if winget is available
        $null = Get-Command winget -ErrorAction Stop

        # Install uv silently using winget
        $result = winget install --id astral-sh.uv --silent --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Host "uv installed successfully via winget!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "winget installation failed with exit code: $LASTEXITCODE" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "Online installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Install-UV-Offline {
    Write-Host "Attempting offline installation using pre-built binaries..." -ForegroundColor Green

    # Find the offline installer in the same directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $offlineInstallerPath = Join-Path $scriptDir "uv-installer.ps1"

    if (-not (Test-Path $offlineInstallerPath)) {
        Write-Host "ERROR: Offline installer not found at $offlineInstallerPath" -ForegroundColor Red
        return $false
    }

    try {
        # Run the offline installer
        & $offlineInstallerPath

        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Write-Host "uv installed successfully via offline installer!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Offline installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Offline installation error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
if (-not $Elevated) {
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow

        # Re-run this script with elevation
        try {
            Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated" -Wait
            exit
        }
        catch {
            $errorMsg = "Failed to elevate privileges: $($_.Exception.Message)"
            Write-Host $errorMsg -ForegroundColor Red
            Add-Content -Path "error.log" -Value "$(Get-Date): $errorMsg"
            exit 1
        }
    }
}

# We're running as administrator now
Write-Host "Running with administrator privileges" -ForegroundColor Green
Write-Host ""

# Try online installation first
$onlineSuccess = Install-UV-Online

if (-not $onlineSuccess) {
    Write-Host ""
    Write-Host "Online installation failed or unavailable. Trying offline installation..." -ForegroundColor Yellow
    Write-Host ""

    $offlineSuccess = Install-UV-Offline

    if (-not $offlineSuccess) {
        Write-Host ""
        Write-Host "ERROR: Both online and offline installation methods failed." -ForegroundColor Red
        Add-Content -Path "error.log" -Value "$(Get-Date): All installation methods failed"
        exit 1
    }
}

Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green