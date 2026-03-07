import 'package:local_auth/local_auth.dart';

/// Wraps [LocalAuthentication] to check device capability and authenticate.
class BiometricService {
  static final _auth = LocalAuthentication();

  /// Returns true if the device hardware supports biometrics.
  static Future<bool> isHardwareSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the device has biometrics enrolled (fingerprint, face ID, etc.)
  static Future<bool> hasEnrolledBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the primary [BiometricType] available, or null if none.
  static Future<BiometricType?> primaryBiometricType() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      if (available.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      if (available.contains(BiometricType.face)) return BiometricType.face;
      if (available.isEmpty) return null;
      return available.first;
    } catch (_) {
      return null;
    }
  }

  /// Returns a user-friendly label for the available biometric type.
  static Future<String> biometricLabel() async {
    final type = await primaryBiometricType();
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      default:
        return 'Biometric';
    }
  }

  /// Triggers the native biometric prompt.
  /// Returns true on successful authentication.
  static Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Quick summary: is the device ready for biometric auth?
  /// Returns null if ready, or a human-readable reason string if not.
  static Future<String?> unavailableReason() async {
    final supported = await isHardwareSupported();
    if (!supported) {
      return 'This device does not support biometric authentication.';
    }
    final enrolled = await hasEnrolledBiometrics();
    if (!enrolled) {
      return 'No biometric (fingerprint / face) enrolled on this device. Please set one up in device Settings first.';
    }
    return null; // all good
  }
}
