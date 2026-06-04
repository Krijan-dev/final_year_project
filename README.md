# life_pattern_tracker

Flutter application for tracking app usage, insights, and productivity patterns.

- **Full system guide (app + Render + website + docs map):** [docs/PROJECT_COMPLETE_GUIDE.md](docs/PROJECT_COMPLETE_GUIDE.md) · [Word](docs/PROJECT_COMPLETE_GUIDE.docx)
- **Setup (MongoDB, API, Gemini):** [docs/HOW_TO_RUN.md](docs/HOW_TO_RUN.md)
- **Env sync (app + website + server):** [docs/ENV_SETUP.md](docs/ENV_SETUP.md) — run `.\scripts\sync-env.ps1`
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

## Database + admin website plan

Full plan (Word + Markdown): [docs/DATABASE_AND_WEBSITE_PLAN.docx](docs/DATABASE_AND_WEBSITE_PLAN.docx) · [docs/DATABASE_AND_WEBSITE_PLAN.md](docs/DATABASE_AND_WEBSITE_PLAN.md)

**No local npm server:** [docs/DEPLOY_API_CLOUD.md](docs/DEPLOY_API_CLOUD.md) — deploy API to Render + Atlas; phone syncs over HTTPS.

**Future nav tab ideas:** [docs/NAV_BAR_IDEAS.md](docs/NAV_BAR_IDEAS.md)

**Website (separate repo):** [LifePatternAI_Website](https://github.com/Krijan-dev/LifePatternAI_Website) — Next.js on Vercel · [docs/VERCEL_WEBSITE_GUIDE.md](docs/VERCEL_WEBSITE_GUIDE.md)

## Full Guide

See [docs/USAGE_AND_DOCKER.md](docs/USAGE_AND_DOCKER.md) for app usage, Docker, and troubleshooting.
