import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'shared_widgets.dart';
import 'login.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agreeToTerms = false;
  bool _obscureCreate = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_agreeToTerms) {
      _showSnack('Please agree to the terms to continue');
      return;
    }
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await AuthService.register(
        fullName: name,
        email: email,
        password: password,
        confirmPassword: confirm,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final userEmail = data['user']?['email'] as String? ?? email;

        // Send OTP to the user's email for verification
        final otpResult = await AuthService.requestRegisterOtp(email: userEmail);

        if (!mounted) return;

        if (otpResult['success'] == true) {
          context.push('/verify-otp', extra: {
            'email': userEmail,
            'flow': 'register',
          });
        } else {
          _showSnack(otpResult['message'] ?? 'Failed to send verification code. Please try logging in.');
          // Log out so user can attempt login (account was created but OTP failed)
          await AuthService.logout();
          await StorageService.clearSession();
        }
      } else {
        _showSnack(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showSnack('Registration failed. Please try again.');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 36),

                // Logo
                const AppLogo(),

                const SizedBox(height: 28),

                // Title
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                    children: [
                      TextSpan(text: 'Create your '),
                      TextSpan(
                        text: 'FFP',
                        style: TextStyle(color: brandRed),
                      ),
                      TextSpan(text: ' Vault'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF888888)),
                    children: [
                      TextSpan(
                        text:
                            'Protect your documents, set reminders, and stay in control ',
                      ),
                      TextSpan(
                        text: 'Securely.',
                        style: TextStyle(
                          color: brandRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Fields
                AppInputFieldControlled(
                  controller: _nameCtrl,
                  hint: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                AppInputFieldControlled(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AppInputFieldControlled(
                  controller: _passwordCtrl,
                  hint: 'Create password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureCreate,
                  onToggleObscure: () =>
                      setState(() => _obscureCreate = !_obscureCreate),
                ),
                const SizedBox(height: 14),
                AppInputFieldControlled(
                  controller: _confirmCtrl,
                  hint: 'Confirm password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),

                const SizedBox(height: 18),

                // Agreement checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (v) =>
                            setState(() => _agreeToTerms = v ?? false),
                        activeColor: brandRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'By using this app, you agree to follow all guidelines, use the content responsibly, and accept any future updates to our policies.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF888888),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Sign Up button
                _loading
                    ? const SizedBox(
                        height: 54,
                        child: Center(
                          child: CircularProgressIndicator(color: brandRed),
                        ),
                      )
                    : AppPrimaryButton(
                        label: 'Sign Up',
                        onTap: _handleRegister,
                      ),

                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E1E1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                      ),
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 14,
                          color: brandRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
