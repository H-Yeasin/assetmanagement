import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Centralised session manager for the Vault.
///
/// Responsibilities:
/// - Tracks unlocked state via a reference-counting gate pattern
///   so that navigating between vault sub-routes does NOT lock.
/// - Listens to app lifecycle events and locks automatically when
///   the app goes to background / becomes inactive / is detached.
/// - Enforces an idle timeout of [idleTimeout].
///
/// Usage:
///   Every `VaultAccessGate` calls `enterGate()` in initState and
///   `leaveGate()` in dispose.  When the count drops to zero, the
///   vault is locked with a short delay that allows a new gate
///   widget to register in the same frame.
class VaultSessionManager extends ChangeNotifier {
  VaultSessionManager._();

  static final VaultSessionManager instance = VaultSessionManager._();

  // ── Session state ──────────────────────────────────────────────────────────

  bool _isUnlocked = false;
  String? _unlockedUserId;
  bool _expectingExternalActivity = false;
  Timer? _externalActivityTimer;

  bool get isUnlocked => _isUnlocked;

  /// Mark that an external activity (camera, file-picker, etc.) is about to
  /// open.  The flag stays active for [_externalActivityWindow] so that
  /// **all** lifecycle transitions triggered by the same intent are ignored.
  /// It is cleared automatically on timeout or when [onAppResumed] is called.
  static const Duration _externalActivityWindow = Duration(seconds: 60);

  void expectExternalActivity() {
    _expectingExternalActivity = true;
    _externalActivityTimer?.cancel();
    _externalActivityTimer = Timer(_externalActivityWindow, () {
      _expectingExternalActivity = false;
      _externalActivityTimer = null;
    });
  }

  /// Called when the app returns to the foreground after an external activity.
  void onAppResumed() {
    _externalActivityTimer?.cancel();
    _externalActivityTimer = null;
    // Keep the flag alive briefly in case the OS fires another paused/inactive
    // event immediately after resume (some Android OEMs do this).
    if (_expectingExternalActivity) {
      _externalActivityTimer = Timer(const Duration(seconds: 2), () {
        _expectingExternalActivity = false;
        _externalActivityTimer = null;
      });
    }
  }

  bool isUnlockedFor(String? userId) =>
      userId != null && _isUnlocked && _unlockedUserId == userId;

  // ── Reference counting for vault gates ─────────────────────────────────────
  int _activeGateCount = 0;

  /// Called by a VaultAccessGate when it mounts (initState).
  void enterGate() {
    _activeGateCount++;
    _cancelPendingLock();
  }

  /// Called by a VaultAccessGate when it disposes.
  ///
  /// The actual lock is deferred by one frame to allow a new gate
  /// on the next vault sub-page to register via [enterGate] before
  /// the count is re-evaluated.
  void leaveGate() {
    _activeGateCount--;
    if (_activeGateCount < 0) _activeGateCount = 0;

    _cancelPendingLock();
    // Use a short Timer (0 duration) to defer the check by one event-loop cycle.
    // This gives any newly mounted gate on the next page time to call enterGate().
    _pendingLockTimer = Timer(Duration.zero, _evaluateLock);
  }

  Timer? _pendingLockTimer;

  void _cancelPendingLock() {
    _pendingLockTimer?.cancel();
    _pendingLockTimer = null;
  }

  void _evaluateLock() {
    _pendingLockTimer = null;
    if (_activeGateCount <= 0) {
      _isUnlocked = false;
      _unlockedUserId = null;
      _cancelIdleTimer();
      notifyListeners();
    }
  }

  // ── Unlock / Lock API ──────────────────────────────────────────────────────

  void unlock({String? userId}) {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _isUnlocked = false;
      _unlockedUserId = null;
      return;
    }
    _isUnlocked = true;
    _unlockedUserId = uid;
    _resetIdleTimer();
    notifyListeners();
  }

  void lock() {
    _isUnlocked = false;
    _unlockedUserId = null;
    _cancelIdleTimer();
    _cancelPendingLock();
    notifyListeners();
  }

  // ── Activity tracking & idle timeout ───────────────────────────────────────

  static const Duration idleTimeout = Duration(minutes: 5);

  Timer? _idleTimer;

  /// Call this whenever the user interacts with the vault (tap, scroll, etc.).
  void updateActivity() {
    if (!_isUnlocked) return;
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _cancelIdleTimer();
    _idleTimer = Timer(idleTimeout, _onIdleTimeout);
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _onIdleTimeout() {
    debugPrint('VaultSessionManager: idle timeout reached – locking vault');
    lock();
  }

  // ── Lifecycle lock ─────────────────────────────────────────────────────────

  /// Called when the app transitions to paused/inactive/detached.
  /// Locks the vault unless an external activity (camera, file-picker) is
  /// expected.  The flag is NOT consumed here — it stays active until the
  /// timer expires or [onAppResumed] clears it.
  void onAppBackground() {
    if (!_isUnlocked) return;
    if (_expectingExternalActivity) {
      debugPrint(
        'VaultSessionManager: app backgrounded for expected external activity – NOT locking vault',
      );
      return;
    }
    debugPrint('VaultSessionManager: app backgrounded – locking vault');
    lock();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _cancelIdleTimer();
    _cancelPendingLock();
    _externalActivityTimer?.cancel();
    _externalActivityTimer = null;
    super.dispose();
  }
}
