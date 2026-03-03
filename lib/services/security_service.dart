import 'dart:convert';
import 'package:crypto/crypto.dart';
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
    final hash = _hashPin(pin);
    await Future.wait([
      _storage.write(key: _kPin, value: hash),
      _storage.write(key: _kPinEnabled, value: 'true'),
    ]);
  }

  /// Returns true if the supplied [pin] matches the stored hash.
  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPin);
    if (stored == null) return false;
    return _hashPin(pin) == stored;
  }

  /// Returns true if a PIN has been set by the user.
  static Future<bool> isPinSet() async {
    final val = await _storage.read(key: _kPinEnabled);
    return val == 'true';
  }

  /// Removes the stored PIN and disables PIN protection.
  static Future<void> clearPin() async {
    await Future.wait([
      _storage.delete(key: _kPin),
      _storage.write(key: _kPinEnabled, value: 'false'),
    ]);
  }

  // ── Biometrics ─────────────────────────────────────────────────────────────

  /// Persists whether biometric unlock is enabled.
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _kBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Returns true if biometric unlock has been enabled by the user.
  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _kBiometricEnabled);
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
}
