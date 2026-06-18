import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../config/app_config.dart';
import '../services/biometric_service.dart';
import '../services/security_service.dart';
import '../services/revenuecat_service.dart';
import '../services/subscription_service.dart';
import '../services/vault_session_manager.dart';

/// A single gate widget that checks BOTH subscription status and vault auth
/// (PIN / biometrics) in a single linear async flow, with NO stream re-builds
/// that would cause the screen to flicker or shake.
///
/// Registers with [VaultSessionManager] via enter/leave gate so that
/// navigating between vault sub-routes does NOT trigger a lock, while
/// leaving the vault entirely (or the app going to background) does.
/// Also tracks user interaction for the idle timeout.
///
/// Registers with [VaultSessionManager] via enter/leave gate so that
/// navigating between vault sub-routes does NOT trigger a lock, while
/// leaving the vault entirely (or the app going to background) does.
/// Also tracks user interaction for the idle timeout.
class VaultAccessGate extends StatefulWidget {
  final Widget child;

  const VaultAccessGate({super.key, required this.child});

  @override
  State<VaultAccessGate> createState() => _VaultAccessGateState();
}

class _VaultAccessGateState extends State<VaultAccessGate>
    with WidgetsBindingObserver {
  bool _authorized = false;
  bool _checking = true;
  bool _started = false;

  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final mgr = VaultSessionManager.instance;
    mgr.enterGate();

    // Re-run the gate if the session manager notifies (e.g. on background lock).
    mgr.addListener(_onSessionChanged);

    Future.microtask(() {
      if (mounted && !_started) _runGate();
    });
  }

  @override
  void dispose() {
    VaultSessionManager.instance.removeListener(_onSessionChanged);
    VaultSessionManager.instance.leaveGate();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── App lifecycle observer ─────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      VaultSessionManager.instance.onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      VaultSessionManager.instance.onAppBackground();
    }
  }

  // ── Session-manager listener ───────────────────────────────────────────────

  void _onSessionChanged() {
    if (!mounted) return;
    if (!VaultSessionManager.instance.isUnlocked) {
      // Vault was locked externally (background / idle timeout).
      _goHome(shouldLock: false);
    }
  }

  // ── Gate logic ─────────────────────────────────────────────────────────────

  Future<void> _runGate() async {
    if (_started) return;
    _started = true;

    try {
      // ── Step 1: Check subscription (one-time read, not a stream) ──────────
      final subscription = await _subscriptionService
          .streamSubscription()
          .first;

      if (!mounted) return;

      // Fallback: if Firestore shows inactive, check RevenueCat directly.
      // RevenueCat's backend may have activated the entitlement before the
      // Firestore sync completed.
      bool isActive = subscription.isActive;
      if (!isActive && !AppConfig.bypassVaultSubscription) {
        try {
          final activeSubscription = await _subscriptionService
              .waitForActiveSubscription(timeout: const Duration(seconds: 8));
          isActive = activeSubscription.isActive;
        } catch (_) {
          final rcActive = await RevenueCatService().checkProEntitlement();
          if (rcActive) {
            // Force a Firestore sync so future reads see the correct state.
            final customerInfo = await RevenueCatService().getCustomerInfo();
            await RevenueCatService().syncToFirestore(customerInfo);
            isActive = true;
          }
        }
      }

      if (!isActive && !AppConfig.bypassVaultSubscription) {
        VaultSessionManager.instance.lock();
        // Replace the gated vault route so back navigation returns to the
        // previous stable screen instead of a half-initialized gate.
        GoRouter.of(context).pushReplacement(
          '/subscription-plan',
          extra: {'openedFromVaultGate': true},
        );
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (VaultSessionManager.instance.isUnlockedFor(uid)) {
        setState(() {
          _authorized = true;
          _checking = false;
        });
        return;
      }

      // ── Step 2: Check vault auth (PIN / biometrics) ───────────────────────
      final pinEnabled = await SecurityService.isPinSet();

      if (!mounted) return;

      if (!pinEnabled) {
        VaultSessionManager.instance.lock();
        GoRouter.of(
          context,
        ).pushReplacement('/set-pin', extra: {'afterSetupRoute': '/vault'});
        return;
      }

      final biometricEnabled = await SecurityService.isBiometricEnabled();

      if (!mounted) return;

      // Try biometrics first
      if (biometricEnabled) {
        final reason = await BiometricService.unavailableReason();
        if (reason == null) {
          final success = await BiometricService.authenticate(
            reason: 'Authenticate to open your FFP Vault',
          );
          if (!mounted) return;
          if (success) {
            VaultSessionManager.instance.unlock(userId: uid);
            setState(() {
              _authorized = true;
              _checking = false;
            });
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
          VaultSessionManager.instance.unlock();
          setState(() {
            _authorized = true;
            _checking = false;
          });
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

  void _goHome({bool shouldLock = true}) {
    if (!mounted) return;
    if (shouldLock) {
      VaultSessionManager.instance.lock();
    }
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

    // Wrap child with a Listener to track user activity for idle timeout.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => VaultSessionManager.instance.updateActivity(),
      onPointerMove: (_) => VaultSessionManager.instance.updateActivity(),
      child: widget.child,
    );
  }
}
