# Build & deploy a website on Vercel (Life Pattern Tracker)

This guide explains **what to build**, **in what order**, and **how to host it on Vercel** so it works with your Android app and cloud database plan.

You do **not** run the website on your laptop in production—Vercel hosts it. You do **not** connect Vercel to MongoDB directly—the site calls your **API on Render** (see [DEPLOY_API_CLOUD.md](DEPLOY_API_CLOUD.md)).

---

## 1. Decide what kind of website you need

Most projects need **two layers** (can be one Vercel project or two):

| Type | Audience | Hosted on Vercel? | Needs API? |
|------|----------|-------------------|------------|
| **A. Marketing / landing** | Public, supervisors, GitHub visitors | Yes | No (static pages only) |
| **B. Admin dashboard** | You / team—view all users’ data | Yes | Yes—Render API + **admin routes** (not built yet) |
| **C. User portal** (optional) | Logged-in users see *their* data in a browser | Yes | Yes—existing auth + usage endpoints |

**Recommendation for your thesis**

1. Start with **A** (fast, works today).  
2. Add **B** after you extend `server/` with admin APIs (see [DATABASE_AND_WEBSITE_PLAN.md](DATABASE_AND_WEBSITE_PLAN.md)).  
3. Skip **C** unless you explicitly want “use app or website” for the same user.

---

## 2. Overall architecture

```
┌─────────────────┐     HTTPS      ┌──────────────────┐     ┌─────────────┐
│  Vercel site    │ ──────────────► │  API (Render)    │ ──► │ MongoDB     │
│  (Next.js etc.) │                 │  server/         │     │ Atlas       │
└─────────────────┘                 └──────────────────┘     └─────────────┘
        ▲
        │  Flutter app (same API URL)
```

| Piece | Where | Your action |
|-------|--------|-------------|
| Database | MongoDB Atlas | Already in plan |
| API | Render (`server/`) | Deploy first—[DEPLOY_API_CLOUD.md](DEPLOY_API_CLOUD.md) |
| Website | Vercel | This guide |
| Secrets | Render + Vercel env dashboards | Never commit `.env` to GitHub |

---

## 3. Prerequisites (do these before Vercel)

- [ ] GitHub repo with your Flutter + `server/` code pushed  
- [ ] MongoDB Atlas cluster + `MONGODB_URI` on **Render**  
- [ ] Render API live: `https://YOUR-API.onrender.com/health` → `{"ok":true,"mongo":true}`  
- [ ] Flutter app uses `API_BASE_URL=https://YOUR-API.onrender.com` (optional for website, required for sync story)

**Note:** Today’s API has **user** auth and **usage-days** only. An admin “see all users” page needs new endpoints (`GET /api/v1/admin/...`)—plan in DATABASE_AND_WEBSITE_PLAN Phase 4.

---

## 4. Choose a web framework (for Vercel)

| Framework | Vercel support | Good for |
|-----------|----------------|----------|
| **Next.js** (React) | Excellent (default) | Landing + admin dashboard + API routes later |
| **Vite + React** | Excellent (static) | Simple landing; admin as SPA calling Render |
| **Astro** | Excellent | Mostly marketing content, fast |

**This project uses a separate repo:** [LifePatternAI_Website](https://github.com/Krijan-dev/LifePatternAI_Website) (Next.js 14 App Router). On Vercel, set **Root Directory** to `.` (repo root).

---

## 5. Create the website project (local, one-time)

From your project root (PowerShell):

```powershell
# Option A: Next.js inside this repo
npx create-next-app@latest website --typescript --eslint --tailwind --app --src-dir --no-import-alias

cd website
```

Or use Vercel’s dashboard to **import** a template when you connect GitHub (skip local create if you prefer).

### Folder layout (suggested)

```
final_year_project/
├── lib/                 # Flutter app (unchanged)
├── server/              # API → Render
└── LifePatternAI_Website/   # separate repo → Vercel
    ├── src/app/
    │   ├── page.tsx           # Landing home
    │   ├── about/page.tsx
    │   ├── login/page.tsx     # Admin login (later)
    │   └── dashboard/         # Admin UI (later)
    ├── .env.local.example
    └── package.json
```

Add to root `.gitignore` (if not already):

```
.env.local (in LifePatternAI_Website repo root)
node_modules/
.next/
```

---

## 6. Environment variables (Vercel)

Create `.env.local` in the **LifePatternAI_Website** repo (copy from `.env.local.example`). On Vercel: **Project → Settings → Environment Variables**.

| Variable | Example | Used for |
|----------|---------|----------|
| `NEXT_PUBLIC_API_BASE_URL` | `https://your-api.onrender.com` | Browser calls to Render API |
| `ADMIN_EMAIL` | your email | Admin login check (until proper admin API) |
| `ADMIN_PASSWORD` | strong secret | **Server-side only**—use in Next.js Route Handlers, not `NEXT_PUBLIC_` |

**Rule:** Only prefix with `NEXT_PUBLIC_` if the browser must see it (API base URL). Never expose MongoDB URI or admin password to the client.

Example `.env.local.example` (repo root):

```env
NEXT_PUBLIC_API_BASE_URL=https://your-api.onrender.com
# Server-only (Next.js API routes / server actions):
ADMIN_EMAIL=
ADMIN_PASSWORD=
```

---

## 7. What pages to build (phased)

### Phase 1 — Landing site (can deploy immediately)

No admin API required.

| Page | Content |
|------|---------|
| **Home** | App name, tagline, screenshots, link to Play Store / APK later |
| **Features** | Dashboard, habits, insights, screen time, AI assistant |
| **How it works** | App → API → MongoDB diagram (for thesis) |
| **Privacy** | What data is collected, hashed passwords, not selling data |
| **Contact / project** | Your name, university, GitHub link |

Uses: Tailwind, static images from `website/public/`.

### Phase 2 — Admin dashboard (after API work)

| Page | Content | API needed |
|------|---------|------------|
| **/login** | Admin email + password | `POST /api/v1/admin/login` (to add) |
| **/dashboard** | Total users, active this week | `GET /api/v1/admin/stats` |
| **/users** | Table: email, last sync, habit % | `GET /api/v1/admin/users` |
| **/users/[email]** | Charts: screen time, mood, habits | `GET /api/v1/admin/users/:email/...` |

Charts: [Chart.js](https://www.chartjs.org/) or [Recharts](https://recharts.org/) with JSON from your API.

### Phase 3 — Polish

- Dark mode  
- Export CSV for thesis appendix  
- “API status” badge calling `GET /health` on Render  

---

## 8. CORS (allow Vercel to call Render)

Your `server/src/index.js` uses `cors()` with default (allows all origins). That works for development and Vercel.

**For production**, restrict to your domains:

```js
const allowed = [
  "https://your-project.vercel.app",
  "https://your-custom-domain.com",
];
app.use(cors({ origin: allowed, credentials: true }));
```

Redeploy Render after changing CORS.

---

## 9. Deploy to Vercel (step-by-step)

### A. Push **LifePatternAI_Website** to GitHub

Repo: https://github.com/Krijan-dev/LifePatternAI_Website — commit from repo root (not `.env.local`).

### B. Connect Vercel

1. Go to [vercel.com](https://vercel.com) → sign in with GitHub.  
2. **Add New Project** → import your repository.  
3. **Root Directory:** `.` (repository root — this is a dedicated website repo).  
4. **Framework Preset:** Next.js (auto-detected).  
5. **Environment Variables:** add `NEXT_PUBLIC_API_BASE_URL` and server-only admin vars.  
6. **Deploy**.

You get a URL like `https://life-pattern-tracker.vercel.app`.

### C. Custom domain (optional)

Vercel → Project → **Domains** → add your domain → follow DNS instructions.

### D. Redeploy on every push

Default: push to `main` → Vercel rebuilds automatically.

---

## 10. Example: call your API from Next.js (Phase 2 preview)

Client component or server component fetching health:

```ts
const base = process.env.NEXT_PUBLIC_API_BASE_URL;

export async function getApiHealth() {
  const res = await fetch(`${base}/health`, { cache: "no-store" });
  return res.json();
}
```

User usage (requires user’s Bearer token—typically after that user logs in on the site):

```ts
await fetch(`${base}/api/v1/users/${encodeURIComponent(email)}/usage-days`, {
  headers: { Authorization: `Bearer ${token}` },
});
```

Admin list (**after you implement admin endpoints**):

```ts
await fetch(`${base}/api/v1/admin/users`, {
  headers: { Authorization: `Bearer ${adminToken}` },
});
```

---

## 11. Security checklist (website)

- [ ] HTTPS only (Vercel provides TLS)  
- [ ] No MongoDB URI in frontend env  
- [ ] No `passwordHash` or raw passwords in UI  
- [ ] Admin pages behind login; use httpOnly cookies for admin session if possible  
- [ ] Do not commit `website/.env.local`  
- [ ] Rate-limit admin login on the API (when you add it)  

---

## 12. Order of work (checklist)

| Step | Task | Done? |
|------|------|-------|
| 1 | Deploy API to Render + Atlas | ☐ |
| 2 | LifePatternAI_Website repo with Next.js landing pages | ☐ |
| 3 | Deploy to Vercel (root dir = `.`) | ☐ |
| 4 | Add screenshots + thesis copy on landing | ☐ |
| 5 | Implement admin API routes in `server/` | ☐ |
| 6 | Build `/login` + `/dashboard` + user charts on Vercel | ☐ |
| 7 | Tighten CORS to your Vercel URL | ☐ |
| 8 | Link website URL in README and thesis report | ☐ |

---

## 13. Free tier limits (know before demo day)

| Service | Limit |
|---------|--------|
| **Vercel Hobby** | Fine for student traffic; commercial use has rules |
| **Render free** | API sleeps when idle—first load slow |
| **Atlas M0** | 512 MB storage |

For a supervisor demo: open the Vercel site first, then hit the Render `/health` URL once to wake the API, then open the admin dashboard.

---

## 14. Related docs

| Doc | Topic |
|-----|--------|
| [DEPLOY_API_CLOUD.md](DEPLOY_API_CLOUD.md) | API on Render—no laptop npm |
| [DATABASE_AND_WEBSITE_PLAN.md](DATABASE_AND_WEBSITE_PLAN.md) | DB schema + admin API phases |
| [MONGODB.md](MONGODB.md) | Atlas setup |

---

## 15. Quick answers

**Can Vercel host the database?**  
No. Use Atlas. Vercel hosts the **website** only.

**Can Vercel run my `server/` Node API?**  
Possible with Vercel Serverless, but your Express app is easier on **Render**. Keep API on Render, site on Vercel.

**Do I need npm on my laptop for the website?**  
Only to **develop** (`npm run dev` in **LifePatternAI_Website**). Production runs on Vercel’s build servers.

**What can I ship this week without coding the API more?**  
A polished **landing site** on Vercel + link to GitHub + architecture diagram. That already strengthens your thesis.
