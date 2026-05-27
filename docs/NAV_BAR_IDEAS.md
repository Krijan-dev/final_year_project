# Bottom navigation — ideas for future tabs

Current nav (as of this doc): **Dashboard** · **Habit** · **Insights** · **Apps**  
**Chat** is a floating overlay (not in the nav bar). **Account / Log out** is in the app bar menu.

Use this list when planning new features. Nothing here is implemented yet.

---

## High value (strong fit for Life Pattern Tracker)

| Tab / area | What it could include | Why add it |
|------------|----------------------|------------|
| **Profile / Account** | Email, cloud sync status, change password, delete account, privacy summary | Users need one place for identity and data; ties into MongoDB / website plan |
| **Goals** | Daily screen-time target, habit targets, weekly goals | Separates “what I want” from “what happened” (Dashboard is mostly the latter) |
| **History / Trends** | Week and month charts: screen time, mood, habit completion over time | Deeper than Insights cards; good for thesis demos and admin website parity |
| **Health** | Health Connect: steps, sleep, heart rate, weekly summary | You already use Health on Habit tab; a dedicated tab if data grows |
| **Quick log** | Fast add: water, exercise, mood, preset activities | One tap to log without opening full Habit screen |

---

## Medium value (good for final-year demo)

| Tab / area | What it could include | Why add it |
|------------|----------------------|------------|
| **Focus / Timer** | Pomodoro or focus session; compare usage before/after session | Links behaviour change to measurable screen time |
| **Reminders** | Habit reminders, screen-time nudges, quiet hours | Increases engagement and habit consistency |
| **Achievements** | Streaks, badges, milestones | Gamification; easy to show in reports |
| **Compare** | This week vs last week (screen, habits, mood) | Single “am I improving?” view |
| **App limits** | Per-app daily limits and warnings | Natural extension of Apps tab if platform APIs allow |

---

## Lower priority — usually not a main nav tab

| Feature | Suggested placement | Notes |
|---------|---------------------|--------|
| **Settings** | App bar ⚙ or inside Profile | Theme, permissions, API URL, debug Gemini key |
| **Help / FAQ** | Profile or overflow menu | How to grant usage access, sync, Health Connect |
| **Crisis / Support** | Help or Settings | Lifeline **13 11 14**, emergency **000** — link only, not a daily tab |
| **AI suggestions** | Inside Insights or Dashboard | Avoid duplicating Insights if AI tips already live there |
| **Charts (legacy screen)** | Merge into History / Trends | `charts_screen.dart` exists in repo; fold into one trends experience |
| **Onboarding / Permissions** | First launch only | Usage access, Health Connect — not permanent nav |

---

## UX patterns (when you have many ideas)

### Too many tabs

Android **NavigationBar** works best with **3–5** destinations. More feels crowded on small phones.

### “More” tab pattern

Keep four main tabs and group extras:

| Main nav | Contents |
|----------|----------|
| Home | Dashboard (today’s metrics) |
| Habits | Current Habit tab |
| Insights | Recommendations, risk, trends |
| More | Apps, History, Health, Goals, Settings, Account |

### Keep chat floating?

| Approach | Pros | Cons |
|----------|------|------|
| **Floating chat (current)** | Always reachable; doesn’t use a tab slot | Can overlap content on small screens |
| **Nav tab “Assistant”** | Obvious entry | Uses a slot; less “support widget” feel |

---

## Suggested priority (must have vs nice to have)

### Must have (if you expand nav for thesis / production)

1. **Profile / Account** — sync, logout, privacy (aligns with cloud database plan)  
2. **History / Trends** — proves longitudinal tracking  
3. **Settings** — permissions and configuration (can live under Profile)

### Nice to have

4. **Goals**  
5. **Quick log**  
6. **Health** (if Health Connect becomes a headline feature)  
7. **Focus / Timer**  
8. **Reminders**  
9. **Achievements**  
10. **Compare**  
11. **App limits**

### Probably skip as nav tabs

- Crisis support (use Help/Settings)  
- Duplicate AI surface  
- Standalone onboarding  

---

## Example “full product” nav (one opinion)

```
[ Home ]  [ Habits ]  [ Insights ]  [ More ]
```

**More** menu or sub-list:

- Apps (current Apps screen)  
- History & charts  
- Goals  
- Health summary  
- Account & sync  
- Settings  
- Help & support  

---

## Mapping to thesis themes

| Thesis focus | Prioritise these nav ideas |
|--------------|----------------------------|
| Digital wellbeing / screen time | History, Goals, App limits, Compare |
| Habit & mood tracking | Quick log, Achievements, Reminders |
| Data + admin website | Profile (sync status), History (data for web charts) |
| AI coaching | Keep chat floating; enrich Insights, don’t add a 5th AI tab |

---

## Related files in this repo

| File | Role |
|------|------|
| `lib/screens/home_shell.dart` | Bottom `NavigationBar` and tab pages |
| `lib/widgets/floating_chat_overlay.dart` | Assistant chat |
| `lib/screens/charts_screen.dart` | Older charts — candidate to merge into History |
| `lib/screens/dashboard_screen.dart` | Dashboard tab |
| `lib/screens/habit_screen.dart` | Habit tab |
| `lib/screens/insights_screen.dart` | Insights tab |
| `lib/screens/apps_screen.dart` | Apps tab |

---

## Changelog

| Date | Note |
|------|------|
| 2026-05-21 | Initial ideas doc (no implementation) |
