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

## 4) What gets saved in MongoDB

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

## 5) Security notes

- Do **not** commit `server/.env` or root `.env`.
- Use **HTTPS** in production.
- See [SECURITY_GITHUB_ALERTS.md](SECURITY_GITHUB_ALERTS.md) if GitHub flags secrets.
