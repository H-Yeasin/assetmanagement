import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';

/// Step 2 of 2FA setup: Enter the OTP sent to email.
/// Also used for the login 2FA verification flow.
///
/// Parameters via [GoRouterState.extra]:
///   - 'email' (String): The email the OTP was sent to
///   - 'flow'  (String): 'enable' | 'login'
class TwoFactorOtpScreen extends StatefulWidget {
  const TwoFactorOtpScreen({super.key});

  @override
  State<TwoFactorOtpScreen> createState() => _TwoFactorOtpScreenState();
}

class _TwoFactorOtpScreenState extends State<TwoFactorOtpScreen> {
  final List<String> _digits = List.filled(6, '');
  int _secondsLeft = 60;
  bool _isExpired = false;
  bool _isIncorrect = false;
  bool _isLoading = false;
  bool _isDialPadVisible = false;
  Timer? _timer;

  String _email = '';
  String _flow = 'enable'; // 'enable' | 'login'

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _email = extra?['email'] as String? ?? '';
    _flow = extra?['flow'] as String? ?? 'enable';
  }

  void _startTimer() {
    _secondsLeft = 60;
    _isExpired = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _isExpired = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onKeyTap(String val) {
    setState(() {
      _isIncorrect = false;
      if (val == 'X') {
        for (int i = 5; i >= 0; i--) {
          if (_digits[i].isNotEmpty) {
            _digits[i] = '';
            break;
          }
        }
      } else {
        for (int i = 0; i < 6; i++) {
          if (_digits[i].isEmpty) {
            _digits[i] = val;
            break;
          }
        }
      }
    });
  }

  Future<void> _onVerify() async {
    final code = _digits.join();
    if (code.length < 6) {
      setState(() => _isIncorrect = true);
      return;
    }
    if (_isExpired) return;

    setState(() => _isLoading = true);
    try {
      if (_flow == 'login') {
        await _handleLoginVerify(code);
      } else {
        await _handleEnableVerify(code);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEnableVerify(String code) async {
    final token = await StorageService.getAccessToken();
    if (token == null || token.isEmpty) {
      _showSnack('Session expired. Please log in again.');
      return;
    }

    final result = await AuthService.verifyTwoFactorEnable(
      otp: code,
      token: token,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final verifiedEmail = data?['email'] as String? ?? _email;
      await SecurityService.set2faEnabled(true, email: verifiedEmail);
      _showSuccessDialog(message: '2FA enabled successfully!');
    } else {
      setState(() => _isIncorrect = true);
      _showSnack(result['message'] ?? 'Invalid code. Please try again.');
    }
  }

  Future<void> _handleLoginVerify(String code) async {
    final result = await AuthService.verifyTwoFactorLogin(
      email: _email,
      otp: code,
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
        email: _email,
        name: userName,
      );
      if (!mounted) return;
      context.go('/home');
    } else {
      setState(() => _isIncorrect = true);
      _showSnack(result['message'] ?? 'Invalid code. Please try again.');
    }
  }

  Future<void> _onResend() async {
    setState(() {
      _digits.fillRange(0, 6, '');
      _isIncorrect = false;
      _isExpired = false;
    });
    _startTimer();

    try {
      if (_flow == 'enable') {
        final token = await StorageService.getAccessToken();
        if (token == null) return;
        await AuthService.requestTwoFactorEnable(email: _email, token: token);
      }
      // For 'login' flow, ask user to go back and log in again (backend sends on login)
      if (mounted) _showSnack('New verification code sent to $_email');
    } catch (_) {
      if (mounted) _showSnack('Failed to resend code.');
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

  void _showSuccessDialog({String message = 'Verification Successful'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/icon/verificaion_done_icon.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Two-Factor Authentication is now active on your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back To Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isDialPadVisible) setState(() => _isDialPadVisible = false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: brandRed,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0F2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/icon/tow_factor_icon.png',
                            width: 44,
                            height: 44,
                            color: brandRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Enter code',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: brandRed,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _email.isNotEmpty
                            ? 'We sent a 6-digit code to\n$_email'
                            : 'Please check your email for a\n6-digit verification code.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // OTP Boxes
                      GestureDetector(
                        onTap: () => setState(() => _isDialPadVisible = true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (i) {
                              final bool hasValue = _digits[i].isNotEmpty;
                              return Container(
                                width: 48,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: (_isIncorrect || _isExpired)
                                        ? brandRed
                                        : hasValue
                                        ? brandRed
                                        : const Color(0xFFDDDDDD),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _digits[i],
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: hasValue
                                        ? brandRed
                                        : const Color(0xFF111111),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Error / Expired message
                      if (_isExpired)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Code expired. Tap Resend to get a new one.',
                              style: TextStyle(
                                fontSize: 13,
                                color: brandRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else if (_isIncorrect)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Incorrect code. Please try again.',
                              style: TextStyle(
                                fontSize: 13,
                                color: brandRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Resend row
                      _isExpired
                          ? GestureDetector(
                              onTap: _onResend,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: brandRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Text(
                              'Resend code in ${_secondsLeft}s',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                              ),
                            ),
                      const SizedBox(height: 20),

                      // Verify button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_isExpired || _isLoading)
                                ? null
                                : _onVerify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandRed,
                              disabledBackgroundColor: brandRed.withValues(
                                alpha: 0.5,
                              ),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Custom Numpad
              if (_isDialPadVisible)
                Container(
                  color: brandRed,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: 24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      for (final row in [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: row.map((key) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _onKeyTap(key),
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        key,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: GestureDetector(
                                onTap: () => _onKeyTap('0'),
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: GestureDetector(
                                onTap: () => _onKeyTap('X'),
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.backspace_outlined,
                                    color: brandRed,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
