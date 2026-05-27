# Environment variables (one `.env` → app, website, server)

Keep secrets in the **project root** `.env` (gitignored). Run sync when values change:

```powershell
.\scripts\sync-env.ps1
```

## Root `.env` (Flutter app)

| Variable | Used by |
|----------|---------|
| `GEMINI_API_KEY` | Flutter (Insights AI, etc.) |
| `API_BASE_URL` | Flutter → auth, usage, and habit sync to MongoDB via API |
| `MONGODB_URI` | Optional here; copied to `server/.env` when set |

## After sync

| File | Variables |
|------|-----------|
| `LifePatternAI_Website/.env.local` | `NEXT_PUBLIC_API_BASE_URL` (= `API_BASE_URL`) |
| `server/.env` | `MONGODB_URI`, `PORT=3000` |

## Vercel (website repo)

In [Vercel](https://vercel.com) → **LifePatternAI_Website** → **Settings** → **Environment Variables**:

| Name | Value |
|------|--------|
| `NEXT_PUBLIC_API_BASE_URL` | Same as `API_BASE_URL` — use **Render HTTPS URL** for production |

Redeploy after changing.

**Note:** A LAN URL like `http://192.168.x.x:3000` works for local `npm run dev` only. Vercel’s servers cannot reach your home network.

## Render (API)

Set in Render dashboard (not in the website repo):

| Name | Value |
|------|--------|
| `MONGODB_URI` | Atlas connection string |
| `PORT` | `3000` (optional) |

## Render URL in root `.env`

When the API is deployed, update root `.env`:

```env
API_BASE_URL=https://your-service.onrender.com
```

Then run `.\scripts\sync-env.ps1` and update Vercel env to match.
