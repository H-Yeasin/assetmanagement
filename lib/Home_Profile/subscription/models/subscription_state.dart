import 'package:cloud_firestore/cloud_firestore.dart';

/// The subscription provider — either Stripe or RevenueCat.
enum SubscriptionProvider { stripe, revenuecat }

/// Represents the user's subscription state synced from Firestore.
///
/// Provider-agnostic: works with both Stripe and RevenueCat data shapes.
class SubscriptionState {
  // ── Plan metadata ────────────────────────────────────────────────────────
  final String planCode;
  final String planName;
  final int amount;
  final String currency;

  // ── Status ───────────────────────────────────────────────────────────────
  /// `active` | `trialing` | `past_due` | `expired` | `canceled` | `inactive`
  final String status;

  // ── Provider identity ────────────────────────────────────────────────────
  final SubscriptionProvider provider;
  final String providerCustomerId;
  final String providerSubscriptionId;

  // ── Flags ────────────────────────────────────────────────────────────────
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndDate;

  const SubscriptionState({
    required this.planCode,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.providerCustomerId,
    required this.providerSubscriptionId,
    required this.cancelAtPeriodEnd,
    required this.currentPeriodEnd,
    this.trialEndDate,
  });

  // ── Backward-compatible convenience getters ──────────────────────────────
  String get stripeCustomerId =>
      provider == SubscriptionProvider.stripe ? providerCustomerId : '';
  String get stripeSubscriptionId =>
      provider == SubscriptionProvider.stripe ? providerSubscriptionId : '';

  /// Default inactive state used as a fallback when no subscription data exists.
  static const inactive = SubscriptionState(
    planCode: '',
    planName: '',
    amount: 0,
    currency: 'usd',
    status: 'inactive',
    provider: SubscriptionProvider.revenuecat,
    providerCustomerId: '',
    providerSubscriptionId: '',
    cancelAtPeriodEnd: false,
    currentPeriodEnd: null,
    trialEndDate: null,
  );

  // ── Getters the app depends on ───────────────────────────────────────────

  /// Whether the user has an active paid subscription.
  bool get isSubscribed {
    return status == 'active' ||
        status == 'past_due' ||
        (status == 'trialing' && providerSubscriptionId.isNotEmpty);
  }

  /// Whether the user is in the 14-day free trial (no payment method entered yet).
  bool get isFreeTrialActive {
    if (status == 'trialing' && providerSubscriptionId.isEmpty) {
      if (trialEndDate != null) {
        return trialEndDate!.isAfter(DateTime.now());
      }
      return true;
    }
    return false;
  }

  /// Whether the user can access the vault (either subscribed or in free trial).
  bool get isActive => isSubscribed || isFreeTrialActive;

  // ── Firestore factory ────────────────────────────────────────────────────

  factory SubscriptionState.fromMap(Map<String, dynamic>? data) {
    if (data == null) return inactive;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Detect provider from Firestore data.
    final providerRaw = data['provider'] as String? ?? 'revenuecat';
    final provider = providerRaw == 'revenuecat'
        ? SubscriptionProvider.revenuecat
        : SubscriptionProvider.stripe;

    // Resolve provider-specific IDs.
    final providerCustomerId = provider == SubscriptionProvider.revenuecat
        ? (data['rcCustomerId'] as String? ?? '')
        : (data['stripeCustomerId'] as String? ?? '');
    final providerSubscriptionId = provider == SubscriptionProvider.revenuecat
        ? (data['rcEntitlementId'] as String? ?? '')
        : (data['stripeSubscriptionId'] as String? ?? '');

    return SubscriptionState(
      planCode: data['planCode'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'usd',
      status: data['status'] as String? ?? 'inactive',
      provider: provider,
      providerCustomerId: providerCustomerId,
      providerSubscriptionId: providerSubscriptionId,
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] == true,
      currentPeriodEnd: parseDate(data['currentPeriodEnd']),
      trialEndDate: parseDate(data['trialEndDate']),
    );
  }

  // ── RevenueCat factory (used post-purchase for immediate state) ──────────

  /// Builds a subscription state from RevenueCat [CustomerInfo].
  ///
  /// This is a convenience for the short window between purchase and webhook
  /// sync — the canonical state always lives in Firestore.
  factory SubscriptionState.fromRevenueCat(Map<String, dynamic> rcData) {
    final isActive = rcData['isActive'] == true;
    final entitlementId = rcData['entitlementId'] as String? ?? '';

    return SubscriptionState(
      planCode: rcData['productId'] as String? ?? '',
      planName: 'FFP Vault Pro',
      amount: 699,
      currency: 'usd',
      status: isActive ? 'active' : 'inactive',
      provider: SubscriptionProvider.revenuecat,
      providerCustomerId: rcData['appUserId'] as String? ?? '',
      providerSubscriptionId: entitlementId,
      cancelAtPeriodEnd: rcData['willRenew'] == false,
      currentPeriodEnd: rcData['expirationDate'] is DateTime
          ? rcData['expirationDate'] as DateTime
          : null,
      trialEndDate: null,
    );
  }
}

/// Provider-agnostic public config for the subscription plan.
///
/// When using RevenueCat, the publishable key is not used — plan metadata
/// comes from the RevenueCat offering.
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
      planName: data['planName'] as String? ?? 'FFP Vault Pro',
    );
  }
}
