# Life Pattern Tracker — website (Vercel)

This folder is for the **Next.js** site deployed to Vercel.

**Full setup guide:** [../docs/VERCEL_WEBSITE_GUIDE.md](../docs/VERCEL_WEBSITE_GUIDE.md)

## Create project (first time)

From repo root:

```powershell
npx create-next-app@latest website --typescript --eslint --tailwind --app --src-dir --no-import-alias
```

If this folder already exists with only `.env.local.example`, run the command above or scaffold manually.

## Local dev

```powershell
cd website
copy .env.local.example .env.local
# Edit NEXT_PUBLIC_API_BASE_URL
npm install
npm run dev
```

Open http://localhost:3000

## Deploy

1. Push to GitHub  
2. [vercel.com](https://vercel.com) → Import repo → **Root Directory:** `website`  
3. Add env vars from `.env.local.example`  
4. Deploy  
