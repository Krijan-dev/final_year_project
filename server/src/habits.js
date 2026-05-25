"use strict";

function normalizeEmail(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase();
}

function registerHabitRoutes(app, { HabitSnapshot, requireAuth, requireAdmin, assertOwnUser }) {
  app.put("/api/v1/users/:userId/habit-snapshot/:weekKey", requireAuth, async (req, res) => {
    try {
      if (!assertOwnUser(req, res)) return;
      const userId = req.authEmail;
      const weekKey = decodeURIComponent(req.params.weekKey);
      const body = req.body;
      if (!body || typeof body !== "object") {
        return res.status(400).json({ error: "JSON body required" });
      }
      await HabitSnapshot.findOneAndUpdate(
        { userId, weekKey },
        {
          userId,
          weekKey,
          data: {
            weekKey: body.weekKey ?? weekKey,
            habits: body.habits ?? [],
            moodDays: body.moodDays ?? [],
            logs: body.logs ?? [],
          },
        },
        { upsert: true, new: true },
      );
      res.json({ ok: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/users/:userId/habit-snapshot/:weekKey", requireAuth, async (req, res) => {
    try {
      if (!assertOwnUser(req, res)) return;
      const userId = req.authEmail;
      const weekKey = decodeURIComponent(req.params.weekKey);
      const row = await HabitSnapshot.findOne({ userId, weekKey }).lean().exec();
      if (!row) {
        return res.json({ ok: true, weekKey, habits: [], moodDays: [], logs: [] });
      }
      res.json({ ok: true, ...(row.data || {}) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/users/:email/habit-snapshot", requireAdmin, async (req, res) => {
    try {
      const email = normalizeEmail(decodeURIComponent(req.params.email));
      const row = await HabitSnapshot.findOne({ userId: email })
        .sort({ updatedAt: -1 })
        .lean()
        .exec();
      if (!row) {
        return res.json({ ok: true, email, snapshot: null });
      }
      res.json({
        ok: true,
        email,
        weekKey: row.weekKey,
        snapshot: row.data,
        updatedAt: row.updatedAt,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });
}

module.exports = { registerHabitRoutes };
