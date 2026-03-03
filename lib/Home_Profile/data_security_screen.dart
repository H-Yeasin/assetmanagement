import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';

class DataSecurityScreen extends StatefulWidget {
  const DataSecurityScreen({super.key});

  @override
  State<DataSecurityScreen> createState() => _DataSecurityScreenState();
}

class _DataSecurityScreenState extends State<DataSecurityScreen> {
  bool _fingerprintEnabled = false;
  bool _pinEnabled = false;
  bool _biometricSupported = false;
  String? _biometricUnavailableReason;
  String _biometricLabel = 'Fingerprint';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh state whenever we come back to this screen
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final results = await Future.wait([
      SecurityService.isBiometricEnabled(),
      SecurityService.isPinSet(),
      BiometricService.unavailableReason(),
      BiometricService.biometricLabel(),
    ]);
    if (!mounted) return;
    setState(() {
      _fingerprintEnabled = results[0] as bool;
      _pinEnabled = results[1] as bool;
      _biometricUnavailableReason = results[2] as String?;
      _biometricLabel = results[3] as String;
      _biometricSupported = _biometricUnavailableReason == null;
      _isLoading = false;
    });
  }

  // ── Fingerprint toggle handler ─────────────────────────────────────────────
  Future<void> _onFingerprintToggle(bool val) async {
    if (val) {
      // Enabling: check support first
      if (!_biometricSupported) {
        _showBiometricUnavailableDialog();
        return;
      }
      // Navigate to fingerprint setup screen
      context.push('/fingerprint');
    } else {
      // Disabling biometric
      await SecurityService.setBiometricEnabled(false);
      setState(() => _fingerprintEnabled = false);
    }
  }

  // ── PIN toggle handler ─────────────────────────────────────────────────────
  Future<void> _onPinToggle(bool val) async {
    if (val) {
      // Navigate to PIN setup
      context.push('/set-pin');
    } else {
      // Confirm disable
      final confirmed = await _showDisablePinDialog();
      if (confirmed == true) {
        await SecurityService.clearPin();
        setState(() => _pinEnabled = false);
      }
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showBiometricUnavailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFAA00),
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Biometrics Unavailable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          _biometricUnavailableReason ??
              'Biometrics are not available on this device.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF555555),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: brandRed)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDisablePinDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Disable PIN?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Your PIN will be removed and the Vault will no longer require it for access.',
          style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Disable',
              style: TextStyle(color: brandRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
            size: 18,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Setup Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: brandRed))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Red title ──────────────────────────────────
                          const Text(
                            'Secure Your Vault',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: brandRed,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Choose how you'd like to protect your data\nand personal finance details.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Fingerprint Card ───────────────────────────
                          _SecurityOptionCard(
                            iconPath:
                                'assets/images/icon/fringerprint_icon.png',
                            title: _biometricLabel,
                            subtitle: _biometricSupported
                                ? 'Unlock quickly using\nyour biometric data.'
                                : 'Not available on this device.',
                            value: _fingerprintEnabled,
                            enabled: _biometricSupported,
                            onChanged: _onFingerprintToggle,
                          ),
                          const SizedBox(height: 16),

                          // ── PIN Code Card ──────────────────────────────
                          _SecurityOptionCard(
                            iconPath: 'assets/images/icon/pincode_icon.png',
                            title: 'PIN Code',
                            subtitle:
                                'Set a secure 4-digit\ncode for manual entry.',
                            value: _pinEnabled,
                            enabled: true,
                            onChanged: _onPinToggle,
                          ),
                          const SizedBox(height: 32),

                          // ── Status summary ─────────────────────────────
                          if (_fingerprintEnabled || _pinEnabled)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _fingerprintEnabled && _pinEnabled
                                          ? 'Vault is protected by $_biometricLabel and PIN.'
                                          : _fingerprintEnabled
                                          ? 'Vault is protected by $_biometricLabel.'
                                          : 'Vault is protected by PIN.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2E7D32),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                'Enable at least one security option above.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  height: 1.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Continue button ────────────────────────────────────
                  Container(
                    color: const Color(0xFFF8F6F6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (GoRouter.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go('/profile');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Security Option Card ──────────────────────────────────────────────────────
class _SecurityOptionCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SecurityOptionCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Large icon box
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFCECEE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Image.asset(
                  iconPath,
                  width: 36,
                  height: 36,
                  color: enabled ? null : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle
            Switch(
              value: value && enabled,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.white,
              activeTrackColor: brandRed,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFDDDDDD),
            ),
          ],
        ),
      ),
    );
  }
}
