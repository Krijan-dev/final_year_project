param(
  [string]$AppId = "1:502535900986:android:d429bf0426b900eff58a03",
  [string]$Groups = "",
  [string]$Testers = "",
  [string]$ReleaseNotes = "",
  [switch]$SkipBuild,
  [switch]$Debug,
  [switch]$GenerateQr
)

$ErrorActionPreference = "Stop"

function Assert-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is not installed. Install it and retry."
  }
}

Assert-Command "flutter"
Assert-Command "firebase"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $projectRoot

$flutterEnvFile = Join-Path $projectRoot "flutter.env"
& (Join-Path $PSScriptRoot "sync_flutter_env.ps1")

if ($Debug) {
  $apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
} else {
  $apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"
}

if (-not $SkipBuild) {
  if ($Debug) {
    Write-Host "Building debug APK (with API keys)..." -ForegroundColor Cyan
    flutter build apk --debug --dart-define-from-file="$flutterEnvFile"
  } else {
    Write-Host "Building release APK for testers (with API keys, no demo spoof)..." -ForegroundColor Cyan
    flutter build apk --release --dart-define-from-file="$flutterEnvFile"
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter APK build failed."
  }
}

if (-not (Test-Path $apkPath)) {
  throw "APK not found at $apkPath. Build failed or path changed."
}

if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
  $ReleaseNotes = "Life Pattern Tracker test build - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

$firebaseArgs = @(
  "appdistribution:distribute",
  $apkPath,
  "--app", $AppId,
  "--release-notes", $ReleaseNotes
)

if (-not [string]::IsNullOrWhiteSpace($Groups)) {
  $firebaseArgs += @("--groups", $Groups)
}
if (-not [string]::IsNullOrWhiteSpace($Testers)) {
  $firebaseArgs += @("--testers", $Testers)
}

if ([string]::IsNullOrWhiteSpace($Groups) -and [string]::IsNullOrWhiteSpace($Testers)) {
  Write-Host "Upload only (no -Groups / -Testers). Invite testers from Firebase Console after upload." -ForegroundColor Yellow
}

Write-Host "Uploading APK to Firebase App Distribution..." -ForegroundColor Cyan
& firebase @firebaseArgs
if ($LASTEXITCODE -ne 0) {
  throw @"
Firebase command failed.

If you saw 'uploaded ... successfully' but distribution failed with 404:
  - Use -Testers "email@gmail.com" instead of -Groups, or fix group alias in Console.

Re-upload after fixing keys:
  powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1 -Testers "you@gmail.com"
"@
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "APK: $apkPath"
if (-not [string]::IsNullOrWhiteSpace($Groups)) { Write-Host "Groups: $Groups" }
if (-not [string]::IsNullOrWhiteSpace($Testers)) { Write-Host "Testers: $Testers" }

if ($GenerateQr) {
  $qrScript = Join-Path $PSScriptRoot "generate_tester_qr.ps1"
  if (Test-Path $qrScript) {
    Write-Host ""
    & powershell -ExecutionPolicy Bypass -File $qrScript
  }
} else {
  $linkFile = Join-Path $projectRoot "tester_invite_link.txt"
  if (Test-Path $linkFile) {
    Write-Host ""
    Write-Host "Tip: run with -GenerateQr to refresh build\tester_invite_qr.png for self-serve testers." -ForegroundColor Yellow
  } else {
    Write-Host ""
    Write-Host "For QR self-serve testing: create an Invite link in Firebase Console, save to tester_invite_link.txt, then run .\scripts\generate_tester_qr.ps1" -ForegroundColor Yellow
  }
}
