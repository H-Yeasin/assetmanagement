import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Home_Dashboard/widgets.dart';
import '../services/biometric_service.dart';
import '../services/security_service.dart';

class VaultAccessSession {
  static bool _isUnlocked = false;

  static bool get isUnlocked => _isUnlocked;

  static void unlock() {
    _isUnlocked = true;
  }

  static void reset() {
    _isUnlocked = false;
  }
}

class VaultAccessGate extends StatefulWidget {
  final Widget child;

  const VaultAccessGate({super.key, required this.child});

  @override
  State<VaultAccessGate> createState() => _VaultAccessGateState();
}

class _VaultAccessGateState extends State<VaultAccessGate> {
  bool _authorized = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authorize());
  }

  Future<void> _authorize() async {
    if (VaultAccessSession.isUnlocked) {
      setState(() {
        _authorized = true;
        _isChecking = false;
      });
      return;
    }

    final router = GoRouter.of(context);
    final biometricEnabled = await SecurityService.isBiometricEnabled();
    final pinEnabled = await SecurityService.isPinSet();

    if (!mounted) return;

    if (!biometricEnabled && !pinEnabled) {
      VaultAccessSession.unlock();
      setState(() {
        _authorized = true;
        _isChecking = false;
      });
      return;
    }

    if (biometricEnabled) {
      final reason = await BiometricService.unavailableReason();
      if (reason == null) {
        final success = await BiometricService.authenticate(
          reason: 'Authenticate to open your FFP Vault',
        );
        if (!mounted) return;
        if (success) {
          VaultAccessSession.unlock();
          setState(() {
            _authorized = true;
            _isChecking = false;
          });
          return;
        }
      }
    }

    if (pinEnabled) {
      setState(() => _isChecking = false);
      final result = await router.push<bool>('/pin-verify');
      if (!mounted) return;
      if (result == true) {
        VaultAccessSession.unlock();
        setState(() => _authorized = true);
      } else {
        VaultAccessSession.reset();
        router.go('/home');
      }
      return;
    }

    setState(() => _isChecking = false);
    if (!mounted) return;
    VaultAccessSession.reset();
    router.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: brandRed)),
      );
    }

    if (!_authorized) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    return widget.child;
  }
}
