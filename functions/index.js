/**
 * GymApp Cloud Functions
 * -----------------------
 * These run server-side (deployed to Firebase Cloud Functions), which is where
 * anything involving API keys or scheduled/automated messaging MUST live —
 * never in the iOS app itself.
 *
 * Set your secrets before deploying:
 *   firebase functions:config:set twilio.sid="ACxxxx" twilio.auth_token="xxxx" twilio.whatsapp_from="whatsapp:+14155238886" twilio.sms_from="+1XXXXXXXXXX"
 *
 * Deploy with:
 *   firebase deploy --only functions
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const twilio = require("twilio");
const logger = require("firebase-functions/logger");

admin.initializeApp();
const db = admin.firestore();

function getTwilioClient() {
  const sid = process.env.TWILIO_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  return twilio(sid, token);
}

// ---------------------------------------------------------------------------
// 1. DAILY SCHEDULED REMINDER: runs every day at 9:00 AM (server time).
//    Scans members expiring in 1-3 days and sends a WhatsApp + SMS reminder,
//    matching "3 day payment WhatsApp" from the original notes.
// ---------------------------------------------------------------------------
exports.sendExpiryReminders = onSchedule(
  {
    schedule: "0 9 * * *", // every day at 9 AM
    timeZone: "Asia/Kolkata",
    secrets: ["TWILIO_SID", "TWILIO_AUTH_TOKEN", "TWILIO_WHATSAPP_FROM", "TWILIO_SMS_FROM"],
  },
  async (event) => {
    const client = getTwilioClient();
    const now = new Date();
    const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    const snapshot = await db
      .collection("members")
      .where("expiryDate", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("expiryDate", "<=", admin.firestore.Timestamp.fromDate(threeDaysFromNow))
      .where("status", "==", "live")
      .get();

    logger.info(`Found ${snapshot.size} members expiring within 3 days`);

    const results = await Promise.allSettled(
      snapshot.docs.map(async (doc) => {
        const member = doc.data();
        const message = `Hi ${member.name}, your gym membership expires soon. Please renew to keep your plan active. Reply here if you have questions.`;

        // WhatsApp
        if (member.phone) {
          await client.messages.create({
            from: process.env.TWILIO_WHATSAPP_FROM,
            to: `whatsapp:${member.phone}`,
            body: message,
          });

          // SMS fallback
          await client.messages.create({
            from: process.env.TWILIO_SMS_FROM,
            to: member.phone,
            body: message,
          });
        }

        // Log the reminder so it shows up in the app's notification history
        await db.collection("reminderLogs").add({
          memberId: doc.id,
          type: "expiry",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      })
    );

    const failures = results.filter((r) => r.status === "rejected");
    if (failures.length > 0) {
      logger.error(`${failures.length} reminder(s) failed`, failures);
    }
  }
);

// ---------------------------------------------------------------------------
// 2. DAILY BIRTHDAY / ANNIVERSARY MESSAGES
// ---------------------------------------------------------------------------
exports.sendBirthdayAnniversaryMessages = onSchedule(
  {
    schedule: "0 8 * * *", // every day at 8 AM
    timeZone: "Asia/Kolkata",
    secrets: ["TWILIO_SID", "TWILIO_AUTH_TOKEN", "TWILIO_WHATSAPP_FROM"],
  },
  async (event) => {
    const client = getTwilioClient();
    const today = new Date();
    const month = today.getMonth() + 1;
    const day = today.getDate();

    const snapshot = await db.collection("members").where("status", "==", "live").get();

    const birthdayMembers = snapshot.docs.filter((doc) => {
      const dob = doc.data().dateOfBirth?.toDate();
      return dob && dob.getMonth() + 1 === month && dob.getDate() === day;
    });

    for (const doc of birthdayMembers) {
      const member = doc.data();
      if (!member.phone) continue;
      await client.messages.create({
        from: process.env.TWILIO_WHATSAPP_FROM,
        to: `whatsapp:${member.phone}`,
        body: `🎂 Happy Birthday, ${member.name}! Wishing you a great year ahead from all of us at the gym.`,
      });
    }

    logger.info(`Sent ${birthdayMembers.length} birthday messages`);
  }
);

// ---------------------------------------------------------------------------
// 3. MANUAL "SEND REMINDER NOW" — callable from the iOS app's member detail screen
// ---------------------------------------------------------------------------
exports.sendManualReminder = onCall(
  { secrets: ["TWILIO_SID", "TWILIO_AUTH_TOKEN", "TWILIO_WHATSAPP_FROM", "TWILIO_SMS_FROM"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const { memberId, channel } = request.data; // channel: "whatsapp" | "sms"

    const memberDoc = await db.collection("members").doc(memberId).get();
    if (!memberDoc.exists) {
      throw new HttpsError("not-found", "Member not found.");
    }
    const member = memberDoc.data();
    const message = `Hi ${member.name}, this is a reminder about your gym membership dues (₹${member.dueAmount}). Please make payment at your earliest convenience.`;

    const client = getTwilioClient();
    if (channel === "whatsapp") {
      await client.messages.create({
        from: process.env.TWILIO_WHATSAPP_FROM,
        to: `whatsapp:${member.phone}`,
        body: message,
      });
    } else {
      await client.messages.create({
        from: process.env.TWILIO_SMS_FROM,
        to: member.phone,
        body: message,
      });
    }

    return { success: true };
  }
);

// ---------------------------------------------------------------------------
// 4. CREATE STAFF ACCOUNT — called from Manage Staff screen (owner only).
//    Done server-side via Admin SDK so it doesn't sign the calling owner out
//    (which is what happens if you call createUser() directly from the client SDK).
// ---------------------------------------------------------------------------
exports.createStaffAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  // Verify the caller is an owner
  const callerDoc = await db.collection("admins").doc(request.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "owner") {
    throw new HttpsError("permission-denied", "Only owners can add staff.");
  }

  const { name, email, password, role } = request.data;
  if (!["staff", "trainer"].includes(role)) {
    throw new HttpsError("invalid-argument", "Role must be 'staff' or 'trainer'.");
  }

  const userRecord = await admin.auth().createUser({ email, password, displayName: name });

  await db.collection("admins").doc(userRecord.uid).set({
    name,
    loginEmail: email,
    role,
  });

  return { success: true, uid: userRecord.uid };
});
