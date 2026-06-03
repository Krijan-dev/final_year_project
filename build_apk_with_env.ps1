$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

& (Join-Path $PSScriptRoot "scripts\sync_flutter_env.ps1")

$flutterEnvFile = Join-Path $PSScriptRoot "flutter.env"
flutter build apk --release --dart-define-from-file="$flutterEnvFile" @args
