# MongoDB + API for saving usage data

The Flutter app **does not** talk to MongoDB directly (your connection string would be exposed in the APK).  
Instead, a small **Node.js + Express + Mongoose** service in `server/` stores JSON documents in MongoDB, and the app **HTTP PUT**s each day after a successful refresh.

## 1) Create a MongoDB database

1. Create a free cluster at [MongoDB Atlas](https://www.mongodb.com/atlas).
2. Database user + password, allow network access (for dev: `0.0.0.0/0` or your IP).
3. Copy the **connection string** (SRV), e.g.  
   `mongodb+srv://USER:PASS@cluster0.xxxxx.mongodb.net/life_pattern?retryWrites=true&w=majority`

## 2) Run the API locally

```powershell
cd server
copy .env.example .env
# Edit .env — set MONGODB_URI=...
npm install
npm start
```

You should see: `MongoDB connected` and `API listening on http://localhost:3000`.

Test: open `http://localhost:3000/health` in a browser.

## 3) Point the Flutter app at the API

Add to your project root **`.env`** (same file as `GEMINI_API_KEY`):

```env
API_BASE_URL=http://10.0.2.2:3000
```

- **Android emulator** → host machine: use `http://10.0.2.2:PORT` (not `localhost`).
- **Physical device** on same Wi‑Fi: use your PC’s LAN IP, e.g. `http://192.168.1.50:3000`.
- **Release / production**: deploy the API (Railway, Render, Fly.io, etc.) and set `API_BASE_URL` to the HTTPS URL.

Then **fully restart** the app (e.g. `run_dev.bat` / `run_dev.ps1`) so `String.fromEnvironment` picks up the new define.

## 4) What gets saved

After **Refresh** pulls today’s usage and saves to Hive, the app **PUT**s the same payload to:

`PUT /api/v1/users/<url-encoded-email>/usage-days/<YYYY-MM-DD>`

Body = `DailyUsageModel.toMap()` JSON.

Optional listing (for a future “restore from cloud” feature):

`GET /api/v1/users/<email>/usage-days` → JSON array of day maps.

## 5) Security notes (important for a real project)

- Add **authentication** (JWT, session cookies, or API keys) on the server before public deployment.
- Do **not** commit `server/.env` or root `.env` with secrets.
- Use **HTTPS** in production and restrict CORS to your app origins.
