# RevenueCat Migration Guide

## Current Architecture → Target Architecture

| Layer | Current (Stripe) | Target (RevenueCat) |
|---|---|---|
| **Mobile Payment SDK** | `flutter_stripe` | `purchases_flutter` |
| **Payment Processing** | Stripe (cards, SetupIntent) | Apple StoreKit 2 / Google Play Billing |
| **Subscription Backend** | Firebase Cloud Functions (Stripe API calls) | RevenueCat dashboard + webhooks |
| **State storage** | Firestore `users/{uid}.subscription` | Firestore `users/{uid}.subscription` (synced by webhook) |
| **Trial handling** | Stripe-managed (14d trial_period_days) | RevenueCat-managed (introductory offers) |
| **Cancellation** | Cloud Function → Stripe API | User-managed in device Settings OR RevenueCat `canManageSubscription` |

---

## STEP 0 — Prerequisites (Client Action Required)

### 0.1 — RevenueCat Account Setup
1. Sign up at [revenuecat.com](https://www.revenuecat.com) (free tier to start)
2. Create a new project named **"FFP Vault"**
3. Under **Project Settings → API Keys**, note down:
   - Apple App Store **public** API key (`appl_xxx`)
   - Google Play **public** API key (`goog_xxx`)
4. Share these with your developer

### 0.2 — App Store Connect (iOS) Product Setup
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your app → **Subscriptions** under **In-App Purchases**
3. Click **Create** → **Subscription Group** (name: "FFP Vault Subscription")
4. Create a subscription product:
   - **Reference Name**: `FFP Vault Monthly`
   - **Product ID**: `ffp_vault_monthly`
   - **Price**: `$6.99 USD` per month
   - **Duration**: 1 Month
   - Add **Introductory Offer**: 14-day free trial (type: free trial)
   - Family Sharing: Off (unless you want it)
5. Submit for review (subscriptions need approval even before the app is live)

### 0.3 — Google Play Console (Android) Product Setup
1. Log in to [Google Play Console](https://play.google.com/console)
2. Go to your app → **Monetize → Products → Subscriptions**
3. Click **Create subscription**
4. Set:
   - **Product ID**: `ffp_vault_monthly`
   - **Name**: `FFP Vault Monthly`
   - **Price**: `$6.99 USD` per month
   - Add **Introductory offer**: 14-day free trial
   - Grace period: 3 days (recommended)
5. Click **Activate**

### 0.4 — RevenueCat Product & Offering Configuration
1. In RevenueCat dashboard → **Products**, import the products from App Store Connect and Google Play (this happens automatically once the apps are connected)
2. Go to **Offerings** → click **Create Offering**
3. Name the offering: `default`
4. Add a package → select the `ffp_vault_monthly` entitlement
5. It should look like:
   ```
   Offering: default
   └── Package: monthly
       └── Product: ffp_vault_monthly ($6.99/mo, 14-day trial)
   ```
6. Create an **Entitlement** called `vault_access` — this is what your app checks to gate features

### 0.5 — Firebase Blaze Plan (Critical)
Remind client that without an active Firebase Blaze plan:
- Cloud Functions won't deploy
- Firestore won't work
- The RevenueCat webhook (that syncs subscription state to Firestore) will fail

---

## STEP 1 — Add RevenueCat SDK to Flutter

### 1.1 — Remove Stripe, Add RevenueCat

**Remove from `pubspec.yaml`:**
```yaml
# REMOVE this line:
flutter_stripe: ^12.3.0
```

**Add to `pubspec.yaml`:**
```yaml
# ADD this line:
purchases_flutter: ^8.6.0
```

### 1.2 — Run
```bash
flutter pub get
```

---

## STEP 2 — Configure Platform-Specific Files

### 2.1 — iOS (`ios/Runner/Info.plist`)

Add RevenueCat API key (replace `REVENUECAT_APPLE_API_KEY` with the actual key from Step 0.1):

```xml
<key>RC_APPLE_API_KEY</key>
<string>REVENUECAT_APPLE_API_KEY</string>
```

### 2.2 — Android (`android/app/build.gradle`)

No code change needed in build.gradle — RevenueCat config goes in code. But ensure these Billing permissions exist (they should already be there):

In `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### 2.3 — RevenueCat SDK Key in Code

In `main.dart` `initServices()`, add RevenueCat initialization right after Firebase setup:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

// Inside your init block, after Firebase.initializeApp():
await Purchases.configure(
  PurchasesConfiguration(
    Platform.isIOS
        ? 'YOUR_REVENUECAT_APPLE_API_KEY'
        : 'YOUR_REVENUECAT_GOOGLE_API_KEY',
  ),
);
```

---

## STEP 3 — Rewrite `SubscriptionService` (The Big One)

Replace [lib/services/subscription_service.dart](lib/services/subscription_service.dart) entirely. The new version wraps RevenueCat instead of Stripe.

### New file: `lib/services/revenuecat_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Mirrors the old SubscriptionState but sourced from RevenueCat + Firestore.
class SubscriptionState {
  final String planCode;
  final String planName;
  final int amount;
  final String currency;
  final String status;          // active | trialing | expired | canceled | inactive
  final String rcCustomerId;    // RevenueCat customer ID (replaces stripeCustomerId)
  final String rcEntitlementId; // which entitlement is active
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndDate;

  const SubscriptionState({
    required this.planCode,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.rcCustomerId,
    required this.rcEntitlementId,
    required this.cancelAtPeriodEnd,
    required this.currentPeriodEnd,
    this.trialEndDate,
  });

  static const inactive = SubscriptionState(
    planCode: '',
    planName: '',
    amount: 0,
    currency: 'usd',
    status: 'inactive',
    rcCustomerId: '',
    rcEntitlementId: '',
    cancelAtPeriodEnd: false,
    currentPeriodEnd: null,
    trialEndDate: null,
  );

  bool get isSubscribed =>
      status == 'active' || status == 'past_due' || status == 'trialing';

  bool get isActive => isSubscribed;

  factory SubscriptionState.fromRC(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.active['vault_access'];
    final hasEntitlement = entitlement != null && !entitlement.isSandbox
        ? entitlement
        : null;

    return SubscriptionState(
      planCode: hasEntitlement?.productIdentifier ?? '',
      planName: 'FFP Vault Monthly',
      amount: 699,
      currency: 'usd',
      status: hasEntitlement != null ? 'active' : 'inactive',
      rcCustomerId: customerInfo.originalAppUserId,
      rcEntitlementId: hasEntitlement?.identifier ?? '',
      cancelAtPeriodEnd: hasEntitlement?.willRenew == false,
      currentPeriodEnd: hasEntitlement?.expirationDate?.toLocal() is DateTime
          ? hasEntitlement!.expirationDate!.toLocal()
          : null,
      trialEndDate: null,
    );
  }

  factory SubscriptionState.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return inactive;
    return SubscriptionState(
      planCode: data['planCode'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'usd',
      status: data['status'] as String? ?? 'inactive',
      rcCustomerId: data['rcCustomerId'] as String? ?? '',
      rcEntitlementId: data['rcEntitlementId'] as String? ?? '',
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] == true,
      currentPeriodEnd: data['currentPeriodEnd'] is Timestamp
          ? (data['currentPeriodEnd'] as Timestamp).toDate()
          : null,
      trialEndDate: data['trialEndDate'] is Timestamp
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
    );
  }
}

class RevenueCatService {
  static RevenueCatService? _instance;

  factory RevenueCatService() => _instance ??= RevenueCatService._();

  RevenueCatService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 1. Login to RevenueCat (call right after Firebase auth succeeds)
  Future<void> login() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await Purchases.logIn(uid);
  }

  /// 2. Logout (call on sign-out)
  Future<void> logout() async {
    await Purchases.logOut();
  }

  /// 3. Fetch offerings from RevenueCat (packages the user can buy)
  Future<Offering?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      return null;
    }
  }

  /// 4. Purchase a package (replaces createCheckout + payWithCard pipeline)
  Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  /// 5. Restore purchases (for users re-installing the app)
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  /// 6. Stream subscription state (combine RevenueCat + Firestore)
  Stream<SubscriptionState> streamSubscription() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(SubscriptionState.inactive);

    // Primary: Firestore (synced by webhook)
    // Fallback: RevenueCat SDK (immediate after purchase)
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          final sub = data?['subscription'];
          if (sub is Map<String, dynamic>) {
            return SubscriptionState.fromFirestore(sub);
          }
          return SubscriptionState.inactive;
        });
  }

  /// 7. Check subscription from RevenueCat directly (for post-purchase)
  Future<CustomerInfo> refreshCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// 8. Get subscription management URL (user manages in App Store / Play Store settings)
  Future<bool> showManageSubscription() async {
    try {
      // RevenueCat redirects to the right store subscription management
      await Purchases.showManageSubscriptions();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 9. Sync RevenueCat customerInfo to Firestore
  /// Called after purchase or on app resume to keep Firestore in sync.
  Future<void> syncToFirestore(CustomerInfo customerInfo) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final vaultEntitlement =
        customerInfo.entitlements.active['vault_access'];

    final subData = <String, dynamic>{
      'provider': 'revenuecat',
      'rcCustomerId': customerInfo.originalAppUserId,
      'rcEntitlementId': vaultEntitlement?.identifier ?? '',
      'planCode': vaultEntitlement?.productIdentifier ?? '',
      'planName': 'FFP Vault Monthly',
      'amount': 699,
      'currency': 'usd',
      'status': vaultEntitlement != null ? 'active' : 'inactive',
      'cancelAtPeriodEnd': vaultEntitlement?.willRenew == false,
      'currentPeriodEnd': vaultEntitlement?.expirationDate?.toLocal() is DateTime
          ? Timestamp.fromDate(
              vaultEntitlement!.expirationDate!.toLocal())
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(uid).set(
      {'subscription': subData},
      SetOptions(merge: true),
    );
  }
}
```

---

## STEP 4 — Rewrite the Payment Screen

[lib/Home_Profile/subscription/choose_payment_screen.dart](lib/Home_Profile/subscription/choose_payment_screen.dart) currently handles Stripe card input + Stripe Payment Sheet. With RevenueCat, all payment is handled natively by the platform. The screen becomes much simpler.

### Key changes:
- Remove `flutter_stripe` imports and `CardEditController`
- Remove cloud function calls (`createStripePaymentIntent`, `finalizeStripePayment`, `abandonStripeCheckout`)
- Replace with `RevenueCatService().purchase(package)`
- Remove the two payment method choices (card vs Stripe sheet) — RevenueCat uses the platform-native purchase sheet

### New simplified flow:

```dart
Future<void> _purchase() async {
  setState(() => _isLoading = true);
  try {
    final offering = await _rcService.getOfferings();
    final package = offering?.monthly; // the monthly package
    if (package == null) {
      _showError('Subscription not available right now.');
      return;
    }

    final customerInfo = await _rcService.purchase(package);
    await _rcService.syncToFirestore(customerInfo);

    if (!mounted) return;
    context.go('/payment-success', extra: ...);
  } on PlatformException catch (e) {
    // user_cancelled → user dismissed the native purchase dialog
    if (e.details['userCancelled'] == true) {
      if (mounted) context.pop(); // go back
      return;
    }
    context.go('/payment-failed', extra: ...);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## STEP 5 — Update the Plan Screen

[lib/Home_Profile/subscription/subscription_plan_screen.dart](lib/Home_Profile/subscription/subscription_plan_screen.dart) — minimal changes needed.

### Changes:
1. Replace `import` of `SubscriptionService` with `RevenueCatService`
2. Replace `_subscriptionService.cancelSubscription()` with a redirect to platform subscription management:

```dart
Future<void> _cancelSubscription() async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;

  // RevenueCat handles cancellation by redirecting to store settings
  await RevenueCatService().showManageSubscription();
}
```

3. Update the `SubscriptionState` to use the new class (fields like `isFreeTrialActive` change — RevenueCat handles trials through `IntroductoryPrice`, so the trial logic can be checked via `Purchases.getCustomerInfo()`)

---

## STEP 6 — Update the Access Gate

[lib/Home_Vault/subscription_access_gate.dart](lib/Home_Vault/subscription_access_gate.dart) — minimal changes.

Replace:
```dart
import '../services/subscription_service.dart';
```
with:
```dart
import '../services/revenuecat_service.dart';
```

And replace `SubscriptionService` with `RevenueCatService`.

---

## STEP 7 — Update App Entry Point (`main.dart`)

Add RevenueCat initialization and auto-login:

```dart
import 'services/revenuecat_service.dart';

// In your Firebase auth state listener:
FirebaseAuth.instance.authStateChanges().listen((user) async {
  if (user != null) {
    await RevenueCatService().login();
  } else {
    await RevenueCatService().logout();
  }
});
```

Also set up listener for purchase updates (for when a purchase happens on another device, or subscription renewals):

```dart
Purchases.addCustomerInfoUpdateListener((customerInfo) async {
  await RevenueCatService().syncToFirestore(customerInfo);
});
```

---

## STEP 8 — Set Up RevenueCat → Firestore Webhook

RevenueCat sends webhooks on events like purchases, renewals, cancellations, trials. You need a Cloud Function to receive these and sync to Firestore.

### 8.1 — In RevenueCat Dashboard
Go to **Integrations → Outbound Webhooks** → Add new endpoint:
- URL: `https://us-central1-YOUR_PROJECT.cloudfunctions.net/revenuecatWebhook`
- Events: Check all subscription events (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, etc.)

### 8.2 — New Cloud Function

Add this to [functions/index.js](functions/index.js):

```javascript
// RevenueCat webhook secret
const rcWebhookSecret = defineSecret("RC_WEBHOOK_SECRET");

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
      response.status(401).send("Unauthorized");
      return;
    }

    try {
      const event = request.body;
      const eventType = event?.event?.type;
      const appUserId = event?.event?.app_user_id; // This is the Firebase UID
      const productId = event?.event?.product_id || "ffp_vault_monthly";
      const entitlementId =
        event?.event?.entitlement_ids?.[0] || "vault_access";

      if (!appUserId) {
        response.status(400).send("Missing app_user_id");
        return;
      }

      const userRef = db.collection("users").doc(appUserId);
      const userSnap = await userRef.get();

      let subscriptionState;

      switch (eventType) {
        case "INITIAL_PURCHASE":
        case "RENEWAL":
        case "UNCANCELLATION":
          subscriptionState = {
            planCode: productId,
            planName: "FFP Vault Monthly",
            amount: 699,
            currency: "usd",
            status: "active",
            provider: "revenuecat",
            rcCustomerId: appUserId,
            rcEntitlementId: entitlementId,
            cancelAtPeriodEnd: false,
            currentPeriodEnd: admin.firestore.Timestamp.fromDate(
              new Date(event.event.expiration_at_ms)
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          break;

        case "CANCELLATION":
          subscriptionState = {
            planCode: productId,
            planName: "FFP Vault Monthly",
            amount: 699,
            currency: "usd",
            status: "active", // stays active until period end
            provider: "revenuecat",
            rcCustomerId: appUserId,
            rcEntitlementId: entitlementId,
            cancelAtPeriodEnd: true,
            currentPeriodEnd: admin.firestore.Timestamp.fromDate(
              new Date(event.event.expiration_at_ms)
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          break;

        case "EXPIRATION":
        case "SUBSCRIPTION_PAUSED":
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

        default:
          response.json({ received: true, action: "ignored" });
          return;
      }

      await userRef.set(
        { subscription: subscriptionState },
        { mergeFields: ["subscription"] }
      );

      console.log(`RevenueCat ${eventType} synced for user ${appUserId}`);
      response.json({ received: true });
    } catch (error) {
      console.error("RevenueCat webhook error:", error);
      response.status(500).send(`Webhook Error: ${error.message}`);
    }
  }
);
```

### 8.3 — Deploy
```bash
firebase deploy --only functions:revenuecatWebhook
```

---

## STEP 9 — Clean Up: Remove Stripe Artifacts

### Files to DELETE:
- All Stripe Cloud Functions in `functions/index.js`:
  - `getStripePublicConfig`
  - `createStripePaymentIntent`
  - `finalizeStripePayment`
  - `abandonStripeCheckout`
  - `cancelStripeSubscription`
  - `stripeWebhook`
- Keep: `checkRemindersAndNotify`, `checkTrialExpirations` (or update trial check to work with RC data)

### Secrets to DELETE (Firebase):
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PUBLISHABLE_KEY_SECRET`

### Files to REMOVE:
- [lib/services/subscription_service.dart](lib/services/subscription_service.dart) (replaced by `revenuecat_service.dart`)
- The `flutter_stripe` dependency from `pubspec.yaml`

### Stripe Dashboard Cleanup:
- Cancel any active test subscriptions in Stripe before deleting
- Can optionally keep Stripe account if they plan to use it for web payments later

---

## STEP 10 — Test Everything

### Dev/Test Mode:
Keep the `bypassVaultSubscription` toggle in [lib/config/app_config.dart](lib/config/app_config.dart) during development.

```dart
static const bool bypassVaultSubscription = bool.fromEnvironment(
  'BYPASS_VAULT_SUBSCRIPTION',
  defaultValue: true,  // set to true during dev
);
```

### Testing checklist:

| Scenario | How to test |
|---|---|
| **Fresh install → subscribe** | New device, tap Subscribe, Apple/Google native sheet appears, complete purchase → routed to success → vault opens |
| **Fresh install → cancel purchase sheet** | Tap Subscribe, cancel the native dialog → stays on same screen |
| **Fresh install → free trial** | Subscribe → 14-day trial starts → verify vault access works |
| **Returning subscriber → restore** | Delete & reinstall app → Profile → Subscription Plan → RevenueCat auto-restores |
| **Active subscriber → cancel** | Tap Cancel → redirects to App Store / Play Store subscription settings |
| **Active subscriber → renewal** | RevenueCat webhook fires → Firestore subscription status stays `active` |
| **Cancelled subscriber → expiration** | Wait past period end → RC webhook fires `EXPIRATION` → Firestore status → `expired` → vault access denied |
| **Device 1 purchases → Device 2 auto-syncs** | Purchase on device 1 → `syncToFirestore` runs → device 2 picks up via Firestore stream |

---

## Summary: Files Changed

| File | Action | Effort |
|---|---|---|
| `pubspec.yaml` | Remove `flutter_stripe`, add `purchases_flutter` | Low |
| `lib/main.dart` | Add RevenueCat init + auth listener | Low |
| `lib/config/app_config.dart` | No change needed | None |
| `lib/services/subscription_service.dart` | **DELETE**, replaced by `revenuecat_service.dart` | Medium |
| `lib/services/revenuecat_service.dart` | **NEW FILE** | Medium |
| `lib/Home_Profile/subscription/choose_payment_screen.dart` | **REWRITE** (Stripe → RevenueCat purchase) | High |
| `lib/Home_Profile/subscription/subscription_plan_screen.dart` | Update imports + cancel flow | Medium |
| `lib/Home_Profile/subscription/payment_status_screen.dart` | Update import (use new `SubscriptionState`) | Low |
| `lib/Home_Vault/subscription_access_gate.dart` | Update import | Low |
| `lib/router.dart` | No structural change needed (routes stay same) | None |
| `functions/index.js` | Remove Stripe functions, add RC webhook | High |
| `ios/Runner/Info.plist` | Add RevenueCat API key | Low |

---

## Estimated Effort

- **Flutter side**: 2–3 days (rewrite payment screen, new service, test)
- **Cloud Functions side**: 0.5 day (add webhook, remove Stripe)
- **RevenueCat + App Store + Play Console setup**: 2–3 days (mostly waiting for Apple approval of subscription products)
- **Testing**: 1–2 days
- **Total**: ~5–8 days including app review wait times
