import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:async';

import '../Home_Profile/subscription/models/subscription_checkout.dart';
import '../Home_Profile/subscription/models/subscription_confirmation.dart';
import '../Home_Profile/subscription/models/subscription_state.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  static SubscriptionPublicConfig? _cachedConfig;

  Future<SubscriptionPublicConfig> getPublicConfig({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedConfig != null) {
      return _cachedConfig!;
    }

    final config = await _loadPublicConfig();
    if (config.publishableKey.isNotEmpty) {
      _cachedConfig = config;
    }
    return config;
  }

  Future<void> ensureStripeConfigured({bool forceRefresh = false}) async {
    final config = await getPublicConfig(forceRefresh: forceRefresh);
    if (config.publishableKey.isEmpty) {
      if (!forceRefresh) {
        await ensureStripeConfigured(forceRefresh: true);
        return;
      }
      throw StateError('Stripe publishable key is not configured.');
    }

    bool needsUpdate = false;
    try {
      if (Stripe.publishableKey != config.publishableKey) {
        needsUpdate = true;
      }
    } catch (_) {
      // The getter throws if publishableKey is not yet set
      needsUpdate = true;
    }

    if (needsUpdate) {
      Stripe.publishableKey = config.publishableKey;
      await Stripe.instance.applySettings();
    }
  }

  Future<SubscriptionPublicConfig> _loadPublicConfig() async {
    final callable = _functions.httpsCallable('getStripePublicConfig');
    final result = await callable.call();
    return SubscriptionPublicConfig.fromMap(
      result.data as Map<dynamic, dynamic>,
    );
  }

  Future<SubscriptionCheckout> createCheckout() async {
    await ensureStripeConfigured();
    final callable = _functions.httpsCallable('createStripePaymentIntent');
    final result = await callable.call();
    return SubscriptionCheckout.fromMap(result.data as Map<dynamic, dynamic>);
  }

  Future<SubscriptionConfirmation> finalizePayment({
    required String subscriptionId,
    String paymentMethodId = '',
    String setupIntentId = '',
  }) async {
    final callable = _functions.httpsCallable('finalizeStripePayment');
    final result = await callable.call({
      'subscriptionId': subscriptionId,
      'paymentMethodId': paymentMethodId,
      'setupIntentId': setupIntentId,
    });
    return SubscriptionConfirmation.fromMap(
      result.data as Map<dynamic, dynamic>,
    );
  }

  Future<SubscriptionConfirmation> cancelSubscription() async {
    final callable = _functions.httpsCallable('cancelStripeSubscription');
    final result = await callable.call();
    return SubscriptionConfirmation.fromMap(
      result.data as Map<dynamic, dynamic>,
    );
  }

  Future<SubscriptionConfirmation> abandonCheckout({
    required String subscriptionId,
  }) async {
    final callable = _functions.httpsCallable('abandonStripeCheckout');
    final result = await callable.call({'subscriptionId': subscriptionId});
    return SubscriptionConfirmation.fromMap(
      result.data as Map<dynamic, dynamic>,
    );
  }

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

  Future<SubscriptionState> waitForActiveSubscription({
    Duration timeout = const Duration(seconds: 12),
  }) {
    return streamSubscription()
        .firstWhere((subscription) => subscription.isActive)
        .timeout(timeout);
  }
}
