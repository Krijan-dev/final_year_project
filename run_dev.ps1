$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Missing .env in project root." -ForegroundColor Yellow
    Write-Host "Copy .env.example to .env and set GEMINI_API_KEY=..." -ForegroundColor Yellow
    exit 1
}

flutter run "--dart-define-from-file=$envFile" @args
