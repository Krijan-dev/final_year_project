# Live support chat (app ↔ admin website)

Users can tap **Chat with a real person** in the floating assistant. Admins reply from the website **Support chat** page.

## Requirements

- Render API deployed with latest `server/` code (support routes).
- App built with `API_BASE_URL` and user **signed in** (Bearer token).
- Admin website on Vercel with `NEXT_PUBLIC_API_BASE_URL` pointing at the same API.

## Flow

1. User opens chat → **Chat with a real person** → `POST /api/v1/support/conversations`
2. App polls `GET /api/v1/support/messages` every 3 seconds.
3. Admin opens `/support` on the website → selects user → sends messages via admin API.
4. User sees admin replies on the next poll.

## Admin website (separate repo)

Copy or push changes under `LifePatternAI_Website/`:

- `/support` page
- `/api/admin/support/...` proxy routes
- Nav link **Support chat**

Redeploy Vercel after pushing.

## MongoDB collections

- `supportconversations` — one open thread per user (`waiting` / `active` / `closed`)
- `supportmessages` — `sender`: `user` | `admin`

## End chat

Admin clicks **End chat** → conversation `closed`. User can start a new thread by tapping **Chat with a real person** again.
