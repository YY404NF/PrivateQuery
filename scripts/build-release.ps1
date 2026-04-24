[CmdletBinding()]
param(
    [string]$WslDistro = "Ubuntu-24.04",
    [string]$OutputDir = "deploy/release",
    [switch]$SkipFrontend,
    [switch]$SkipBackend
)

$ErrorActionPreference = "Stop"

function Get-WslPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )

    $resolved = (Resolve-Path -LiteralPath $WindowsPath).Path
    if ($resolved -match '^([A-Za-z]):\\(.*)$') {
        $drive = $matches[1].ToLowerInvariant()
        $rest = ($matches[2] -replace '\\', '/')
        return "/mnt/$drive/$rest"
    }

    throw "Unsupported path for WSL conversion: $resolved"
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Script
    )

    Write-Host "==> $Name"
    & $Script
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputRoot = Join-Path $repoRoot $OutputDir
$frontendOutput = Join-Path $outputRoot "frontend"
$backendOutput = Join-Path $outputRoot "backend"

New-Item -ItemType Directory -Force -Path $frontendOutput | Out-Null
New-Item -ItemType Directory -Force -Path $backendOutput | Out-Null

if (-not $SkipFrontend) {
    Invoke-Step -Name "Building frontend on Windows" -Script {
        Push-Location (Join-Path $repoRoot "pq-frontend")
        try {
            npm ci
            npm run build

            Remove-Item -Recurse -Force $frontendOutput -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Force -Path $frontendOutput | Out-Null
            Copy-Item -Recurse -Force (Join-Path (Get-Location) "dist\\*") $frontendOutput
        }
        finally {
            Pop-Location
        }
    }
}

if (-not $SkipBackend) {
    $repoRootWsl = Get-WslPath -WindowsPath $repoRoot
    $outputRootWsl = "$repoRootWsl/$($OutputDir -replace '\\', '/')"

    Invoke-Step -Name "Building Ubuntu 24.04 backend binaries in WSL" -Script {
        $bashScript = @"
set -euo pipefail

require_cmd() {
  if ! command -v "\$1" >/dev/null 2>&1; then
    echo "missing command in WSL: \$1" >&2
    exit 20
  fi
}

require_cmd go
require_cmd g++

cd "$repoRootWsl/pq-backend"
mkdir -p "$outputRootWsl/backend"
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=amd64

go build -o "$outputRootWsl/backend/server-a" ./cmd/server
cp "$outputRootWsl/backend/server-a" "$outputRootWsl/backend/server-b"
"@

        wsl -d $WslDistro -- bash -lc $bashScript
    }

    Copy-Item -Force (Join-Path $repoRoot "deploy\\ubuntu2404\\server-a.env") (Join-Path $backendOutput "server-a.env")
    Copy-Item -Force (Join-Path $repoRoot "deploy\\ubuntu2404\\server-b.env") (Join-Path $backendOutput "server-b.env")
    Copy-Item -Force (Join-Path $repoRoot "deploy\\ubuntu2404\\start-server-a.sh") (Join-Path $backendOutput "start-server-a.sh")
    Copy-Item -Force (Join-Path $repoRoot "deploy\\ubuntu2404\\start-server-b.sh") (Join-Path $backendOutput "start-server-b.sh")
}

Copy-Item -Force (Join-Path $repoRoot "deploy\\ubuntu2404\\README.md") (Join-Path $outputRoot "README.md")

Write-Host ""
Write-Host "Release artifacts are ready in: $outputRoot"
