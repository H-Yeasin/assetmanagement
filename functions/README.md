# Email OTP Password Reset (Firebase Functions)

This project now uses 3 callable functions for forgot-password OTP:

- `requestPasswordResetOtp`
- `verifyPasswordResetOtp`
- `resetPasswordWithOtp`

## 1) Install dependencies

```bash
cd functions
npm install
```

## 2) Configure secrets

Set these as Firebase Functions secrets before deploy:

- `SMTP_HOST_SECRET`
- `SMTP_USER_SECRET`
- `SMTP_PASS_SECRET`
- `SMTP_FROM_SECRET`
- `RC_WEBHOOK_SECRET`
- `FIRESTORE_DB_ID` (set to `ffpvault` if you use the named Firestore database)

`RC_WEBHOOK_SECRET` must match the bearer token configured in RevenueCat.

If OTP sending fails with `535 5.7.8` or `authentication failed`, the SMTP
server rejected the configured credentials. For Gmail/Google Workspace, use an
App Password, not the normal mailbox password.

Example:

```bash
firebase functions:secrets:set SMTP_HOST_SECRET
firebase functions:secrets:set SMTP_USER_SECRET
firebase functions:secrets:set SMTP_PASS_SECRET
firebase functions:secrets:set SMTP_FROM_SECRET
firebase deploy --only functions
```

## 3) Deploy functions

```bash
firebase deploy --only functions
```

## 4) Flutter side

Flutter app already calls these callable functions via `cloud_functions`.
After deployment, forgot-password flow will send OTP to email (not reset link).
