# How to run Life Pattern Tracker (app + MongoDB API)

This guide is for anyone cloning the project: set up **MongoDB Atlas**, run the **Node API**, configure **API keys**, then run the **Flutter app** on Android.

> Do not paste real connection strings or API keys into markdown. Use local `.env` files only.  
> See [SECURITY_GITHUB_ALERTS.md](SECURITY_GITHUB_ALERTS.md) if GitHub flags secrets.

---

## What you need installed

| Tool | Purpose |
|------|---------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Mobile app |
| [Node.js](https://nodejs.org/) (LTS, v18+) | API server in `server/` |
| [MongoDB Atlas](https://www.mongodb.com/atlas) account (free tier) | Cloud database |
| Android Studio + emulator **or** a physical Android phone | App targets Android for usage tracking |
| Google AI Studio key (optional) | Gemini chat & AI suggestions |

---

## Project layout

```
final_year_project/
├── .env                 ← Flutter secrets (create from .env.example) — NOT in git
├── lib/                 ← Flutter app
├── server/
│   ├── .env             ← MongoDB URI (create from server/.env.example) — NOT in git
│   └── src/index.js     ← REST API
└── docs/
    └── HOW_TO_RUN.md    ← this file
```

The app **never** connects to MongoDB directly. It talks to the **API**; the API talks to MongoDB.

---

## Step 1 — MongoDB Atlas

1. Sign in at [MongoDB Atlas](https://cloud.mongodb.com) and create a **free cluster**.
2. **Database Access** → add a database user (username + password). Save the password.
3. **Network Access** → **Add IP Address** (`0.0.0.0/0` for dev, or your current IP).
4. **Database** → **Connect** → **Drivers** → copy the connection string.
5. Paste it into **`server/.env`** only:
   ```env
   MONGODB_URI=
   ```
   (paste after `=`). **Never commit** `server/.env`.

Wait 1–2 minutes after changing network access before connecting.

---

## Step 2 — Run the API server

```powershell
cd server
copy .env.example .env
```

Edit **`server\.env`** — set `MONGODB_URI` from Atlas. Optional: `PORT=3000`.

```powershell
npm install
npm start
```

**Success:** `MongoDB connected` and `API listening on http://localhost:3000`.

| URL | Expected |
|-----|----------|
| http://localhost:3000/health | `{"ok":true,"mongo":true}` |

---

## Step 3 — Configure the Flutter app (`.env`)

In the **project root**:

```powershell
copy .env.example .env
```

Edit **`.env`** (no spaces around `=`):

```env
GEMINI_API_KEY=your_google_ai_studio_key_here
API_BASE_URL=http://10.0.2.2:3000
```

| Where you run the app | `API_BASE_URL` |
|------------------------|------------------|
| **Android emulator** | `http://10.0.2.2:3000` |
| **Physical phone** (same Wi‑Fi) | `http://YOUR_PC_LAN_IP:3000` |

Get PC IP: `ipconfig` → IPv4 Address.

Without a Gemini key, usage tracking still works; AI features use fallback text.

---

## Step 4 — Run the Flutter app

```powershell
flutter pub get
.\run_dev.ps1
```

Or: `flutter run --dart-define-from-file=.env`

Restart the app after changing `.env`. Grant **Usage access** on Android.

---

## Step 5 — Verify

1. Register / login → Atlas → **`users`** collection.
2. Refresh usage → Atlas → **`usagedays`** collection.
3. AI chat when `GEMINI_API_KEY` is set.

---

## More documentation

- [MONGODB.md](MONGODB.md) — database schema  
- [SECURITY_GITHUB_ALERTS.md](SECURITY_GITHUB_ALERTS.md) — fix GitHub secret alerts  
- [PROJECT_COMPLETE_GUIDE.md](PROJECT_COMPLETE_GUIDE.md) — full feature overview & troubleshooting  

---

## Quick commands

**API:** `cd server` → `npm install` → `npm start`  
**App:** copy `.env.example` → `.env` → `.\run_dev.ps1`
