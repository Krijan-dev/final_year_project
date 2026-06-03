# Writes flutter.env from .env (Flutter keys only). Used by run_dev and Firebase release.
$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$envFile = Join-Path $projectRoot ".env"
$flutterEnvFallback = Join-Path $projectRoot "flutter.env"
$flutterEnvFile = $flutterEnvFallback

function Read-EnvFile {
  param([string]$Path)
  $result = @{}
  if (-not (Test-Path $Path)) { return $result }
  foreach ($line in Get-Content $Path -Encoding UTF8) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
    if ($line -match '^\s*([^=]+)=(.*)$') {
      $key = $Matches[1].Trim()
      $value = $Matches[2].Trim()
      if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      if ($value.StartsWith("'") -and $value.EndsWith("'")) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      $result[$key] = $value
    }
  }
  return $result
}

if (-not (Test-Path $envFile)) {
  throw "Missing .env in project root. Copy .env.example to .env and set GEMINI_API_KEY and API_BASE_URL."
}

$flutterKeys = @("GEMINI_API_KEY", "API_BASE_URL")
$values = Read-EnvFile $envFile

# If .env is missing keys, merge from existing flutter.env (common when only flutter.env was edited).
if (Test-Path $flutterEnvFallback) {
  $fromFlutter = Read-EnvFile $flutterEnvFallback
  foreach ($key in $flutterKeys) {
    if ([string]::IsNullOrWhiteSpace($values[$key]) -and -not [string]::IsNullOrWhiteSpace($fromFlutter[$key])) {
      $values[$key] = $fromFlutter[$key]
      Write-Host "Using $key from flutter.env (not set in .env)." -ForegroundColor Yellow
    }
  }
}

if ([string]::IsNullOrWhiteSpace($values["GEMINI_API_KEY"])) {
  throw @"
GEMINI_API_KEY is empty or missing.

Fix: open .env in the project root and set:
  GEMINI_API_KEY=your_key_here

Or copy from flutter.env, then run the release script again.
"@
}
if ([string]::IsNullOrWhiteSpace($values["API_BASE_URL"])) {
  throw @"
API_BASE_URL is empty or missing.

Fix: open .env and set:
  API_BASE_URL=https://your-render-url.onrender.com
"@
}

$out = New-Object System.Collections.Generic.List[string]
foreach ($key in $flutterKeys) {
  $out.Add("$key=$($values[$key])")
}
$out | Set-Content -Path $flutterEnvFile -Encoding utf8
Write-Host "Wrote flutter.env ($($out.Count) keys)" -ForegroundColor DarkGray
