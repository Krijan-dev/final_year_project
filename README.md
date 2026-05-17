# life_pattern_tracker

Flutter application for tracking app usage, insights, and productivity patterns.

- **Setup (MongoDB, API, Gemini):** [docs/HOW_TO_RUN.md](docs/HOW_TO_RUN.md)
- **GitHub secret scanning alerts:** [docs/SECURITY_GITHUB_ALERTS.md](docs/SECURITY_GITHUB_ALERTS.md)

## Quick Start

Install dependencies:

```powershell
flutter pub get
```

Run app (with Gemini key from `.env` — recommended):

```powershell
.\run_dev.ps1
```

Or:

```powershell
flutter run --dart-define-from-file=.env
```

One-time setup: copy `.env.example` to `.env` and set `GEMINI_API_KEY=...`.

**Note:** Restart the app after changing `.env` (hot reload does not reload keys). In **debug**, use **Account → Paste Gemini key (debug)** for immediate testing.

## Docker Workflow

```powershell
.\docker\run.ps1
```

## MongoDB / cloud backup

See [docs/HOW_TO_RUN.md](docs/HOW_TO_RUN.md) and [docs/MONGODB.md](docs/MONGODB.md).

## Full Guide

See [docs/USAGE_AND_DOCKER.md](docs/USAGE_AND_DOCKER.md) for app usage, Docker, and troubleshooting.
