# Database, Cloud Sync & Admin Website — Plan

> Markdown only (Word export removed). Regenerate Word optionally: `python scripts/generate_database_plan_docx.py`

## Executive summary

You already have a cloud database foundation: **MongoDB Atlas** (free) + **Node.js API** in `server/` stores user accounts (hashed passwords) and daily screen-usage JSON. The Flutter app syncs usage when `API_BASE_URL` is set.

**You do not need to run `npm start` on your laptop to save data.** Deploy `server/` once to **Render** (free); the API runs in the cloud 24/7. Your phone uses `API_BASE_URL=https://your-app.onrender.com`. See **[DEPLOY_API_CLOUD.md](DEPLOY_API_CLOUD.md)**.

To build a **website that displays user data**, extend the API to sync **habits, mood, and activity logs** (today they live only on the phone in Hive), then build an **admin web app** that reads from the API. **Never store or display plain-text passwords.**

---

## What you already have

| Component | Location |
|-----------|----------|
| MongoDB API | `server/` |
| Atlas docs | `docs/MONGODB.md` |
| Usage sync | `lib/services/usage_remote_service.dart` |
| Remote auth (not wired to UI yet) | `lib/services/auth_remote_service.dart` |
| Local-only auth today | `lib/services/auth_storage_service.dart` |

### MongoDB collections (today)

- **users** — `email`, `passwordHash`, `sessionToken`
- **usagedays** — per user per day: screen time, apps, hourly data

### Still on device only (Hive)

- Weekly habits, mood, Today’s Log entries
- Local auth accounts (unless you connect remote auth)

---

## Recommended architecture

```
Flutter app  →  REST API (Node/Express)  →  MongoDB Atlas
Admin website  →  same REST API (admin routes)  →  MongoDB Atlas
```

The website **does not** connect to MongoDB directly.

---

## Schema to add

| Collection | Purpose |
|------------|---------|
| `habit_snapshots` | Per user per `weekKey`: habits grid + mood days |
| `activity_logs` | Log entries (or embedded in habit_snapshots) |
| `profiles` | Optional: display name, lastSyncAt |
| Admin | `role` on user or separate `admin_accounts` |

---

## API phases

1. **Unify auth** — `auth_provider` uses `AuthRemoteService` when `API_BASE_URL` is set.
2. **Habit + mood sync** — `PUT/GET .../habit-week/<weekKey>`.
3. **Activity logs sync** — batch POST or embed in habit snapshot.
4. **Admin API** — list users, per-user dashboard JSON (no passwords).

---

## Admin website

- **Stack:** React or Next.js + Chart.js/Recharts.
- **Pages:** Admin login, users table, user detail (screen time, habits %, mood).
- **Hosting:** Vercel or Netlify (free, HTTPS).

---

## Free hosting recommendations

### Database (use this)

| Service | Free tier | Notes |
|---------|-----------|--------|
| **[MongoDB Atlas](https://www.mongodb.com/atlas)** | M0, 512 MB | **Recommended** — already in your project |

### API (`server/`)

| Service | Free tier | Notes |
|---------|-----------|--------|
| **[Render](https://render.com)** | Web service sleeps when idle | Easiest GitHub deploy |
| **[Railway](https://railway.app)** | Monthly credits | Good for demos |
| **[Fly.io](https://fly.io)** | Small allowance | Docker-friendly |
| **Oracle Cloud Always Free VM** | Always-on VM | More setup, no sleep |

### Admin website

| Service | Free tier | Notes |
|---------|-----------|--------|
| **[Vercel](https://vercel.com)** | Hobby | Best for Next.js |
| **[Netlify](https://netlify.com)** | Starter | Static React/Vite |
| **[Cloudflare Pages](https://pages.cloudflare.com)** | Free | Fast CDN |

### Recommended demo stack ( $0 )

**MongoDB Atlas + Render (API) + Vercel (website)**

---

## Security

- Passwords: hashed only (never plain text in DB or UI).
- Do not commit `server/.env` or MongoDB URI.
- HTTPS in production; restrict Atlas IP in production.
- Admin routes separate from user routes; no `passwordHash` in API responses to the browser.

---

## Next steps

1. Create Atlas M0 cluster → put `MONGODB_URI` in **Render** environment (not only on laptop)
2. Deploy `server/` to **Render** → test `https://YOUR-APP.onrender.com/health` ([guide](DEPLOY_API_CLOUD.md))
3. Set Flutter `API_BASE_URL` to that HTTPS URL → rebuild app
4. Wire Flutter auth to `AuthRemoteService`
5. Add habit/mood sync endpoints + Flutter calls
6. Build admin website on **Vercel** (calls same cloud API)

See this file for tables, timeline, and environment variable list.
