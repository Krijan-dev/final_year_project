# Fixing GitHub secret scanning alerts

If GitHub shows **MongoDB URI** or **Google API Key** alerts, follow this checklist.

## 1. Rotate exposed secrets (do this first)

### Google API key (`google-services.json`)

The key in git history may be public. Treat it as compromised.

1. Open [Google Cloud Console](https://console.cloud.google.com/) → project **android-app-723a5** (or your Firebase project).
2. **APIs & Services** → **Credentials** → find the exposed key → **Delete** or **Regenerate**.
3. In [Firebase Console](https://console.firebase.google.com/) → Project settings → your Android app → download a **new** `google-services.json`.
4. Save it as `android/app/google-services.json` on your machine only (this file is **gitignored**).

### MongoDB Atlas

If a **real** connection string (not a doc placeholder) was ever committed:

1. Atlas → **Database Access** → edit user → **Edit password** (new password).
2. Update `server/.env` locally only — never commit `server/.env`.

Doc-only placeholders (`USER`, `PASS`, `xxxxx`) do not require rotation, but you should still fix the docs so alerts close after the next push.

---

## 2. What we changed in the repo

- Documentation no longer contains `mongodb+srv://...` example URLs (scanners flag them).
- `android/app/google-services.json` is **gitignored**; use `google-services.json.example` as a template.
- `.env` and `server/.env` are **gitignored**.

---

## 3. Remove secrets from Git tracking

After pulling the latest code:

```powershell
cd F:\final_project\final_year_project

# Stop tracking Firebase config (keep your local copy)
git rm --cached android/app/google-services.json

git add .gitignore android/app/google-services.json.example docs/
git commit -m "Stop tracking secrets; fix docs for secret scanning"
git push
```

If `google-services.json` was never on your machine, skip the rm step or run it only if the file is tracked.

---

## 4. Clear alerts still tied to old commits

GitHub scans **history**. A normal commit does not remove secrets from past commits.

Options:

| Option | When to use |
|--------|-------------|
| **Close alert** as “revoked” after rotating keys | Key rotated; acceptable for a student repo |
| **Rewrite history** (`git filter-repo` / BFG) | You need secrets gone from all commits |
| **New repo** | Simplest clean slate for a final submission |

For a university project, **rotate keys** + **stop tracking the file** + **close alerts** is usually enough.

---

## 5. Never commit

- `server/.env` (real `MONGODB_URI`)
- `.env` (real `GEMINI_API_KEY`)
- `android/app/google-services.json` (real Firebase config)

Copy from `*.example` files and fill in values locally.
