import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import '../Home_Profile/subscription/models/subscription_state.dart';
import '../config/app_config.dart';
import 'revenuecat_service.dart';

/// Facade for subscription operations.
///
/// Reads subscription state from Firestore (which is synced by the RevenueCat
/// webhook + SDK listener) and delegates provider-specific actions
/// (purchase, cancel) to [RevenueCatService].
///
class SubscriptionService {
  SubscriptionService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );

  // ── Active API ──────────────────────────────────────────────────────────

  /// Streams the user's [SubscriptionState] from Firestore.
  ///
  /// Works with the RevenueCat subscription data synced by the webhook.
  Stream<SubscriptionState> streamSubscription() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(SubscriptionState.inactive);

    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final subscription = data?['subscription'];
      if (subscription is Map<String, dynamic>) {
        return SubscriptionState.fromMap(subscription);
      }
      if (subscription is Map) {
        return SubscriptionState.fromMap(
          Map<String, dynamic>.from(subscription),
        );
      }
      return SubscriptionState.inactive;
    });
  }

  /// Waits until the subscription becomes active, then returns its state.
  ///
  /// Polls both the Firestore stream AND RevenueCat directly so that a delayed
  /// Firestore sync doesn't block vault access. When RevenueCat reports the
  /// entitlement as active before Firestore does, we force a sync.
  Future<SubscriptionState> waitForActiveSubscription({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Race the Firestore stream against periodic RevenueCat direct checks.
    final firestoreFuture = streamSubscription()
        .firstWhere((subscription) => subscription.isActive)
        .timeout(timeout);

    // Poll RevenueCat every 2 seconds as a fallback.
    final rcFuture = _pollRevenueCat(timeout: timeout);

    // Whichever resolves first wins.
    return Future.any([firestoreFuture, rcFuture]);
  }

  /// Polls RevenueCat directly until the vault entitlement is active, or the
  /// timeout expires. Returns a [SubscriptionState] when active, or `null` on
  /// timeout.
  Future<SubscriptionState> _pollRevenueCat({
    required Duration timeout,
  }) async {
    final customerInfo = await RevenueCatService().waitForActiveCustomerInfo(
      timeout: timeout,
    );
    await RevenueCatService().syncToFirestore(customerInfo);

    return SubscriptionState.fromRevenueCat({
      'isActive': true,
      'entitlementId': AppConfig.vaultEntitlementId,
      'appUserId': FirebaseAuth.instance.currentUser?.uid ?? '',
      'productId': '',
      'willRenew': true,
    });
  }

  /// Opens a subscription-management UX for the user.
  ///
  /// Uses RevenueCat's Customer Center when available; falls back to the
  /// platform-native subscription settings (App Store / Google Play).
  ///
  /// Returns `true` when the management UI was presented successfully.
  Future<bool> cancelSubscription() async {
    return RevenueCatService().showCustomerCenter();
  }
}
