import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles all secure token / session persistence for the app.
class StorageService {
  static const _storage = FlutterSecureStorage();

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kUserEmail = 'user_email';
  static const _kUserName = 'user_name';
  static const _kUserAvatar = 'user_avatar';
  static const _kOnboardingSeen = 'onboarding_seen';

  // ── Save session after login / register ────────────────────────────────────
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String name,
    String? avatar,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kUserId, value: userId),
      _storage.write(key: _kUserEmail, value: email),
      _storage.write(key: _kUserName, value: name),
      if (avatar != null) _storage.write(key: _kUserAvatar, value: avatar),
    ]);
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  static Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _kRefreshToken);

  static Future<String?> getUserId() => _storage.read(key: _kUserId);

  static Future<String?> getUserEmail() => _storage.read(key: _kUserEmail);

  static Future<String?> getUserName() => _storage.read(key: _kUserName);

  static Future<String?> getUserAvatar() => _storage.read(key: _kUserAvatar);

  /// Returns true if an access token is stored (user is logged in).
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _kAccessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserId),
      _storage.delete(key: _kUserEmail),
      _storage.delete(key: _kUserName),
      _storage.delete(key: _kUserAvatar),
    ]);
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────
  static Future<void> setOnboardingSeen() =>
      _storage.write(key: _kOnboardingSeen, value: 'true');

  static Future<bool> hasSeenOnboarding() async {
    final val = await _storage.read(key: _kOnboardingSeen);
    return val == 'true';
  }
}
