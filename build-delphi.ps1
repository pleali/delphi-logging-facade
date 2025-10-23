<#
.SYNOPSIS
    Build Delphi projects from command line with automatic RAD Studio detection.

.DESCRIPTION
    This PowerShell script compiles Delphi projects (.dproj) from the command line
    with automatic detection of RAD Studio installation. It supports multiple build
    configurations, clean builds, verbose output, and automatic logging.

.PARAMETER ProjectFile
    Path to the Delphi project file (.dproj) - Required

.PARAMETER Config
    Build configuration: Debug, Release, or custom profile name
    Default: Debug

.PARAMETER Platform
    Target platform: Win32, Win64, OSX64, Android, etc.
    Default: Win32

.PARAMETER Clean
    Perform a clean build (rebuild all)

.PARAMETER VerboseOutput
    Enable verbose output with detailed compilation information

.PARAMETER LogFile
    Path to log file for compilation output
    Default: build-logs\<project>-<config>-<platform>-<timestamp>.log

.PARAMETER NoLog
    Disable automatic log file generation

.EXAMPLE
    .\build-delphi.ps1 examples\delphi\annotated-agent\AnnotatedAgent.dproj

.EXAMPLE
    .\build-delphi.ps1 examples\delphi\annotated-agent\AnnotatedAgent.dproj -Config Release -Platform Win64

.EXAMPLE
    .\build-delphi.ps1 examples\delphi\annotated-agent\AnnotatedAgent.dproj -Clean -VerboseOutput

.EXAMPLE
    .\build-delphi.ps1 examples\delphi\annotated-agent\AnnotatedAgent.dproj -Config Release -LogFile custom.log

.NOTES
    Author: MQTT-RPC Project
    Version: 2.0.0
    Requires: RAD Studio/Delphi installed
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to Delphi project file (.dproj)")]
    [string]$ProjectFile,

    [Parameter(Mandatory=$false, Position=1, HelpMessage="Build configuration (Debug, Release, etc.)")]
    [string]$Config = "Debug",

    [Parameter(Mandatory=$false, Position=2, HelpMessage="Target platform (Win32, Win64, etc.)")]
    [string]$Platform = "Win32",

    [Parameter(Mandatory=$false, HelpMessage="Perform a clean build")]
    [switch]$Clean,

    [Parameter(Mandatory=$false, HelpMessage="Enable verbose output")]
    [switch]$VerboseOutput,

    [Parameter(Mandatory=$false, HelpMessage="Path to log file")]
    [string]$LogFile = "",

    [Parameter(Mandatory=$false, HelpMessage="Disable automatic logging")]
    [switch]$NoLog
)

# ========================================
# Script Configuration
# ========================================

$ErrorActionPreference = "Stop"
$Script:VerboseMode = $VerboseOutput.IsPresent
$Script:StartTime = Get-Date

# ========================================
# Utility Functions
# ========================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor White
}

function Write-VerboseInfo {
    param([string]$Message)
    if ($Script:VerboseMode) {
        Write-Host "[VERBOSE] $Message" -ForegroundColor Gray
    }
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Get-ElapsedTime {
    $elapsed = (Get-Date) - $Script:StartTime
    return "{0:mm}m {0:ss}s" -f $elapsed
}

# ========================================
# RAD Studio Auto-Detection
# ========================================

function Find-RadStudio {
    Write-VerboseInfo "Searching for RAD Studio installation..."

    $rsvarsPath = $null
    $studioVersion = "Unknown"

    # Method 1: Try to find in PATH
    Write-VerboseInfo "Method 1: Checking PATH environment..."
    $pathRsvars = Get-Command "rsvars.bat" -ErrorAction SilentlyContinue
    if ($pathRsvars) {
        $rsvarsPath = $pathRsvars.Source
        Write-VerboseInfo "Found rsvars.bat in PATH: $rsvarsPath"

        # Extract version from path
        if ($rsvarsPath -match "Studio\\(\d+\.\d+)\\") {
            $studioVersion = $Matches[1]
        }
    }

    # Method 2 & 3: Search standard installation directories
    if (-not $rsvarsPath) {
        $searchPaths = @(
            "C:\Program Files (x86)\Embarcadero\Studio",
            "C:\Program Files\Embarcadero\Studio"
        )

        $maxVersion = 0
        $bestPath = $null

        foreach ($basePath in $searchPaths) {
            if (Test-Path $basePath) {
                Write-VerboseInfo "Searching in: $basePath"

                $studios = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
                foreach ($studio in $studios) {
                    $candidatePath = Join-Path $studio.FullName "bin\rsvars.bat"
                    if (Test-Path $candidatePath) {
                        Write-VerboseInfo "Found candidate: $candidatePath"

                        # Extract major version number
                        if ($studio.Name -match "^(\d+)\.") {
                            $majorVersion = [int]$Matches[1]
                            if ($majorVersion -gt $maxVersion) {
                                $maxVersion = $majorVersion
                                $bestPath = $candidatePath
                                $studioVersion = $studio.Name
                            }
                        }
                    }
                }
            }
        }

        $rsvarsPath = $bestPath
    }

    if (-not $rsvarsPath) {
        throw "ERROR: Could not find RAD Studio installation`n`nSearched in:`n  - PATH environment variable`n  - C:\Program Files (x86)\Embarcadero\Studio`n  - C:\Program Files\Embarcadero\Studio`n`nPlease ensure RAD Studio is installed."
    }

    Write-VerboseInfo "Selected RAD Studio version: $studioVersion"
    Write-VerboseInfo "Using rsvars.bat: $rsvarsPath"

    return @{
        Path = $rsvarsPath
        Version = $studioVersion
    }
}

# ========================================
# Build Functions
# ========================================

function Invoke-Clean {
    param([string]$ProjectPath)

    Write-Header "Cleaning Project"

    $projectDir = Split-Path -Parent $ProjectPath
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($ProjectPath)

    Write-VerboseInfo "Project directory: $projectDir"
    Write-VerboseInfo "Project name: $projectName"

    # Clean patterns
    $cleanPatterns = @(
        "*.dcu",
        "*.exe",
        "*.dll",
        "*.bpl",
        "*.dcp",
        "*.map",
        "*.rsm",
        "*.local",
        "*.identcache"
    )

    $cleanedCount = 0

    foreach ($pattern in $cleanPatterns) {
        $files = Get-ChildItem -Path $projectDir -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            Write-VerboseInfo "Deleting: $($file.FullName)"
            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
            $cleanedCount++
        }
    }

    # Clean output directories
    $outputDirs = @("Win32", "Win64", "__history", "__recovery")
    foreach ($dir in $outputDirs) {
        $dirPath = Join-Path $projectDir $dir
        if (Test-Path $dirPath) {
            Write-VerboseInfo "Removing directory: $dirPath"
            Remove-Item $dirPath -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedCount++
        }
    }

    Write-Success "Cleaned $cleanedCount item(s)"
    Write-Host ""
}

function Invoke-Build {
    param(
        [string]$ProjectPath,
        [string]$Configuration,
        [string]$TargetPlatform,
        [string]$LogPath,
        [string]$RsvarsPath
    )

    Write-Header "Building Project"

    # Determine MSBuild verbosity
    $msbuildVerbosity = if ($Script:VerboseMode) { "normal" } else { "minimal" }

    # Create a batch script that sets up environment and calls MSBuild
    $tempBatchFile = [System.IO.Path]::GetTempFileName() + ".bat"

    try {
        $batchContent = @"
@echo off
call "$RsvarsPath" >NUL 2>&1
msbuild "$ProjectPath" /t:Build /p:Config=$Configuration /p:Platform=$TargetPlatform /nologo /v:$msbuildVerbosity
exit /b %ERRORLEVEL%
"@

        Write-VerboseInfo "Creating temporary batch file: $tempBatchFile"
        $batchContent | Out-File -FilePath $tempBatchFile -Encoding ASCII

        # Execute the batch file
        Write-Host ""

        if ($LogPath) {
            Write-VerboseInfo "Logging output to: $LogPath"

            # Ensure log directory exists
            $logDir = Split-Path -Parent $LogPath
            if (-not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }

            # Build with logging
            $output = cmd /c $tempBatchFile 2>&1 | Tee-Object -FilePath $LogPath
            $buildSuccess = $LASTEXITCODE -eq 0

            # Display output
            $output | ForEach-Object { Write-Host $_ }
        }
        else {
            # Build without logging
            $output = cmd /c $tempBatchFile 2>&1
            $buildSuccess = $LASTEXITCODE -eq 0

            # Display output
            $output | ForEach-Object { Write-Host $_ }
        }
    }
    finally {
        # Clean up temp file
        if (Test-Path $tempBatchFile) {
            Remove-Item $tempBatchFile -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host ""

    if ($buildSuccess) {
        Write-Header "BUILD SUCCESSFUL"
        Write-Success "Build completed in $(Get-ElapsedTime)"

        # Show output file information
        $projectDir = Split-Path -Parent $ProjectPath
        $projectName = [System.IO.Path]::GetFileNameWithoutExtension($ProjectPath)

        # Try to find the output executable
        $possibleExePaths = @(
            (Join-Path $projectDir "$projectName.exe"),
            (Join-Path $projectDir "$TargetPlatform\$Configuration\$projectName.exe"),
            (Join-Path $projectDir "$TargetPlatform\$projectName.exe")
        )

        foreach ($exePath in $possibleExePaths) {
            if (Test-Path $exePath) {
                $exeInfo = Get-Item $exePath
                $sizeMB = [math]::Round($exeInfo.Length / 1MB, 2)
                Write-Success "Output: $exePath ($sizeMB MB)"
                break
            }
        }

        if ($LogPath) {
            Write-Info "Log file: $LogPath"
        }

        return 0
    }
    else {
        Write-Header "BUILD FAILED"
        Write-ErrorMessage "Build failed with exit code: $LASTEXITCODE"
        Write-ErrorMessage "Build time: $(Get-ElapsedTime)"

        if ($LogPath) {
            Write-Info "Check log file for details: $LogPath"
        }

        return 1
    }
}

# ========================================
# Main Script
# ========================================

try {
    Write-Header "Delphi Build Script (PowerShell)"

    # Validate project file
    if (-not (Test-Path $ProjectFile)) {
        throw "ERROR: Project file not found: $ProjectFile"
    }

    $projectFullPath = Resolve-Path $ProjectFile
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($ProjectFile)

    # Generate log file path if needed
    if (-not $NoLog -and -not $LogFile) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $logFileName = "$projectName-$Config-$Platform-$timestamp.log"
        $LogFile = Join-Path "build-logs" $logFileName
    }
    elseif ($NoLog) {
        $LogFile = $null
    }

    # Display build information
    Write-Info "Project:    $projectFullPath"
    Write-Info "Config:     $Config"
    Write-Info "Platform:   $Platform"
    Write-Info "Clean:      $($Clean.IsPresent)"
    Write-Info "Verbose:    $($VerboseOutput.IsPresent)"
    if ($LogFile) {
        Write-Info "Log file:   $LogFile"
    }
    Write-Host ""

    # Find RAD Studio
    $radStudio = Find-RadStudio
    Write-Info "RAD Studio: $($radStudio.Version)"
    Write-Info "rsvars.bat: $($radStudio.Path)"
    Write-Host ""

    # Clean if requested
    if ($Clean) {
        Invoke-Clean -ProjectPath $projectFullPath
    }

    # Build
    $exitCode = Invoke-Build -ProjectPath $projectFullPath -Configuration $Config -TargetPlatform $Platform -LogPath $LogFile -RsvarsPath $radStudio.Path

    Write-Host ""
    exit $exitCode
}
catch {
    Write-Host ""
    Write-ErrorMessage "FATAL ERROR: $($_.Exception.Message)"
    Write-Host ""
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Write-Host ""
    exit 1
}
