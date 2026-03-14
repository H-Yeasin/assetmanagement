import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../services/subscription_service.dart';
import 'payment_status_screen.dart';

class ChoosePaymentScreen extends StatefulWidget {
  const ChoosePaymentScreen({super.key});

  @override
  State<ChoosePaymentScreen> createState() => _ChoosePaymentScreenState();
}

class _ChoosePaymentScreenState extends State<ChoosePaymentScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CardEditController _cardController = CardEditController();

  int _selectedMethod = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_selectedMethod == 0) {
      await _payWithCard();
      return;
    }
    await _payWithStripeSheet();
  }

  Future<void> _payWithCard() async {
    if (_isLoading) return;

    if (!_cardController.complete) {
      _showError('Please complete your card details.');
      return;
    }

    setState(() => _isLoading = true);
    SubscriptionCheckout? checkout;
    try {
      // Ensure Stripe is configured with a valid publishable key first
      await _subscriptionService.ensureStripeConfigured(forceRefresh: true);

      checkout = await _subscriptionService.createCheckout();

      final setupIntent = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: checkout.clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: 'FFP Vault User'),
          ),
        ),
      );

      final paymentMethodId = setupIntent.paymentMethodId;
      if (paymentMethodId.isEmpty) {
        throw StateError('Payment method setup was not completed.');
      }

      await _subscriptionService.finalizePayment(
        subscriptionId: checkout.subscriptionId,
        paymentMethodId: paymentMethodId,
        setupIntentId: setupIntent.id,
      );

      if (!mounted) return;
      context.go(
        '/payment-success',
        extra: const PaymentStatusArgs(
          isSuccess: true,
          title: 'Payment Successful',
          message:
              'Welcome to the FFP Vault.\n\nYour subscription is now active and you can start organizing your finances with clarity and confidence.',
          buttonLabel: 'Open the Vault',
        ),
      );
    } on StripeException catch (e) {
      await _cleanupFailedCheckout(checkout);
      _handleStripeFailure(e);
    } on FirebaseFunctionsException catch (e) {
      await _cleanupFailedCheckout(checkout);
      _handleFunctionsFailure(e);
    } on StateError catch (e) {
      await _cleanupFailedCheckout(checkout);
      if (!mounted) return;
      context.go(
        '/payment-failed',
        extra: PaymentStatusArgs(
          isSuccess: false,
          title: 'Payment Not Available',
          message:
              e.message.contains('publishable key') ||
                  e.message.contains('not configured')
              ? 'Payment is not yet configured. Please try again later or contact support.'
              : e.message,
        ),
      );
    } catch (e) {
      await _cleanupFailedCheckout(checkout);
      _handleGenericFailure(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payWithStripeSheet() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    SubscriptionCheckout? checkout;
    try {
      // Ensure Stripe is configured with a valid publishable key first
      await _subscriptionService.ensureStripeConfigured(forceRefresh: true);

      checkout = await _subscriptionService.createCheckout();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: checkout.clientSecret,
          customerId: checkout.customerId,
          customerEphemeralKeySecret: checkout.customerEphemeralKeySecret,
          merchantDisplayName: 'Anick Giroux',
          paymentMethodOrder: const ['card'],
          returnURL: 'anickgiroux://stripe-redirect',
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      final setupIntent = await Stripe.instance.retrieveSetupIntent(
        checkout.clientSecret,
      );
      final paymentMethodId = setupIntent.paymentMethodId;
      if (paymentMethodId.isEmpty) {
        throw StateError('Payment method setup was not completed.');
      }
      await _subscriptionService.finalizePayment(
        subscriptionId: checkout.subscriptionId,
        paymentMethodId: paymentMethodId,
        setupIntentId: setupIntent.id,
      );

      if (!mounted) return;
      context.go(
        '/payment-success',
        extra: const PaymentStatusArgs(
          isSuccess: true,
          title: 'Payment Successful',
          message:
              'Welcome to the FFP Vault.\n\nYour subscription is now active and you can start organizing your finances with clarity and confidence.',
          buttonLabel: 'Open the Vault',
        ),
      );
    } on StripeException catch (e) {
      await _cleanupFailedCheckout(checkout);
      _handleStripeFailure(e);
    } on FirebaseFunctionsException catch (e) {
      await _cleanupFailedCheckout(checkout);
      _handleFunctionsFailure(e);
    } on StateError catch (e) {
      await _cleanupFailedCheckout(checkout);
      if (!mounted) return;
      context.go(
        '/payment-failed',
        extra: PaymentStatusArgs(
          isSuccess: false,
          title: 'Payment Not Available',
          message:
              e.message.contains('publishable key') ||
                  e.message.contains('not configured')
              ? 'Payment is not yet configured. Please try again later or contact support.'
              : e.message,
        ),
      );
    } catch (e) {
      await _cleanupFailedCheckout(checkout);
      _handleGenericFailure(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupFailedCheckout(SubscriptionCheckout? checkout) async {
    final subscriptionId = checkout?.subscriptionId ?? '';
    if (subscriptionId.isEmpty) return;

    try {
      await _subscriptionService.abandonCheckout(
        subscriptionId: subscriptionId,
      );
    } catch (_) {
      // Best-effort cleanup for abandoned incomplete subscriptions.
    }
  }

  void _handleStripeFailure(StripeException e) {
    if (!mounted) return;
    final cancelled = e.error.code == FailureCode.Canceled;
    context.go(
      '/payment-failed',
      extra: PaymentStatusArgs(
        isSuccess: false,
        title: cancelled ? 'Payment Cancelled' : 'Payment Failed',
        message: e.error.localizedMessage ?? 'Payment was not completed.',
      ),
    );
  }

  void _handleGenericFailure(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      StripeConfigException(:final message) => message.trim(),
      _ => error.toString().replaceFirst('Exception: ', '').trim(),
    };
    context.go(
      '/payment-failed',
      extra: PaymentStatusArgs(
        isSuccess: false,
        title: 'Payment Failed',
        message: message.isNotEmpty
            ? message
            : 'We could not verify your payment right now. Please try again.',
      ),
    );
  }

  void _handleFunctionsFailure(FirebaseFunctionsException error) {
    if (!mounted) return;

    final message = switch (error.code) {
      'already-exists' => 'This account already has an active subscription.',
      'failed-precondition' =>
        'Your payment could not be completed. Please try again.',
      'unauthenticated' => 'Please log in again before continuing.',
      _ =>
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'We could not verify your payment right now. Please try again.',
    };

    context.go(
      '/payment-failed',
      extra: PaymentStatusArgs(
        isSuccess: false,
        title: 'Payment Failed',
        message: message,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                if (GoRouter.of(context).canPop()) {
                                  GoRouter.of(context).pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                          child: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFFC61C36),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Choose Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC61C36),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PaymentMethodTile(
                      icon: Image.asset(
                        'assets/images/creditcard.png',
                        width: 32,
                        height: 32,
                        color: const Color(0xFFC61C36),
                      ),
                      title: 'Debit / Credit Card',
                      subtitle: 'Visa, Mastercard',
                      isSelected: _selectedMethod == 0,
                      onTap: () => setState(() => _selectedMethod = 0),
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodTile(
                      icon: Image.asset(
                        'assets/images/stripe.png',
                        width: 38,
                        height: 24,
                      ),
                      title: 'Stripe',
                      subtitle: 'Secure payment powered by Stripe',
                      isSelected: _selectedMethod == 1,
                      onTap: () => setState(() => _selectedMethod = 1),
                    ),
                    if (_selectedMethod == 0) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Card Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC61C36),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF283252),
                            width: 1,
                          ),
                        ),
                        child: CardField(
                          controller: _cardController,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Card Details',
                            hintStyle: const TextStyle(
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF283252),
                        ),
                      ),
                      Text(
                        _selectedMethod == 0 ? '\$6.99' : '\$6.99 / month',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF283252),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC61C36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedMethod == 0
                                      ? 'Pay \$6.99'
                                      : 'Pay Securely',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: Color(0xFF888888),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedMethod == 0
                            ? 'Your payment is encrypted and secure'
                            : 'Your payment is encrypted and verified server-side',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC61C36)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFFC61C36) : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


