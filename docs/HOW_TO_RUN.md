# How to run Life Pattern Tracker (app + MongoDB API)

This guide is for anyone cloning the project: set up **MongoDB Atlas**, run the **Node API**, configure **API keys**, then run the **Flutter app** on Android.

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
3. **Network Access** → **Add IP Address**:
   - Development: `0.0.0.0/0` (allow from anywhere), **or**
   - **Add Current IP Address** (more secure; update if your IP changes).
4. **Database** → **Connect** → **Drivers** → copy the connection string.  
   Example:
   ```text
   mongodb+srv://myuser:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/life_pattern?retryWrites=true&w=majority
   ```
5. Replace `YOUR_PASSWORD`. If the password contains `@`, `#`, `/`, etc., [URL-encode](https://www.w3schools.com/tags/ref_urlencode.asp) it in the URI.

Wait 1–2 minutes after changing network access before connecting.

---

## Step 2 — Run the API server

Open a terminal in the **`server`** folder:

```powershell
cd F:\final_project\final_year_project\server
copy .env.example .env
```

Edit **`server\.env`**:

```env
MONGODB_URI=mongodb+srv://USER:PASS@cluster0.xxxxx.mongodb.net/life_pattern?retryWrites=true&w=majority
PORT=3000
```

Install and start:

```powershell
npm install
npm start
```

**Success looks like:**

```text
Connecting to MongoDB (timeout 15s)...
MongoDB connected
API listening on http://localhost:3000
```

**Quick tests (browser):**

| URL | Expected |
|-----|----------|
| http://localhost:3000/ | Short API help text |
| http://localhost:3000/health | `{"ok":true,"mongo":true}` |

Leave this terminal **running** while you use the app.

### Common server problems

| Problem | Fix |
|---------|-----|
| Hangs on “Connecting to MongoDB…” | Atlas **Network Access** / wrong URI / wrong password |
| `Missing MONGODB_URI` | Create `server\.env` from `server\.env.example` |
| Port in use | Change `PORT=3001` in `server\.env` and use that port in `API_BASE_URL` below |

---

## Step 3 — Configure the Flutter app (`.env`)

In the **project root** (not `server/`):

```powershell
cd F:\final_project\final_year_project
copy .env.example .env
```

Edit **`.env`** (no spaces around `=`):

```env
GEMINI_API_KEY=your_google_ai_studio_key_here

# Point app at your PC where the API runs:
API_BASE_URL=http://10.0.2.2:3000
```

| Where you run the app | `API_BASE_URL` |
|------------------------|------------------|
| **Android emulator** | `http://10.0.2.2:3000` (`10.0.2.2` = your PC from the emulator) |
| **Physical phone** (same Wi‑Fi as PC) | `http://YOUR_PC_LAN_IP:3000` (e.g. `http://192.168.1.50:3000`) |
| API not needed (offline-only auth) | Leave empty |

Get your PC IP (PowerShell): `ipconfig` → look for **IPv4 Address** on Wi‑Fi/Ethernet.

### Gemini API key

1. Create a key at [Google AI Studio](https://aistudio.google.com/apikey).
2. Put it in `GEMINI_API_KEY=` in root `.env`.

Without a key, usage tracking still works; **AI chat** and **AI suggestions** use fallback text.

**Debug shortcut:** Account menu → **Paste Gemini key (debug)** stores a key on the device (no full restart needed in debug only).

---

## Step 4 — Run the Flutter app

```powershell
cd F:\final_project\final_year_project
flutter pub get
```

**Recommended** (loads `.env` automatically):

```powershell
.\run_dev.ps1
```

If PowerShell blocks scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_dev.ps1
```

Or use **`run_dev.bat`** (double-click or cmd.exe).

**Manual:**

```powershell
flutter run --dart-define-from-file=.env
```

### Important

- **Stop and start** the app after changing `.env` — hot reload does **not** reload compile-time keys.
- Use an **Android** device/emulator (screen-time APIs are Android-only).
- Grant **Usage access** when the app asks (Settings → Usage access → Life Pattern Tracker).

---

## Step 5 — Verify everything works

### A. Register / login (MongoDB `users`)

1. API server running (`npm start`).
2. `API_BASE_URL` set in root `.env`, app **fully restarted**.
3. In the app: create an account or log in.
4. In Atlas → **Browse Collections** → database (e.g. `life_pattern`) → **`users`**  
   You should see `email` and `passwordHash` (never plain passwords).

### B. Usage sync (MongoDB `usagedays`)

1. Stay logged in.
2. Open dashboard → **Refresh** (with Usage access granted).
3. Atlas → **`usagedays`** → documents with `userId` (email), `dayKey`, and `data` (screen time JSON).

### C. AI (Gemini)

1. `GEMINI_API_KEY` in `.env`, app restarted.
2. Open floating **chat** or **AI** tab — status should show connected when configured.
3. Ask about habits / screen time (off-topic messages are answered locally without using the API).

### D. Health Connect (optional)

- Install **Health Connect** on the device/emulator.
- **Habits** tab → allow permissions → steps/sleep on the card (not stored in MongoDB today).

---

## Release build (less console logging)

Debug runs log more to the terminal. For a production-style build:

```powershell
flutter build apk --release --dart-define-from-file=.env
```

Install the APK from `build\app\outputs\flutter-apk\`.

---

## Environment files checklist

| File | Required? | Contains |
|------|-----------|----------|
| `server\.env` | Yes, for cloud DB | `MONGODB_URI`, optional `PORT` |
| `.env` (project root) | Recommended | `GEMINI_API_KEY`, `API_BASE_URL` |

**Never commit** real `.env` files (they are gitignored).

---

## API reference (for testers)

**Auth**

```http
POST /api/v1/auth/register   { "email", "password" }
POST /api/v1/auth/login      { "email", "password" }
POST /api/v1/auth/logout     Authorization: Bearer <token>
```

**Usage** (requires `Authorization: Bearer <token>` from login)

```http
PUT  /api/v1/users/<email>/usage-days/<YYYY-MM-DD>   body = daily usage JSON
GET  /api/v1/users/<email>/usage-days
```

---

## More documentation

- `docs/MONGODB.md` — database schema and security notes  
- `docs/USAGE_AND_DOCKER.md` — app features, Docker, troubleshooting  
- `README.md` — short overview  

---

## Quick command summary

**Terminal 1 — API:**

```powershell
cd server
npm install
npm start
```

**Terminal 2 — App:**

```powershell
cd F:\final_project\final_year_project
copy .env.example .env
# edit .env → GEMINI_API_KEY, API_BASE_URL
flutter pub get
.\run_dev.ps1
```
