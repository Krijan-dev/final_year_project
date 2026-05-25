"use strict";

const crypto = require("crypto");
const { sendPasswordResetEmail, isSmtpConfigured } = require("./email");
const { hashPassword, newSessionToken } = require("./password");

const CODE_TTL_MS = 15 * 60 * 1000;
const TOKEN_TTL_MS = 30 * 60 * 1000;
const MIN_RESEND_MS = 60 * 1000;
const MAX_SENDS_PER_HOUR = 5;

function hashValue(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex");
}

function randomSixDigitCode() {
  return String(crypto.randomInt(100000, 1000000));
}

function newResetToken() {
  return crypto.randomBytes(32).toString("hex");
}

function registerPasswordResetRoutes(app, { PasswordReset, User, normalizeEmail, isValidEmail }) {
  app.post("/api/v1/auth/forgot-password", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }

      const user = await User.findOne({ email }).lean().exec();
      if (!user) {
        return res.json({
          ok: true,
          email,
          message: "If an account exists for this email, we sent a reset code.",
        });
      }

      const now = Date.now();
      let row = await PasswordReset.findOne({ email }).exec();
      if (row) {
        if (row.lastSentAt && now - row.lastSentAt.getTime() < MIN_RESEND_MS) {
          return res.status(429).json({
            error: "Please wait a minute before requesting another code.",
          });
        }
        const hourAgo = new Date(now - 60 * 60 * 1000);
        if (row.sendWindowStart && row.sendWindowStart > hourAgo) {
          if ((row.sendCountInWindow ?? 0) >= MAX_SENDS_PER_HOUR) {
            return res.status(429).json({
              error: "Too many codes sent. Try again in an hour.",
            });
          }
        } else {
          row.sendWindowStart = new Date(now);
          row.sendCountInWindow = 0;
        }
      }

      const code = randomSixDigitCode();
      const codeHash = hashValue(`reset:${email}:${code}`);
      const codeExpiresAt = new Date(now + CODE_TTL_MS);

      if (!row) {
        await PasswordReset.create({
          email,
          codeHash,
          codeExpiresAt,
          lastSentAt: new Date(now),
          sendWindowStart: new Date(now),
          sendCountInWindow: 1,
          verified: false,
          resetToken: null,
          tokenExpiresAt: null,
        });
      } else {
        row.codeHash = codeHash;
        row.codeExpiresAt = codeExpiresAt;
        row.lastSentAt = new Date(now);
        row.verified = false;
        row.resetToken = null;
        row.tokenExpiresAt = null;
        row.sendCountInWindow = (row.sendCountInWindow ?? 0) + 1;
        await row.save();
      }

      await sendPasswordResetEmail({ to: email, code });

      const exposeDevCode =
        process.env.EMAIL_DEV_EXPOSE_CODE === "1" || process.env.EMAIL_DEV_EXPOSE_CODE === "true";
      const payload = {
        ok: true,
        email,
        expiresInMinutes: 15,
        message: "If an account exists for this email, we sent a reset code.",
        smtpConfigured: isSmtpConfigured(),
      };
      if (exposeDevCode && !isSmtpConfigured()) {
        payload.devCode = code;
        payload.devHint = "SMTP not set — use this code for local testing only.";
      }
      res.json(payload);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message || "Could not send reset code." });
    }
  });

  app.post("/api/v1/auth/verify-reset-code", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      const code = String(req.body?.code || "").trim();
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }
      if (!/^\d{6}$/.test(code)) {
        return res.status(400).json({ error: "Enter the 6-digit code from your email." });
      }

      const row = await PasswordReset.findOne({ email }).exec();
      if (!row || !row.codeHash || !row.codeExpiresAt) {
        return res.status(400).json({ error: "Request a reset code first." });
      }
      if (row.codeExpiresAt.getTime() < Date.now()) {
        return res.status(400).json({ error: "Code expired. Request a new one." });
      }
      if (row.codeHash !== hashValue(`reset:${email}:${code}`)) {
        return res.status(400).json({ error: "Incorrect code. Check your email and try again." });
      }

      const resetToken = newResetToken();
      row.verified = true;
      row.resetToken = resetToken;
      row.tokenExpiresAt = new Date(Date.now() + TOKEN_TTL_MS);
      row.codeHash = null;
      row.codeExpiresAt = null;
      await row.save();

      res.json({
        ok: true,
        email,
        resetToken,
        expiresInMinutes: 30,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.post("/api/v1/auth/reset-password", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      const password = String(req.body?.password || "");
      const resetToken = String(req.body?.resetToken || "").trim();
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }
      if (password.length < 6) {
        return res.status(400).json({ error: "Password must be at least 6 characters." });
      }
      if (!resetToken) {
        return res.status(400).json({ error: "Verify the reset code before setting a new password." });
      }

      const row = await PasswordReset.findOne({
        email,
        verified: true,
        resetToken,
        tokenExpiresAt: { $gt: new Date() },
      }).exec();
      if (!row) {
        return res.status(400).json({
          error: "Reset session expired. Request a new code.",
        });
      }

      const user = await User.findOne({ email }).exec();
      if (!user) {
        return res.status(400).json({ error: "No account found for this email." });
      }

      user.passwordHash = hashPassword(password);
      user.sessionToken = newSessionToken();
      await user.save();
      await PasswordReset.deleteOne({ email }).exec();

      res.json({ ok: true, email, token: user.sessionToken });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });
}

module.exports = { registerPasswordResetRoutes };
