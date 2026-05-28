"use strict";

async function deleteUserFully(models, email) {
  const userId = String(email || "").trim().toLowerCase();
  if (!userId) throw new Error("Missing user email");

  const {
    User,
    UsageDay,
    HabitSnapshot,
    SupportConversation,
    SupportMessage,
    CrisisFlag,
    EmailVerification,
    PasswordReset,
  } = models;

  // Delete support messages first (they reference conversationId).
  const convs = await SupportConversation.find({ userId })
    .select({ _id: 1 })
    .lean()
    .exec();
  const convIds = convs.map((c) => c._id);
  if (convIds.length > 0) {
    await SupportMessage.deleteMany({ conversationId: { $in: convIds } }).exec();
  }
  await SupportConversation.deleteMany({ userId }).exec();

  // Delete user-linked collections.
  await Promise.all([
    UsageDay.deleteMany({ userId }).exec(),
    HabitSnapshot.deleteMany({ userId }).exec(),
    CrisisFlag.deleteMany({ userId }).exec(),
    EmailVerification.deleteOne({ email: userId }).exec(),
    PasswordReset.deleteOne({ email: userId }).exec(),
  ]);

  // Finally delete the user account.
  await User.deleteOne({ email: userId }).exec();

  return { ok: true };
}

module.exports = { deleteUserFully };

