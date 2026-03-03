import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Step 1 of 2FA setup in profile:
/// User enters (or confirms) the email that will receive the OTP.
class TwoFactorEmailScreen extends StatefulWidget {
  const TwoFactorEmailScreen({super.key});

  @override
  State<TwoFactorEmailScreen> createState() => _TwoFactorEmailScreenState();
}

class _TwoFactorEmailScreenState extends State<TwoFactorEmailScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _prefillEmail();
  }

  Future<void> _prefillEmail() async {
    final stored = await StorageService.getUserEmail();
    if (stored != null && mounted) {
      _emailController.text = stored;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address');
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        _showSnack('Session expired. Please log in again.');
        return;
      }

      final result = await AuthService.requestTwoFactorEnable(
        email: email,
        token: token,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Navigate to OTP verification screen, passing the email
        context.push(
          '/two-factor-otp',
          extra: {'email': email, 'flow': 'enable'},
        );
      } else {
        _showSnack(
          result['message'] ?? 'Failed to send code. Please try again.',
        );
      }
    } catch (e) {
      _showSnack('Network error. Is the backend running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 22,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Two-Factor Authentication',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandRed.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: brandRed, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'A 6-digit verification code will be sent to this email each time you log in.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
                decoration: InputDecoration(
                  hintText: 'Enter your Gmail address',
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF888888),
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF888888),
                    size: 20,
                  ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDDDDD),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDDDDD),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandRed, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We recommend using your Gmail account for reliable delivery.',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    disabledBackgroundColor: brandRed.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Send Verification Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
