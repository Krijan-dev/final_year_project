@echo off
setlocal
cd /d "%~dp0"
if not exist ".env" (
  echo Missing .env. Copy .env.example to .env and set GEMINI_API_KEY.
  exit /b 1
)
set "ENVFILE=%~dp0.env"
flutter build apk "--dart-define-from-file=%ENVFILE%" %*
