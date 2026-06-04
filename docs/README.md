# Documentation index

Start here for the full system picture:

| Document | Audience | What it covers |
|----------|----------|----------------|
| **[PROJECT_COMPLETE_GUIDE.md](PROJECT_COMPLETE_GUIDE.md)** · [Word](PROJECT_COMPLETE_GUIDE.docx) | Developers & supervisors | **Everything:** app architecture, Render API, MongoDB, website, sync rules, docs folder map |
| **[HEALTH_DATA_PHASE2.md](HEALTH_DATA_PHASE2.md)** | Developers & testers | Health Connect Phase 2: all phones, sleep fix, Samsung optional path |
| [User_Manual_In_A_Nutshell.docx](User_Manual_In_A_Nutshell.docx) | End users / testers | How to use the Android app (tabs, permissions, Health Connect) |
| [HOW_TO_RUN.md](HOW_TO_RUN.md) | Developers | Local setup: Atlas, `npm start`, Flutter `.env` |
| [DEPLOY_API_CLOUD.md](DEPLOY_API_CLOUD.md) | Developers | Deploy `server/` to **Render** (production API) |
| [VERCEL_WEBSITE_GUIDE.md](VERCEL_WEBSITE_GUIDE.md) | Developers | **LifePatternAI_Website** on Vercel → same Render API |
| [ENV_SETUP.md](ENV_SETUP.md) | Developers | Root `.env` → `sync-env.ps1` → app / server / website |
| [MONGODB.md](MONGODB.md) | Developers | Collections, auth, usage & habit endpoints |
| [DATABASE_AND_WEBSITE_PLAN.md](DATABASE_AND_WEBSITE_PLAN.md) | Planning | Schema phases, admin site roadmap |
| [firebase_testing_quickstart.md](firebase_testing_quickstart.md) | Testers | Firebase App Distribution APK |
| [EMAIL_VERIFICATION.md](EMAIL_VERIFICATION.md) | Developers | SMTP / sign-up verification codes |
| [PASSWORD_RESET.md](PASSWORD_RESET.md) | Developers | Forgot-password flow |
| [SUPPORT_CHAT.md](SUPPORT_CHAT.md) | Developers | User ↔ admin live chat via API |
| [USAGE_AND_DOCKER.md](USAGE_AND_DOCKER.md) | Developers | Docker workflow (optional) |
| [RENDER_FIX.md](RENDER_FIX.md) | Developers | Common Render deploy issues |
| [SECURITY_GITHUB_ALERTS.md](SECURITY_GITHUB_ALERTS.md) | Developers | Secret scanning / `.env` hygiene |
| [NAV_BAR_IDEAS.md](NAV_BAR_IDEAS.md) | Planning | Future navigation ideas |

**Regenerate Word manuals**

```powershell
python docs/generate_user_manual.py
python docs/generate_project_guide.py
```
