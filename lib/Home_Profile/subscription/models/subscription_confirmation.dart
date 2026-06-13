/// The result returned after finalizing or cancelling a Stripe subscription.
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

/// Arguments passed to the [PaymentStatusScreen] via GoRouter extra.
class PaymentStatusArgs {
  final bool isSuccess;
  final String title;
  final String message;
  final String buttonLabel;

  const PaymentStatusArgs({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.buttonLabel = 'Done',
  });
}
