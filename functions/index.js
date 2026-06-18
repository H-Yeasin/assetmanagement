import crypto from "node:crypto";
import nodemailer from "nodemailer";
import admin from "firebase-admin";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { defineSecret } from "firebase-functions/params";

const rcWebhookSecret = defineSecret("RC_WEBHOOK_SECRET");

const smtpUserSecret = defineSecret("SMTP_USER_SECRET");
const smtpPassSecret = defineSecret("SMTP_PASS_SECRET");
const smtpHostSecret = defineSecret("SMTP_HOST_SECRET");
const smtpFromSecret = defineSecret("SMTP_FROM_SECRET");


admin.initializeApp();

const firestoreDbId = (process.env.FIRESTORE_DB_ID || "ffpvault").trim();
const db =
  firestoreDbId.length > 0 ?
    getFirestore(admin.app(), firestoreDbId) :
    getFirestore(admin.app());
const OTP_COLLECTION = "passwordResetOtps";
const TWO_FACTOR_COLLECTION = "twoFactorOtps";
const REGISTER_OTP_COLLECTION = "registerOtps";
const OTP_EXPIRE_MINUTES = 10;

function normalizeEmail(email) {
  return String(email || "")
    .trim()
    .toLowerCase();
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
  const host = smtpHostSecret.value();
  const port = 587;
  const user = smtpUserSecret.value();
  const pass = smtpPassSecret.value();
  const from = smtpFromSecret.value() || user;


  if (!host || !user || !pass || !from) {
    throw new HttpsError(
      "failed-precondition",
      "SMTP configuration is missing. Ensure secrets are set in Firebase.",
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

async function sendOtpEmail(email, otp, purpose = "reset") {
  const { from, client } = transporter();

  const subjectMap = {
    reset: "Reset your password \u2013 FFP Vault",
    twoFactorEnable: "Enable two-factor authentication \u2013 FFP Vault",
    twoFactorLogin: "Verify your login \u2013 FFP Vault",
    register: "Verify your email \u2013 FFP Vault",
  };
  const titleMap = {
    reset: "Reset your password",
    twoFactorEnable: "Enable two-factor authentication",
    twoFactorLogin: "Verify your login",
    register: "Verify your email address",
  };
  const bodyMap = {
    reset: "We received a request to reset your password for your FFP Vault.",
    twoFactorEnable:
      "We received a request to enable two-factor authentication on your FFP Vault account.",
    twoFactorLogin:
      "We received a login attempt for your FFP Vault account. Use the code below to complete your sign-in.",
    register:
      "Thank you for creating your FFP Vault account. Use the code below to verify your email address.",
  };

  const title = titleMap[purpose] || titleMap.reset;
  const bodyText = bodyMap[purpose] || bodyMap.reset;
  const subject = subjectMap[purpose] || subjectMap.reset;

  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${subject}</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;">

  <!-- Outer wrapper -->
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f4f4f5;padding:40px 16px;">
    <tr>
      <td align="center">

        <!-- Card -->
        <table width="100%" cellpadding="0" cellspacing="0" border="0"
          style="max-width:560px;background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.07);">

          <!-- Header accent bar -->
          <tr>
            <td style="background-color:#C61C36;height:5px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Logo / Brand header -->
          <tr>
            <td align="center" style="padding:36px 40px 28px;">
              <!-- Real FFP logo (hosted on Firebase Storage for email client compatibility) -->
              <img
                src="https://storage.googleapis.com/ffp-vault-app.firebasestorage.app/public%2Flogo.png"
                alt="Financial Freedom Power"
                width="80"
                style="display:block;margin:0 auto 14px;width:80px;height:auto;"
              />
              <div style="margin:0;font-size:18px;font-weight:700;color:#111111;letter-spacing:-0.3px;">
                Financial Freedom Power
              </div>
              <div style="margin:4px 0 0;font-size:12px;color:#888888;letter-spacing:0.4px;text-transform:uppercase;">
                FFP Vault
              </div>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 40px;">
              <div style="height:1px;background-color:#f0f0f0;"></div>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:36px 40px 0;">

              <!-- Title -->
              <h1 style="margin:0 0 20px;font-size:22px;font-weight:700;color:#111111;line-height:1.3;">
                ${title}
              </h1>

              <!-- Greeting -->
              <p style="margin:0 0 16px;font-size:15px;color:#444444;line-height:1.6;">
                Hi,
              </p>

              <!-- Body text -->
              <p style="margin:0 0 28px;font-size:15px;color:#444444;line-height:1.7;">
                ${bodyText}<br/>Use the code below to continue:
              </p>

              <!-- OTP Box -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:28px;">
                <tr>
                  <td align="center">
                    <div style="display:inline-block;background-color:#fff8f8;border:2px solid #C61C36;border-radius:12px;padding:20px 36px;">
                      <span style="font-size:38px;font-weight:900;color:#C61C36;letter-spacing:12px;font-family:'Courier New',Courier,monospace;">
                        ${otp}
                      </span>
                    </div>
                  </td>
                </tr>
              </table>

              <!-- Expiry note -->
              <p style="margin:0 0 12px;font-size:14px;color:#666666;line-height:1.6;">
                This code will expire in <strong>${OTP_EXPIRE_MINUTES} minutes</strong>.
              </p>

              <!-- Ignore note -->
              <p style="margin:0 0 32px;font-size:14px;color:#888888;line-height:1.6;">
                If you didn&rsquo;t request this, you can safely ignore this email.
              </p>

              <!-- Reassurance -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:36px;">
                <tr>
                  <td style="background-color:#f9f9f9;border-left:3px solid #C61C36;border-radius:0 8px 8px 0;padding:14px 18px;">
                    <p style="margin:0;font-size:13px;color:#555555;line-height:1.5;">
                      &#128274;&nbsp; Your information remains secure.
                    </p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Footer divider -->
          <tr>
            <td style="padding:0 40px;">
              <div style="height:1px;background-color:#f0f0f0;"></div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 40px 36px;">
              <p style="margin:0 0 4px;font-size:13px;font-weight:600;color:#333333;">
                Financial Freedom Power
              </p>
              <p style="margin:0 0 12px;font-size:12px;color:#999999;letter-spacing:0.2px;">
                Secure Document &amp; Financial Organization
              </p>
              <a href="mailto:support@financialfreedompower.com"
                style="font-size:12px;color:#C61C36;text-decoration:none;">
                support@financialfreedompower.com
              </a>
            </td>
          </tr>

          <!-- Bottom accent bar -->
          <tr>
            <td style="background-color:#C61C36;height:3px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

        </table>
        <!-- /Card -->

      </td>
    </tr>
  </table>

</body>
</html>
  `;

  await client.sendMail({ from, to: email, subject, html });
}

async function getOtpState(email) {
  const ref = db.collection(OTP_COLLECTION).doc(docIdForEmail(email));
  const snap = await ref.get();
  if (!snap.exists) return { ref, data: null };
  return { ref, data: snap.data() };
}

async function getTwoFactorState(uid, purpose) {
  const ref = db.collection(TWO_FACTOR_COLLECTION).doc(`${uid}_${purpose}`);
  const snap = await ref.get();
  if (!snap.exists) return { ref, data: null };
  return { ref, data: snap.data() };
}

async function getRegisterOtpState(uid) {
  const ref = db.collection(REGISTER_OTP_COLLECTION).doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return { ref, data: null };
  return { ref, data: snap.data() };
}

async function issueTwoFactorOtp({ uid, email, purpose }) {
  const otp = generateOtp();
  const salt = crypto.randomBytes(16).toString("hex");
  const otpHash = hashOtp(email, otp, salt);
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + OTP_EXPIRE_MINUTES * 60 * 1000),
  );

  const ref = db.collection(TWO_FACTOR_COLLECTION).doc(`${uid}_${purpose}`);
  await ref.set(
    {
      uid,
      email,
      purpose,
      otpHash,
      salt,
      attempts: 0,
      expiresAt,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await sendOtpEmail(email, otp, purpose);
}

export const requestPasswordResetOtp = onCall(
  { secrets: [smtpUserSecret, smtpPassSecret, smtpHostSecret, smtpFromSecret] },
  async (request) => {
    try {
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
        { merge: true },
      );

      await sendOtpEmail(email, otp);
      return { success: true, message: "OTP sent successfully." };
    } catch (error) {
      console.error("requestPasswordResetOtp failed:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "internal",
        `Failed to process forgot password: ${error.message || "Unknown error"}`,
      );
    }
  });


export const requestTwoFactorEnable = onCall(
  { secrets: [smtpUserSecret, smtpPassSecret, smtpHostSecret, smtpFromSecret] },
  async (request) => {
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

    await issueTwoFactorOtp({ uid, email, purpose: "twoFactorEnable" });
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

  const { ref, data } = await getTwoFactorState(uid, "twoFactorEnable");
  if (!data) {
    throw new HttpsError("not-found", "OTP not found. Request a new code.");
  }
  if (data.expiresAt?.toMillis?.() < Date.now()) {
    await ref.delete();
    throw new HttpsError(
      "deadline-exceeded",
      "OTP expired. Request a new code.",
    );
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

  await db.collection("users").doc(uid).set(
    {
      twoFactorEnabled: true,
      twoFactorEmail: data.email,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await ref.delete();

  return {
    success: true,
    message: "Two-factor authentication enabled.",
    email: data.email,
  };
});

export const requestTwoFactorLogin = onCall(
  { secrets: [smtpUserSecret, smtpPassSecret, smtpHostSecret, smtpFromSecret] },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const uid = request.auth.uid;
    const userSnap = await db.collection("users").doc(uid).get();
    const userData = userSnap.data() || {};
    const enabled = userData.twoFactorEnabled === true;
    if (!enabled) {
      return { success: true, twoFactorRequired: false };
    }

    const email = normalizeEmail(
      userData.twoFactorEmail ||
      request.auth.token?.email ||
      request.data?.email ||
      "",
    );
    if (!validateEmail(email)) {
      throw new HttpsError("failed-precondition", "No 2FA email configured.");
    }

    await issueTwoFactorOtp({ uid, email, purpose: "twoFactorLogin" });
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

  const { ref, data } = await getTwoFactorState(uid, "twoFactorLogin");
  if (!data) {
    throw new HttpsError("not-found", "OTP not found. Please log in again.");
  }
  if (data.expiresAt?.toMillis?.() < Date.now()) {
    await ref.delete();
    throw new HttpsError(
      "deadline-exceeded",
      "OTP expired. Please log in again.",
    );
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
  return { success: true, message: "Login verification successful." };
});

export const verifyPasswordResetOtp = onCall(async (request) => {
  try {
    const email = normalizeEmail(request.data?.email);
    const otp = String(request.data?.otp || "").trim();

    if (!validateEmail(email) || otp.length != 6) {
      throw new HttpsError(
        "invalid-argument",
        "Email and 6-digit OTP required.",
      );
    }

    const { ref, data } = await getOtpState(email);
    if (!data) {
      throw new HttpsError("not-found", "OTP not found. Request a new OTP.");
    }
    if (data.expiresAt?.toMillis?.() < Date.now()) {
      await ref.delete();
      throw new HttpsError(
        "deadline-exceeded",
        "OTP expired. Request a new OTP.",
      );
    }

    const valid = hashOtp(email, otp, data.salt) === data.otpHash;
    if (!valid) {
      const attempts = Number(data.attempts || 0) + 1;
      if (attempts >= 5) {
        await ref.delete();
        throw new HttpsError(
          "permission-denied",
          "Too many attempts. Request OTP again.",
        );
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
  } catch (error) {
    console.error("verifyPasswordResetOtp failed:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "Failed to verify OTP");
  }
});


export const requestRegisterOtp = onCall(
  { secrets: [smtpUserSecret, smtpPassSecret, smtpHostSecret, smtpFromSecret] },
  async (request) => {
    try {
      if (!request.auth?.uid) {
        throw new HttpsError("unauthenticated", "Login required to request registration OTP.");
      }

      const uid = request.auth.uid;
      const email = normalizeEmail(
        request.data?.email || request.auth.token?.email || "",
      );
      if (!validateEmail(email)) {
        throw new HttpsError("invalid-argument", "Valid email is required.");
      }

      const otp = generateOtp();
      const salt = crypto.randomBytes(16).toString("hex");
      const otpHash = hashOtp(email, otp, salt);
      const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + OTP_EXPIRE_MINUTES * 60 * 1000),
      );

      const ref = db.collection(REGISTER_OTP_COLLECTION).doc(uid);
      await ref.set(
        {
          uid,
          email,
          otpHash,
          salt,
          attempts: 0,
          expiresAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      await sendOtpEmail(email, otp, "register");
      return { success: true, message: "Verification code sent.", email };
    } catch (error) {
      console.error("requestRegisterOtp failed:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Failed to send verification code");
    }
  },
);


export const verifyRegisterOtp = onCall(async (request) => {
  try {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required to verify registration OTP.");
    }

    const uid = request.auth.uid;
    const otp = String(request.data?.otp || "").trim();
    if (otp.length !== 6) {
      throw new HttpsError("invalid-argument", "6-digit OTP is required.");
    }

    const { ref, data } = await getRegisterOtpState(uid);
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
        throw new HttpsError("permission-denied", "Too many attempts. Request a new code.");
      }
      await ref.update({
        attempts,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new HttpsError("permission-denied", "Invalid OTP.");
    }

    // Mark email as verified in Firebase Auth
    await admin.auth().updateUser(uid, { emailVerified: true });

    // Mark verified in the user's Firestore document
    await db.collection("users").doc(uid).set(
      {
        emailVerified: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await ref.delete();
    return { success: true, message: "Email verified successfully.", email: data.email };
  } catch (error) {
    console.error("verifyRegisterOtp failed:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "Failed to verify OTP");
  }
});


export const resetPasswordWithOtp = onCall(async (request) => {
  try {
    const email = normalizeEmail(request.data?.email);
    const otp = String(request.data?.otp || "").trim();
    const newPassword = String(request.data?.newPassword || "");

    if (!validateEmail(email) || otp.length != 6 || newPassword.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "Email, 6-digit OTP, and new password (min 6) are required.",
      );
    }

    const { ref, data } = await getOtpState(email);
    if (!data) {
      throw new HttpsError("not-found", "OTP not found. Request a new OTP.");
    }
    if (data.expiresAt?.toMillis?.() < Date.now()) {
      await ref.delete();
      throw new HttpsError(
        "deadline-exceeded",
        "OTP expired. Request a new OTP.",
      );
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
  } catch (error) {
    console.error("resetPasswordWithOtp failed:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "Failed to reset password");
  }
});


// ── RevenueCat Webhook ──────────────────────────────────────────────────────
// Receives purchase lifecycle events from RevenueCat and syncs them to Firestore.
// Set this URL in the RevenueCat dashboard:
//   https://us-central1-YOUR_PROJECT.cloudfunctions.net/revenuecatWebhook
// Authorization: Bearer token (set RC_WEBHOOK_SECRET in Firebase secrets).
export const revenuecatWebhook = onRequest(
  { secrets: [rcWebhookSecret] },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("Method Not Allowed");
      return;
    }

    const secret = rcWebhookSecret.value();
    const authHeader = request.headers["authorization"] || "";
    if (secret && authHeader !== `Bearer ${secret}`) {
      console.warn("RevenueCat webhook: unauthorized request");
      response.status(401).send("Unauthorized");
      return;
    }

    try {
      const event = request.body;
      const eventType = event?.event?.type;
      const appUserId = event?.event?.app_user_id; // This is the Firebase UID

      if (!appUserId) {
        response.status(400).send("Missing app_user_id");
        return;
      }

      const userRef = db.collection("users").doc(appUserId);

      const productId = event?.event?.product_id || "ffpvaultapp_pro_monthly";
      const entitlementId =
        event?.event?.entitlement_ids?.[0] || "ffpvaultapp_pro";
      const expirationMs = event?.event?.expiration_at_ms || 0;

      let subscriptionState;

      switch (eventType) {
        case "INITIAL_PURCHASE":
        case "RENEWAL":
        case "UNCANCELLATION":
        case "TRANSFER":
        case "PRODUCT_CHANGE":
          subscriptionState = {
            planCode: productId,
            planName: "FFP Vault Pro",
            amount: 699,
            currency: "usd",
            status: "active",
            provider: "revenuecat",
            rcCustomerId: appUserId,
            rcEntitlementId: entitlementId,
            cancelAtPeriodEnd: false,
            currentPeriodEnd: expirationMs ?
              admin.firestore.Timestamp.fromMillis(expirationMs) :
              null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          break;

        case "CANCELLATION":
          subscriptionState = {
            planCode: productId,
            planName: "FFP Vault Pro",
            amount: 699,
            currency: "usd",
            status: "active", // stays active until period end
            provider: "revenuecat",
            rcCustomerId: appUserId,
            rcEntitlementId: entitlementId,
            cancelAtPeriodEnd: true,
            currentPeriodEnd: expirationMs ?
              admin.firestore.Timestamp.fromMillis(expirationMs) :
              null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          break;

        case "EXPIRATION":
        case "SUBSCRIPTION_PAUSED":
        case "BILLING_ISSUE":
        case "SUBSCRIPTION_EXTENDED":
          subscriptionState = {
            planCode: "",
            planName: "",
            amount: 0,
            currency: "usd",
            status: "expired",
            provider: "revenuecat",
            rcCustomerId: appUserId,
            rcEntitlementId: "",
            cancelAtPeriodEnd: false,
            currentPeriodEnd: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          break;

        case "TEST":
          // RevenueCat test events — acknowledge but don't change state.
          console.log(`RevenueCat test event received for ${appUserId}`);
          response.json({ received: true, action: "test_ignored" });
          return;

        default:
          console.log(
            `RevenueCat unhandled event type: ${eventType} for ${appUserId}`,
          );
          response.json({ received: true, action: "ignored" });
          return;
      }

      await userRef.set(
        { subscription: subscriptionState },
        { mergeFields: ["subscription"] },
      );

      console.log(
        `RevenueCat ${eventType} synced for user ${appUserId}`,
      );
      response.json({ received: true });
    } catch (error) {
      console.error("RevenueCat webhook error:", error);
      response.status(500).send(`Webhook Error: ${error.message}`);
    }
  },
);

// ── Delete User Account (complete data wipe) ─────────────────────────────────
// Deletes ALL user data across Firestore sub-collections, Cloud Storage files,
// OTP records, payment history, and reminders.
// Requires Firebase Auth (admin SDK) — must be called by an authenticated user.
export const deleteUserAccount = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required to delete account.");
  }

  const uid = request.auth.uid;
  const email = request.auth.token?.email || "";
  const normalizedEmail = email.trim().toLowerCase();

  const errors = [];

  // 1. Delete ALL Firestore collections for this user
  const firestoreCollections = [
    { name: "users", docId: uid },
    { name: "housingCosts", field: "userId", value: uid },
    { name: "loans", field: "userId", value: uid },
    { name: "insurancePolicies", field: "userId", value: uid },
    { name: "documents", field: "userId", value: uid },
    { name: "reminders", field: "userId", value: uid },
  ];

  for (const col of firestoreCollections) {
    try {
      if (col.docId) {
        await db.collection(col.name).doc(col.docId).delete();
      } else {
        const snapshot = await db
          .collection(col.name)
          .where(col.field, "==", col.value)
          .get();

        const batchSize = 500;
        for (let i = 0; i < snapshot.docs.length; i += batchSize) {
          const batch = db.batch();
          const slice = snapshot.docs.slice(i, i + batchSize);
          slice.forEach((doc) => batch.delete(doc.ref));
          await batch.commit();
        }
      }
    } catch (e) {
      errors.push(`Firestore ${col.name}: ${e.message}`);
    }
  }

  // 3. Delete subscriptionPayments
  try {
    const paymentSnap = await db
      .collection("subscriptionPayments")
      .where("uid", "==", uid)
      .get();

    const batchSize = 500;
    for (let i = 0; i < paymentSnap.docs.length; i += batchSize) {
      const batch = db.batch();
      const slice = paymentSnap.docs.slice(i, i + batchSize);
      slice.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  } catch (e) {
    errors.push(`subscriptionPayments: ${e.message}`);
  }

  // 4. Delete OTP records (passwordResetOtps by email, twoFactorOtps by uid prefix)
  try {
    if (normalizedEmail) {
      const otpDocId = docIdForEmail(normalizedEmail);
      await db.collection(OTP_COLLECTION).doc(otpDocId).delete();
    }
  } catch (e) {
    errors.push(`passwordResetOtps: ${e.message}`);
  }

  try {
    const tfSnap = await db
      .collection(TWO_FACTOR_COLLECTION)
      .where("uid", "==", uid)
      .get();

    for (const doc of tfSnap.docs) {
      await doc.ref.delete();
    }
  } catch (e) {
    errors.push(`twoFactorOtps: ${e.message}`);
  }

  // 5. Delete ALL Cloud Storage files under the user's prefix
  const storageModules = ["avatars", "housing", "loans", "insurance", "documents"];
  const bucket = getStorage().bucket();

  for (const module of storageModules) {
    try {
      const prefix = `${module}/${uid}/`;
      const [files] = await bucket.getFiles({ prefix });

      const deletePromises = files.map((file) =>
        file.delete().catch((e) =>
          console.warn(`Storage delete ${file.name}: ${e.message}`)
        )
      );
      await Promise.all(deletePromises);
    } catch (e) {
      errors.push(`Storage ${module}/${uid}: ${e.message}`);
    }
  }

  // 6. Delete the Firebase Auth user (this is the final irrevocable step)
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    errors.push(`Auth user deletion: ${e.message}`);
  }

  if (errors.length > 0) {
    console.error(`Account deletion for ${uid} completed with ${errors.length} errors:`, errors);
    return {
      success: true,
      message: "Account deleted with some cleanup errors. Support has been notified.",
      errors,
    };
  }

  console.log(`Account ${uid} fully deleted successfully.`);
  return { success: true, message: "Account deleted successfully." };
});

// ── Check Reminders Cron Job ────────────────────────────────────────────────
export const checkRemindersAndNotify = onSchedule(
  "every 15 minutes",
  async (event) => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Look for reminders that are due or past due and haven't been sent yet
      const snapshot = await db
        .collection("reminders")
        .where("isSent", "==", false)
        .where("remindAt", "<=", now)
        .get();

      if (snapshot.empty) {
        console.log("No pending reminders to send.");
        return;
      }

      const batch = db.batch();
      const notifications = [];

      for (const doc of snapshot.docs) {
        const reminder = doc.data();
        const userId = reminder.userId || reminder.uid; // Account for either convention

        if (!userId) {
          console.warn(`Reminder ${doc.id} missing userId. Skipping.`);
          continue;
        }

        // Fetch user to get FCM token
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
          console.warn(`User ${userId} not found for reminder ${doc.id}.`);
          continue;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.warn(
            `User ${userId} has no FCM token. Skipping notification.`,
          );
          // Note: You may want to mark as sent anyway to avoid infinite retries
          batch.update(doc.ref, {
            isSent: true,
            failedReason: "No FCM token",
          });
          continue;
        }

        const title = reminder.title || "FFP Vault Reminder";
        const body =
          reminder.note || `Reminder for your ${reminder.itemType || "item"}.`;

        notifications.push({
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data: {
            reminderId: doc.id,
            itemId: reminder.itemId || "",
            itemType: reminder.itemType || "",
          },
        });

        // Mark the reminder as sent
        batch.update(doc.ref, {
          isSent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      if (notifications.length > 0) {
        // Send notifications via FCM
        const response = await admin.messaging().sendEach(
          notifications.map((n) => ({
            token: n.token,
            notification: n.notification,
            data: n.data,
          })),
        );

        console.log(
          `Successfully sent ${response.successCount} messages; failed ${response.failureCount} messages.`,
        );

        response.responses.forEach((res, idx) => {
          if (!res.success) {
            console.error(
              `Failed to send to ${notifications[idx].token}:`,
              res.error,
            );
          }
        });
      }

      // Commit the batch to mark reminders as sent
      await batch.commit();
      console.log("Reminders checked and updated successfully.");
    } catch (error) {
      console.error("Error processing reminders:", error);
    }
  },
);

export const checkTrialExpirations = onSchedule(
  "0 0 * * *", // Run once a day at midnight
  async (event) => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Find users with trialing status whose trial has ended
      const snapshot = await db
        .collection("users")
        .where("subscription.status", "==", "trialing")
        .where("subscription.trialEndDate", "<=", now)
        .get();

      if (snapshot.empty) {
        console.log("No expired trials found.");
        return;
      }

      console.log(`Found ${snapshot.docs.length} expired trials.`);
      const batch = db.batch();
      const notifications = [];

      for (const doc of snapshot.docs) {
        const userData = doc.data();
        const fcmToken = userData.fcmToken;

        // Revoke access by updating status
        batch.update(doc.ref, {
          "subscription.status": "expired",
          "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        });

        if (fcmToken) {
          notifications.push({
            token: fcmToken,
            notification: {
              title: "Free Trial Expired",
              body: "Your 14-day free trial has expired. Subscribe now to keep accessing your secure Vault!",
            },
            data: {
              type: "trial_expired",
            },
          });
        }
      }

      // Commit status updates
      await batch.commit();

      // Send notifications
      if (notifications.length > 0) {
        const response = await admin.messaging().sendEach(notifications);
        console.log(`Sent ${response.successCount} expiry notifications.`);
      }

      console.log("Trial expiration check completed.");
    } catch (error) {
      console.error("Error checking trial expirations:", error);
    }
  },
);
