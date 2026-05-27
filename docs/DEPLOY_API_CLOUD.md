# Save data without running npm on your laptop

Your laptop was only needed for **development**. In production, the Node API runs on **free cloud hosting**; your phone and website talk to that URL. MongoDB Atlas also runs in the cloud—you never host the database locally.

```
Android app  ──HTTPS──►  API on Render (or Railway)  ──►  MongoDB Atlas
Admin website ──HTTPS──►  same API URL
```

You do **not** need `npm start` on your PC after deployment.

---

## Option A — Keep your existing API (recommended, least work)

You already have `server/` + MongoDB. Deploy it once to **Render** (free).

### 1) MongoDB Atlas (database only — browser setup)

1. [MongoDB Atlas](https://www.mongodb.com/atlas) → free M0 cluster.
2. Database user + password.
3. Network Access → allow `0.0.0.0/0` (or Render’s outbound IPs if you restrict later).
4. Copy connection string → you will paste it into **Render**, not only on your laptop.

### 2) Push project to GitHub

Render deploys from your repo. Do not commit `server/.env`.

### 3) Deploy API on Render

1. [render.com](https://render.com) → sign up → **New +** → **Web Service**.
2. Connect your GitHub repo.
3. Settings:
   - **Root directory:** `server`
   - **Build command:** `npm install`
   - **Start command:** `npm start`
   - **Instance type:** Free
4. **Environment** → add:
   - `MONGODB_URI` = your Atlas connection string
   - `PORT` = `3000` (Render sets `PORT` automatically; your code already uses `process.env.PORT`)
5. Create service. Wait for deploy. Note the URL, e.g. `https://life-pattern-api.onrender.com`.

Test in a browser: `https://YOUR-SERVICE.onrender.com/health` → `{"ok":true,"mongo":true}`.

**Free tier note:** the service sleeps after ~15 minutes idle; the first request after sleep may take 30–60 seconds (fine for a student project).

### 4) Point the Flutter app at the cloud API

In project root `.env` (not committed):

```env
API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

Rebuild the app (full restart):

```powershell
flutter run --dart-define-from-file=.env
```

On a **physical phone**, use the Render HTTPS URL (not `10.0.2.2`).

### 5) Your laptop’s role

| Task | On laptop? |
|------|------------|
| Run Flutter app / build APK | Yes |
| Run `npm start` for saving data | **No** (Render does this) |
| Run MongoDB | **No** (Atlas does this) |

You only run `npm start` locally if you are **testing** API changes before redeploying to Render.

---

## Option B — No custom Node server (more rework)

If you do not want to maintain `server/` at all, use a **hosted backend-as-a-service**:

| Service | What you get | Flutter |
|---------|----------------|---------|
| [Supabase](https://supabase.com) | Hosted Postgres + Auth + REST | `supabase_flutter` |
| [Firebase](https://firebase.google.com) | Auth + Firestore | `firebase_auth`, `cloud_firestore` |

Pros: no Render deploy, no Express code. Cons: rewrite auth/sync away from your current `server/` and `MONGODB.md` flow.

---

## Admin website (also no laptop server)

Host the dashboard on **Vercel** or **Netlify** (static site). It calls the same `https://YOUR-SERVICE.onrender.com` API—nothing runs on your laptop.

---

## Quick checklist

- [ ] Atlas cluster created; `MONGODB_URI` in Render env vars only  
- [ ] Render web service live; `/health` works  
- [ ] Flutter `.env` has `API_BASE_URL=https://...onrender.com`  
- [ ] App rebuilt after changing `.env`  
- [ ] (Later) Wire `auth_provider` to `AuthRemoteService` so logins save to Atlas  

See also: [MONGODB.md](MONGODB.md), [DATABASE_AND_WEBSITE_PLAN.md](DATABASE_AND_WEBSITE_PLAN.md).
