import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../services/subscription_service.dart';
import 'models/subscription_confirmation.dart';

class PaymentStatusScreen extends StatefulWidget {
  final PaymentStatusArgs args;

  const PaymentStatusScreen({super.key, required this.args});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isOpeningVault = false;

  Future<void> _handlePrimaryAction() async {
    if (!widget.args.isSuccess) {
      context.go('/home');
      return;
    }

    if (_isOpeningVault) return;

    setState(() => _isOpeningVault = true);
    try {
      await _subscriptionService.waitForActiveSubscription();
      if (!mounted) return;
      context.go('/vault');
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your plan is still finishing activation. Please try again in a moment.',
          ),
        ),
      );
      context.go('/subscription-plan');
    } catch (_) {
      if (!mounted) return;
      context.go('/subscription-plan');
    } finally {
      if (mounted) {
        setState(() => _isOpeningVault = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        widget.args.isSuccess
                            ? 'assets/images/payment_success.png'
                            : 'assets/images/payment_failed.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.args.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: widget.args.isSuccess
                              ? const Color(0xFF2E9E5B)
                              : const Color(0xFFC61C36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.args.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handlePrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC61C36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isOpeningVault
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.args.buttonLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
