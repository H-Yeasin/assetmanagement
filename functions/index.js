import crypto from "node:crypto";
import nodemailer from "nodemailer";
import admin from "firebase-admin";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
const stripePublishableKey = defineSecret("STRIPE_PUBLISHABLE_KEY_SECRET");

admin.initializeApp();

const firestoreDbId = (process.env.FIRESTORE_DB_ID || "ffpvault").trim();
const db =
  firestoreDbId.length > 0 ?
    getFirestore(admin.app(), firestoreDbId) :
    getFirestore(admin.app());
const OTP_COLLECTION = "passwordResetOtps";
const TWO_FACTOR_COLLECTION = "twoFactorOtps";
const OTP_EXPIRE_MINUTES = 10;
const SUBSCRIPTION_PLAN = Object.freeze({
  code: "monthly_core",
  name: "FFP Vault Monthly",
  amount: 699,
  currency: "usd",
});
const SUBSCRIPTION_TRIAL_DAYS = 14;

function getStripeClient() {
  const apiKey = stripeSecretKey.value() || process.env.STRIPE_SECRET_KEY;
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "Stripe secret key is not configured.",
    );
  }
  return new Stripe(apiKey);
}

function getStripePublishableKey() {
  const key =
    stripePublishableKey.value() ||
    process.env.STRIPE_PUBLISHABLE_KEY_SECRET ||
    process.env.STRIPE_PUBLISHABLE_KEY;
  if (!key) {
    throw new HttpsError(
      "failed-precondition",
      "Stripe publishable key is not configured.",
    );
  }
  return key;
}

function subscriptionTimestamp(unixSeconds) {
  return unixSeconds ?
    admin.firestore.Timestamp.fromMillis(unixSeconds * 1000) :
    null;
}

function buildSubscriptionState({
  customerId,
  subscription,
  paymentIntentId = "",
  activated = false,
}) {
  const resolvedCustomerId = typeof customerId === "string" ?
    customerId :
    typeof subscription.customer === "string" ?
      subscription.customer :
      subscription.customer?.id || "";

  return {
    planCode: SUBSCRIPTION_PLAN.code,
    planName: SUBSCRIPTION_PLAN.name,
    amount: SUBSCRIPTION_PLAN.amount,
    currency: SUBSCRIPTION_PLAN.currency,
    status: subscription?.status || "inactive",
    provider: "stripe",
    stripeCustomerId: resolvedCustomerId,
    stripeSubscriptionId: subscription?.id || "",
    cancelAtPeriodEnd: subscription?.cancel_at_period_end === true,
    currentPeriodEnd: subscriptionTimestamp(subscription?.current_period_end),
    stripePaymentIntentId: paymentIntentId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(activated ?
      {activatedAt: admin.firestore.FieldValue.serverTimestamp()} :
      {}),
  };
}

function buildInactiveSubscriptionState(customerId = "") {
  return {
    planCode: "",
    planName: "",
    amount: 0,
    currency: SUBSCRIPTION_PLAN.currency,
    status: "inactive",
    provider: "stripe",
    stripeCustomerId: customerId,
    stripeSubscriptionId: "",
    cancelAtPeriodEnd: false,
    currentPeriodEnd: null,
    stripePaymentIntentId: "",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function replaceUserSubscription(userRef, subscriptionState) {
  await userRef.set(
    {subscription: subscriptionState},
    {mergeFields: ["subscription"]},
  );
}

async function findUserByStripeCustomerId(customerId) {
  if (!customerId) return null;
  const snapshot = await db
    .collection("users")
    .where("subscription.stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  return snapshot.docs[0];
}

async function resolveUserRefForSubscription(subscription) {
  const uid = subscription?.metadata?.uid;
  if (uid) {
    return db.collection("users").doc(uid);
  }

  const customerId = typeof subscription?.customer === "string" ?
    subscription.customer :
    subscription?.customer?.id || "";
  const userDoc = await findUserByStripeCustomerId(customerId);
  return userDoc?.ref ?? null;
}

async function cancelStripeSubscriptionIfRetryable(stripeClient, subscriptionId) {
  if (!subscriptionId) return null;

  try {
    const subscription = await stripeClient.subscriptions.retrieve(subscriptionId);
    if (["incomplete", "incomplete_expired"].includes(subscription.status) ||
        (subscription.status === "trialing" && !subscription.default_payment_method)) {
      return await stripeClient.subscriptions.cancel(subscriptionId);
    }
    return subscription;
  } catch (error) {
    if (error?.code === "resource_missing") {
      return null;
    }
    throw error;
  }
}

async function syncStripeSubscriptionToFirestore(
  subscription,
  {paymentIntentId = "", activated = false} = {},
) {
  const userRef = await resolveUserRefForSubscription(subscription);
  if (!userRef) {
    console.warn(`No user found for Stripe subscription ${subscription.id}`);
    return;
  }

  await replaceUserSubscription(
    userRef,
    buildSubscriptionState({
      customerId: subscription.customer,
      subscription,
      paymentIntentId,
      activated,
    }),
  );
}

async function markStripeCustomerInactive(customerId, subscriptionStatus = "inactive") {
  const userDoc = await findUserByStripeCustomerId(customerId);
  if (!userDoc) {
    console.warn(`No user found for Stripe customer ${customerId}`);
    return;
  }

  await replaceUserSubscription(
    userDoc.ref,
    {
      ...buildInactiveSubscriptionState(customerId),
      status: subscriptionStatus,
    },
  );
}

async function recordStripePayment({
  uid,
  subscriptionId,
  paymentIntentId,
  amount,
  currency,
  status,
  invoiceId = "",
}) {
  if (!paymentIntentId) return;

  const paymentRef = db.collection("subscriptionPayments").doc(paymentIntentId);
  const paymentSnap = await paymentRef.get();
  if (paymentSnap.exists) return;

  await paymentRef.set({
    uid,
    planCode: SUBSCRIPTION_PLAN.code,
    planName: SUBSCRIPTION_PLAN.name,
    amount,
    currency,
    status,
    invoiceId,
    stripeSubscriptionId: subscriptionId,
    stripePaymentIntentId: paymentIntentId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function getOrCreateStripeCustomer(uid, email, stripeClient) {
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.exists ? userSnap.data() : {};
  const existingCustomerId = userData?.subscription?.stripeCustomerId;

  if (existingCustomerId) {
    return {customerId: existingCustomerId, userRef, userData};
  }

  const customer = await stripeClient.customers.create({
    email: email || undefined,
    metadata: {uid},
  });

  await userRef.set({
    subscription: {
      stripeCustomerId: customer.id,
    },
  }, {merge: true});

  return {customerId: customer.id, userRef, userData};
}

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
      auth: { user, pass },
    }),
  };
}

async function sendOtpEmail(email, otp, purpose = "reset") {
  const { from, client } = transporter();
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
    twoFactorEnable:
      "Use this 6-digit OTP to enable two-factor authentication:",
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
  if (!snap.exists) return { ref, data: null };
  return { ref, data: snap.data() };
}

async function getTwoFactorState(uid, purpose) {
  const ref = db.collection(TWO_FACTOR_COLLECTION).doc(`${uid}_${purpose}`);
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

export const requestTwoFactorLogin = onCall(async (request) => {
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
});

export const getStripePublicConfig = onCall({secrets: [stripePublishableKey]}, async () => {
  return {
    publishableKey: getStripePublishableKey(),
    currency: SUBSCRIPTION_PLAN.currency,
    amount: SUBSCRIPTION_PLAN.amount,
    planCode: SUBSCRIPTION_PLAN.code,
    planName: SUBSCRIPTION_PLAN.name,
    firestoreDbId,
  };
});

export const createStripePaymentIntent = onCall({secrets: [stripeSecretKey]}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required to make payments.");
  }

  try {
    const stripe = getStripeClient();
    const {customerId, userRef, userData} = await getOrCreateStripeCustomer(
      request.auth.uid,
      request.auth.token.email,
      stripe,
    );

    const activeStatus = userData?.subscription?.status;
    const existingSubscriptionId = userData?.subscription?.stripeSubscriptionId;
    if (existingSubscriptionId) {
      const existingSubscription = await cancelStripeSubscriptionIfRetryable(
        stripe,
        existingSubscriptionId,
      );
      const existingStatus = existingSubscription?.status || activeStatus;

      if (["active", "trialing", "past_due", "unpaid"].includes(existingStatus)) {
        throw new HttpsError(
          "already-exists",
          "An active subscription already exists for this account.",
        );
      }

      if (["canceled", "incomplete", "incomplete_expired"].includes(existingStatus)) {
        await replaceUserSubscription(
          userRef,
          buildInactiveSubscriptionState(customerId),
        );
      }
    }

    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{
        price_data: {
          currency: SUBSCRIPTION_PLAN.currency,
          unit_amount: SUBSCRIPTION_PLAN.amount,
          recurring: {
            interval: "month",
          },
          product_data: {
            name: SUBSCRIPTION_PLAN.name,
          },
        },
      }],
      trial_period_days: SUBSCRIPTION_TRIAL_DAYS,
      payment_behavior: "default_incomplete",
      payment_settings: {
        save_default_payment_method: "on_subscription",
      },
      trial_settings: {
        end_behavior: {
          missing_payment_method: "cancel",
        },
      },
      metadata: {
        uid: request.auth.uid,
        planCode: SUBSCRIPTION_PLAN.code,
        planName: SUBSCRIPTION_PLAN.name,
      },
      expand: ["pending_setup_intent"],
    });

    const setupIntent = subscription.pending_setup_intent;
    if (!setupIntent?.client_secret) {
      throw new HttpsError(
        "internal",
        "Unable to initialize subscription trial.",
      );
    }

    const ephemeralKey = await stripe.ephemeralKeys.create(
      {customer: customerId},
      {apiVersion: "2024-06-20"},
    );

    await replaceUserSubscription(
      userRef,
      buildSubscriptionState({
        customerId,
        subscription,
      }),
    );

    return {
      clientSecret: setupIntent.client_secret,
      setupIntentId: setupIntent.id,
      customerId,
      customerEphemeralKeySecret: ephemeralKey.secret,
      subscriptionId: subscription.id,
      amount: SUBSCRIPTION_PLAN.amount,
      currency: SUBSCRIPTION_PLAN.currency,
      planCode: SUBSCRIPTION_PLAN.code,
      planName: SUBSCRIPTION_PLAN.name,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

export const finalizeStripePayment = onCall({secrets: [stripeSecretKey]}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required to make payments.");
  }

  const subscriptionId = String(request.data?.subscriptionId || "").trim();
  if (!subscriptionId.startsWith("sub_")) {
    throw new HttpsError("invalid-argument", "Valid subscriptionId is required.");
  }
  const paymentMethodId = String(request.data?.paymentMethodId || "").trim();
  const setupIntentId = String(request.data?.setupIntentId || "").trim();

  try {
    const stripe = getStripeClient();
    const subscription = await stripe.subscriptions.retrieve(subscriptionId, {
      expand: ["pending_setup_intent"],
    });
    const setupIntent = subscription.pending_setup_intent;

    if (setupIntent && setupIntent.status !== "succeeded") {
      throw new HttpsError(
        "failed-precondition",
        "Payment setup has not completed successfully.",
      );
    }

    if (subscription.metadata?.uid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "Subscription does not belong to this user.");
    }

    let resolvedPaymentMethodId = paymentMethodId;
    if (!resolvedPaymentMethodId && setupIntentId.startsWith("seti_")) {
      const retrievedSetupIntent = await stripe.setupIntents.retrieve(setupIntentId);
      if (retrievedSetupIntent.status !== "succeeded") {
        throw new HttpsError(
          "failed-precondition",
          "Payment setup has not completed successfully.",
        );
      }
      resolvedPaymentMethodId = typeof retrievedSetupIntent.payment_method === "string" ?
        retrievedSetupIntent.payment_method :
        retrievedSetupIntent.payment_method?.id || "";
    }

    if (!resolvedPaymentMethodId.startsWith("pm_")) {
      throw new HttpsError(
        "failed-precondition",
        "No payment method was attached to the subscription setup.",
      );
    }

    await stripe.customers.update(subscription.customer, {
      invoice_settings: {
        default_payment_method: resolvedPaymentMethodId,
      },
    });

    const updatedSubscription = await stripe.subscriptions.update(subscription.id, {
      default_payment_method: resolvedPaymentMethodId,
    });

    await replaceUserSubscription(
      db.collection("users").doc(request.auth.uid),
      buildSubscriptionState({
        customerId: updatedSubscription.customer,
        subscription: updatedSubscription,
        paymentIntentId: "",
        activated: true,
      }),
    );

    return {
      status: "trial_started",
      subscriptionStatus: updatedSubscription.status,
      paymentIntentId: "",
      subscriptionId: updatedSubscription.id,
      cancelAtPeriodEnd: updatedSubscription.cancel_at_period_end,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

export const abandonStripeCheckout = onCall({secrets: [stripeSecretKey]}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required to manage billing.");
  }

  const subscriptionId = String(request.data?.subscriptionId || "").trim();
  if (!subscriptionId.startsWith("sub_")) {
    throw new HttpsError("invalid-argument", "Valid subscriptionId is required.");
  }

  try {
    const stripe = getStripeClient();
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    if (subscription.metadata?.uid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "Subscription does not belong to this user.");
    }

    const customerId = typeof subscription.customer === "string" ?
      subscription.customer :
      subscription.customer?.id || "";

    if (["active", "trialing"].includes(subscription.status) &&
        subscription.default_payment_method) {
      return {
        status: "kept",
        subscriptionStatus: subscription.status,
        paymentIntentId: "",
        subscriptionId: subscription.id,
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
      };
    }

    if (!["canceled", "incomplete_expired"].includes(subscription.status)) {
      await stripe.subscriptions.cancel(subscription.id);
    }

    await replaceUserSubscription(
      db.collection("users").doc(request.auth.uid),
      buildInactiveSubscriptionState(customerId),
    );

    return {
      status: "abandoned",
      subscriptionStatus: "inactive",
      paymentIntentId: "",
      subscriptionId: subscription.id,
      cancelAtPeriodEnd: false,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

export const cancelStripeSubscription = onCall({secrets: [stripeSecretKey]}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required to manage billing.");
  }

  const userRef = db.collection("users").doc(request.auth.uid);
  const userSnap = await userRef.get();
  const subscriptionId = userSnap.data()?.subscription?.stripeSubscriptionId;

  if (!subscriptionId) {
    throw new HttpsError("not-found", "No active subscription was found.");
  }

  try {
    const stripe = getStripeClient();
    const subscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });

    await replaceUserSubscription(
      userRef,
      buildSubscriptionState({
        customerId: subscription.customer,
        subscription,
      }),
    );

    return {
      status: "cancel_scheduled",
      subscriptionStatus: subscription.status,
      paymentIntentId: "",
      subscriptionId: subscription.id,
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

export const stripeWebhook = onRequest(
  {secrets: [stripeSecretKey, stripeWebhookSecret]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("Method Not Allowed");
      return;
    }

    const signature = request.headers["stripe-signature"];
    if (!signature) {
      response.status(400).send("Missing Stripe signature");
      return;
    }

    try {
      const stripe = getStripeClient();
      const webhookSecret = stripeWebhookSecret.value() || process.env.STRIPE_WEBHOOK_SECRET;
      if (!webhookSecret) {
        throw new Error("Stripe webhook secret is not configured.");
      }

      const event = stripe.webhooks.constructEvent(
        request.rawBody,
        signature,
        webhookSecret,
      );

      switch (event.type) {
      case "customer.subscription.created":
      case "customer.subscription.updated": {
        const subscription = event.data.object;
        await syncStripeSubscriptionToFirestore(subscription);
        break;
      }
      case "customer.subscription.deleted": {
        const subscription = event.data.object;
        const customerId = typeof subscription.customer === "string" ?
          subscription.customer :
          subscription.customer?.id || "";
        await markStripeCustomerInactive(customerId, subscription.status || "canceled");
        break;
      }
      case "invoice.payment_succeeded": {
        const invoice = event.data.object;
        if (!invoice.subscription) break;
        const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
        const userRef = await resolveUserRefForSubscription(subscription);
        if (userRef) {
          await recordStripePayment({
            uid: userRef.id,
            subscriptionId: subscription.id,
            paymentIntentId: typeof invoice.payment_intent === "string" ?
              invoice.payment_intent :
              invoice.payment_intent?.id || "",
            amount: invoice.amount_paid,
            currency: invoice.currency,
            status: "succeeded",
            invoiceId: invoice.id,
          });
        }
        await syncStripeSubscriptionToFirestore(
          subscription,
          {
            paymentIntentId: typeof invoice.payment_intent === "string" ?
              invoice.payment_intent :
              invoice.payment_intent?.id || "",
            activated: true,
          },
        );
        break;
      }
      case "invoice.payment_failed": {
        const invoice = event.data.object;
        if (!invoice.subscription) break;
        const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
        await syncStripeSubscriptionToFirestore(subscription, {
          paymentIntentId: typeof invoice.payment_intent === "string" ?
            invoice.payment_intent :
            invoice.payment_intent?.id || "",
        });
        break;
      }
      default:
        break;
      }

      response.json({received: true});
    } catch (error) {
      console.error("Stripe webhook error", error);
      response.status(400).send(`Webhook Error: ${error.message}`);
    }
  },
);

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
