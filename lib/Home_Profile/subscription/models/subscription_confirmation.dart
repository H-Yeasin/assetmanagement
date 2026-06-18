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
