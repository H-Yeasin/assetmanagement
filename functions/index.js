import crypto from "node:crypto";
import nodemailer from "nodemailer";
import admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";

admin.initializeApp();

const firestoreDbId = (process.env.FIRESTORE_DB_ID || "").trim();
const db = firestoreDbId.length > 0 ?
  getFirestore(admin.app(), firestoreDbId) :
  getFirestore(admin.app());
const OTP_COLLECTION = "passwordResetOtps";
const TWO_FACTOR_COLLECTION = "twoFactorOtps";
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
      "SMTP env is missing. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM.",
    );
  }

  return {
    from,
    client: nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: {user, pass},
    }),
  };
}

async function sendOtpEmail(email, otp, purpose = "reset") {
  const {from, client} = transporter();
  const subjectMap = {
    reset: "FFP Vault Password Reset OTP",
    twoFactorEnable: "FFP Vault Two-Factor Setup OTP",
    twoFactorLogin: "FFP Vault Login Verification OTP",
  };
  const titleMap = {
    reset: "Reset your password",
    twoFactorEnable: "Enable two-factor authentication",
    twoFactorLogin: "Verify your login",
  };
  const descMap = {
    reset: "Use this 6-digit OTP to reset your FFP Vault password:",
    twoFactorEnable: "Use this 6-digit OTP to enable two-factor authentication:",
    twoFactorLogin: "Use this 6-digit OTP to complete your login:",
  };

  await client.sendMail({
    from,
    to: email,
    subject: subjectMap[purpose] || subjectMap.reset,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;padding:20px">
        <h2 style="margin:0 0 12px;color:#111">${titleMap[purpose] || titleMap.reset}</h2>
        <p style="color:#444;margin:0 0 20px">${descMap[purpose] || descMap.reset}</p>
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
  if (!snap.exists) return {ref, data: null};
  return {ref, data: snap.data()};
}

async function getTwoFactorState(uid, purpose) {
  const ref = db.collection(TWO_FACTOR_COLLECTION).doc(`${uid}_${purpose}`);
  const snap = await ref.get();
  if (!snap.exists) return {ref, data: null};
  return {ref, data: snap.data()};
}

async function issueTwoFactorOtp({uid, email, purpose}) {
  const otp = generateOtp();
  const salt = crypto.randomBytes(16).toString("hex");
  const otpHash = hashOtp(email, otp, salt);
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + OTP_EXPIRE_MINUTES * 60 * 1000),
  );

  const ref = db.collection(TWO_FACTOR_COLLECTION).doc(`${uid}_${purpose}`);
  await ref.set({
    uid,
    email,
    purpose,
    otpHash,
    salt,
    attempts: 0,
    expiresAt,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  await sendOtpEmail(email, otp, purpose);
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
    return {success: true, message: "OTP sent if account exists."};
  }

  const otp = generateOtp();
  const salt = crypto.randomBytes(16).toString("hex");
  const otpHash = hashOtp(email, otp, salt);
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + OTP_EXPIRE_MINUTES * 60 * 1000),
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
    {merge: true},
  );

  await sendOtpEmail(email, otp);
  return {success: true, message: "OTP sent successfully."};
});

export const requestTwoFactorEnable = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;
  const email = normalizeEmail(
    request.data?.email || request.auth.token?.email || "",
  );
  if (!validateEmail(email)) {
    throw new HttpsError("invalid-argument", "Valid email is required.");
  }

  await issueTwoFactorOtp({uid, email, purpose: "twoFactorEnable"});
  return {
    success: true,
    message: "Verification code sent.",
    email,
  };
});

export const verifyTwoFactorEnable = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;
  const otp = String(request.data?.otp || "").trim();
  if (otp.length !== 6) {
    throw new HttpsError("invalid-argument", "6-digit OTP is required.");
  }

  const {ref, data} = await getTwoFactorState(uid, "twoFactorEnable");
  if (!data) {
    throw new HttpsError("not-found", "OTP not found. Request a new code.");
  }
  if (data.expiresAt?.toMillis?.() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "OTP expired. Request a new code.");
  }

  const valid = hashOtp(data.email, otp, data.salt) === data.otpHash;
  if (!valid) {
    const attempts = Number(data.attempts || 0) + 1;
    if (attempts >= 5) {
      await ref.delete();
      throw new HttpsError("permission-denied", "Too many attempts.");
    }
    await ref.update({
      attempts,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("permission-denied", "Invalid OTP.");
  }

  await db.collection("users").doc(uid).set({
    twoFactorEnabled: true,
    twoFactorEmail: data.email,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  await ref.delete();

  return {
    success: true,
    message: "Two-factor authentication enabled.",
    email: data.email,
  };
});

export const requestTwoFactorLogin = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;
  const userSnap = await db.collection("users").doc(uid).get();
  const userData = userSnap.data() || {};
  const enabled = userData.twoFactorEnabled === true;
  if (!enabled) {
    return {success: true, twoFactorRequired: false};
  }

  const email = normalizeEmail(
    userData.twoFactorEmail || request.auth.token?.email || request.data?.email || "",
  );
  if (!validateEmail(email)) {
    throw new HttpsError("failed-precondition", "No 2FA email configured.");
  }

  await issueTwoFactorOtp({uid, email, purpose: "twoFactorLogin"});
  return {
    success: true,
    twoFactorRequired: true,
    message: "Verification code sent.",
    email,
  };
});

export const verifyTwoFactorLogin = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;
  const otp = String(request.data?.otp || "").trim();
  if (otp.length !== 6) {
    throw new HttpsError("invalid-argument", "6-digit OTP is required.");
  }

  const {ref, data} = await getTwoFactorState(uid, "twoFactorLogin");
  if (!data) {
    throw new HttpsError("not-found", "OTP not found. Please log in again.");
  }
  if (data.expiresAt?.toMillis?.() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "OTP expired. Please log in again.");
  }

  const valid = hashOtp(data.email, otp, data.salt) === data.otpHash;
  if (!valid) {
    const attempts = Number(data.attempts || 0) + 1;
    if (attempts >= 5) {
      await ref.delete();
      throw new HttpsError("permission-denied", "Too many attempts.");
    }
    await ref.update({
      attempts,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("permission-denied", "Invalid OTP.");
  }

  await ref.delete();
  return {success: true, message: "Login verification successful."};
});

export const verifyPasswordResetOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const otp = String(request.data?.otp || "").trim();

  if (!validateEmail(email) || otp.length != 6) {
    throw new HttpsError("invalid-argument", "Email and 6-digit OTP required.");
  }

  const {ref, data} = await getOtpState(email);
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

  return {success: true, message: "OTP verified."};
});

export const resetPasswordWithOtp = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const otp = String(request.data?.otp || "").trim();
  const newPassword = String(request.data?.newPassword || "");

  if (!validateEmail(email) || otp.length != 6 || newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Email, 6-digit OTP, and new password (min 6) are required.",
    );
  }

  const {ref, data} = await getOtpState(email);
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

  await admin.auth().updateUser(uid, {password: newPassword});
  await ref.delete();

  return {success: true, message: "Password reset successful."};
});
