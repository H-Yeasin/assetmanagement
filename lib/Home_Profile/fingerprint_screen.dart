import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';

/// Fingerprint / Biometric setup screen.
/// Checks device support before letting the user enable biometric unlock.
class FingerprintScreen extends StatefulWidget {
  const FingerprintScreen({super.key});

  @override
  State<FingerprintScreen> createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends State<FingerprintScreen> {
  bool _isChecking = true;
  String? _unavailableReason; // null = available, non-null = disabled reason
  String _biometricLabel = 'Fingerprint';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    final reason = await BiometricService.unavailableReason();
    final label = await BiometricService.biometricLabel();

    if (mounted) {
      setState(() {
        _unavailableReason = reason;
        _biometricLabel = label;
        _isChecking = false;
      });
    }
  }

  Future<void> _onVerify() async {
    if (_unavailableReason != null || _isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    final success = await BiometricService.authenticate(
      reason:
          'Confirm your ${_biometricLabel.toLowerCase()} to enable biometric unlock',
    );

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      await SecurityService.setBiometricEnabled(true);
      if (mounted) context.pushReplacement('/fingerprint-success');
    } else {
      _showSnack('$_biometricLabel authentication failed. Please try again.');
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
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
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
          'Fingerprint Setup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isChecking
            ? const Center(child: CircularProgressIndicator(color: brandRed))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_unavailableReason != null) {
      return _buildUnavailableState();
    }
    return _buildAvailableState();
  }

  /// Shown when biometrics are not available on the device.
  Widget _buildUnavailableState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          const Text(
            'Fingerprint Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Large fingerprint icon – greyed out
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFFBBBBBB),
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/icon/fringerprint_icon.png',
              width: 140,
              height: 190,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 32),

          // Warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC02), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFAA00),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biometrics Unavailable',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _unavailableReason!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'You can use PIN authentication instead for secure Vault access.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              height: 1.5,
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: brandRed,
                side: const BorderSide(color: brandRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Shown when biometrics are available.
  Widget _buildAvailableState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Text(
            '$_biometricLabel Verification',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your fingerprint is stored securely on\nyour device and is never shared.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF888888),
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),

          // Fingerprint icon with pulse effect
          _isAuthenticating
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.08),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Image.asset(
                    'assets/images/icon/fringerprint_icon.png',
                    width: 140,
                    height: 190,
                    color: brandRed,
                    fit: BoxFit.contain,
                  ),
                )
              : Image.asset(
                  'assets/images/icon/fringerprint_icon.png',
                  width: 140,
                  height: 190,
                  fit: BoxFit.contain,
                ),

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isAuthenticating ? null : _onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                disabledBackgroundColor: brandRed.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAuthenticating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Verify My $_biometricLabel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
