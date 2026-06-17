/// The checkout payload returned from `createStripePaymentIntent`.
///
/// Contains everything the client needs to run the Stripe payment sheet or
/// card field and then finalize the subscription.
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
      planName: data['planName'] as String? ?? 'FFP Vault Pro',
    );
  }
}
