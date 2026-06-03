# Writes flutter.env from .env (Flutter keys only). Used by run_dev and Firebase release.
$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$envFile = Join-Path $projectRoot ".env"
$flutterEnvFile = Join-Path $projectRoot "flutter.env"

if (-not (Test-Path $envFile)) {
  throw "Missing .env in project root. Copy .env.example to .env and set GEMINI_API_KEY and API_BASE_URL."
}

$flutterKeys = @("GEMINI_API_KEY", "API_BASE_URL")
$values = @{}
foreach ($line in Get-Content $envFile -Encoding UTF8) {
  if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
  if ($line -match '^\s*([^=]+)=(.*)$') {
    $key = $Matches[1].Trim()
    if ($flutterKeys -contains $key) {
      $values[$key] = $Matches[2].Trim()
    }
  }
}

if ([string]::IsNullOrWhiteSpace($values["GEMINI_API_KEY"])) {
  throw "GEMINI_API_KEY is empty in .env — testers need this for AI features."
}
if ([string]::IsNullOrWhiteSpace($values["API_BASE_URL"])) {
  throw "API_BASE_URL is empty in .env — testers need this for login/sync."
}

$out = New-Object System.Collections.Generic.List[string]
foreach ($key in $flutterKeys) {
  if ($values.ContainsKey($key)) {
    $out.Add("$key=$($values[$key])")
  }
}
$out | Set-Content -Path $flutterEnvFile -Encoding utf8
Write-Host "Wrote flutter.env ($($out.Count) keys)" -ForegroundColor DarkGray
