import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'shared_widgets.dart';
import 'sign_in.dart';
import 'forgot_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await AuthService.login(email: email, password: password);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String? ?? '';
        final refreshToken = data['refreshToken'] as String? ?? '';
        final userId = data['_id'] as String? ?? '';
        final userName = data['user']?['fullName'] as String? ?? 'User';
        await StorageService.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
          email: email,
          name: userName,
        );

        if (!mounted) return;
        context.go('/home');
      } else {
        _showSnack(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showSnack('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      final result = await AuthService.loginWithGoogle();
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        await StorageService.saveSession(
          accessToken: data['accessToken'] as String? ?? '',
          refreshToken: data['refreshToken'] as String? ?? '',
          userId: data['_id'] as String? ?? '',
          email: data['user']?['email'] as String? ?? '',
          name: data['user']?['fullName'] as String? ?? 'User',
          avatar: data['user']?['avatar']?['url'] as String?,
        );
        if (!mounted) return;
        context.go('/home');
      } else {
        _showSnack(result['message'] ?? 'Google login failed');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _loading = true);
    try {
      final result = await AuthService.loginWithApple();
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        await StorageService.saveSession(
          accessToken: data['accessToken'] as String? ?? '',
          refreshToken: data['refreshToken'] as String? ?? '',
          userId: data['_id'] as String? ?? '',
          email: data['user']?['email'] as String? ?? '',
          name: data['user']?['fullName'] as String? ?? 'User',
          avatar: data['user']?['avatar']?['url'] as String?,
        );
        if (!mounted) return;
        context.go('/home');
      } else {
        _showSnack(result['message'] ?? 'Apple login failed');
      }
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
          child: Column(
            children: [
              const SizedBox(height: 36),

              // Logo
              const AppLogo(),

              const SizedBox(height: 28),

              // Title
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Access your FFP Vault securely.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
              ),

              const SizedBox(height: 32),

              // Email
              AppInputFieldControlled(
                controller: _emailCtrl,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              // Password
              AppInputFieldControlled(
                controller: _passwordCtrl,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 14),

              // Remember me + Forgot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: brandRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPassword()),
                    ),
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Log in button
              _loading
                  ? const SizedBox(
                      height: 54,
                      child: Center(
                        child: CircularProgressIndicator(color: brandRed),
                      ),
                    )
                  : AppPrimaryButton(label: 'Log in', onTap: _handleLogin),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                ],
              ),

              const SizedBox(height: 20),

              // Social buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSocialButton(
                    onTap: _loading ? () {} : _handleGoogleLogin,
                    child: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 26,
                      height: 26,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 28,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AppSocialButton(
                    onTap: _loading ? () {} : _handleAppleLogin,
                    child: const Icon(
                      Icons.apple_rounded,
                      size: 28,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 14, color: Color(0xFF1E1E1E)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignIn()),
                    ),
                    child: const Text(
                      'Sign up',
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
    );
  }
}
