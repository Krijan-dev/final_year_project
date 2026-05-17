$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Missing .env. Copy .env.example to .env and set GEMINI_API_KEY." -ForegroundColor Yellow
    exit 1
}

flutter build apk "--dart-define-from-file=$envFile" @args
