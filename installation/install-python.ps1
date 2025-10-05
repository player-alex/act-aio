# PowerShell script to install Python from local mirror using uv
# Reads Python version from pyproject.toml and installs using UV environment variables

param(
    [string]$MirrorPath = "$PSScriptRoot\mirror"
)

function Get-PythonVersionFromMetadata {
    param(
        [string]$MetadataPath
    )

    if (-not (Test-Path $MetadataPath)) {
        Write-Host "ERROR: Metadata file not found at $MetadataPath" -ForegroundColor Red
        exit 1
    }

    try {
        $metadata = Get-Content $MetadataPath -Raw | ConvertFrom-Json
        $firstEntry = $metadata.PSObject.Properties.Value | Select-Object -First 1

        if ($firstEntry -and $firstEntry.major -and $firstEntry.minor) {
            $version = "$($firstEntry.major).$($firstEntry.minor)"
            Write-Host "Detected Python version from mirror: $version" -ForegroundColor Green
            return $version
        } else {
            Write-Host "ERROR: Could not parse Python version from metadata" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "ERROR: Failed to read metadata: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Install-PythonFromMirror {
    param(
        [string]$Version,
        [string]$Mirror
    )

    $mirrorFullPath = (Resolve-Path $Mirror).Path
    $metadataPath = Join-Path $mirrorFullPath "download-metadata.json"

    if (-not (Test-Path $metadataPath)) {
        Write-Host "ERROR: Metadata file not found at $metadataPath" -ForegroundColor Red
        Write-Host "Please run: uv run .\generate-metadata.py --mirror .\mirror" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Installing Python $Version from local mirror..." -ForegroundColor Green
    Write-Host "Mirror path: $mirrorFullPath" -ForegroundColor Cyan
    Write-Host "Metadata: $metadataPath" -ForegroundColor Cyan

    $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
    $tempMetadata = @{}

    foreach ($key in $metadata.PSObject.Properties.Name) {
        $entry = $metadata.$key
        $url = $entry.url

        if ($url -notmatch '^(https?|file)://') {
            $absolutePath = Join-Path $mirrorFullPath $url
            $entry.url = ([System.Uri]$absolutePath).AbsoluteUri
        }

        $tempMetadata[$key] = $entry
    }

    $tempMetadataPath = Join-Path $env:TEMP "uv-python-metadata-$(Get-Random).json"
    $jsonContent = [PSCustomObject]$tempMetadata | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($tempMetadataPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))

    $metadataUri = ([System.Uri]$tempMetadataPath).AbsoluteUri

    Write-Host "UV_PYTHON_DOWNLOADS_JSON_URL=$metadataUri" -ForegroundColor DarkGray

    try {
        & uv python install $Version --python-downloads-json-url $metadataUri

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Python $Version installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Python installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    }
    catch {
        Write-Host "ERROR: Failed to install Python: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    finally {
        if (Test-Path $tempMetadataPath) {
            Remove-Item $tempMetadataPath -Force
        }
    }
}

Write-Host "=== Python Installation from Local Mirror ===" -ForegroundColor Cyan
Write-Host ""

$mirrorFullPath = (Resolve-Path $MirrorPath).Path
$metadataPath = Join-Path $mirrorFullPath "download-metadata.json"

$pythonVersion = Get-PythonVersionFromMetadata -MetadataPath $metadataPath
Write-Host ""

Install-PythonFromMirror -Version $pythonVersion -Mirror $MirrorPath

Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green