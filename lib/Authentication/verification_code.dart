import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'shared_widgets.dart';

/// Universal OTP verification screen.
/// Receives [email] and [flow] via route extra.
/// flow = 'register'  → verifyEmailOtp → save session → /home
/// flow = 'forgot'    → navigate to /reset-password (email + otp)
/// flow = 'twofactor' → (handled by existing two_factor_otp_screen)
class VerificationCodeScreen extends StatefulWidget {
  final String email;
  final String flow; // 'register' | 'forgot'

  const VerificationCodeScreen({
    super.key,
    required this.email,
    required this.flow,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  int _resendSeconds = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onKeyTap(String value) {
    for (int i = 0; i < 6; i++) {
      if (_controllers[i].text.isEmpty) {
        setState(() => _controllers[i].text = value);
        if (i < 5) FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        break;
      }
    }
  }

  void _onBackspace() {
    for (int i = 5; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        setState(() => _controllers[i].text = '');
        if (i > 0) FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
        break;
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otp;
    if (otp.length < 6) {
      _showSnack('Please enter the full 6-digit code');
      return;
    }

    setState(() => _loading = true);
    try {
      if (widget.flow == 'forgot') {
        final result = await AuthService.verifyPasswordResetOtp(
          email: widget.email,
          otp: otp,
        );
        if (!mounted) return;
        if (result['success'] == true) {
          context.push(
            '/reset-password',
            extra: {'email': widget.email, 'otp': otp},
          );
        } else {
          _showSnack(result['message'] ?? 'Invalid OTP');
        }
        return;
      }

      if (widget.flow == 'twofactor') {
        // Login 2FA – verify OTP and save session
        final result = await AuthService.verifyTwoFactorLogin(
          email: widget.email,
          otp: otp,
        );
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
            email: widget.email,
            name: userName,
          );
          if (!mounted) return;
          context.go('/home');
        } else {
          _showSnack(result['message'] ?? 'Invalid code. Please try again.');
        }
        return;
      }

      // flow == 'register' → verify email OTP
      final result = await AuthService.verifyEmailOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // User is already authenticated from registration.
        // Get fresh token and save session.
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          final token = user.refreshToken;
          await StorageService.saveSession(
            accessToken: idToken ?? '',
            refreshToken: token ?? '',
            userId: user.uid,
            email: user.email ?? widget.email,
            name: user.displayName ?? 'User',
          );
        }
        if (!mounted) return;
        context.go('/home');
      } else {
        _showSnack(result['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showSnack('Network error. Is the backend running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0) return;
    try {
      if (widget.flow == 'forgot') {
        await AuthService.forgotPassword(email: widget.email);
      } else if (widget.flow == 'register') {
        await AuthService.requestRegisterOtp(email: widget.email);
      }
      _showSnack('OTP resent to ${widget.email}');
      _startCountdown();
    } catch (_) {
      _showSnack('Failed to resend OTP');
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const AppLogo(),
                  const SizedBox(height: 28),
                  const Text(
                    'Enter Verification Code',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We've sent a 6-digit code to ${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // OTP Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 56,
                          constraints: const BoxConstraints(maxWidth: 48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _controllers[index].text.isNotEmpty
                                  ? brandRed
                                  : const Color(0xFFC61C36),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _controllers[index].text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Resend countdown / button
                  GestureDetector(
                    onTap: _resendSeconds == 0 ? _handleResend : null,
                    child: Text(
                      _resendSeconds > 0
                          ? 'Resend code in ${_resendSeconds}s'
                          : 'Resend code',
                      style: TextStyle(
                        fontSize: 14,
                        color: _resendSeconds > 0
                            ? const Color(0xFF888888)
                            : brandRed,
                        fontWeight: _resendSeconds == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  _loading
                      ? const SizedBox(
                          height: 54,
                          child: Center(
                            child: CircularProgressIndicator(color: brandRed),
                          ),
                        )
                      : AppPrimaryButton(label: 'Verify', onTap: _handleVerify),
                ],
              ),
            ),
          ),

          // Custom Keypad
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: brandRed,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _buildKeyRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _buildKeyRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_buildKey('0'), _buildBackspaceKey()],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          onTap: () => _onKeyTap(value),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          onTap: _onBackspace,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 24),
          ),
        ),
      ),
    );
  }
}
