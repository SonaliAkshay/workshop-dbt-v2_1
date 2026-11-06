# Quick health check (no build). Windows PowerShell.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Project = $Root

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
        if (Test-Path $path) { $ordered += $path }
    }
    foreach ($candidate in $ordered) {
        $versionLine = (& $candidate --version 2>$null | Select-Object -First 1)
        if ($versionLine -match '^dbt\s+2\.') {
            return @{ Name = $candidate; Version = $versionLine }
        }
    }
    return $null
}

$dbt = Resolve-DbtV2
if (-not $dbt) {
    Write-Error "FAIL: dbt v2 not found (try .\scripts\setup.ps1 -Install)"
    exit 1
}

Write-Host "OK: $($dbt.Name) ($($dbt.Version))"
Set-Location $Project
& $dbt.Name debug --profiles-dir .
if ($LASTEXITCODE -ne 0) { throw "dbt debug failed" }
Write-Host "OK: DuckDB connection"
