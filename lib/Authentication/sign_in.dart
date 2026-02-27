import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shared_widgets.dart';
import 'login.dart';



class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _obscureCreate = true;
  bool _obscureConfirm = true;

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
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF888888),
                    ),
                    children: [
                      TextSpan(
                          text:
                              'Protect your documents, set reminders, and stay in control '),
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
                const AppInputField(
                  hint: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                const AppInputField(
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AppInputField(
                  hint: 'Create password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureCreate,
                  onToggleObscure: () =>
                      setState(() => _obscureCreate = !_obscureCreate),
                ),
                const SizedBox(height: 14),
                AppInputField(
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

                // Sign in button
                AppPrimaryButton(
                  label: 'Sign In',
                  onTap: () {
                    context.go('/home');
                  },
                ),

                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
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