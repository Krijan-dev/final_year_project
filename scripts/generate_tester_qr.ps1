param(
  [string]$Url = "",
  [string]$LinkFile = "",
  [string]$OutputPath = "",
  [int]$Size = 400
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$defaultLinkFile = Join-Path $projectRoot "tester_invite_link.txt"
$defaultOutput = Join-Path $projectRoot "build\tester_invite_qr.png"

if ([string]::IsNullOrWhiteSpace($LinkFile)) {
  $LinkFile = $defaultLinkFile
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = $defaultOutput
}

if ([string]::IsNullOrWhiteSpace($Url)) {
  if (-not (Test-Path $LinkFile)) {
    throw @"
No invite URL provided.

1. Firebase Console -> App Distribution -> Invite links -> Create invite link
2. Copy the link into: $LinkFile
   (see tester_invite_link.example.txt)
3. Run: powershell -ExecutionPolicy Bypass -File .\scripts\generate_tester_qr.ps1
"@
  }
  foreach ($line in Get-Content $LinkFile -Encoding UTF8) {
    $t = $line.Trim()
    if ($t.StartsWith("#") -or $t.Length -eq 0) { continue }
    if ($t -match "^https?://") {
      $Url = $t
      break
    }
  }
}

if ([string]::IsNullOrWhiteSpace($Url) -or $Url -notmatch "^https?://") {
  throw "Invite URL must start with http:// or https://. Got: '$Url'"
}

$outDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$encoded = [uri]::EscapeDataString($Url)
$qrApi = "https://api.qrserver.com/v1/create-qr-code/?size=${Size}x${Size}&data=$encoded"

Write-Host "Generating QR for tester invite link..." -ForegroundColor Cyan
Write-Host "URL: $Url"
Invoke-WebRequest -Uri $qrApi -OutFile $OutputPath -UseBasicParsing | Out-Null

Write-Host ""
Write-Host "Saved QR image:" -ForegroundColor Green
Write-Host $OutputPath
Write-Host ""
Write-Host "Testers scan the QR, enter their email, accept with Google, then install from Firebase App Tester or the email link."
