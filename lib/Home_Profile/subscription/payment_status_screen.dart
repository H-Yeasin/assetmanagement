import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentStatusScreen extends StatelessWidget {
  final bool isSuccess;

  const PaymentStatusScreen({super.key, this.isSuccess = true});

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
                      // Status icon
                      Image.asset(
                        isSuccess
                            ? 'assets/images/payment_success.png'
                            : 'assets/images/payment_failed.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 32),
                      // Title
                      Text(
                        isSuccess ? 'Payment Successful' : 'Payment Failed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isSuccess
                              ? const Color(0xFF2E9E5B)
                              : const Color(0xFFC61C36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      Text(
                        isSuccess
                            ? 'Your job is now live and visible to our\ncreative community'
                            : 'Something went wrong with your payment.\nPlease try again.',
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
            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC61C36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
