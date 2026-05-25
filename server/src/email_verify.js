"use strict";

const crypto = require("crypto");
const { sendVerificationEmail, isSmtpConfigured } = require("./email");

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

function newVerificationToken() {
  return crypto.randomBytes(32).toString("hex");
}

function registerEmailVerifyRoutes(app, { EmailVerification, User, normalizeEmail, isValidEmail }) {
  app.post("/api/v1/auth/send-verification", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }

      const existingUser = await User.findOne({ email }).lean().exec();
      if (existingUser) {
        return res.status(409).json({ error: "An account with this email already exists." });
      }

      const now = Date.now();
      let row = await EmailVerification.findOne({ email }).exec();
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
      const codeHash = hashValue(`${email}:${code}`);
      const codeExpiresAt = new Date(now + CODE_TTL_MS);

      if (!row) {
        row = await EmailVerification.create({
          email,
          codeHash,
          codeExpiresAt,
          lastSentAt: new Date(now),
          sendWindowStart: new Date(now),
          sendCountInWindow: 1,
          verified: false,
          verificationToken: null,
          tokenExpiresAt: null,
        });
      } else {
        row.codeHash = codeHash;
        row.codeExpiresAt = codeExpiresAt;
        row.lastSentAt = new Date(now);
        row.verified = false;
        row.verificationToken = null;
        row.tokenExpiresAt = null;
        row.sendCountInWindow = (row.sendCountInWindow ?? 0) + 1;
        await row.save();
      }

      await sendVerificationEmail({ to: email, code });

      const exposeDevCode =
        process.env.EMAIL_DEV_EXPOSE_CODE === "1" || process.env.EMAIL_DEV_EXPOSE_CODE === "true";
      const payload = {
        ok: true,
        email,
        expiresInMinutes: 15,
        smtpConfigured: isSmtpConfigured(),
      };
      if (exposeDevCode && !isSmtpConfigured()) {
        payload.devCode = code;
        payload.devHint = "SMTP not set — use this code for local testing only.";
      }
      res.json(payload);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message || "Could not send verification email." });
    }
  });

  app.post("/api/v1/auth/verify-email", async (req, res) => {
    try {
      const email = normalizeEmail(req.body?.email);
      const code = String(req.body?.code || "").trim();
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: "Enter a valid email address." });
      }
      if (!/^\d{6}$/.test(code)) {
        return res.status(400).json({ error: "Enter the 6-digit code from your email." });
      }

      const row = await EmailVerification.findOne({ email }).exec();
      if (!row || !row.codeHash || !row.codeExpiresAt) {
        return res.status(400).json({ error: "Request a verification code first." });
      }
      if (row.codeExpiresAt.getTime() < Date.now()) {
        return res.status(400).json({ error: "Code expired. Request a new one." });
      }
      if (row.codeHash !== hashValue(`${email}:${code}`)) {
        return res.status(400).json({ error: "Incorrect code. Check your email and try again." });
      }

      const verificationToken = newVerificationToken();
      row.verified = true;
      row.verificationToken = verificationToken;
      row.tokenExpiresAt = new Date(Date.now() + TOKEN_TTL_MS);
      row.codeHash = null;
      row.codeExpiresAt = null;
      await row.save();

      res.json({
        ok: true,
        email,
        verificationToken,
        expiresInMinutes: 30,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });
}

function assertEmailVerifiedForRegister(EmailVerification, email, verificationToken) {
  return EmailVerification.findOne({
    email,
    verified: true,
    verificationToken,
    tokenExpiresAt: { $gt: new Date() },
  }).exec();
}

module.exports = {
  registerEmailVerifyRoutes,
  assertEmailVerifiedForRegister,
};
