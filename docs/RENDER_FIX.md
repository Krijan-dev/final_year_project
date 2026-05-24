# Render build failed: package.json not found

## Error

```
ENOENT: no such file or directory, open '.../package.json'
```

Render ran `npm install` at the **repository root**. The API is in **`server/`**, where `package.json` lives.

## Fix in Render dashboard

1. Open your service on [dashboard.render.com](https://dashboard.render.com)
2. **Settings**
3. Set:

| Setting | Value |
|---------|--------|
| **Root Directory** | `server` |
| **Runtime** | Node |
| **Build Command** | `npm install` |
| **Start Command** | `npm start` |

4. **Environment** → confirm `MONGODB_URI` is set
5. **Manual Deploy** → **Deploy latest commit**

Root Directory must be exactly `server` (no slash, not `src`, not empty).

## Verify

After deploy succeeds, open:

`https://YOUR-SERVICE.onrender.com/health`

Expected: `{"ok":true,"mongo":true}`

## Optional: render.yaml

This repo includes `render.yaml` at the root so new Render services can pick up `rootDir: server` automatically. Existing services still need the dashboard fix above.
