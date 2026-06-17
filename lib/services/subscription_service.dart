import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import '../Home_Profile/subscription/models/subscription_state.dart';
import 'revenuecat_service.dart';

/// Facade for subscription operations.
///
/// Reads subscription state from Firestore (which is synced by the RevenueCat
/// webhook + SDK listener) and delegates provider-specific actions
/// (purchase, cancel) to [RevenueCatService].
///
/// LEGACY: Stripe-specific methods are kept temporarily and will be removed
/// once the Stripe Cloud Functions are deleted.
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
  /// Works regardless of provider (Stripe or RevenueCat) because the data
  /// shape in Firestore is unified by the server-side webhooks.
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
  Future<SubscriptionState> waitForActiveSubscription({
    Duration timeout = const Duration(seconds: 12),
  }) {
    return streamSubscription()
        .firstWhere((subscription) => subscription.isActive)
        .timeout(timeout);
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
