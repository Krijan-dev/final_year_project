"use strict";

const crypto = require("crypto");

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString("hex");
  const digest = crypto.createHash("sha256").update(`${salt}${password}`).digest("hex");
  return `${salt}:${digest}`;
}

function verifyPassword(password, stored) {
  const parts = String(stored).split(":");
  if (parts.length !== 2) return false;
  const [salt, expected] = parts;
  const digest = crypto.createHash("sha256").update(`${salt}${password}`).digest("hex");
  return digest === expected;
}

function newSessionToken() {
  return crypto.randomBytes(32).toString("hex");
}

module.exports = { hashPassword, verifyPassword, newSessionToken };
