# Life Pattern Tracker — Complete project guide

> **Word version:** [PROJECT_COMPLETE_GUIDE.docx](PROJECT_COMPLETE_GUIDE.docx)  
> **Regenerate:** `python docs/generate_project_guide.py`  
> **User-facing manual:** [User_Manual_In_A_Nutshell.docx](User_Manual_In_A_Nutshell.docx)

This document explains how the **Android app**, **Node API on Render**, **MongoDB Atlas**, and **admin website on Vercel** fit together, and what every major file in `docs/` is for.

---

## 1. System overview

Life Pattern Tracker is a **digital wellbeing** product: screen time, habits, mood, health (steps/sleep), AI insights, and optional live support. Nothing runs on your laptop in production except development builds.

```
┌─────────────────────┐     HTTPS (Bearer token)     ┌──────────────────────────┐
│  Flutter Android    │ ───────────────────────────► │  Node.js API (Render)    │
│  lib/ + android/    │                              │  server/src/index.js     │
└─────────┬───────────┘                              └────────────┬─────────────┘
          │                                                       │
          │ Usage Access (on-device only)                         │ Mongoose
          │ Health Connect (on-device read)                       ▼
          ▼                                            ┌──────────────────────────┐
   Phone system stats                                  │  MongoDB Atlas (cloud)   │
   + fitness apps → HC                                 │  users, usagedays,       │
                                                       │  habitsnapshots, support │
┌─────────────────────┐     HTTPS                      └──────────────────────────┘
│  Next.js website    │ ───────────────────────────►   same Render API
│  (Vercel, separate  │     Admin routes + proxies
│   GitHub repo)      │
└─────────────────────┘

Optional: Google Gemini (AI chat/insights) — key in app `.env` / `flutter.env`
Optional: Firebase (App Distribution for tester APKs)
```

| Layer | Technology | Hosted where |
|-------|------------|--------------|
| Mobile app | Flutter 3, Riverpod, Hive | User’s Android phone |
| Screen time source | Android `UsageStatsManager` | Phone only (not cloud for display) |
| Health data | Health Connect + native Kotlin bridge | Phone |
| REST API | Express + Mongoose | **Render** (free tier) |
| Database | MongoDB | **Atlas** M0 |
| Admin website | Next.js 14 | **Vercel** ([LifePatternAI_Website](https://github.com/Krijan-dev/LifePatternAI_Website)) |
| Tester APK | Firebase App Distribution | `scripts/release_to_firebase.ps1` |

**Critical rule:** The Flutter app **never** connects to MongoDB directly. It only talks to `API_BASE_URL`. The website also calls that URL—never Atlas from the browser.

---

## 2. Repository layout

```
final_year_project/
├── lib/                    # Flutter application (Dart)
├── android/                # Native Android (Usage Access, Health Connect)
├── server/                 # Node API → deploy to Render
├── docs/                   # All project documentation (this folder)
├── scripts/                # sync-env, release_to_firebase, sync_flutter_env
├── .env.example            # Template for secrets (copy to .env, gitignored)
├── flutter.env.example     # Subset for APK builds (GEMINI + API only)
├── docker-compose.yml      # Optional local stack
├── pubspec.yaml
└── README.md               # Quick links into docs/
```

There is **no `website/` folder** in this repo. The marketing/admin site lives in a **separate repository** and is deployed to Vercel (see §7).

---

## 3. Flutter app — how it works

### 3.1 Startup (`lib/main.dart`)

1. Optional **Firebase** init (distribution / future features; app still runs if missing).
2. Load **`flutter.env`** or **`.env`** for `API_BASE_URL` and `GEMINI_API_KEY`.
3. Open **Hive** boxes for local settings and habit data.
4. Show **Welcome** (first launch) or **HomeShell** when signed in on Android.

Auth and API require `API_BASE_URL` to be set at build time (`run_dev.ps1` or `--dart-define-from-file=flutter.env`).

### 3.2 Bottom navigation (`lib/screens/home_shell.dart`)

| Tab | Screen | Main data source |
|-----|--------|------------------|
| **Home** | `dashboard_screen.dart` | Usage Access + habits + health summary |
| **Time** | `screen_time_screen.dart` | Usage Access (today, charts, app limits) |
| **Habits** | `habit_screen.dart` | Hive (local); cloud backup via API |
| **Insights** | `insights_screen.dart` | Calculated metrics + optional Gemini AI |
| **Health** | `health_screen.dart` | Health Connect (native `HealthConnectBridge`) |

**Floating chat** (`lib/widgets/floating_chat_overlay.dart`): opens AI assistant; signed-in users can request **live support** (polls Render API).

**Account** (`lib/screens/account_screen.dart`): opened from profile avatar—permissions, cloud backup, theme, password reset, crisis help.

### 3.3 State management (Riverpod providers)

| Provider | Role |
|----------|------|
| `authProvider` | Session email, remote register/login/verify via `AuthRemoteService` |
| `usageProvider` | Usage Access permission, today’s usage, refresh from device |
| `habitTrackerProvider` | Weekly habits, mood, today’s log (Hive) |
| `dashboardProvider` | Aggregated metrics for Home |
| `insightsProvider` | Wellness / risk scores and recommendations |
| `themeModeProvider` | Light / dark / system |
| `screenTimeLimitsProvider` | Per-app daily limits + notifications |

### 3.4 Local storage (Hive)

| Data | Stored locally | Synced to cloud? |
|------|----------------|------------------|
| Habits, mood, logs | Yes (`habit_tracker_storage_service.dart`) | Yes — `habit_snapshots` on push / restore |
| Screen time days | Yes (`usage_storage_service.dart`) | Push on backup; **not used for display after sign-in** |
| Auth session | Email + Bearer token | N/A |
| Settings / theme | Hive box | No |

**Sign-in behaviour** (`cloud_sync_service.dart` + `usage_provider.dart`):

- **Habits:** If local habits are empty, pull latest snapshot from API; always push current week on sign-in and manual backup.
- **Screen time:** **Device only** for UI. Cloud may still receive uploads on “Back up to cloud” but the app does **not** download old usage to replace phone stats (avoids stale/wrong screen time).

### 3.5 Native Android (`android/app/src/main/kotlin/...`)

| Component | Purpose |
|-----------|---------|
| `MainActivity.kt` | Method channel `life_pattern_tracker/usage` — usage stats, Health summary, open settings |
| `UsageStatsCalculator.kt` | Accurate daily/hourly screen time (matches system better) |
| `HealthConnectBridge.kt` | Read steps/sleep; fitness-app origin filter; **freshness** (`lastDataUpdateMillis`, stale flag) |
| `FitnessAppRegistry.kt` | Detect Samsung Health, Google Fit, Fitbit, etc. |
| `AndroidCompat.kt` | OEM-specific Usage Access / Health Connect intents |

Permissions:

- **Usage access** — required for Time tab and Home screen time (prompt on those screens, status under Account).
- **Health Connect** — Steps + Sleep read; user enables sharing in fitness app first.

### 3.6 AI (Gemini)

- Key: `GEMINI_API_KEY` in `.env` / `flutter.env`.
- Used in Insights and chat (`lib/services/gemini_service.dart`).
- Runs from the **app** to Google’s API—not through Render (unless you add a proxy later).

### 3.7 Configuration (`lib/services/api_config.dart`)

`API_BASE_URL` from:

1. `--dart-define=API_BASE_URL=...`, or  
2. `flutter.env` / `.env` via `flutter_dotenv`.

Empty URL → auth and cloud sync disabled; app may still work offline for habits/usage locally.

---

## 4. API server (`server/`) and Render

### 4.1 What Render runs

- **Root directory:** `server`
- **Build:** `npm install`
- **Start:** `npm start` → `src/index.js`
- **Env vars:** `MONGODB_URI` (required), `PORT`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, SMTP vars for email

Free tier **sleeps** after ~15 min idle; first request may take 30–60s.

**Health check:** `GET https://YOUR-SERVICE.onrender.com/health` → `{"ok":true,"mongo":true}`

See [DEPLOY_API_CLOUD.md](DEPLOY_API_CLOUD.md) and [RENDER_FIX.md](RENDER_FIX.md).

### 4.2 Authentication

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/auth/send-verification` | Email sign-up code (SMTP or dev code in logs) |
| `POST /api/v1/auth/verify-email` | Verify code → `verificationToken` |
| `POST /api/v1/auth/register` | Create user (needs verification token) |
| `POST /api/v1/auth/login` | Returns `{ email, token }` |
| `POST /api/v1/auth/logout` | Clears session (Bearer) |
| `POST /api/v1/auth/forgot-password` | Reset code email |
| `POST /api/v1/auth/verify-reset-code` | Validate reset code |
| `POST /api/v1/auth/reset-password` | Set new password |
| `DELETE /api/v1/users/me` | Delete account + all user data (password required) |

App sends `Authorization: Bearer <token>` on protected routes. Token stored in `AuthTokenStore`.

### 4.3 User data (Bearer, own email only)

| Endpoint | Description |
|----------|-------------|
| `PUT /api/v1/users/:email/usage-days/:dayKey` | Upload one day of screen time JSON |
| `GET /api/v1/users/:email/usage-days` | List usage days (app rarely uses for display) |
| `PUT /api/v1/users/:email/habit-snapshot/:weekKey` | Upload habits + mood + logs |
| `GET /api/v1/users/:email/habit-snapshots/latest` | Latest week snapshot |
| `GET /api/v1/users/:email/habit-snapshot/:weekKey` | Specific week |

### 4.4 Support & safety

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/support/conversations` | User starts live chat |
| `GET /api/v1/support/messages` | User polls messages |
| `POST /api/v1/support/messages` | User sends message |
| `POST /api/v1/crisis-flags` | App reports crisis keywords |
| `GET /api/v1/admin/support/...` | Admin read/reply/delete (website) |
| `GET /api/v1/admin/crisis-flags` | Admin safety alerts |

Details: [SUPPORT_CHAT.md](SUPPORT_CHAT.md).

### 4.5 Admin routes (website login)

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/admin/login` | Admin email/password → admin token |
| `GET /api/v1/admin/users` | List users (no password hashes) |
| `GET /api/v1/admin/users/:email/usage-days` | User’s usage for dashboard |
| `GET /api/v1/admin/users/:email/habit-snapshot` | Latest habits |
| `GET /api/v1/admin/stats` | Aggregate stats |
| `DELETE /api/v1/admin/users/:email` | Remove user |

Admin credentials: `ADMIN_EMAIL` / `ADMIN_PASSWORD` on Render (synced from root `.env` via `scripts/sync-env.ps1`).

### 4.6 MongoDB collections

| Collection | Contents |
|------------|----------|
| `users` | email, passwordHash, sessionToken, emailVerified |
| `usagedays` | Per user per `YYYY-MM-DD` — screen time JSON |
| `habitsnapshots` | Per user per `weekKey` — habits, moodDays, logs |
| `emailverifications` | Sign-up codes (temporary) |
| `passwordresets` | Reset codes (temporary) |
| `supportconversations` / `supportmessages` | Live support |
| `crisisflags` | Safety alerts from chat |

Full detail: [MONGODB.md](MONGODB.md).

---

## 5. Environment variables and sync script

**Single source (local):** project root `.env` (from `.env.example`).

| Variable | Used by |
|----------|---------|
| `API_BASE_URL` | Flutter → Render; copied to website as `NEXT_PUBLIC_API_BASE_URL` |
| `GEMINI_API_KEY` | Flutter AI features |
| `MONGODB_URI` | Copied to `server/.env` for local `npm start` and reference for Render |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | API admin login + website |
| `SMTP_*` | Sign-up and password-reset emails |

```powershell
.\scripts\sync-env.ps1
```

Produces:

- `server/.env` — local API + Render reference  
- `LifePatternAI_Website/.env.local` — if that repo is cloned beside this project  

APK builds use `scripts/sync_flutter_env.ps1` → **`flutter.env`** (only non-server secrets).

See [ENV_SETUP.md](ENV_SETUP.md).

---

## 6. Connecting the Flutter app to Render

1. Deploy API to Render; note HTTPS URL.
2. In root `.env`: `API_BASE_URL=https://your-service.onrender.com`
3. Run `.\scripts\sync-env.ps1` if needed.
4. Rebuild app:

   ```powershell
   .\run_dev.ps1
   # or
   flutter run --dart-define-from-file=flutter.env
   ```

5. Physical phones must use the **Render HTTPS URL**, not `localhost` or `10.0.2.2`.

6. Register/login in app → token saved → habits sync; screen time stays on-device.

Tester releases: [firebase_testing_quickstart.md](firebase_testing_quickstart.md) + `scripts/release_to_firebase.ps1`.

---

## 7. Admin website (Vercel)

**Repository:** [LifePatternAI_Website](https://github.com/Krijan-dev/LifePatternAI_Website) (not inside `final_year_project`).

| Piece | How it works |
|-------|----------------|
| Hosting | Vercel — static/SSR Next.js, HTTPS |
| API calls | Browser → `NEXT_PUBLIC_API_BASE_URL` (same Render URL as the app) |
| Admin auth | Website calls `POST /api/v1/admin/login`; stores admin token server-side in route handlers |
| Typical pages | Landing, admin login, user list, user detail (usage/habits), **Support chat**, **Safety alerts** |

The website **does not** hold `MONGODB_URI`. All data goes through Express on Render.

Setup: [VERCEL_WEBSITE_GUIDE.md](VERCEL_WEBSITE_GUIDE.md).

**After changing `API_BASE_URL`:** update root `.env`, run `sync-env.ps1`, update Vercel env vars, redeploy Vercel.

---

## 8. End-to-end flows

### 8.1 New user registration

1. App → `send-verification` → email code (SMTP or dev log).  
2. App → `verify-email` → `verificationToken`.  
3. App → `register` → user + Bearer token in MongoDB.  
4. App → `CloudSyncService.syncOnSignIn()` → habits push/pull; usage stays device-sourced.

### 8.2 Screen time today

1. User grants **Usage access** (Account or Home/Time prompt).  
2. `usageProvider` calls native `getUsageStats`.  
3. Home and Time tabs display totals; optional push to `usagedays` on cloud backup.

### 8.3 Steps and sleep

1. User installs fitness app → enables **Health Connect** sharing.  
2. User grants app **Steps + Sleep** in Health Connect.  
3. `HealthConnectBridge.readSummary()` prefers fitness-app origins; UI shows sources and **last updated** / stale warning.  
4. No Render involvement for health reads.

### 8.4 Live support

1. Signed-in user → support conversation on API.  
2. Admin replies on website `/support`.  
3. App polls every ~3s. See [SUPPORT_CHAT.md](SUPPORT_CHAT.md).

---

## 9. `docs/` folder — file-by-file

| File | Purpose |
|------|---------|
| **README.md** | This index |
| **PROJECT_COMPLETE_GUIDE.md** / **.docx** | Full system guide (this document) |
| **User_Manual_In_A_Nutshell.docx** | Short end-user manual |
| **User_Manual_Life_Pattern_Tracker.docx** | Older user manual (if present) |
| **HOW_TO_RUN.md** | Clone → Atlas → local API → Flutter |
| **DEPLOY_API_CLOUD.md** | Render + Atlas production API |
| **VERCEL_WEBSITE_GUIDE.md** | Website on Vercel + env vars |
| **ENV_SETUP.md** | `.env` and `sync-env.ps1` |
| **MONGODB.md** | Collections and REST usage |
| **DATABASE_AND_WEBSITE_PLAN.md** | Roadmap for admin features |
| **DATABASE_AND_WEBSITE_PLAN.docx** | Word export of plan |
| **firebase_testing_quickstart.md** | Tester APK workflow |
| **EMAIL_VERIFICATION.md** | SMTP setup for sign-up |
| **PASSWORD_RESET.md** | Reset flow |
| **SUPPORT_CHAT.md** | Admin/user chat |
| **USAGE_AND_DOCKER.md** | Docker optional dev |
| **RENDER_FIX.md** | Render troubleshooting |
| **SECURITY_GITHUB_ALERTS.md** | No secrets in git |
| **NAV_BAR_IDEAS.md** | Future UI ideas |
| **generate_user_manual.py** | Builds user Word manual |
| **generate_project_guide.py** | Builds this guide’s `.docx` |

---

## 10. Useful scripts

| Script | Purpose |
|--------|---------|
| `scripts/sync-env.ps1` | Root `.env` → `server/.env` + website `.env.local` |
| `scripts/sync_flutter_env.ps1` | API + Gemini → `flutter.env` for release builds |
| `scripts/release_to_firebase.ps1` | Build APK + upload to Firebase App Distribution |
| `run_dev.ps1` | Flutter run with env defines |
| `docker/run.ps1` | Optional containerized dev |

---

## 11. Security summary

- Passwords: hashed on server only (`passwordHash`), never returned in API JSON.  
- Never commit `.env`, `server/.env`, `flutter.env`, or Atlas URIs.  
- Use HTTPS (Render + Vercel) in production.  
- Restrict Atlas IP allowlist when moving beyond student demo.  
- `ADMIN_PASSWORD` only on server/Vercel server routes—not `NEXT_PUBLIC_*`.

---

## 12. Quick troubleshooting

| Symptom | Check |
|---------|--------|
| Login fails | `API_BASE_URL`, Render `/health`, app rebuilt after env change |
| Screen time zero | Usage access in Account; not cloud-related |
| Steps wrong / missing | Health Connect + fitness app sync; new APK with native bridge |
| Website empty | `NEXT_PUBLIC_API_BASE_URL`, admin login, Render awake |
| Email codes missing | SMTP on Render or `EMAIL_DEV_EXPOSE_CODE=1` in logs |
| Render slow first hit | Free tier cold start — wait and retry |

---

*Life Pattern Tracker — project guide. Aligns with codebase as of the Health Connect / device-only screen time architecture.*
