# Windows setup for dnb-dbt-v2-workshop: dbt v2 + DuckDB Jaffle Shop.
# Usage (PowerShell):
#   .\scripts\setup.ps1
#   .\scripts\setup.ps1 -Install
#   .\scripts\setup.ps1 -SkipBuild
[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$SkipInstall,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Project = $Root

function Test-DbtV2 {
    param([string]$CommandPath)
    if (-not (Test-Path $CommandPath) -and -not (Get-Command $CommandPath -ErrorAction SilentlyContinue)) {
        return $null
    }
    try {
        $versionLine = (& $CommandPath --version 2>$null | Select-Object -First 1)
    } catch {
        return $null
    }
    if ($versionLine -match '^dbt\s+2\.') {
        return @{ Name = $CommandPath; Version = $versionLine }
    }
    return $null
}

function Resolve-DbtV2 {
    $ordered = @()
    foreach ($name in @("dbtf", "dbt")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { $ordered += $cmd.Source }
    }
    foreach ($path in @(
        "$env:USERPROFILE\.local\bin\dbt.exe",
        "$env:USERPROFILE\.local\bin\dbt"
    )) {
        Get-Item $path -ErrorAction SilentlyContinue | ForEach-Object { $ordered += $_.FullName }
    }
    foreach ($candidate in $ordered) {
        $hit = Test-DbtV2 -CommandPath $candidate
        if ($hit) { return $hit }
    }
    return $null
}

function Install-DbtV2 {
    Write-Host "Installing dbt v2 (Fusion) as a standalone binary. Python is not required."
    irm https://public.cdn.getdbt.com/fs/install/install.ps1 | iex
    $localBin = Join-Path $env:USERPROFILE ".local\bin"
    $env:Path = "$localBin;$env:Path"
    Install-DbtfShim
}

function Install-DbtfShim {
    $localBin = Join-Path $env:USERPROFILE ".local\bin"
    $localDbt = Join-Path $localBin "dbt.exe"
    $localDbtf = Join-Path $localBin "dbtf.cmd"
    if ((Test-Path $localDbt) -and -not (Test-Path $localDbtf)) {
        New-Item -ItemType Directory -Force -Path $localBin | Out-Null
        Set-Content -Path $localDbtf -Encoding ascii -Value "@echo off`r`n`"%~dp0dbt.exe`" %*`r`n"
    }
}

if (-not (Test-Path (Join-Path $Project "dbt_project.yml"))) {
    throw "Missing $Project\dbt_project.yml"
}
if (-not (Test-Path (Join-Path $Project "profiles.yml"))) {
    throw "Missing $Project\profiles.yml (portable DuckDB profile required)"
}

$DoInstall = -not $SkipInstall.IsPresent
$dbt = Resolve-DbtV2
if (-not $dbt) {
    if ($DoInstall) {
        Install-DbtV2
        $dbt = Resolve-DbtV2
        if (-not $dbt) {
            throw "dbt v2 still not found after the standalone install (~/.local/bin/dbt.exe)."
        }
    } else {
        Write-Error "dbt v2 not found on PATH. Re-run with -Install"
        exit 1
    }
}

Install-DbtfShim
$localDbtf = Join-Path $env:USERPROFILE ".local\bin\dbtf.cmd"
$localDbt = Join-Path $env:USERPROFILE ".local\bin\dbt.exe"
if (Test-Path $localDbtf) {
    $dbt = Test-DbtV2 -CommandPath $localDbtf
} elseif (Test-Path $localDbt) {
    $dbt = Test-DbtV2 -CommandPath $localDbt
}
if (-not $dbt -or $dbt.Version -notmatch '^dbt\s+2\.') {
    throw "Fusion check failed. Expected dbt 2.x from dbtf."
}

Write-Host "Using: $($dbt.Name) ($($dbt.Version))"
Set-Location $Project

Write-Host "==> deps"
& $dbt.Name deps --profiles-dir .
if ($LASTEXITCODE -ne 0) { throw "dbt deps failed" }

Write-Host "==> debug"
& $dbt.Name debug --profiles-dir .
if ($LASTEXITCODE -ne 0) { throw "dbt debug failed" }

if ($SkipBuild) {
    Write-Host "Skipping build (-SkipBuild)."
    exit 0
}

Write-Host "==> dbtf build (compare baseline)"
# The VS Code Compare feature diffs your dev models against this baseline.
# .vscode/settings.json points the extension at target/compare_state.
& $dbt.Name build --target compare_baseline --target-path target/compare_baseline --profiles-dir . --quiet
if ($LASTEXITCODE -ne 0) { throw "dbt build (compare baseline) failed" }
New-Item -ItemType Directory -Force -Path (Join-Path $Project "target\compare_state") | Out-Null
Copy-Item (Join-Path $Project "target\compare_baseline\manifest.json") (Join-Path $Project "target\compare_state\manifest.json") -Force

Write-Host "==> dbtf build"
& $dbt.Name build --profiles-dir .
if ($LASTEXITCODE -ne 0) { throw "dbt build failed" }

Write-Host ""
Write-Host "Fusion check passed: dbtf build ($($dbt.Version))"
Write-Host "Setup OK. DuckDB file: $Project\jaffle_shop.duckdb"

function Find-CodeCli {
    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($candidate in @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Install-VsCode {
    Write-Host "VS Code not found. Downloading Visual Studio Code..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        & winget install --id Microsoft.VisualStudioCode --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -eq 0) { return }
    }
    $installer = Join-Path $env:TEMP "VSCodeUserSetup.exe"
    Invoke-WebRequest -Uri "https://update.code.visualstudio.com/latest/win32-x64-user/stable" -OutFile $installer
    $proc = Start-Process -FilePath $installer -ArgumentList "/VERYSILENT","/NORESTART","/MERGETASKS=!runcode,addtopath" -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        throw "VS Code installer exited $($proc.ExitCode)"
    }
}

Write-Host "==> VS Code"
$codeCli = Find-CodeCli
if (-not $codeCli) {
    try {
        Install-VsCode
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $codeCli = Find-CodeCli
    } catch {
        Write-Host "Could not install VS Code. Skipping dbtLabsInc.dbt. $($_.Exception.Message)"
    }
}
if (-not $codeCli) {
    Write-Host "VS Code is not available. Skipping dbtLabsInc.dbt."
} else {
    Write-Host "==> dbt VS Code extension"
    & $codeCli --uninstall-extension dbt-labs.dbt-prime 2>$null
    & $codeCli --install-extension dbtLabsInc.dbt --force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installed official dbt VS Code extension (dbtLabsInc.dbt)."
    } else {
        Write-Host "Could not install dbtLabsInc.dbt. Install it from Extensions in VS Code."
    }
}
