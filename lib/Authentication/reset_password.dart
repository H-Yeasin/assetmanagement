import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import 'shared_widgets.dart';
import 'login.dart';


/// Step 3 of Forgot Password: enter new password after OTP verification.
/// Receives [email] and [otp] via route extra.
class ResetPassword extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPassword({super.key, required this.email, required this.otp});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final newPassword = _newPasswordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPassword.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in both password fields');
      return;
    }
    if (newPassword != confirm) {
      _showSnack('Passwords do not match');
      return;
    }
    if (newPassword.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await AuthService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnack('Password reset successfully! Please log in.');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
          );
        }
      } else {

        _showSnack(result['message'] ?? 'Reset failed. Try again.');
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
                'Set New Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Create a strong new password for your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // New password
              AppInputFieldControlled(
                controller: _newPasswordCtrl,
                hint: 'New password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureNew,
                onToggleObscure: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),

              const SizedBox(height: 14),

              // Confirm password
              AppInputFieldControlled(
                controller: _confirmCtrl,
                hint: 'Confirm password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 36),

              // Reset button
              _loading
                  ? const SizedBox(
                      height: 54,
                      child: Center(
                        child: CircularProgressIndicator(color: brandRed),
                      ),
                    )
                  : AppPrimaryButton(
                      label: 'Reset Password',
                      onTap: _handleReset,
                    ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
