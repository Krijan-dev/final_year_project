"use strict";

const nodemailer = require("nodemailer");

function isSmtpConfigured() {
  return Boolean(
    process.env.SMTP_HOST?.trim() &&
      process.env.SMTP_USER?.trim() &&
      process.env.SMTP_PASS?.trim(),
  );
}

function createTransport() {
  const port = Number(process.env.SMTP_PORT) || 587;
  const secure = process.env.SMTP_SECURE === "true" || port === 465;
  const connectionTimeout = Number(process.env.SMTP_CONNECTION_TIMEOUT_MS) || 15000;
  const greetingTimeout = Number(process.env.SMTP_GREETING_TIMEOUT_MS) || 15000;
  const socketTimeout = Number(process.env.SMTP_SOCKET_TIMEOUT_MS) || 20000;
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST.trim(),
    port,
    secure,
    requireTLS: !secure,
    connectionTimeout,
    greetingTimeout,
    socketTimeout,
    auth: {
      user: process.env.SMTP_USER.trim(),
      pass: process.env.SMTP_PASS.trim(),
    },
  });
}

async function logSmtpStartupStatus() {
  if (!isSmtpConfigured()) {
    console.log("[email] SMTP startup check: skipped (SMTP env vars not fully configured).");
    return;
  }

  const host = process.env.SMTP_HOST?.trim();
  const port = Number(process.env.SMTP_PORT) || 587;
  const secure = process.env.SMTP_SECURE === "true" || port === 465;
  const user = process.env.SMTP_USER?.trim() || "";

  try {
    const transport = createTransport();
    await transport.verify();
    console.log(
      `[email] SMTP startup check: OK (${host}:${port}, secure=${secure}, user=${user})`,
    );
  } catch (err) {
    const code = err?.code ? ` code=${err.code}` : "";
    console.error(
      `[email] SMTP startup check: FAILED (${host}:${port}, secure=${secure}, user=${user})${code} message=${err?.message || err}`,
    );
  }
}

async function sendVerificationEmail({ to, code }) {
  const from = process.env.SMTP_FROM?.trim() || process.env.SMTP_USER?.trim() || "noreply@lifepattern.app";
  const subject = "Your Life Pattern Tracker verification code";
  const text =
    `Your verification code is: ${code}\n\n` +
    "Enter this code in the app to verify your email. It expires in 15 minutes.\n\n" +
    "If you did not request this, you can ignore this email.";
  const html =
    `<div style="font-family:sans-serif;max-width:480px">` +
    `<h2 style="color:#16a34a">Life Pattern Tracker</h2>` +
    `<p>Your verification code is:</p>` +
    `<p style="font-size:28px;font-weight:bold;letter-spacing:4px;color:#16a34a">${code}</p>` +
    `<p style="color:#64748b;font-size:14px">This code expires in 15 minutes. If you did not sign up, ignore this email.</p>` +
    `</div>`;

  if (!isSmtpConfigured()) {
    console.log(`[email] SMTP not configured — verification code for ${to}: ${code}`);
    return { sent: false, devLogged: true };
  }

  const transport = createTransport();
  try {
    await transport.sendMail({ from, to, subject, text, html });
    return { sent: true, devLogged: false };
  } catch (err) {
    console.error("[email] SMTP send failed:", err.message);
    const msg = String(err?.message || "").toLowerCase();
    if (
      msg.includes("connection timeout") ||
      msg.includes("timed out") ||
      err?.code === "ETIMEDOUT" ||
      err?.code === "ESOCKET"
    ) {
      throw new Error(
        "Could not connect to SMTP server (timeout). Check SMTP_HOST/SMTP_PORT and try port 465 with SMTP_SECURE=true, or use a dedicated SMTP provider.",
      );
    }
    throw new Error(
      "Could not send email. Check SMTP_USER/SMTP_PASS (use a Gmail App Password, not your normal login password).",
    );
  }
}

async function sendPasswordResetEmail({ to, code }) {
  const from = process.env.SMTP_FROM?.trim() || process.env.SMTP_USER?.trim() || "noreply@lifepattern.app";
  const subject = "Reset your Life Pattern Tracker password";
  const text =
    `Your password reset code is: ${code}\n\n` +
    "Enter this code in the app to choose a new password. It expires in 15 minutes.\n\n" +
    "If you did not request this, you can ignore this email.";
  const html =
    `<div style="font-family:sans-serif;max-width:480px">` +
    `<h2 style="color:#16a34a">Life Pattern Tracker</h2>` +
    `<p>Your password reset code is:</p>` +
    `<p style="font-size:28px;font-weight:bold;letter-spacing:4px;color:#16a34a">${code}</p>` +
    `<p style="color:#64748b;font-size:14px">This code expires in 15 minutes. If you did not request a reset, ignore this email.</p>` +
    `</div>`;

  if (!isSmtpConfigured()) {
    console.log(`[email] SMTP not configured — password reset code for ${to}: ${code}`);
    return { sent: false, devLogged: true };
  }

  const transport = createTransport();
  try {
    await transport.sendMail({ from, to, subject, text, html });
    return { sent: true, devLogged: false };
  } catch (err) {
    console.error("[email] SMTP send failed:", err.message);
    const msg = String(err?.message || "").toLowerCase();
    if (
      msg.includes("connection timeout") ||
      msg.includes("timed out") ||
      err?.code === "ETIMEDOUT" ||
      err?.code === "ESOCKET"
    ) {
      throw new Error(
        "Could not connect to SMTP server (timeout). Check SMTP_HOST/SMTP_PORT and try port 465 with SMTP_SECURE=true, or use a dedicated SMTP provider.",
      );
    }
    throw new Error(
      "Could not send email. Check SMTP_USER/SMTP_PASS (use a Gmail App Password, not your normal login password).",
    );
  }
}

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  isSmtpConfigured,
  logSmtpStartupStatus,
};

