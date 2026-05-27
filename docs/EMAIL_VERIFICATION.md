# Email verification (sign-up)

New accounts must verify a real inbox before registration completes.

## Flow

1. User enters email → **Send verification code**
2. Your email account sends a **6-digit code** (15 min expiry)
3. User enters code → sets password → **Create account**

You do **not** need a paid email service. Use **your own Gmail or Outlook** as the mail sender.

---

## Use your own Gmail (recommended)

### Step 1 — Turn on 2-Step Verification

1. Open [Google Account → Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** (required for app passwords)

### Step 2 — Create an App Password

1. Same page → **App passwords** (or search “App passwords” in Google Account)
2. App: **Mail**, Device: **Windows** (or Other)
3. Google shows a **16-character password** (like `abcd efgh ijkl mnop`) — copy it

This is **not** your normal Gmail password. The API uses only this app password.

### Step 3 — Add to project root `.env`

Replace with **your** Gmail address and the app password (spaces in the app password are OK):

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=you@gmail.com
SMTP_PASS=abcdefghijklmnop
SMTP_FROM=Life Pattern Tracker <you@gmail.com>
```

Optional while testing locally (shows code in app if SMTP fails):

```env
EMAIL_DEV_EXPOSE_CODE=1
```

### Flutter app

Do **not** run `flutter run --dart-define-from-file=.env` — SMTP lines with spaces break the build. Use:

```powershell
.\run_dev.ps1
```

That passes only `GEMINI_API_KEY` and `API_BASE_URL` via `flutter.env`.

### Step 4 — Sync to the API server

```powershell
.\scripts\sync-env.ps1
```

### Step 5 — Deploy server code to Render

The app calls `POST /api/v1/auth/send-verification`. If the live API returns **404**, Render is still running an old build.

1. Commit and push `server/` (including `email.js`, `email_verify.js`, `nodemailer` in `package.json`).
2. Wait for Render to finish deploying (or trigger **Manual Deploy**).
3. Open `https://YOUR-SERVICE.onrender.com/` — the text should mention `send-verification`.

### Step 6 — Render environment (production)

In [Render](https://dashboard.render.com) → your API service → **Environment** → add the **same** variables:

| Key | Example |
|-----|---------|
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_SECURE` | `false` |
| `SMTP_USER` | `you@gmail.com` |
| `SMTP_PASS` | your 16-char app password |
| `SMTP_FROM` | `Life Pattern Tracker <you@gmail.com>` |

Redeploy after saving.

---

## Use your own Outlook / Hotmail / Live

```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=you@outlook.com
SMTP_PASS=your-outlook-password
SMTP_FROM=Life Pattern Tracker <you@outlook.com>
```

If Microsoft blocks sign-in, create an **app password** in Microsoft account security (same idea as Gmail).

---

## Test locally

```powershell
cd server
npm install
npm start
```

Sign up in the app → you should receive an email from your address within a minute (check spam).

---

## No SMTP yet (temporary dev only)

If you skip SMTP and set `EMAIL_DEV_EXPOSE_CODE=1`, codes appear in server logs and in a dev snackbar — **not for production**.

---

## API endpoints

- `POST /api/v1/auth/send-verification` — `{ "email": "..." }`
- `POST /api/v1/auth/verify-email` — `{ "email": "...", "code": "123456" }`
- `POST /api/v1/auth/register` — `{ "email", "password", "verificationToken" }`

Password reset: see [PASSWORD_RESET.md](PASSWORD_RESET.md).
