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
