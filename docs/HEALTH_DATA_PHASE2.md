# Health data — Phase 2 plan (all phones)

> **Current (Phase 1):** Health Connect only — steps + sleep via `HealthConnectBridge` + Flutter `health` plugin.  
> **Goal:** Reliable steps and sleep on **any Android phone**, with optional OEM boosts where legally/technically possible.

---

## Why we cannot “open the health app directly” on every phone

| Source | All Android? | Direct read? | Notes |
|--------|----------------|-------------|--------|
| **Health Connect** | Yes (API 28+, HC app on 9+) | Yes (with permission) | **Primary path** — Samsung, Fitbit, Google Fit sync *into* HC |
| Samsung Health app only | Samsung | Samsung Health Data SDK | Partner approval for Play Store; dev mode for testing |
| Google Fit API | Yes | Deprecated → migrate to HC | Sunset 2025–2026 |
| Fitbit / Garmin API | Yes | OAuth + their cloud API | Per-vendor integration, accounts, rate limits |
| Reading app private DB | No | Blocked by Android | Not possible |

**Phase 2 does not replace Health Connect.** It makes HC more reliable and adds **fallbacks** when HC is empty or wrong.

---

## Phase 2 architecture (target)

```
┌─────────────────────────────────────────────────────────────┐
│                    Life Pattern Tracker                      │
├─────────────────────────────────────────────────────────────┤
│  HealthDataOrchestrator (Dart)                               │
│    1. Health Connect native aggregate (steps + sleep)        │
│    2. Health plugin enrich (max of native vs plugin)         │
│    3. [2b] OEM reader if available (Samsung SDK)             │
│    4. [2c] Manual sleep/steps override (user entry)          │
└───────────────────────────┬─────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
   Health Connect    Samsung Health      User manual
   (all phones)      Data SDK            (optional)
                     (Samsung only)
```

---

## Phase 2A — Health Connect hardening (all phones) — **in progress**

**Scope:** Every Android tester; no new store approvals.

| Task | Status | Detail |
|------|--------|--------|
| Steps via HC **aggregate** | Done | Matches HC dashboard totals |
| Sleep via HC **aggregate** + longest session | Done | `SLEEP_DURATION_TOTAL` + best session |
| Separate Steps vs Sleep permission UI | Done | Banner if only Steps allowed |
| Native HC permission dialog (Steps + Sleep) | Done | `requestHealthConnectPermissions` in MainActivity |
| Auto-open fitness app after grant | Done | Samsung Health / Fitbit etc. when sleep missing |
| Manual sleep + sleep score fallback | Done | `ManualSleepStorage`, Health tab "Add sleep manually" |
| Wider “last night” window | Done | Yesterday 00:00 → now |
| Plugin sleep enrich (session + asleep types) | Done | Takes max with native |
| Freshness / stale banner | Done | Last update time |
| Fitness app detection + open app | Done | Samsung Health, Fitbit, etc. |
| Auto-refresh on resume | Done | Health tab |
| Background refresh (WorkManager) | Planned | Refresh HC every 6h when permitted |
| Debug panel (testers) | Planned | Show raw: aggregate, session count, origins |
| Compare with HC app link | Planned | “Open Health Connect” button |
| Request `READ_HEALTH_DATA_HISTORY` | Planned | Steps/sleep older than 30 days if needed |

**Tester checklist (sleep):**

1. Health Connect → App permissions → **Life Pattern Tracker** → turn on **Steps** and **Sleep**.
2. Fitness app → share **Sleep** to Health Connect (not only steps).
3. Open Health Connect → confirm a **sleep session** appears for last night.
4. Life Pattern Tracker → Health → **Refresh**.

---

## Phase 2B — Multi-source merge (all phones)

**Scope:** When HC and plugin disagree, pick the best value with rules (not OEM-specific).

| Task | Effort | Detail |
|------|--------|--------|
| `HealthReading` model | Medium | `{ steps, sleepHours, source, confidence, updatedAt }` |
| Confidence scoring | Medium | Prefer aggregate > longest session > plugin sum |
| De-duplicate sleep | Medium | Never sum overlapping sessions from multiple apps |
| Show “source” on UI | Small | “Sleep: 7.2 h (Samsung Health via Health Connect)” |
| Log sync failures | Small | Analytics for thesis (permission vs empty HC) |

---

## Phase 2C — Samsung optional module (Samsung phones only)

**Scope:** ~40% of testers on Galaxy; **optional** add-on, not required for others.

| Task | Effort | Detail |
|------|--------|--------|
| Register Samsung developer + partner request | High | Required for production APK on Play |
| Integrate Samsung Health Data SDK | High | Native module; connect to Samsung Health app |
| Use when HC steps/sleep &lt; 70% of Samsung Health | Medium | Fallback only on Samsung devices |
| Feature flag in build | Small | `ENABLE_SAMSUNG_DIRECT=false` default |

**Not a replacement for HC:** Apple Watch on iPhone N/A; Fitbit users still need HC.

---

## Phase 2D — Other OEM / vendor (optional, lower priority)

| Vendor | Approach | All phones? |
|--------|----------|-------------|
| Google Fit | Health Connect only (Fit API deprecated) | Yes |
| Fitbit | Health Connect or Fitbit Web API + OAuth | Yes, heavy |
| Garmin | Health Connect or Garmin Health API | Yes, heavy |
| Xiaomi / Huawei | Health Connect + HC in their health apps | Yes |

**Recommendation:** Document “enable HC sync” per brand in user manual; only build vendor APIs if thesis scope expands.

---

## Phase 2E — Manual fallback (all phones)

**Scope:** When HC has no sleep/steps after permissions.

| Task | Effort | Detail |
|------|--------|--------|
| “Add sleep manually” on Health tab | Medium | Store in Hive; optional cloud sync |
| “Steps override for today” | Low | For demo / edge cases |
| Clear badge “Manual entry” | Small | Don’t mix with HC without label |

---

## Phase 2F — Dashboard integration

| Task | Detail |
|------|--------|
| Home card sleep/steps | Same orchestrator as Health tab |
| Insights wellness score | Use HC sleep when habit sleep missing |
| Chat context | Include sleep source in `InsightContextBuilder` |

---

## Timeline suggestion (thesis)

| Sprint | Deliverable |
|--------|-------------|
| **Now** | Ship APK with sleep aggregate + permission hints (Phase 2A partial) |
| Week 1 | 2A complete: background refresh, HC compare link, tester doc update |
| Week 2 | 2B merge layer + UI source labels |
| Week 3+ | 2E manual fallback OR 2C Samsung SDK (pick one for depth) |

---

## Success criteria

- [ ] Tester with Samsung Health: steps within ~5% of Samsung Health (via HC).
- [ ] Tester with sleep tracked: **Sleep (last night)** shows non-zero after HC has sleep session.
- [ ] Status bar shows if **Sleep** permission missing while Steps works.
- [ ] User manual + Phase 2 doc explain HC sync (not “broken app”).

---

## Files (Phase 1 / 2A touchpoints)

| Area | Path |
|------|------|
| Native HC read | `android/.../HealthConnectBridge.kt` |
| Fitness packages | `android/.../FitnessAppRegistry.kt` |
| Flutter service | `lib/services/health_connect_service.dart` |
| Health UI | `lib/screens/health_screen.dart` |
| User manual | `docs/User_Manual_In_A_Nutshell.docx` |

**Regenerate tester APK after native changes:**

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1 -GenerateQr
```
