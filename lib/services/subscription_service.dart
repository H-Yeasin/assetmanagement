import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:async';

class SubscriptionCheckout {
  final String clientSecret;
  final String setupIntentId;
  final String customerId;
  final String customerEphemeralKeySecret;
  final String subscriptionId;
  final int amount;
  final String currency;
  final String planCode;
  final String planName;

  const SubscriptionCheckout({
    required this.clientSecret,
    required this.setupIntentId,
    required this.customerId,
    required this.customerEphemeralKeySecret,
    required this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.planCode,
    required this.planName,
  });

  factory SubscriptionCheckout.fromMap(Map<dynamic, dynamic> data) {
    return SubscriptionCheckout(
      clientSecret: data['clientSecret'] as String? ?? '',
      setupIntentId: data['setupIntentId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerEphemeralKeySecret:
          data['customerEphemeralKeySecret'] as String? ?? '',
      subscriptionId: data['subscriptionId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'usd',
      planCode: data['planCode'] as String? ?? 'monthly_core',
      planName: data['planName'] as String? ?? 'FFP Vault Monthly',
    );
  }
}

class SubscriptionConfirmation {
  final String status;
  final String subscriptionStatus;
  final String paymentIntentId;
  final String subscriptionId;
  final bool cancelAtPeriodEnd;

  const SubscriptionConfirmation({
    required this.status,
    required this.subscriptionStatus,
    required this.paymentIntentId,
    required this.subscriptionId,
    required this.cancelAtPeriodEnd,
  });

  factory SubscriptionConfirmation.fromMap(Map<dynamic, dynamic> data) {
    return SubscriptionConfirmation(
      status: data['status'] as String? ?? 'unknown',
      subscriptionStatus: data['subscriptionStatus'] as String? ?? 'inactive',
      paymentIntentId: data['paymentIntentId'] as String? ?? '',
      subscriptionId: data['subscriptionId'] as String? ?? '',
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] == true,
    );
  }
}

class SubscriptionState {
  final String planCode;
  final String planName;
  final int amount;
  final String currency;
  final String status;
  final String stripeCustomerId;
  final String stripeSubscriptionId;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;

  const SubscriptionState({
    required this.planCode,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.stripeCustomerId,
    required this.stripeSubscriptionId,
    required this.cancelAtPeriodEnd,
    required this.currentPeriodEnd,
  });

  static const inactive = SubscriptionState(
    planCode: '',
    planName: '',
    amount: 0,
    currency: 'usd',
    status: 'inactive',
    stripeCustomerId: '',
    stripeSubscriptionId: '',
    cancelAtPeriodEnd: false,
    currentPeriodEnd: null,
  );

  bool get isActive =>
      status == 'active' || status == 'trialing' || status == 'past_due';

  factory SubscriptionState.fromMap(Map<String, dynamic>? data) {
    if (data == null) return inactive;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SubscriptionState(
      planCode: data['planCode'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'usd',
      status: data['status'] as String? ?? 'inactive',
      stripeCustomerId: data['stripeCustomerId'] as String? ?? '',
      stripeSubscriptionId: data['stripeSubscriptionId'] as String? ?? '',
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] == true,
      currentPeriodEnd: parseDate(data['currentPeriodEnd']),
    );
  }
}

class SubscriptionPublicConfig {
  final String publishableKey;
  final String firestoreDbId;
  final int amount;
  final String currency;
  final String planCode;
  final String planName;

  const SubscriptionPublicConfig({
    required this.publishableKey,
    required this.firestoreDbId,
    required this.amount,
    required this.currency,
    required this.planCode,
    required this.planName,
  });

  factory SubscriptionPublicConfig.fromMap(Map<dynamic, dynamic> data) {
    return SubscriptionPublicConfig(
      publishableKey: data['publishableKey'] as String? ?? '',
      firestoreDbId: data['firestoreDbId'] as String? ?? 'ffpvault',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'usd',
      planCode: data['planCode'] as String? ?? 'monthly_core',
      planName: data['planName'] as String? ?? 'FFP Vault Monthly',
    );
  }
}

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
