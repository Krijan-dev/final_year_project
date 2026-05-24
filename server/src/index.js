"use strict";

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const { hashPassword, verifyPassword, newSessionToken } = require("./password");
const { registerAdminRoutes } = require("./admin");

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    sessionToken: { type: String, index: true, sparse: true },
  },
  { timestamps: true },
);
const User = mongoose.model("User", userSchema);

const usageDaySchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    dayKey: { type: String, required: true },
    data: { type: mongoose.Schema.Types.Mixed, required: true },
  },
  { timestamps: true },
);
usageDaySchema.index({ userId: 1, dayKey: 1 }, { unique: true });
const UsageDay = mongoose.model("UsageDay", usageDaySchema);

function normalizeEmail(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase();
}

function isValidEmail(email) {
  if (email.length < 5 || !email.includes("@")) return false;
  const parts = email.split("@");
  return parts.length === 2 && parts[0].length > 0 && parts[1].includes(".");
}

async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    if (!header.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Missing or invalid Authorization header" });
    }
    const token = header.slice(7).trim();
    if (!token) {
      return res.status(401).json({ error: "Missing session token" });
    }
    const user = await User.findOne({ sessionToken: token }).lean().exec();
    if (!user) {
      return res.status(401).json({ error: "Invalid or expired session" });
    }
    req.authEmail = user.email;
    next();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
}

function assertOwnUser(req, res) {
  const userId = decodeURIComponent(req.params.userId);
  if (userId !== req.authEmail) {
    res.status(403).json({ error: "You can only access your own data" });
    return false;
  }
  return true;
}

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error("Missing MONGODB_URI. Copy server/.env.example to server/.env");
    process.exit(1);
  }

  console.log("Connecting to MongoDB (timeout 15s)...");
  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 15_000,
      connectTimeoutMS: 15_000,
    });
  } catch (err) {
    console.error("MongoDB connection failed:");
    console.error(err.message || err);
    console.error(
      "\nCheck: Atlas cluster is running, IP allowlist includes your PC (0.0.0.0/0 for dev), " +
        "username/password in MONGODB_URI are correct, and special characters in the password are URL-encoded.",
    );
    process.exit(1);
  }
  console.log("MongoDB connected");

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: "4mb" }));

  app.get("/", (_req, res) => {
    res.type("text/plain").send(
      "Life Pattern Tracker API is running.\n\n" +
        "Auth: POST /api/v1/auth/register  POST /api/v1/auth/login\n" +
        "Admin: POST /api/v1/admin/login  GET /api/v1/admin/users (Bearer admin token)\n" +
        "Data (Bearer token): PUT/GET /api/v1/users/<email>/usage-days/...\n" +
        "Health: GET /health",
    );
  });

  app.get("/health", (_req, res) => {
    res.json({ ok: true, mongo: mongoose.connection.readyState === 1 });
  });

  app.post("/api/v1/auth/register", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      const password = String(req.body?.password || "");
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }
      if (password.length < 6) {
        return res.status(400).json({ error: "Password must be at least 6 characters." });
      }
      const existing = await User.findOne({ email }).exec();
      if (existing) {
        return res.status(409).json({ error: "An account with this email already exists." });
      }
      const token = newSessionToken();
      await User.create({
        email,
        passwordHash: hashPassword(password),
        sessionToken: token,
      });
      res.status(201).json({ ok: true, email, token });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.post("/api/v1/auth/login", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      const password = String(req.body?.password || "");
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }
      if (!password) {
        return res.status(400).json({ error: "Enter your password." });
      }
      const user = await User.findOne({ email }).exec();
      if (!user) {
        return res.status(401).json({ error: "No account found for this email." });
      }
      if (!verifyPassword(password, user.passwordHash)) {
        return res.status(401).json({ error: "Incorrect password." });
      }
      const token = newSessionToken();
      user.sessionToken = token;
      await user.save();
      res.json({ ok: true, email, token });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.post("/api/v1/auth/logout", requireAuth, async (req, res) => {
    try {
      await User.updateOne({ email: req.authEmail }, { $unset: { sessionToken: 1 } });
      res.json({ ok: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.put("/api/v1/users/:userId/usage-days/:dayKey", requireAuth, async (req, res) => {
    try {
      if (!assertOwnUser(req, res)) return;
      const userId = req.authEmail;
      const dayKey = decodeURIComponent(req.params.dayKey);
      const body = req.body;
      if (!body || typeof body !== "object") {
        return res.status(400).json({ error: "JSON body required" });
      }
      await UsageDay.findOneAndUpdate(
        { userId, dayKey },
        { userId, dayKey, data: body },
        { upsert: true, new: true },
      );
      res.json({ ok: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/users/:userId/usage-days", requireAuth, async (req, res) => {
    try {
      if (!assertOwnUser(req, res)) return;
      const userId = req.authEmail;
      const rows = await UsageDay.find({ userId }).sort({ dayKey: 1 }).lean().exec();
      res.json(rows.map((r) => r.data));
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  registerAdminRoutes(app, { User, UsageDay });

  const port = Number(process.env.PORT) || 3000;
  app.listen(port, "0.0.0.0", () => {
    console.log(`API listening on http://localhost:${port}`);
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
