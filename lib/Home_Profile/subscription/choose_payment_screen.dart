import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  int _selectedMethod = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
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

    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if (cardNumber.isEmpty || expiry.isEmpty || cvv.isEmpty) {
      _showError('Please complete all card details.');
      return;
    }

    final expiryParts = expiry.split('/');
    if (expiryParts.length != 2) {
      _showError('Expiry date must be in MM/YY format.');
      return;
    }

    final expMonth = int.tryParse(expiryParts[0]) ?? 0;
    final expYear = int.tryParse('20${expiryParts[1]}') ?? 0;
    if (expMonth < 1 || expMonth > 12 || expYear < DateTime.now().year) {
      _showError('Enter a valid expiry date.');
      return;
    }

    setState(() => _isLoading = true);
    SubscriptionCheckout? checkout;
    try {
      // Ensure Stripe is configured with a valid publishable key first
      await _subscriptionService.ensureStripeConfigured(forceRefresh: true);

      checkout = await _subscriptionService.createCheckout();

      await Stripe.instance.dangerouslyUpdateCardDetails(
        CardDetails(
          number: cardNumber,
          expirationMonth: expMonth,
          expirationYear: expYear,
          cvc: cvv,
        ),
      );

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
                          onTap: _isLoading ? null : () => context.pop(),
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
                        'Card Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC61C36),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Card Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CardInputField(
                        controller: _cardNumberController,
                        hintText: '0000 0000 0000 0000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CardNumberFormatter(),
                        ],
                        maxLength: 19,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/creditcard.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Expiry Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'CVC',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _CardInputField(
                              controller: _expiryController,
                              hintText: 'MM/YY',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _ExpiryDateFormatter(),
                              ],
                              maxLength: 5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CardInputField(
                              controller: _cvvController,
                              hintText: '123',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              maxLength: 4,
                            ),
                          ),
                        ],
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

class _CardInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? suffixIcon;

  const _CardInputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
        counterText: '',
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF283252), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF283252), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
