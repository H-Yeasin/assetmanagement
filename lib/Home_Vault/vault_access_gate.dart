import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../Home_Dashboard/widgets.dart';
import '../services/biometric_service.dart';
import '../services/security_service.dart';
import '../services/subscription_service.dart';
import '../services/storage_service.dart';

/// Tracks whether the vault session is unlocked for the current app session.
class VaultAccessSession {
  static bool _isUnlocked = false;

  static bool get isUnlocked => _isUnlocked;

  static void unlock() => _isUnlocked = true;

  static void reset() => _isUnlocked = false;
}

/// A single gate widget that checks BOTH subscription status and vault auth
/// (PIN / biometrics) in a single linear async flow, with NO stream re-builds
/// that would cause the screen to flicker or shake.
class VaultAccessGate extends StatefulWidget {
  final Widget child;

  const VaultAccessGate({super.key, required this.child});

  @override
  State<VaultAccessGate> createState() => _VaultAccessGateState();
}

class _VaultAccessGateState extends State<VaultAccessGate> {
  bool _authorized = false;
  bool _checking = true;
  bool _started = false;

  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    if (VaultAccessSession.isUnlocked) {
      _authorized = true;
      _checking = false;
      _started = true;
    } else {
      Future.microtask(() {
        if (mounted && !_started) _runGate();
      });
    }
  }

  Future<void> _runGate() async {
    if (_started) return;
    _started = true;

    try {
      // ── Step 1: Check subscription (one-time read, not a stream) ──────────
      final subscription = await _subscriptionService
          .streamSubscription()
          .first;

      if (!mounted) return;

      // BYPASS: If in debug mode or if a bypass flag is set, allow access
      final bool bypassSubscription = kDebugMode; 

      if (!subscription.isActive && !bypassSubscription) {
        // Replace the gated vault route so back navigation returns to the
        // previous stable screen instead of a half-initialized gate.
        GoRouter.of(context).pushReplacement(
          '/subscription-plan',
          extra: {'openedFromVaultGate': true},
        );
        return;
      }

      // ── Step 2: Check vault auth (PIN / biometrics) ───────────────────────
      final biometricEnabled = await SecurityService.isBiometricEnabled();
      final pinEnabled = await SecurityService.isPinSet();

      if (!mounted) return;

      // No lock — grant access
      if (!biometricEnabled && !pinEnabled) {
        VaultAccessSession.unlock();
        if (mounted) setState(() { _authorized = true; _checking = false; });
        return;
      }

      // Try biometrics first
      if (biometricEnabled) {
        final reason = await BiometricService.unavailableReason();
        if (reason == null) {
          final success = await BiometricService.authenticate(
            reason: 'Authenticate to open your FFP Vault',
          );
          if (!mounted) return;
          if (success) {
            VaultAccessSession.unlock();
            setState(() { _authorized = true; _checking = false; });
            return;
          }
          _goHome();
          return;
        }
      }

      // Fall back to PIN
      if (pinEnabled) {
        if (!mounted) return;
        final result = await GoRouter.of(context).push<bool>('/pin-verify');
        if (!mounted) return;
        if (result == true) {
          VaultAccessSession.unlock();
          setState(() { _authorized = true; _checking = false; });
          return;
        }
        // PIN cancelled → go home
        _goHome();
        return;
      }

      _goHome();
    } catch (e) {
      debugPrint('VaultAccessGate error: $e');
      _goHome();
    }
  }

  void _goHome() {
    if (!mounted) return;
    VaultAccessSession.reset();
    GoRouter.of(context).go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
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
