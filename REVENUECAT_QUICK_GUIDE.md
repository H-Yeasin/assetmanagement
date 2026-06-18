# RevenueCat Integration Quick Guide

This guide explains the current FFP Vault RevenueCat setup for developers who
need to maintain, test, or extend subscriptions.

## What RevenueCat Does Here

RevenueCat handles the App Store / Google Play subscription purchase and tells
the app whether the user has the vault entitlement. The app stores a normalized
copy of that subscription state in Firestore at:

```text
users/{firebaseUid}.subscription
```

The vault access gate reads this Firestore state first, then checks RevenueCat
directly as a fallback so a fresh purchase can open the vault before the webhook
finishes syncing.

## Important IDs

Keep these IDs aligned between RevenueCat, the app config, and store products.

| Item | Current value | Where it is used |
|---|---|---|
| Entitlement ID | `ffpvaultapp_pro` | Vault access checks |
| Package ID | `monthly` | Monthly package lookup |
| Plan name | `FFP Vault Pro` | UI and Firestore subscription data |
| Firestore DB | `ffpvault` | User subscription records |
| Price fallback | `699` / `usd` | UI and Firestore fallback metadata |

The entitlement ID is configured in [app_config.dart](lib/config/app_config.dart)
as `AppConfig.vaultEntitlementId`. If the RevenueCat dashboard uses a different
entitlement key, run the app with:

```sh
flutter run --dart-define=RC_VAULT_ENTITLEMENT_ID=your_entitlement_key
```

## Client Flow

1. [main.dart](lib/main.dart) initializes RevenueCat with `RC_API_KEY`.
2. After Firebase auth is available, `RevenueCatService.login()` logs the
   Firebase UID into RevenueCat. This is important because the webhook expects
   RevenueCat `app_user_id` to equal the Firebase UID.
3. The subscription screen loads the RevenueCat offering/package.
4. A purchase uses the native App Store / Google Play payment sheet.
5. `RevenueCatService.syncToFirestore()` writes the latest customer info to
   `users/{uid}.subscription`.
6. The RevenueCat webhook also syncs future lifecycle events such as renewals,
   cancellations, and expirations.
7. [vault_access_gate.dart](lib/Home_Vault/vault_access_gate.dart) grants vault
   access when `SubscriptionState.isActive` is true.

## Key Files

| File | Purpose |
|---|---|
| [lib/main.dart](lib/main.dart) | Initializes RevenueCat and keeps auth identity in sync |
| [lib/config/app_config.dart](lib/config/app_config.dart) | RevenueCat keys, entitlement ID, offering/package config |
| [lib/services/revenuecat_service.dart](lib/services/revenuecat_service.dart) | SDK wrapper for offerings, purchases, restores, entitlement checks, Firestore sync |
| [lib/services/subscription_service.dart](lib/services/subscription_service.dart) | App-facing subscription facade used by UI/gates |
| [lib/Home_Profile/subscription/choose_payment_screen.dart](lib/Home_Profile/subscription/choose_payment_screen.dart) | Custom subscription purchase screen |
| [lib/Home_Profile/subscription/rc_paywall_screen.dart](lib/Home_Profile/subscription/rc_paywall_screen.dart) | Optional RevenueCat hosted paywall screen |
| [lib/Home_Profile/subscription/payment_status_screen.dart](lib/Home_Profile/subscription/payment_status_screen.dart) | Waits for activation before opening the vault |
| [functions/index.js](functions/index.js) | `revenuecatWebhook` Cloud Function |

## Firestore Subscription Shape

The app expects a map similar to this:

```json
{
  "provider": "revenuecat",
  "rcCustomerId": "firebase_uid_here",
  "rcEntitlementId": "ffpvaultapp_pro",
  "planCode": "store_product_id_here",
  "planName": "FFP Vault Pro",
  "amount": 699,
  "currency": "usd",
  "status": "active",
  "cancelAtPeriodEnd": false,
  "currentPeriodEnd": "Firestore Timestamp",
  "updatedAt": "Firestore server timestamp"
}
```

Access is granted when `status` is `active`, `past_due`, or a valid trialing
state according to `SubscriptionState.isActive`.

## Webhook Setup

The Firebase function is:

```text
revenuecatWebhook
```

RevenueCat dashboard webhook URL format:

```text
https://us-central1-YOUR_PROJECT.cloudfunctions.net/revenuecatWebhook
```

The function expects:

```text
Authorization: Bearer YOUR_RC_WEBHOOK_SECRET
```

Set the Firebase secret before deploying functions:

```sh
firebase functions:secrets:set RC_WEBHOOK_SECRET
firebase deploy --only functions:revenuecatWebhook
```

## Running Locally

Use the configured test key or pass a key explicitly:

```sh
flutter run --dart-define=RC_API_KEY=your_revenuecat_public_key
```

Optional flags:

```sh
flutter run \
  --dart-define=RC_API_KEY=your_revenuecat_public_key \
  --dart-define=RC_VAULT_ENTITLEMENT_ID=ffpvaultapp_pro \
  --dart-define=USE_REVENUECAT_PAYWALL=false
```

For development only, vault subscription checks can be bypassed:

```sh
flutter run --dart-define=BYPASS_VAULT_SUBSCRIPTION=true
```

Do not use the bypass flag for production builds.

## Testing Checklist

1. Sign in with a Firebase user.
2. Confirm logs show RevenueCat initialized and logged in.
3. Open the subscription plan screen.
4. Start a sandbox/test purchase.
5. After success, tap "Open the Vault".
6. Confirm Firestore has `users/{uid}.subscription.status = active`.
7. Confirm the vault opens without showing the subscribe screen.
8. Trigger a RevenueCat test webhook and confirm the function returns success.

## Prompt For Agent-Based Developers

Use this prompt when asking an AI coding agent to work on RevenueCat subscription
issues in this repo:

```text
You are working in the FFP Vault Flutter app. RevenueCat is the active
subscription provider; do not reintroduce Stripe flows.

Before changing code, read:
- REVENUECAT_QUICK_GUIDE.md
- lib/main.dart
- lib/config/app_config.dart
- lib/services/revenuecat_service.dart
- lib/services/subscription_service.dart
- lib/Home_Vault/vault_access_gate.dart
- lib/Home_Profile/subscription/payment_status_screen.dart
- functions/index.js revenuecatWebhook section

Current assumptions:
- RevenueCat entitlement ID is ffpvaultapp_pro unless overridden by
  RC_VAULT_ENTITLEMENT_ID.
- RevenueCat app_user_id must match the Firebase UID.
- Firestore subscription state lives at users/{uid}.subscription in the
  ffpvault database.
- The app should check Firestore first, then RevenueCat directly as a fallback
  for fresh purchases or delayed webhooks.
- A valid cancellation keeps access until expiration; cancelAtPeriodEnd should
  not immediately block the vault.

When debugging "purchase succeeded but vault still asks to subscribe":
1. Verify Purchases.configure ran with the intended RC_API_KEY.
2. Verify RevenueCatService.login() ran after Firebase sign-in.
3. Compare active RevenueCat entitlement keys with AppConfig.vaultEntitlementId.
4. Check whether syncToFirestore() wrote status: active.
5. Check the RevenueCat webhook secret and deployment.
6. Keep the user on the success/activation screen if RevenueCat is still
   catching up; do not route a valid buyer back to Subscribe unless entitlement
   is truly inactive.

Prefer small changes that preserve the existing flow:
- RevenueCatService owns SDK calls and Firestore sync.
- SubscriptionService is the app-facing facade.
- VaultAccessGate should only decide access, PIN/biometric auth, and routing.
- PaymentStatusScreen can wait for activation before opening /vault.

After changes, run:
- dart format on touched Dart files
- flutter analyze
```

## Common Issues

### Purchase succeeds but the app still shows Subscribe

Most likely causes:

- RevenueCat entitlement ID does not match `RC_VAULT_ENTITLEMENT_ID`.
- Firebase UID was not logged into RevenueCat before purchase.
- Webhook is delayed or not deployed.
- Firestore App Check / rules are blocking writes.

Check app logs for:

```text
RevenueCat entitlement key mismatch
RevenueCat vault entitlement not active
```

### User has an active store subscription but Firestore is inactive

Use restore purchases or open the vault again. The app checks RevenueCat
directly and calls `syncToFirestore()` when the entitlement is active.

### Cancelled subscription still opens the vault

That is expected until the paid period ends. The webhook stores
`cancelAtPeriodEnd: true` but keeps `status: active` until RevenueCat sends an
expiration event.

## Production Notes

- Replace the fallback RevenueCat test key before release.
- Verify App Store Connect and Google Play products are attached to the same
  RevenueCat entitlement.
- Keep the RevenueCat webhook enabled so renewals, cancellations, and expirations
  update Firestore even when the user does not open the app.
- Test with a real sandbox user on each platform before submitting a release.
