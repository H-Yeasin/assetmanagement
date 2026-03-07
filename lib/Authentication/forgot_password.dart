import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'shared_widgets.dart';

/// Enter email and send password reset OTP.
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email address');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await AuthService.forgotPassword(email: email);
      if (!mounted) return;

      if (result['success'] == true) {
        context.push('/verify-otp', extra: {'email': email, 'flow': 'forgot'});
      } else {
        _showSnack(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showSnack('Failed to send OTP');
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
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Logo
              const AppLogo(),

              const SizedBox(height: 28),

              // Title
              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Enter the email address associated with your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // Email input
              AppInputFieldControlled(
                controller: _emailCtrl,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 36),

              // Send OTP button
              _loading
                  ? const SizedBox(
                      height: 54,
                      child: Center(
                        child: CircularProgressIndicator(color: brandRed),
                      ),
                    )
                  : AppPrimaryButton(label: 'Send OTP', onTap: _handleSendOtp),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
