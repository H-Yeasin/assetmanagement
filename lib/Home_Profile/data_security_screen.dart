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
      await context.push('/fingerprint');
      await _loadSecurityState();
    } else {
      // Disabling biometric requires biometric verification.
      final ok = await BiometricService.authenticate(
        reason:
            'Verify your ${_biometricLabel.toLowerCase()} to disable biometric unlock',
        biometricOnly: true,
      );
      if (!ok) {
        _showSnack(
          'Could not verify ${_biometricLabel.toLowerCase()}. Biometric unlock is still enabled.',
        );
        return;
      }
      await SecurityService.setBiometricEnabled(false);
      setState(() => _fingerprintEnabled = false);
      _showSnack('$_biometricLabel unlock disabled.');
    }
  }

  // ── PIN toggle handler ─────────────────────────────────────────────────────
  Future<void> _onPinToggle(bool val) async {
    if (val) {
      // Navigate to PIN setup
      await context.push('/set-pin');
      await _loadSecurityState();
    } else {
      // Disable PIN only after verifying current PIN.
      final confirmed = await _verifyAndDisablePinDialog();
      if (confirmed == true) {
        await SecurityService.clearPin();
        setState(() => _pinEnabled = false);
        _showSnack('PIN lock disabled.');
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

  Future<bool?> _verifyAndDisablePinDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String pin = '';
        String? errorText;
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Disable PIN?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your current PIN to disable Vault PIN lock.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? brandRed : const Color(0xFFDDDDDD),
                      ),
                    );
                  }),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PinPadButton(
                      label: '1',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '1';
                        errorText = null;
                      }),
                    ),
                    _PinPadButton(
                      label: '2',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '2';
                        errorText = null;
                      }),
                    ),
                    _PinPadButton(
                      label: '3',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '3';
                        errorText = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PinPadButton(
                      label: '4',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '4';
                        errorText = null;
                      }),
                    ),
                    _PinPadButton(
                      label: '5',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '5';
                        errorText = null;
                      }),
                    ),
                    _PinPadButton(
                      label: '6',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '6';
                        errorText = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PinPadButton(
                      label: '7',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '7';
                        errorText = null;
                      }),
                    ),
                    _PinPadButton(
                      label: '8',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '8';
                        errorText = null;
                      }),
                    ),
                    _PinPadButton(
                      label: '9',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '9';
                        errorText = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const _PinPadEmpty(),
                    _PinPadButton(
                      label: '0',
                      onTap: () => setDialogState(() {
                        if (pin.length < 4) pin += '0';
                        errorText = null;
                      }),
                    ),
                    _PinPadDelete(
                      onTap: () => setDialogState(() {
                        if (pin.isNotEmpty) {
                          pin = pin.substring(0, pin.length - 1);
                        }
                        errorText = null;
                      }),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (!isVerifying)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                ),
              TextButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        if (pin.length != 4) {
                          setDialogState(() {
                            errorText = 'Enter valid 4-digit PIN';
                          });
                          return;
                        }

                        setDialogState(() {
                          isVerifying = true;
                          errorText = null;
                        });

                        final ok = await SecurityService.verifyPin(pin);
                        if (!context.mounted) return;

                        if (ok) {
                          Navigator.pop(ctx, true);
                          return;
                        }

                        setDialogState(() {
                          isVerifying = false;
                          errorText = 'Incorrect PIN';
                        });
                      },
                child: isVerifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Disable',
                        style: TextStyle(
                          color: brandRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
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

class _PinPadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinPadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 62,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(21),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}

class _PinPadDelete extends StatelessWidget {
  final VoidCallback onTap;

  const _PinPadDelete({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 62,
        height: 42,
        child: Center(
          child: Icon(Icons.backspace_outlined, size: 22, color: Colors.black),
        ),
      ),
    );
  }
}

class _PinPadEmpty extends StatelessWidget {
  const _PinPadEmpty();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 62, height: 42);
  }
}
