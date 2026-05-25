"use strict";

const CRISIS_PATTERNS = [
  /suicid/i,
  /kill\s+myself/i,
  /killing\s+myself/i,
  /end\s+my\s+life/i,
  /ending\s+my\s+life/i,
  /take\s+my\s+life/i,
  /taking\s+my\s+life/i,
  /want\s+to\s+die/i,
  /wanna\s+die/i,
  /wanting\s+to\s+die/i,
  /trying\s+to\s+die/i,
  /try\s+to\s+die/i,
  /commit(ting)?\s+suicide/i,
  /wish\s+(i\s+)?(was|were)\s+dead/i,
  /don'?t\s+want\s+to\s+live/i,
  /do\s+not\s+want\s+to\s+live/i,
  /better\s+off\s+dead/i,
  /no\s+reason\s+to\s+live/i,
  /end\s+it\s+all/i,
  /want\s+to\s+end\s+it/i,
  /self[\s-]?harm/i,
  /hurt(ing)?\s+myself/i,
  /harm(ing)?\s+myself/i,
  /cut(ting)?\s+myself/i,
  /\bunalive\b/i,
  /not\s+worth\s+living/i,
  /can'?t\s+go\s+on\s+anymore/i,
  /cannot\s+go\s+on\s+anymore/i,
  /\bdying\b/i,
  /\bkill\s+me\b/i,
  /\bi\s+should\s+die\b/i,
];

function isCrisisText(raw) {
  const text = String(raw || "").trim();
  if (!text) return false;
  return CRISIS_PATTERNS.some((p) => p.test(text));
}

function serializeFlag(doc) {
  return {
    id: String(doc._id),
    userId: doc.userId,
    source: doc.source,
    messagePreview: doc.messagePreview,
    status: doc.status,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}

function registerCrisisRoutes(app, { CrisisFlag, requireAuth, requireAdmin }) {
  async function createFlag(userId, source, text) {
    if (!isCrisisText(text)) return null;
    const preview = String(text).trim().slice(0, 500);
    const recent = await CrisisFlag.findOne({
      userId,
      source,
      messagePreview: preview,
      status: "open",
      createdAt: { $gte: new Date(Date.now() - 60 * 60 * 1000) },
    })
      .lean()
      .exec();
    if (recent) return recent;
    return CrisisFlag.create({
      userId,
      source,
      messagePreview: preview,
      status: "open",
    });
  }

  app.post("/api/v1/crisis-flags", requireAuth, async (req, res) => {
    try {
      const text = String(req.body?.text || "").trim();
      const source = String(req.body?.source || "ai_chat").trim();
      if (!["ai_chat", "support_chat"].includes(source)) {
        return res.status(400).json({ error: "Invalid source" });
      }
      if (!text) {
        return res.status(400).json({ error: "Message text is required." });
      }
      if (!isCrisisText(text)) {
        return res.json({ ok: true, flagged: false });
      }
      const flag = await createFlag(req.authEmail, source, text);
      res.status(201).json({ ok: true, flagged: true, flag: serializeFlag(flag) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/crisis-flags", requireAdmin, async (req, res) => {
    try {
      const status = String(req.query.status || "open").trim();
      const filter = status === "all" ? {} : { status: status === "reviewed" ? "reviewed" : "open" };
      const rows = await CrisisFlag.find(filter).sort({ createdAt: -1 }).limit(200).lean().exec();
      const openCount = await CrisisFlag.countDocuments({ status: "open" }).exec();
      res.json({
        ok: true,
        openCount,
        flags: rows.map(serializeFlag),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.patch("/api/v1/admin/crisis-flags/:id", requireAdmin, async (req, res) => {
    try {
      const status = String(req.body?.status || "").trim();
      if (!["open", "reviewed"].includes(status)) {
        return res.status(400).json({ error: "Invalid status" });
      }
      const flag = await CrisisFlag.findByIdAndUpdate(
        req.params.id,
        { status },
        { new: true },
      )
        .lean()
        .exec();
      if (!flag) {
        return res.status(404).json({ error: "Flag not found" });
      }
      res.json({ ok: true, flag: serializeFlag(flag) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  return { createFlag, isCrisisText };
}

module.exports = { registerCrisisRoutes, isCrisisText };
