"use strict";

const crypto = require("crypto");

function normalizeAdminEmail(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase();
}

function adminToken() {
  const email = normalizeAdminEmail(process.env.ADMIN_EMAIL);
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password) return null;
  return crypto.createHash("sha256").update(`admin:${email}:${password}`).digest("hex");
}

function isAdminConfigured() {
  return Boolean(adminToken());
}

function verifyAdminCredentials(email, password) {
  const expectedEmail = normalizeAdminEmail(process.env.ADMIN_EMAIL);
  const expectedPassword = String(process.env.ADMIN_PASSWORD || "");
  return email === expectedEmail && password === expectedPassword;
}

function requireAdmin(req, res, next) {
  const expected = adminToken();
  if (!expected) {
    return res.status(503).json({
      error: "Admin not configured. Set ADMIN_EMAIL and ADMIN_PASSWORD on the API server.",
    });
  }
  const header = req.headers.authorization || "";
  if (!header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing admin token" });
  }
  const token = header.slice(7).trim();
  if (token !== expected) {
    return res.status(401).json({ error: "Invalid admin token" });
  }
  next();
}

function registerAdminRoutes(app, { User, UsageDay }) {
  app.post("/api/v1/admin/login", (req, res) => {
    try {
      if (!isAdminConfigured()) {
        return res.status(503).json({ error: "Admin credentials not configured on server." });
      }
      const email = normalizeAdminEmail(req.body?.email);
      const password = String(req.body?.password || "");
      if (!verifyAdminCredentials(email, password)) {
        return res.status(401).json({ error: "Invalid admin email or password." });
      }
      res.json({ ok: true, token: adminToken() });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/stats", requireAdmin, async (_req, res) => {
    try {
      const totalUsers = await User.countDocuments().exec();
      const usageAgg = await UsageDay.aggregate([
        { $group: { _id: "$userId", count: { $sum: 1 } } },
      ]).exec();
      const usersWithUsage = usageAgg.length;
      const totalUsageDays = usageAgg.reduce((s, r) => s + r.count, 0);
      res.json({
        ok: true,
        totalUsers,
        usersWithUsage,
        totalUsageDays,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/users", requireAdmin, async (_req, res) => {
    try {
      const users = await User.find().sort({ createdAt: -1 }).lean().exec();
      const usageAgg = await UsageDay.aggregate([
        {
          $group: {
            _id: "$userId",
            dayCount: { $sum: 1 },
            lastDayKey: { $max: "$dayKey" },
            totalMinutes: {
              $sum: { $ifNull: ["$data.totalScreenTime", 0] },
            },
          },
        },
      ]).exec();
      const usageByUser = Object.fromEntries(usageAgg.map((r) => [r._id, r]));

      res.json({
        ok: true,
        users: users.map((u) => {
          const usage = usageByUser[u.email];
          return {
            email: u.email,
            createdAt: u.createdAt,
            usageDayCount: usage?.dayCount ?? 0,
            lastDayKey: usage?.lastDayKey ?? null,
            totalScreenMinutes: usage?.totalMinutes ?? 0,
          };
        }),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/users/:email/usage-days", requireAdmin, async (req, res) => {
    try {
      const email = normalizeAdminEmail(decodeURIComponent(req.params.email));
      const user = await User.findOne({ email }).lean().exec();
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }
      const rows = await UsageDay.find({ userId: email }).sort({ dayKey: -1 }).lean().exec();
      res.json({
        ok: true,
        email,
        days: rows.map((r) => ({
          dayKey: r.dayKey,
          totalScreenTime: r.data?.totalScreenTime ?? 0,
          appCount: Array.isArray(r.data?.apps) ? r.data.apps.length : 0,
          updatedAt: r.updatedAt,
          data: r.data,
        })),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });
}

module.exports = {
  registerAdminRoutes,
  isAdminConfigured,
  requireAdmin,
};
