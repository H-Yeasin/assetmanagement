import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FingerprintSuccessScreen extends StatefulWidget {
  const FingerprintSuccessScreen({super.key});

  @override
  State<FingerprintSuccessScreen> createState() =>
      _FingerprintSuccessScreenState();
}

class _FingerprintSuccessScreenState extends State<FingerprintSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Auto navigate back to profile after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/data-security');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success badge icon
              Image.asset(
                'assets/images/icon/verificaion_done_icon.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'FingerPrint Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'You have successfully verified\nyour Fingerprint',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
