import crypto from "node:crypto";
import nodemailer from "nodemailer";
import admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();

const db = admin.firestore();
const OTP_COLLECTION = "passwordResetOtps";
const OTP_EXPIRE_MINUTES = 10;

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function validateEmail(email) {
  const value = normalizeEmail(email);
  return value.includes("@") && value.length >= 6;
}

function docIdForEmail(email) {
  return Buffer.from(normalizeEmail(email)).toString("base64url");
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function hashOtp(email, otp, salt) {
  const raw = `${normalizeEmail(email)}|${otp}|${salt}`;
  return crypto.createHash("sha256").update(raw).digest("hex");
}

function transporter() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || user;

  if (!host || !user || !pass || !from) {
    throw new HttpsError(
      "failed-precondition",
      "SMTP env is missing. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM."
    );
  }

  return {
    from,
    client: nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    }),
  };
}

async function sendOtpEmail(email, otp) {
  const { from, client } = transporter();
  await client.sendMail({
    from,
    to: email,
    subject: "FFP Vault Password Reset OTP",
    html: `
      <div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;padding:20px">
        <h2 style="margin:0 0 12px;color:#111">Reset your password</h2>
        <p style="color:#444;margin:0 0 20px">Use this 6-digit OTP to reset your FFP Vault password:</p>
        <div style="font-size:36px;letter-spacing:10px;font-weight:800;color:#C61C36;margin:12px 0 20px">${otp}</div>
        <p style="color:#666;margin:0 0 8px">This OTP expires in ${OTP_EXPIRE_MINUTES} minutes.</p>
        <p style="color:#888;margin:0">If you did not request this, ignore this email.</p>
      </div>
    `,
  });
}

async function getOtpState(email) {
  const ref = db.collection(OTP_COLLECTION).doc(docIdForEmail(email));
  const snap = await ref.get();
  if (!snap.exists) return { ref, data: null };
  return { ref, data: snap.data() };
}

export const requestPasswordResetOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  if (!validateEmail(email)) {
    throw new HttpsError("invalid-argument", "Valid email is required.");
  }

  // Avoid leaking whether the account exists.
  let userRecord = null;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (_) {
    userRecord = null;
  }

  if (!userRecord) {
    return { success: true, message: "OTP sent if account exists." };
  }

  const otp = generateOtp();
  const salt = crypto.randomBytes(16).toString("hex");
  const otpHash = hashOtp(email, otp, salt);
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + OTP_EXPIRE_MINUTES * 60 * 1000)
  );

  const ref = db.collection(OTP_COLLECTION).doc(docIdForEmail(email));
  await ref.set(
    {
      email,
      uid: userRecord.uid,
      otpHash,
      salt,
      expiresAt,
      attempts: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await sendOtpEmail(email, otp);
  return { success: true, message: "OTP sent successfully." };
});

export const verifyPasswordResetOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const otp = String(request.data?.otp || "").trim();

  if (!validateEmail(email) || otp.length != 6) {
    throw new HttpsError("invalid-argument", "Email and 6-digit OTP required.");
  }

  const { ref, data } = await getOtpState(email);
  if (!data) {
    throw new HttpsError("not-found", "OTP not found. Request a new OTP.");
  }
  if (data.expiresAt?.toMillis?.() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "OTP expired. Request a new OTP.");
  }

  const valid = hashOtp(email, otp, data.salt) === data.otpHash;
  if (!valid) {
    const attempts = Number(data.attempts || 0) + 1;
    if (attempts >= 5) {
      await ref.delete();
      throw new HttpsError("permission-denied", "Too many attempts. Request OTP again.");
    }
    await ref.update({
      attempts,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("permission-denied", "Invalid OTP.");
  }

  await ref.update({
    verified: true,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, message: "OTP verified." };
});

export const resetPasswordWithOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const otp = String(request.data?.otp || "").trim();
  const newPassword = String(request.data?.newPassword || "");

  if (!validateEmail(email) || otp.length != 6 || newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Email, 6-digit OTP, and new password (min 6) are required."
    );
  }

  const { ref, data } = await getOtpState(email);
  if (!data) {
    throw new HttpsError("not-found", "OTP not found. Request a new OTP.");
  }
  if (data.expiresAt?.toMillis?.() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "OTP expired. Request a new OTP.");
  }

  const valid = hashOtp(email, otp, data.salt) === data.otpHash;
  if (!valid) {
    throw new HttpsError("permission-denied", "Invalid OTP.");
  }

  let uid = data.uid;
  if (!uid) {
    const user = await admin.auth().getUserByEmail(email);
    uid = user.uid;
  }

  await admin.auth().updateUser(uid, { password: newPassword });
  await ref.delete();

  return { success: true, message: "Password reset successful." };
});
