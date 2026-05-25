# Password reset

Users can reset a forgotten password with a **6-digit email code** (same SMTP setup as sign-up verification).

## Flow

1. **Log in** tab → **Forgot password?**
2. Enter account email → **Send reset code**
3. Enter code from email → **Continue**
4. Set new password → signed in automatically

## API (Render / local `server/`)

| Method | Path | Body |
|--------|------|------|
| POST | `/api/v1/auth/forgot-password` | `{ "email": "..." }` |
| POST | `/api/v1/auth/verify-reset-code` | `{ "email", "code" }` → `{ "resetToken" }` |
| POST | `/api/v1/auth/reset-password` | `{ "email", "password", "resetToken" }` → `{ "token" }` |

Deploy `server/src/password_reset.js` with the rest of the API. Uses the same `SMTP_*` env vars as [EMAIL_VERIFICATION.md](EMAIL_VERIFICATION.md).

## Privacy

If the email is not registered, `forgot-password` still returns success (no email sent). The app shows the same message either way.

## Dev without SMTP

Set `EMAIL_DEV_EXPOSE_CODE=1` on the server; reset codes appear in server logs and in a dev snackbar when SMTP is off.
