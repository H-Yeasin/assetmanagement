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

## 2) Configure SMTP env for sending email OTP

Set these as function environment variables/secrets before deploy:

- `SMTP_HOST`
- `SMTP_PORT` (`587` or `465`)
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

## 3) Deploy functions

```bash
firebase deploy --only functions
```

## 4) Flutter side

Flutter app already calls these callable functions via `cloud_functions`.
After deployment, forgot-password flow will send OTP to email (not reset link).
