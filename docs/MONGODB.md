# MongoDB + API for saving usage data

The Flutter app **does not** talk to MongoDB directly.  
A **Node.js + Express + Mongoose** service in `server/` stores data in MongoDB; the app syncs via HTTP.

## 1) Create a MongoDB database

1. Create a free cluster at [MongoDB Atlas](https://www.mongodb.com/atlas).
2. Database user + password; allow network access (dev: `0.0.0.0/0` or your IP).
3. Atlas → **Connect** → **Drivers** → copy the connection string.
4. Paste into **`server/.env`** as `MONGODB_URI=` (see `server/.env.example`).  
   **Do not commit** `server/.env`.

URL-encode special characters in passwords if needed.

## 2) Run the API locally

```powershell
cd server
copy .env.example .env
# Edit .env — paste MONGODB_URI from Atlas only into this file
npm install
npm start
```

Test: http://localhost:3000/health → `{"ok":true,"mongo":true}`

## 3) Point the Flutter app at the API

In project root **`.env`**:

```env
API_BASE_URL=http://10.0.2.2:3000
```

- Emulator: `http://10.0.2.2:PORT`
- Physical device: `http://YOUR_PC_LAN_IP:PORT`

Fully restart the app after changing `.env`.

## 4) Automatic sync from the app

When `API_BASE_URL` is set (e.g. your Render URL) and you **register or log in**, the app:

1. Stores a **Bearer token** locally and uses it for API calls.
2. **Downloads** your saved usage days and latest habit snapshot from MongoDB (restores data after a new phone or app reinstall).
3. **Uploads usage** after each refresh (today’s day + full history).
4. **Uploads habits/mood/logs** whenever you change the habit tracker (current week snapshot).

Local Hive storage still works offline. On sign-in, cloud data is pulled first, then local changes are pushed. Use **Account → Refresh all data** to pull again manually.

## 5) What gets saved in MongoDB

### `users` collection

| Field | Description |
|--------|-------------|
| `email` | Normalized lowercase email (unique) |
| `passwordHash` | `salt:sha256hex` — never plain passwords |
| `sessionToken` | Bearer token for API calls |

Endpoints: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/logout`

### `usagedays` collection (per email)

`PUT /api/v1/users/<email>/usage-days/<YYYY-MM-DD>` with `Authorization: Bearer <token>`

Body = daily usage JSON (`date`, `totalScreenTime`, `hourlyUsageMinutes`, `apps[]`).

`GET /api/v1/users/<email>/usage-days` — list days for that user.

### `habitsnapshots` collection (per email + week)

`PUT /api/v1/users/<email>/habit-snapshot/<weekKey>` with Bearer token.

Body: `{ weekKey, habits[], moodDays[], logs[] }` (same shape as local Hive).

Admin: `GET /api/v1/admin/users/<email>/habit-snapshot` (latest week).

## 6) Security notes

- Do **not** commit `server/.env` or root `.env`.
- Use **HTTPS** in production.
- See [SECURITY_GITHUB_ALERTS.md](SECURITY_GITHUB_ALERTS.md) if GitHub flags secrets.
