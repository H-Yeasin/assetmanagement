import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../services/revenuecat_service.dart';
import 'models/subscription_confirmation.dart';

/// Custom-branded purchase screen.
///
/// Shows the plan info and a "Subscribe" button that triggers a
/// RevenueCat purchase. The native platform purchase sheet (Apple / Google)
/// handles all payment UI — no Stripe card fields needed.
class ChoosePaymentScreen extends StatefulWidget {
  const ChoosePaymentScreen({super.key});

  @override
  State<ChoosePaymentScreen> createState() => _ChoosePaymentScreenState();
}

class _ChoosePaymentScreenState extends State<ChoosePaymentScreen> {
  final RevenueCatService _rcService = RevenueCatService();

  bool _isLoading = false;
  Package? _monthlyPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final package = await _rcService.getMonthlyPackage();
    if (!mounted) return;
    setState(() {
      _monthlyPackage = package;
    });
  }

  Future<void> _purchase() async {
    if (_isLoading) return;

    final package = _monthlyPackage;
    if (package == null) {
      _showError('Subscription is not available right now. Please try again later.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _rcService.purchase(package);

      if (!mounted) return;
      context.go(
        '/payment-success',
        extra: const PaymentStatusArgs(
          isSuccess: true,
          title: 'Subscription Active',
          message:
              'Welcome to the FFP Vault.\n\nYour subscription is now active and you can start organizing your finances with clarity and confidence.',
          buttonLabel: 'Open the Vault',
        ),
      );
    } on PlatformException catch (e) {
      // `userCancelled` → user dismissed the native purchase dialog.
      final cancelled = e.details is Map &&
          (e.details as Map)['userCancelled'] == true;

      if (!mounted) return;

      if (cancelled) {
        // Just go back — no error message needed.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/subscription-plan');
        }
        return;
      }

      context.go(
        '/payment-failed',
        extra: PaymentStatusArgs(
          isSuccess: false,
          title: 'Payment Not Completed',
          message:
              e.message?.isNotEmpty == true
                  ? e.message!
                  : 'We could not complete your payment. Please try again.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.go(
        '/payment-failed',
        extra: const PaymentStatusArgs(
          isSuccess: false,
          title: 'Payment Failed',
          message:
              'We could not complete your payment. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packagePrice =
        _monthlyPackage?.storeProduct.priceString ?? '\$6.99';

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
                          'Subscribe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC61C36),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Plan card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFC61C36),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/shield_icon.png',
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'FFP Vault Pro',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: packagePrice,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFC61C36),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' / month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '14-day free trial included',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E9E5B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Features
                    const _FeatureRow(text: 'Centralized Payment Tracking'),
                    const SizedBox(height: 12),
                    const _FeatureRow(text: 'Smart Reminders'),
                    const SizedBox(height: 12),
                    const _FeatureRow(text: 'Secure Document Vault'),
                    const SizedBox(height: 12),
                    const _FeatureRow(text: 'Clear Timelines'),
                    const SizedBox(height: 12),
                    const _FeatureRow(text: 'Mobile First Access'),
                  ],
                ),
              ),
            ),
            // Bottom bar
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
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC61C36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Subscribe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
                      const Text(
                        'Payment processed securely via App Store',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Recurring billing. No commitment. Cancel anytime.\nBy continuing, you agree to our Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      height: 1.5,
                    ),
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

class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFC61C36),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
