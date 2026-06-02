$ErrorActionPreference = "Stop"

$ProjectDir = $PSScriptRoot
$BuildDir   = "$ProjectDir\build\Desktop_Qt_6_9_3_MSVC2022_64bit-Release"
$ReleaseDir = "$BuildDir\release"
$ProFile    = "$ProjectDir\ImageLoop.pro"
$VsVars     = "D:\Visual Studio\Community\VC\Auxiliary\Build\vcvarsall.bat"
$QMake      = "D:\Qt\6.9.3\msvc2022_64\bin\qmake.exe"
$WinDeploy  = "D:\Qt\6.9.3\msvc2022_64\bin\windeployqt.exe"

# 1. kill running instance
$proc = Get-Process -Name "ImageLoop" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "Stopping ImageLoop.exe..." -ForegroundColor Yellow
    $proc | Stop-Process -Force
    Start-Sleep -Seconds 1
}

# 2. clean build dir
if (Test-Path $BuildDir) {
    Write-Host "Cleaning build directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "$BuildDir\*" -ErrorAction SilentlyContinue
}

# 3. create build dir
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

# 4. generate temp build script
$batch = @"
@echo off
call "$VsVars" x64 > nul
if errorlevel 1 exit /b 1
cd /d "$BuildDir"
echo Running qmake...
"$QMake" "$ProFile" -spec win32-msvc CONFIG+=release
if errorlevel 1 exit /b 1
echo Building...
nmake release
if errorlevel 1 exit /b 1
echo Deploying Qt DLLs...
"$WinDeploy" "$ReleaseDir\ImageLoop.exe"
if errorlevel 1 exit /b 1
"@

$batchFile = "$env:TEMP\build_imageloop.bat"
$batch | Out-File -FilePath $batchFile -Encoding ASCII

try {
    Write-Host "Running qmake..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -ne 0) { throw "Build failed (exit code $($proc.ExitCode))" }
    Write-Host "Done: $ReleaseDir\ImageLoop.exe" -ForegroundColor Green
} finally {
    Remove-Item $batchFile -Force -ErrorAction SilentlyContinue
}
