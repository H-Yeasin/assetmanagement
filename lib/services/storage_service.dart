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
  // Versioned key: force one-time onboarding once after this update.
  static const _kOnboardingSeen = 'onboarding_seen_v2';
  static const _kSessionPersistent = 'session_persistent';
  static const _kRememberMe = 'remember_me';
  static const _kRememberedEmail = 'remembered_email';

  // ── Save session after login / register ────────────────────────────────────
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String name,
    String? avatar,
    bool persistLogin = true,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kUserId, value: userId),
      _storage.write(key: _kUserEmail, value: email),
      _storage.write(key: _kUserName, value: name),
      _storage.write(
        key: _kSessionPersistent,
        value: persistLogin ? 'true' : 'false',
      ),
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
      _storage.delete(key: _kSessionPersistent),
    ]);
  }

  static Future<bool> isSessionPersistent() async {
    final val = await _storage.read(key: _kSessionPersistent);
    return val == 'true';
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────
  static Future<void> setOnboardingSeen() =>
      _storage.write(key: _kOnboardingSeen, value: 'true');

  static Future<bool> hasSeenOnboarding() async {
    final val = await _storage.read(key: _kOnboardingSeen);
    return val == 'true';
  }

  // ── Remember Me ────────────────────────────────────────────────────────────
  static Future<void> setRememberMe({
    required bool enabled,
    String? email,
  }) async {
    await Future.wait([
      _storage.write(key: _kRememberMe, value: enabled ? 'true' : 'false'),
      if (enabled && email != null && email.trim().isNotEmpty)
        _storage.write(key: _kRememberedEmail, value: email.trim())
      else
        _storage.delete(key: _kRememberedEmail),
    ]);
  }

  static Future<bool> getRememberMe() async {
    final val = await _storage.read(key: _kRememberMe);
    return val == 'true';
  }

  static Future<String?> getRememberedEmail() =>
      _storage.read(key: _kRememberedEmail);
}
