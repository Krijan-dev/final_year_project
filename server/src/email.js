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
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST.trim(),
    port,
    secure,
    auth: {
      user: process.env.SMTP_USER.trim(),
      pass: process.env.SMTP_PASS.trim(),
    },
  });
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
    throw new Error(
      "Could not send email. Check SMTP_USER/SMTP_PASS (use a Gmail App Password, not your normal login password).",
    );
  }
}

module.exports = { sendVerificationEmail, isSmtpConfigured };
