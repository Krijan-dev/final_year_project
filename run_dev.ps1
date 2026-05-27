$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Missing .env in project root." -ForegroundColor Yellow
    Write-Host "Copy .env.example to .env and set GEMINI_API_KEY=..." -ForegroundColor Yellow
    exit 1
}

# Only pass app keys to Flutter. Full .env has SMTP/MongoDB with spaces/comments that
# break --dart-define-from-file (splits into invalid extra CLI args → black screen on launch).
#
# Include DEV_SPOOF_DATA so you can show fake Health/Usage/Habits without granting permissions.
$flutterKeys = @("GEMINI_API_KEY", "API_BASE_URL", "DEV_SPOOF_DATA")
$flutterEnvFile = Join-Path $PSScriptRoot "flutter.env"
$out = New-Object System.Collections.Generic.List[string]
foreach ($line in Get-Content $envFile -Encoding UTF8) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
    if ($line -match '^\s*([^=]+)=(.*)$') {
        $key = $Matches[1].Trim()
        if ($flutterKeys -contains $key) {
            $out.Add("$key=$($Matches[2].Trim())")
        }
    }
}
if ($out.Count -eq 0) {
    Write-Host "No GEMINI_API_KEY or API_BASE_URL in .env" -ForegroundColor Yellow
    exit 1
}
$out | Set-Content -Path $flutterEnvFile -Encoding utf8
Write-Host "Using flutter.env ($($out.Count) keys); SMTP/MongoDB are not passed to Flutter." -ForegroundColor DarkGray

& flutter run --dart-define-from-file="$flutterEnvFile" @args
