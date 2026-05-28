"use strict";

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const { hashPassword, verifyPassword, newSessionToken } = require("./password");
const { registerAdminRoutes, requireAdmin } = require("./admin");
const { registerHabitRoutes } = require("./habits");
const { registerSupportRoutes } = require("./support");
const { registerCrisisRoutes } = require("./crisis");
const {
  registerEmailVerifyRoutes,
  assertEmailVerifiedForRegister,
} = require("./email_verify");
const { registerPasswordResetRoutes } = require("./password_reset");
const { deleteUserFully } = require("./delete_user");

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    sessionToken: { type: String, index: true, sparse: true },
    emailVerified: { type: Boolean, default: false },
  },
  { timestamps: true },
);
const User = mongoose.model("User", userSchema);

const emailVerificationSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    codeHash: { type: String, default: null },
    codeExpiresAt: { type: Date, default: null },
    lastSentAt: { type: Date, default: null },
    sendWindowStart: { type: Date, default: null },
    sendCountInWindow: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    verificationToken: { type: String, default: null, index: true, sparse: true },
    tokenExpiresAt: { type: Date, default: null },
  },
  { timestamps: true },
);
const EmailVerification = mongoose.model("EmailVerification", emailVerificationSchema);

const passwordResetSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    codeHash: { type: String, default: null },
    codeExpiresAt: { type: Date, default: null },
    lastSentAt: { type: Date, default: null },
    sendWindowStart: { type: Date, default: null },
    sendCountInWindow: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    resetToken: { type: String, default: null, index: true, sparse: true },
    tokenExpiresAt: { type: Date, default: null },
  },
  { timestamps: true },
);
const PasswordReset = mongoose.model("PasswordReset", passwordResetSchema);

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

const habitSnapshotSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    weekKey: { type: String, required: true },
    data: { type: mongoose.Schema.Types.Mixed, required: true },
  },
  { timestamps: true },
);
habitSnapshotSchema.index({ userId: 1, weekKey: 1 }, { unique: true });
const HabitSnapshot = mongoose.model("HabitSnapshot", habitSnapshotSchema);

const supportConversationSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    status: {
      type: String,
      enum: ["waiting", "active", "closed"],
      default: "waiting",
    },
    lastMessageAt: { type: Date, default: Date.now },
    lastPreview: { type: String, default: "" },
    unreadForAdmin: { type: Number, default: 0 },
    unreadForUser: { type: Number, default: 0 },
  },
  { timestamps: true },
);
supportConversationSchema.index({ status: 1, lastMessageAt: -1 });

const supportMessageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "SupportConversation",
      required: true,
      index: true,
    },
    sender: { type: String, enum: ["user", "admin"], required: true },
    text: { type: String, required: true, maxlength: 4000 },
  },
  { timestamps: true },
);

const SupportConversation = mongoose.model("SupportConversation", supportConversationSchema);
const SupportMessage = mongoose.model("SupportMessage", supportMessageSchema);

const crisisFlagSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    source: { type: String, enum: ["ai_chat", "support_chat"], required: true },
    messagePreview: { type: String, required: true },
    status: { type: String, enum: ["open", "reviewed"], default: "open" },
  },
  { timestamps: true },
);
crisisFlagSchema.index({ status: 1, createdAt: -1 });
const CrisisFlag = mongoose.model("CrisisFlag", crisisFlagSchema);

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
        "Auth: POST /api/v1/auth/send-verification  verify-email  register  login\n" +
        "      forgot-password  verify-reset-code  reset-password\n" +
        "Admin: POST /api/v1/admin/login  GET /api/v1/admin/users (Bearer admin token)\n" +
        "Data (Bearer token): PUT/GET /api/v1/users/<email>/usage-days/...\n" +
        "Habits: PUT/GET /api/v1/users/<email>/habit-snapshot/<weekKey>  GET .../habit-snapshots/latest\n" +
        "Support chat: POST/GET /api/v1/support/... (Bearer user token)\n" +
        "Admin support: GET/POST /api/v1/admin/support/conversations/...\n" +
        "Crisis flags: POST /api/v1/crisis-flags  GET /api/v1/admin/crisis-flags\n" +
        "Health: GET /health",
    );
  });

  app.get("/health", (_req, res) => {
    res.json({ ok: true, mongo: mongoose.connection.readyState === 1 });
  });

  registerEmailVerifyRoutes(app, {
    EmailVerification,
    User,
    normalizeEmail,
    isValidEmail,
  });

  registerPasswordResetRoutes(app, {
    PasswordReset,
    User,
    normalizeEmail,
    isValidEmail,
  });

  app.post("/api/v1/auth/register", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      const password = String(req.body?.password || "");
      const verificationToken = String(req.body?.verificationToken || "").trim();
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }
      if (password.length < 6) {
        return res.status(400).json({ error: "Password must be at least 6 characters." });
      }
      if (!verificationToken) {
        return res.status(400).json({
          error: "Verify your email with the code we sent before creating an account.",
        });
      }
      const verified = await assertEmailVerifiedForRegister(
        EmailVerification,
        email,
        verificationToken,
      );
      if (!verified) {
        return res.status(400).json({
          error: "Email not verified or verification expired. Request a new code.",
        });
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
        emailVerified: true,
      });
      await EmailVerification.deleteOne({ email }).exec();
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

  // User self-delete: permanently removes account + all server-side data.
  // Requires valid session token and current password confirmation.
  app.delete("/api/v1/users/me", requireAuth, async (req, res) => {
    try {
      const password = String(req.body?.password || "");
      if (!password) {
        return res.status(400).json({ error: "Password is required to delete your account." });
      }
      const user = await User.findOne({ email: req.authEmail }).exec();
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }
      if (!verifyPassword(password, user.passwordHash)) {
        return res.status(401).json({ error: "Incorrect password." });
      }

      await deleteUserFully(
        {
          User,
          UsageDay,
          HabitSnapshot,
          SupportConversation,
          SupportMessage,
          CrisisFlag,
          EmailVerification,
          PasswordReset,
        },
        req.authEmail,
      );
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

  registerHabitRoutes(app, {
    HabitSnapshot,
    requireAuth,
    requireAdmin,
    assertOwnUser,
  });

  const { createFlag: createCrisisFlag } = registerCrisisRoutes(app, {
    CrisisFlag,
    requireAuth,
    requireAdmin,
  });

  registerSupportRoutes(app, {
    SupportConversation,
    SupportMessage,
    requireAuth,
    requireAdmin,
    createCrisisFlag,
  });

  registerAdminRoutes(app, {
    User,
    UsageDay,
    HabitSnapshot,
    SupportConversation,
    SupportMessage,
    CrisisFlag,
    EmailVerification,
    PasswordReset,
    deleteUserFully,
  });

  const port = Number(process.env.PORT) || 3000;
  app.listen(port, "0.0.0.0", () => {
    console.log(`API listening on http://localhost:${port}`);
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
