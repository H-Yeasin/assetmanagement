import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Wraps the RevenueCat `purchases_flutter` SDK.
///
/// Responsibilities:
/// - Log in / log out the RevenueCat SDK when Firebase auth changes.
/// - Fetch offerings (what the user can buy).
/// - Purchase a package.
/// - Restore previous purchases.
/// - Open native Customer Center for subscription management.
/// - Check entitlements (especially "FFP Vault Pro").
/// - Sync RevenueCat customer info → Firestore so the access gate stays
///   consistent (webhook is the primary sync; this is the immediate fallback).
class RevenueCatService {
  static RevenueCatService? _instance;

  factory RevenueCatService() => _instance ??= RevenueCatService._();

  RevenueCatService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );

  // Cached offerings to avoid redundant network calls during a single session.
  Offerings? _cachedOfferings;

  // ── Identity ─────────────────────────────────────────────────────────────

  /// Log the current Firebase user into RevenueCat.
  ///
  /// Call after every Firebase sign-in so purchases are associated with the
  /// correct account.
  ///
  /// Returns the [CustomerInfo] from the login call, or `null` if no user is
  /// signed in.
  Future<CustomerInfo?> login() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final loginResult = await Purchases.logIn(uid);
    await syncToFirestore(loginResult.customerInfo);
    return loginResult.customerInfo;
  }

  /// Log out of RevenueCat.
  ///
  /// Call on Firebase sign-out so the next user doesn't inherit the previous
  /// user's purchases.
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } on PlatformException catch (e) {
      if (e.code == '22') return;
      if (e.details is Map &&
          (e.details as Map)['readableErrorCode'] ==
              'LogOutWithAnonymousUserError') {
        return;
      }
      rethrow;
    }
  }

  // ── Customer info listener ───────────────────────────────────────────────

  /// Start listening for RevenueCat customer info changes and sync to Firestore.
  ///
  /// Call once at app startup. Handles renewals, cancellations, and purchases
  /// made on other devices.
  void listenForCustomerInfoUpdates() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      await syncToFirestore(customerInfo);
    });
  }

  // ── Offerings ────────────────────────────────────────────────────────────

  /// Fetch offerings from RevenueCat.
  ///
  /// Results are cached in-memory for the lifetime of the service instance.
  /// Pass [forceRefresh] to bypass the cache.
  ///
  /// Returns `null` when offerings aren't configured or the network fails.
  Future<Offerings?> getOfferings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedOfferings != null) {
      return _cachedOfferings;
    }
    try {
      final offerings = await Purchases.getOfferings();
      _cachedOfferings = offerings;
      return offerings;
    } catch (e) {
      return _cachedOfferings; // Return stale cache if available.
    }
  }

  /// Fetch the current offering from RevenueCat.
  ///
  /// If [AppConfig.rcOfferingId] is set, returns that specific offering.
  /// Otherwise returns the default `current` offering.
  Future<Offering?> getCurrentOffering({bool forceRefresh = false}) async {
    final offerings = await getOfferings(forceRefresh: forceRefresh);
    if (offerings == null) return null;

    // If a specific offering is configured, use it.
    if (AppConfig.rcOfferingId.isNotEmpty) {
      return offerings.getOffering(AppConfig.rcOfferingId);
    }
    return offerings.current;
  }

  /// Get the monthly package from the current offering.
  ///
  /// Looks for a package whose identifier matches [AppConfig.monthlyPackageId]
  /// (default: `'monthly'`). Falls back to the first available monthly-duration
  /// package, then to the offering's first available package.
  Future<Package?> getMonthlyPackage({bool forceRefresh = false}) async {
    final offering = await getCurrentOffering(forceRefresh: forceRefresh);
    if (offering == null) return null;

    // 1. Try the built-in `monthly` accessor (RevenueCat maps common identifiers).
    final monthly = offering.monthly;
    if (monthly != null) return monthly;

    // 2. Search available packages for a matching identifier.
    for (final pkg in offering.availablePackages) {
      if (pkg.identifier == AppConfig.monthlyPackageId) return pkg;
    }

    // 3. Fall back to the first available package.
    return offering.availablePackages.isNotEmpty
        ? offering.availablePackages.first
        : null;
  }

  // ── Purchase ─────────────────────────────────────────────────────────────

  /// Purchase a package and immediately sync the result to Firestore.
  ///
  /// Throws [PlatformException] on cancellation or error. Check
  /// `details['userCancelled']` to detect user-initiated cancellation.
  ///
  /// After a successful platform purchase, RevenueCat's backend may take a
  /// few seconds to activate the entitlement. This method polls
  /// [Purchases.getCustomerInfo] for up to 4 seconds so the Firestore sync
  /// writes `status: 'active'` instead of a transient `'inactive'`.
  ///
  /// Returns the latest [CustomerInfo] after the entitlement is confirmed.
  Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));

    CustomerInfo customerInfo;
    try {
      customerInfo = await waitForActiveCustomerInfo(
        initialCustomerInfo: result.customerInfo,
        timeout: const Duration(seconds: 20),
      );
    } on TimeoutException {
      customerInfo = await Purchases.getCustomerInfo();
    }

    await syncToFirestore(customerInfo);
    return customerInfo;
  }

  // ── Restore ──────────────────────────────────────────────────────────────

  /// Restore previous purchases (e.g. after reinstall or switching devices).
  ///
  /// Syncs the restored customer info to Firestore so the access gate is
  /// immediately updated.
  Future<CustomerInfo> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    await syncToFirestore(customerInfo);
    return customerInfo;
  }

  // ── Customer Center ──────────────────────────────────────────────────────

  // NOTE: When you upgrade to `purchases_flutter` ≥ 10.5.0, add an import for
  // `dart:mirrors` is not needed — just uncomment the `Purchases.showCustomerCenter()`
  // call below and remove the fallback-only implementation.
  //
  // The native Customer Center lets users manage their subscription, request
  // refunds, and view billing history — all in-app without platform deep links.
  // Configure it in the RevenueCat dashboard under "Customer Center".

  /// Open a subscription-management UX for the user.
  ///
  /// When [AppConfig.useCustomerCenter] is `true`, this opens RevenueCat's
  /// native Customer Center (requires `purchases_flutter` ≥ 10.5.0 — upgrade
  /// your SDK dependency to enable).
  ///
  /// Currently falls back to the platform subscription settings URL because
  /// `purchases_flutter` 10.2.x does not include `showCustomerCenter`.
  ///
  /// **To enable the native Customer Center:**
  /// 1. Run: `flutter pub upgrade purchases_flutter purchases_ui_flutter`
  /// 2. Uncomment the `await Purchases.showCustomerCenter();` call below.
  /// 3. Configure the Customer Center in the RevenueCat dashboard.
  ///
  /// Returns `true` when the management UI was presented successfully.
  Future<bool> showCustomerCenter() async {
    // When you upgrade to purchases_flutter ≥ 10.5.0, replace this entire
    // method body with:
    //
    //   try {
    //     await Purchases.showCustomerCenter();
    //     return true;
    //   } catch (_) {
    //     return _showPlatformSubscriptionSettings();
    //   }
    //
    // For now, always use the platform settings fallback:
    return _showPlatformSubscriptionSettings();
  }

  /// Open the platform-native subscription management UI.
  ///
  /// iOS → App Store subscription settings.
  /// Android → Google Play subscription settings.
  Future<bool> _showPlatformSubscriptionSettings() async {
    try {
      // iOS: App Store Subscriptions
      final iosUri = Uri.parse('https://apps.apple.com/account/subscriptions');
      // Android: Google Play Subscriptions
      final androidUri = Uri.parse(
        'https://play.google.com/store/account/subscriptions',
      );

      if (await canLaunchUrl(iosUri)) {
        await launchUrl(iosUri, mode: LaunchMode.externalApplication);
        return true;
      }
      if (await canLaunchUrl(androidUri)) {
        await launchUrl(androidUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Entitlement checking ─────────────────────────────────────────────────

  /// Returns `true` when the user has an active "FFP Vault Pro" entitlement.
  ///
  /// Fetches fresh customer info from RevenueCat every call. For UI-driven
  /// checks, prefer [SubscriptionService.streamSubscription] which reads from
  /// Firestore (synced by the webhook + SDK listener).
  ///
  /// See [AppConfig.vaultEntitlementId] for the entitlement key.
  Future<bool> checkProEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = _vaultEntitlementFrom(customerInfo);
      return entitlement?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns detailed entitlement info for "FFP Vault Pro".
  ///
  /// Use this when you need the full [EntitlementInfo] (e.g. expiration date,
  /// product identifier, renewal status), not just a boolean.
  ///
  /// Returns `null` when the entitlement isn't active or when an error occurs.
  Future<EntitlementInfo?> getProEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _vaultEntitlementFrom(customerInfo);
    } catch (_) {
      return null;
    }
  }

  /// Returns a map of all active entitlements keyed by entitlement ID.
  ///
  /// Useful for debugging and for apps with multiple entitlement gates.
  Future<Map<String, EntitlementInfo>> getActiveEntitlements() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active;
    } catch (_) {
      return {};
    }
  }

  // ── Customer info ────────────────────────────────────────────────────────

  /// Get the latest customer info directly from RevenueCat.
  ///
  /// Prefer [checkProEntitlement] for simple entitlement checks, or
  /// [SubscriptionService.streamSubscription] for reactive UI updates.
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// Polls RevenueCat until the vault entitlement is active, then returns the
  /// latest [CustomerInfo]. Throws [TimeoutException] if it never activates.
  Future<CustomerInfo> waitForActiveCustomerInfo({
    CustomerInfo? initialCustomerInfo,
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(seconds: 1),
  }) async {
    final deadline = DateTime.now().add(timeout);
    CustomerInfo customerInfo =
        initialCustomerInfo ?? await Purchases.getCustomerInfo();

    while (true) {
      if (_vaultEntitlementFrom(customerInfo)?.isActive == true) {
        return customerInfo;
      }

      if (!DateTime.now().isBefore(deadline)) {
        _logEntitlementMismatch(customerInfo);
        throw TimeoutException(
          'RevenueCat entitlement did not become active before timeout.',
        );
      }

      await Future.delayed(interval);
      customerInfo = await Purchases.getCustomerInfo();
    }
  }

  /// Returns the cached [CustomerInfo] if available (avoids a network call).
  ///
  /// RevenueCat keeps the latest customer info in memory after the first fetch.
  /// This is safe to use for quick UI decisions where slightly stale data is
  /// acceptable.
  ///
  /// NOTE: `CacheFetchPolicy` is available in `purchases_flutter` ≥ 10.5.0.
  /// On 10.2.x, this calls `getCustomerInfo()` which may hit the network.
  Future<CustomerInfo> getCachedCustomerInfo() async {
    // When you upgrade to purchases_flutter ≥ 10.5.0, replace with:
    //   return await Purchases.getCustomerInfo(
    //     fetchPolicy: CacheFetchPolicy.fromCacheOnly,
    //   );
    return await Purchases.getCustomerInfo();
  }

  // ── Firestore sync ───────────────────────────────────────────────────────

  /// Sync RevenueCat customer info to Firestore so the access gate works
  /// without waiting for the webhook.
  ///
  /// Public so that [SubscriptionService] and gate widgets can force a sync
  /// when they detect a stale Firestore state.
  Future<void> syncToFirestore(CustomerInfo customerInfo) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final vaultEntitlement = _vaultEntitlementFrom(customerInfo);

    // expirationDate is an ISO 8601 string in RevenueCat 10.x.
    Timestamp? periodEnd;
    final expDate = vaultEntitlement?.expirationDate;
    if (expDate != null) {
      final parsed = DateTime.tryParse(expDate);
      if (parsed != null) {
        periodEnd = Timestamp.fromDate(parsed.toLocal());
      }
    }

    final isActive = vaultEntitlement?.isActive ?? false;

    // Regression guard: don't let a stale CustomerInfo (e.g. from login or
    // a transient listener event) overwrite an active, non-expired subscription.
    if (!isActive) {
      final existingDoc = await _db.collection('users').doc(uid).get();
      final existingSub = existingDoc.data()?['subscription'];
      if (existingSub is Map && existingSub['status'] == 'active') {
        final periodEnd = existingSub['currentPeriodEnd'];
        if (periodEnd is Timestamp &&
            periodEnd.toDate().isAfter(DateTime.now())) {
          return; // Keep the existing active subscription intact.
        }
      }
    }

    final subData = <String, dynamic>{
      'provider': 'revenuecat',
      'rcCustomerId': customerInfo.originalAppUserId,
      'rcEntitlementId': AppConfig.vaultEntitlementId,
      'planCode': vaultEntitlement?.productIdentifier ?? '',
      'planName': AppConfig.planName,
      'amount': AppConfig.defaultPlanAmountCents,
      'currency': AppConfig.defaultPlanCurrency,
      'status': isActive ? 'active' : 'inactive',
      'cancelAtPeriodEnd': vaultEntitlement?.willRenew == false,
      'currentPeriodEnd': periodEnd,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(uid).set({
      'subscription': subData,
    }, SetOptions(merge: true));
  }

  EntitlementInfo? _vaultEntitlementFrom(CustomerInfo customerInfo) {
    final configured =
        customerInfo.entitlements.active[AppConfig.vaultEntitlementId] ??
        customerInfo.entitlements.all[AppConfig.vaultEntitlementId];

    if (configured?.isActive == true) return configured;

    final activeEntitlements = customerInfo.entitlements.active;
    if (activeEntitlements.length == 1) {
      final fallback = activeEntitlements.entries.single;
      if (fallback.value.isActive) {
        debugPrint(
          'RevenueCat entitlement key mismatch: configured '
          '"${AppConfig.vaultEntitlementId}", active "${fallback.key}". '
          'Update RC_VAULT_ENTITLEMENT_ID to remove this fallback.',
        );
        return fallback.value;
      }
    }

    return null;
  }

  void _logEntitlementMismatch(CustomerInfo customerInfo) {
    final activeKeys = customerInfo.entitlements.active.keys.join(', ');
    final allKeys = customerInfo.entitlements.all.keys.join(', ');
    debugPrint(
      'RevenueCat vault entitlement not active. Configured: '
      '"${AppConfig.vaultEntitlementId}". Active: [$activeKeys]. '
      'All: [$allKeys].',
    );
  }
}
