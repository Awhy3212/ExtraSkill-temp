#Requires -Version 5.1
<#
.SYNOPSIS
    Builds every configuration of ExtraskillTemp.
.DESCRIPTION
    Locates MSBuild via vswhere, then builds all four configurations
    (Debug|Win32, Release|Win32, Debug|x64, Release|x64).
    Run from the repo root:  .\scripts\build_all.ps1
.PARAMETER Configuration
    Optional. Build only a specific configuration (Debug or Release).
    If omitted, both are built.
.PARAMETER Platform
    Optional. Build only a specific platform (Win32 or x64).
    If omitted, both are built.
.PARAMETER Clean
    If set, runs a /t:Clean before building.
#>
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration,

    [ValidateSet("Win32", "x64")]
    [string]$Platform,

    [switch]$Clean
)

# ------ Resolve paths ------------------------------------------------------------------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent $ScriptDir
$SolutionFile = Join-Path $RepoRoot 'ExtraskillTemp.slnx'
$ProjectFile = Join-Path $RepoRoot 'ExtraskillTemp.vcxproj'

# Prefer .slnx if it exists; fall back to .vcxproj
if (Test-Path $SolutionFile) {
    $BuildTarget = $SolutionFile
}
elseif (Test-Path $ProjectFile) {
    $BuildTarget = $ProjectFile
}
else {
    Write-Host "[!] Could not find ExtraskillTemp.slnx or .vcxproj in $RepoRoot" -ForegroundColor Red
    exit 1
}

# ------ Locate MSBuild via vswhere ---------------------------------------------------------------------------------------------------------------------
function Find-MSBuild {
    # Try vswhere (ships with VS 2017+ and Build Tools)
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $installPath = & $vswhere -latest -products * `
            -requires Microsoft.Component.MSBuild `
            -property installationPath 2>$null

        if ($installPath) {
            # VS 2022+ keeps MSBuild under "Current"
            $msbuild = Join-Path $installPath 'MSBuild\Current\Bin\amd64\MSBuild.exe'
            if (Test-Path $msbuild) { return $msbuild }

            $msbuild = Join-Path $installPath 'MSBuild\Current\Bin\MSBuild.exe'
            if (Test-Path $msbuild) { return $msbuild }
        }
    }

    # Fallback: check PATH
    $inPath = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }

    return $null
}

$MSBuild = Find-MSBuild
if (-not $MSBuild) {
    Write-Host "[!] MSBuild not found. Install Visual Studio 2022 or Build Tools." -ForegroundColor Red
    exit 1
}
Write-Host "[*] MSBuild: $MSBuild" -ForegroundColor DarkGray

# ------ Build matrix ---------------------------------------------------------------------------------------------------------------------------------------------------------------
$Configs = if ($Configuration) { @($Configuration) } else { @('Debug', 'Release') }
$Platforms = if ($Platform) { @($Platform) }      else { @('Win32', 'x64') }

$Results = @()
$Failed = 0
$TotalSw = [System.Diagnostics.Stopwatch]::StartNew()

# ------ Output directory ---------------------------------------------------------------------------------------------------------------------------------------------------
$BuildOutputRoot = Join-Path $RepoRoot 'build'
if (-not (Test-Path $BuildOutputRoot)) {
    New-Item -ItemType Directory -Path $BuildOutputRoot -Force | Out-Null
}

# ------ Build loop ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach ($cfg in $Configs) {
    foreach ($plat in $Platforms) {
        $label = "$cfg|$plat"
        Write-Host ""
        Write-Host ("=" * 60) -ForegroundColor Cyan
        Write-Host "  Building: $label" -ForegroundColor Cyan
        Write-Host ("=" * 60) -ForegroundColor Cyan

        $outDir = Join-Path $BuildOutputRoot "$cfg\$plat"
        if (-not (Test-Path $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        $logFile = Join-Path $BuildOutputRoot "$cfg`_$plat.log"

        # Construct MSBuild arguments as a string safely using -f operator to avoid Start-Process auto-quoting issues
        $escapedLogFile = $logFile -replace '\\', '\\'
        $msbuildArgs = '"{0}" /p:Configuration={1} /p:Platform={2} /p:OutDir="{3}\\" /m /nologo /v:minimal /fl /flp:"logfile={4};verbosity=detailed"' -f $BuildTarget, $cfg, $plat, $outDir, $escapedLogFile

        if ($Clean) {
            $msbuildArgs += ' /t:Clean;Build'
        }
        else {
            $msbuildArgs += ' /t:Build'
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        # Run MSBuild
        $proc = Start-Process -FilePath $MSBuild `
            -ArgumentList $msbuildArgs `
            -NoNewWindow -Wait -PassThru

        $sw.Stop()
        $elapsed = $sw.Elapsed.ToString("mm\:ss\.ff")

        if ($proc.ExitCode -eq 0) {
            $status = 'OK'
            Write-Host "[+] $label  ->  SUCCESS  ($elapsed)" -ForegroundColor Green
        }
        else {
            $status = 'FAIL'
            $Failed++
            Write-Host "[!] $label  ->  FAILED   ($elapsed)  - see $logFile" -ForegroundColor Red
        }

        $Results += [PSCustomObject]@{
            Config   = $cfg
            Platform = $plat
            Status   = $status
            Time     = $elapsed
            Log      = $logFile
        }
    }
}

$TotalSw.Stop()

# ------ Summary ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host "  BUILD SUMMARY" -ForegroundColor Magenta
Write-Host ("=" * 60) -ForegroundColor Magenta

$Results | Format-Table -AutoSize

$total = $Results.Count
$passed = $total - $Failed
Write-Host "  $passed / $total succeeded   |   Total time: $($TotalSw.Elapsed.ToString('mm\:ss\.ff'))" -ForegroundColor White

if ($Failed -gt 0) {
    Write-Host ""
    Write-Host "  [!] $Failed build(s) FAILED. Check logs in $BuildOutputRoot" -ForegroundColor Red
    exit 1
}
else {
    Write-Host ""
    Write-Host "  [+] All builds passed!" -ForegroundColor Green
    Write-Host "  [*] Binaries are in: $BuildOutputRoot" -ForegroundColor DarkGray
    exit 0
}


