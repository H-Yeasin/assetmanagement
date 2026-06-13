import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the user's subscription state synced from Firestore.
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
  final DateTime? trialEndDate;

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
    this.trialEndDate,
  });

  /// Default inactive state used as a fallback when no subscription data exists.
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
    trialEndDate: null,
  );

  /// Whether the user has an active paid subscription.
  /// Includes `active`, `past_due`, and `trialing` with a Stripe subscription ID.
  bool get isSubscribed {
    return status == 'active' ||
        status == 'past_due' ||
        (status == 'trialing' && stripeSubscriptionId.isNotEmpty);
  }

  /// Whether the user is in the 14-day free trial (no payment method entered yet).
  bool get isFreeTrialActive {
    if (status == 'trialing' && stripeSubscriptionId.isEmpty) {
      if (trialEndDate != null) {
        return trialEndDate!.isAfter(DateTime.now());
      }
      return true;
    }
    return false;
  }

  /// Whether the user can access the vault (either subscribed or in free trial).
  bool get isActive => isSubscribed || isFreeTrialActive;

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
      trialEndDate: parseDate(data['trialEndDate']),
    );
  }
}

/// Public configuration for Stripe, fetched from the cloud function.
///
/// Contains the publishable key and plan metadata needed by the client.
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
