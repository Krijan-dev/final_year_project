"use strict";

function serializeConversation(doc) {
  return {
    id: String(doc._id),
    userId: doc.userId,
    status: doc.status,
    lastMessageAt: doc.lastMessageAt,
    lastPreview: doc.lastPreview ?? "",
    unreadForAdmin: doc.unreadForAdmin ?? 0,
    unreadForUser: doc.unreadForUser ?? 0,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}

function serializeMessage(doc) {
  return {
    id: String(doc._id),
    sender: doc.sender,
    text: doc.text,
    createdAt: doc.createdAt,
  };
}

async function deleteConversationFully(SupportConversation, SupportMessage, convId) {
  await SupportMessage.deleteMany({ conversationId: convId });
  await SupportConversation.findByIdAndDelete(convId);
}

function registerSupportRoutes(
  app,
  { SupportConversation, SupportMessage, requireAuth, requireAdmin, createCrisisFlag },
) {
  async function findOpenConversation(userId) {
    return SupportConversation.findOne({
      userId,
      status: { $in: ["waiting", "active"] },
    }).exec();
  }

  const welcomeText =
    "Thanks for reaching out. You're connected to our support team — we'll reply here as soon as someone is available.";

  app.post("/api/v1/support/conversations", requireAuth, async (req, res) => {
    try {
      let conv = await findOpenConversation(req.authEmail);
      if (!conv) {
        conv = await SupportConversation.create({
          userId: req.authEmail,
          status: "waiting",
          lastPreview: welcomeText.slice(0, 120),
        });
        await SupportMessage.create({
          conversationId: conv._id,
          sender: "admin",
          text: welcomeText,
        });
        await SupportConversation.updateOne(
          { _id: conv._id },
          { lastMessageAt: new Date(), unreadForUser: 1 },
        );
        conv = await SupportConversation.findById(conv._id).exec();
      }
      res.json({ ok: true, conversation: serializeConversation(conv) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/support/conversation", requireAuth, async (req, res) => {
    try {
      const conv = await findOpenConversation(req.authEmail);
      if (!conv) {
        return res.json({ ok: true, conversation: null });
      }
      res.json({ ok: true, conversation: serializeConversation(conv) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/support/messages", requireAuth, async (req, res) => {
    try {
      const conv = await findOpenConversation(req.authEmail);
      if (!conv) {
        return res.json({ ok: true, conversation: null, messages: [] });
      }
      const since = req.query.since ? new Date(String(req.query.since)) : null;
      const filter = { conversationId: conv._id };
      if (since && !Number.isNaN(since.getTime())) {
        filter.createdAt = { $gt: since };
      }
      const rows = await SupportMessage.find(filter).sort({ createdAt: 1 }).lean().exec();
      await SupportConversation.updateOne({ _id: conv._id }, { unreadForUser: 0 });
      res.json({
        ok: true,
        conversation: serializeConversation(conv),
        messages: rows.map(serializeMessage),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.post("/api/v1/support/messages", requireAuth, async (req, res) => {
    try {
      const text = String(req.body?.text || "").trim();
      if (!text) {
        return res.status(400).json({ error: "Message text is required." });
      }
      if (text.length > 4000) {
        return res.status(400).json({ error: "Message is too long (max 4000 characters)." });
      }

      let conv = await findOpenConversation(req.authEmail);
      if (!conv) {
        conv = await SupportConversation.create({
          userId: req.authEmail,
          status: "waiting",
        });
      }

      const msg = await SupportMessage.create({
        conversationId: conv._id,
        sender: "user",
        text,
      });
      await SupportConversation.updateOne(
        { _id: conv._id },
        {
          lastMessageAt: new Date(),
          lastPreview: text.slice(0, 120),
          $inc: { unreadForAdmin: 1 },
        },
      );

      if (createCrisisFlag) {
        await createCrisisFlag(req.authEmail, "support_chat", text);
      }

      res.status(201).json({ ok: true, message: serializeMessage(msg) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/support/conversations", requireAdmin, async (_req, res) => {
    try {
      const rows = await SupportConversation.find({
        status: { $in: ["waiting", "active"] },
      })
        .sort({ lastMessageAt: -1 })
        .lean()
        .exec();
      res.json({
        ok: true,
        conversations: rows.map(serializeConversation),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.get("/api/v1/admin/support/conversations/:id/messages", requireAdmin, async (req, res) => {
    try {
      const conv = await SupportConversation.findById(req.params.id).lean().exec();
      if (!conv) {
        return res.status(404).json({ error: "Conversation not found" });
      }
      const since = req.query.since ? new Date(String(req.query.since)) : null;
      const filter = { conversationId: conv._id };
      if (since && !Number.isNaN(since.getTime())) {
        filter.createdAt = { $gt: since };
      }
      const rows = await SupportMessage.find(filter).sort({ createdAt: 1 }).lean().exec();
      if (conv.status === "waiting") {
        await SupportConversation.updateOne({ _id: conv._id }, { status: "active" });
        conv.status = "active";
      }
      await SupportConversation.updateOne({ _id: conv._id }, { unreadForAdmin: 0 });
      res.json({
        ok: true,
        conversation: serializeConversation(conv),
        messages: rows.map(serializeMessage),
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.post("/api/v1/admin/support/conversations/:id/messages", requireAdmin, async (req, res) => {
    try {
      const text = String(req.body?.text || "").trim();
      if (!text) {
        return res.status(400).json({ error: "Message text is required." });
      }
      const conv = await SupportConversation.findById(req.params.id).exec();
      if (!conv) {
        return res.status(404).json({ error: "Conversation not found" });
      }
      if (conv.status === "closed") {
        return res.status(400).json({ error: "Conversation is closed." });
      }

      const msg = await SupportMessage.create({
        conversationId: conv._id,
        sender: "admin",
        text,
      });
      await SupportConversation.updateOne(
        { _id: conv._id },
        {
          status: "active",
          lastMessageAt: new Date(),
          lastPreview: text.slice(0, 120),
          $inc: { unreadForUser: 1 },
        },
      );

      res.status(201).json({ ok: true, message: serializeMessage(msg) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.delete("/api/v1/admin/support/conversations/:id", requireAdmin, async (req, res) => {
    try {
      const conv = await SupportConversation.findById(req.params.id).exec();
      if (!conv) {
        return res.status(404).json({ error: "Conversation not found" });
      }
      await deleteConversationFully(SupportConversation, SupportMessage, conv._id);
      res.json({ ok: true, deleted: true });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });
}

module.exports = { registerSupportRoutes, deleteConversationFully };
