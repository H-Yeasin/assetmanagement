import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles all on-device security: PIN hashing/verification and biometric flag.
class SecurityService {
  static const _storage = FlutterSecureStorage();

  // ── Secure storage keys ────────────────────────────────────────────────────
  static const _kPin = 'app_pin_hash';
  static const _kPinEnabled = 'pin_enabled';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _k2faEnabled = '2fa_enabled';
  static const _k2faEmail = '2fa_email';

  // ── PIN ────────────────────────────────────────────────────────────────────

  /// Hash the raw PIN using SHA-256 and store it securely.
  static Future<void> setPin(String pin) async {
    final pinKey = _scopedKey(_kPin);
    final pinEnabledKey = _scopedKey(_kPinEnabled);
    if (pinKey == null || pinEnabledKey == null) return;

    final hash = _hashPin(pin);
    await Future.wait([
      _storage.write(key: pinKey, value: hash),
      _storage.write(key: pinEnabledKey, value: 'true'),
    ]);
  }

  /// Returns true if the supplied [pin] matches the stored hash.
  static Future<bool> verifyPin(String pin) async {
    final pinKey = _scopedKey(_kPin);
    if (pinKey == null) return false;

    final stored = await _storage.read(key: pinKey);
    if (stored == null) return false;
    return _hashPin(pin) == stored;
  }

  /// Returns true if a PIN has been set by the user.
  static Future<bool> isPinSet() async {
    final pinEnabledKey = _scopedKey(_kPinEnabled);
    if (pinEnabledKey == null) return false;

    final val = await _storage.read(key: pinEnabledKey);
    return val == 'true';
  }

  /// Removes the stored PIN and disables PIN protection.
  static Future<void> clearPin() async {
    final pinKey = _scopedKey(_kPin);
    final pinEnabledKey = _scopedKey(_kPinEnabled);
    if (pinKey == null || pinEnabledKey == null) return;

    await Future.wait([
      _storage.delete(key: pinKey),
      _storage.write(key: pinEnabledKey, value: 'false'),
    ]);
  }

  // ── Biometrics ─────────────────────────────────────────────────────────────

  /// Persists whether biometric unlock is enabled.
  static Future<void> setBiometricEnabled(bool enabled) async {
    final biometricKey = _scopedKey(_kBiometricEnabled);
    if (biometricKey == null) return;

    await _storage.write(key: biometricKey, value: enabled ? 'true' : 'false');
  }

  /// Returns true if biometric unlock has been enabled by the user.
  static Future<bool> isBiometricEnabled() async {
    final biometricKey = _scopedKey(_kBiometricEnabled);
    if (biometricKey == null) return false;

    final val = await _storage.read(key: biometricKey);
    return val == 'true';
  }

  // ── 2FA ────────────────────────────────────────────────────────────────────

  static Future<void> set2faEnabled(bool enabled, {String email = ''}) async {
    await Future.wait([
      _storage.write(key: _k2faEnabled, value: enabled ? 'true' : 'false'),
      _storage.write(key: _k2faEmail, value: email),
    ]);
  }

  static Future<bool> is2faEnabled() async {
    final val = await _storage.read(key: _k2faEnabled);
    return val == 'true';
  }

  static Future<String> get2faEmail() async {
    return await _storage.read(key: _k2faEmail) ?? '';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static String? _scopedKey(String baseKey) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return '${baseKey}_$uid';
  }
}
