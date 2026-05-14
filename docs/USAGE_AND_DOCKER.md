# Life Pattern Tracker - Usage and Docker Guide

## 1) What this app does

`life_pattern_tracker` is a Flutter app that helps you monitor digital behavior:
- Dashboard views for daily and trend insights
- Charts for hourly and weekly usage
- App usage breakdown
- Chatbot and AI suggestion pages for productivity guidance

## 2) Run the app normally (without Docker)

### Prerequisites
- Flutter SDK installed
- Android Studio (or Android SDK + emulator/device)
- Android usage access permission available on target device

### Install dependencies
```powershell
flutter pub get
```

### Run the app
```powershell
flutter run
```

For Gemini AI without typing the key each time, use a `.env` file — see **section 6**.

## 3) Run setup/check commands with Docker

This repo includes Docker files so you can run Flutter commands in a consistent container.

### Prerequisites
- Docker Desktop installed and running

### Build and run one command workflow
From the project root:
```powershell
.\docker\run.ps1
```

This script will run:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

All inside Docker.

## 4) Run individual Docker commands

From project root:

```powershell
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
```

## 5) Notes and limitations

- This Docker setup is best for dependency setup, static analysis, and tests.
- Building and running Android APKs fully inside Docker is possible but requires a larger Android SDK/emulator setup and is intentionally not included here.
- For day-to-day app execution on device/emulator, use local Flutter + Android tooling.

## 6) Gemini API key (`.env` file — recommended)

Flutter can load compile-time defines from a **`.env`** file in the project root (do not commit it).

### One-time setup

1. Copy the example file:

```powershell
copy .env.example .env
```

2. Edit `.env` and set your key (no quotes needed):

```env
GEMINI_API_KEY=your_actual_key_here
```

### Run / build without typing the key each time

```powershell
.\run_dev.ps1
```

If PowerShell blocks the script (**not digitally signed** / execution policy), use:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_dev.ps1
```

Or run **`run_dev.bat`** from Command Prompt (or double‑click it in Explorer).

Or:

```powershell
flutter run --dart-define-from-file=.env
```

Release APK:

```powershell
.\build_apk_with_env.ps1
```

Or use **`build_apk_with_env.bat`** if `.ps1` scripts are blocked.

Or:

```powershell
flutter build apk --dart-define-from-file=.env
```

### VS Code / Cursor

Use the launch configuration **"life_pattern_tracker (with .env)"** (requires `.env` to exist).

### Older / manual override

```powershell
flutter run --dart-define=GEMINI_API_KEY=your_actual_key_here
```

Notes:

- Never commit `.env` or real API keys (`.env` is listed in `.gitignore`).
- If the key is missing, the app shows fallback messages/suggestions instead of AI responses.
- **`String.fromEnvironment` is fixed when the app process starts.** Creating or editing `.env` then using **hot reload only** does not update the key. Do a **full stop** of the run session, then start again with `.\run_dev.ps1` or `--dart-define-from-file=.env`.
- **Cursor / VS Code:** This repo includes `.vscode/settings.json` so **Run / Debug** passes `--dart-define-from-file=.env` from the project root. If you added it recently, **reload the window** or restart the IDE once, then stop the app and run again.
- **`.env` format:** use `GEMINI_API_KEY=yourkey` with **no space** after `=`. A leading space in the value can prevent the define from loading correctly in some setups.
- **Debug workaround:** Account menu → **Paste Gemini key (debug)** stores the key in Hive on the device; that path **does** update after save without recompiling, and survives hot reload.
