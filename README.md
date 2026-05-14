# life_pattern_tracker

Flutter application for tracking app usage, insights, and productivity patterns.

## Quick Start

Install dependencies:

```powershell
flutter pub get
```

Run app (with Gemini key from `.env` — recommended):

**If PowerShell blocks `run_dev.ps1` (execution policy):** use Command Prompt or double‑click `run_dev.bat`, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_dev.ps1
```

Otherwise:

```powershell
.\run_dev.ps1
```

Or from **cmd.exe**:

```bat
run_dev.bat
```

Or pass the file directly:

```powershell
flutter run --dart-define-from-file=.env
```

One-time setup: copy `.env.example` to `.env` and set `GEMINI_API_KEY=...`.

**Note:** The key from `.env` is applied when the **Flutter process starts**. Hot reload does not reload it. Stop the app, then run `.\run_dev.ps1` again. In **debug**, you can also use **Account → Paste Gemini key (debug)** so the key works immediately (including after hot reload).

## Docker Workflow

Run setup + analyze + tests in Docker:

```powershell
.\docker\run.ps1
```

## Full Guide

See `docs/USAGE_AND_DOCKER.md` for:
- app usage instructions
- Docker install/run commands
- limitations and troubleshooting notes
