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
  static const _kPendingTwoFactorEmail = 'pending_two_factor_email';
  static const _kPendingTwoFactorPersist = 'pending_two_factor_persist';
  static const _kPendingRegisterEmail = 'pending_register_email';
  static const _kReminderNotificationsEnabled =
      'reminder_notifications_enabled';

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
      _storage.delete(key: _kPendingTwoFactorEmail),
      _storage.delete(key: _kPendingTwoFactorPersist),
      _storage.delete(key: _kPendingRegisterEmail),
    ]);
  }

  // ── Update partial profile data ────────────────────────────────────────────
  static Future<void> updateNameAndAvatar({
    required String name,
    String? avatar,
  }) async {
    await Future.wait([
      _storage.write(key: _kUserName, value: name),
      if (avatar != null)
        _storage.write(key: _kUserAvatar, value: avatar)
      else
        _storage.delete(key: _kUserAvatar),
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
      _storage.delete(key: _kPendingTwoFactorEmail),
      _storage.delete(key: _kPendingTwoFactorPersist),
      _storage.delete(key: _kPendingRegisterEmail),
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

  // ── Pending 2FA login ─────────────────────────────────────────────────────
  static Future<void> setPendingTwoFactorLogin({
    required String email,
    required bool persistLogin,
  }) async {
    await Future.wait([
      _storage.write(key: _kPendingTwoFactorEmail, value: email.trim()),
      _storage.write(
        key: _kPendingTwoFactorPersist,
        value: persistLogin ? 'true' : 'false',
      ),
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserId),
      _storage.delete(key: _kUserEmail),
      _storage.delete(key: _kUserName),
      _storage.delete(key: _kUserAvatar),
      _storage.delete(key: _kSessionPersistent),
    ]);
  }

  static Future<void> clearPendingTwoFactorLogin() async {
    await Future.wait([
      _storage.delete(key: _kPendingTwoFactorEmail),
      _storage.delete(key: _kPendingTwoFactorPersist),
    ]);
  }

  static Future<bool> hasPendingTwoFactorLogin() async {
    final email = await _storage.read(key: _kPendingTwoFactorEmail);
    return email != null && email.isNotEmpty;
  }

  static Future<String?> getPendingTwoFactorEmail() =>
      _storage.read(key: _kPendingTwoFactorEmail);

  static Future<bool> getPendingTwoFactorPersistLogin() async {
    final val = await _storage.read(key: _kPendingTwoFactorPersist);
    return val == 'true';
  }

  static Future<void> setPendingRegistration({required String email}) =>
      _storage.write(key: _kPendingRegisterEmail, value: email.trim());

  static Future<void> clearPendingRegistration() =>
      _storage.delete(key: _kPendingRegisterEmail);

  static Future<String?> getPendingRegistrationEmail() =>
      _storage.read(key: _kPendingRegisterEmail);

  // ── Reminder Notifications ────────────────────────────────────────────────
  static Future<void> setReminderNotificationsEnabled(bool enabled) =>
      _storage.write(
        key: _kReminderNotificationsEnabled,
        value: enabled ? 'true' : 'false',
      );

  static Future<bool> getReminderNotificationsEnabled() async {
    final val = await _storage.read(key: _kReminderNotificationsEnabled);
    if (val == null) return true;
    return val == 'true';
  }
}
