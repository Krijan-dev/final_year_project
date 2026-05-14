"use strict";

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");

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

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error("Missing MONGODB_URI. Copy server/.env.example to server/.env");
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log("MongoDB connected");

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: "4mb" }));

  app.get("/health", (_req, res) => {
    res.json({ ok: true, mongo: mongoose.connection.readyState === 1 });
  });

  /**
   * PUT body = same JSON shape as Flutter DailyUsageModel.toMap()
   * userId = URL-encoded email
   * dayKey = YYYY-MM-DD (URL-encoded if needed)
   */
  app.put("/api/v1/users/:userId/usage-days/:dayKey", async (req, res) => {
    try {
      const userId = decodeURIComponent(req.params.userId);
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

  /** Returns array of usage payloads (newest last), sorted by dayKey */
  app.get("/api/v1/users/:userId/usage-days", async (req, res) => {
    try {
      const userId = decodeURIComponent(req.params.userId);
      const rows = await UsageDay.find({ userId }).sort({ dayKey: 1 }).lean().exec();
      res.json(rows.map((r) => r.data));
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
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
